# Device configuration
dev_series  := "artix7"
dev_model   := "xc7a100t"
dev_part    := dev_model + "csg324-1"
constraints := `find constraints -name "*.xdc" | tr '\n' ' '`
board_cfg   := "config/arty_a7.cfg"

# dirs
work_dir      := 'work'
rpt_dir       := work_dir + '/reports'
ckpt_dir      := work_dir + '/checkpoints'
synth_script  := work_dir + '/synth.tcl'
place_script  := work_dir + '/place.tcl'
route_script  := work_dir + '/route.tcl'
upload_script := work_dir + '/upload.tcl'

# parse source files
src_sv := `find hdl/src -name "*.sv" | tr '\n' ' '`

# vivado configuration
# change if vivado is installed somewhere else
vivado_path  := '/opt/xilinx/Vivado/2024.2/bin'
vivado_flags := '-nolog -nojournal -mode batch'


## Private recipes

_default:
    @just --list --justfile vivado.just

_prep:
    @mkdir -p {{rpt_dir}}
    @mkdir -p {{ckpt_dir}}

# Clean up generated files
clean:
    rm -rf {{work_dir}}

# Write the synth.tcl script
_write_synth_script design: _prep
    @echo "read_verilog -sv {{src_sv}}" > {{synth_script}}
    @echo "read_verilog top/{{design}}.sv" >> {{synth_script}}
    @echo "read_xdc {{constraints}}" >> {{synth_script}}
    @echo "synth_design -top {{design}} -part {{dev_part}}" >> {{synth_script}}
    @echo "write_checkpoint -force {{ckpt_dir}}/post_synth" >> {{synth_script}}
    @echo "report_timing_summary -file {{rpt_dir}}/post_synth_timing.rpt" >> {{synth_script}}
    @echo "report_power -file {{rpt_dir}}/power.rpt" >> {{synth_script}}

# Write the place.tcl script
_write_place_script design: _prep
    @echo "open_checkpoint -part {{dev_part}} {{ckpt_dir}}/post_synth.dcp" > {{place_script}}
    @echo "read_xdc {{constraints}}" >> {{place_script}}
    @echo "opt_design" >> {{place_script}}
    @echo "place_design" >> {{place_script}}
    @echo "phys_opt_design" >> {{place_script}}
    @echo "write_checkpoint -force {{ckpt_dir}}/post_place" >> {{place_script}}
    @echo "report_timing_summary -file {{rpt_dir}}/post_place_timing.rpt" >> {{place_script}}

# Write the route.tcl script
_write_route_script design: _prep
    @echo "open_checkpoint -part {{dev_part}} {{ckpt_dir}}/post_place.dcp" > {{route_script}}
    @echo "read_xdc {{constraints}}" >> {{route_script}}
    @echo "route_design" >> {{route_script}}
    @echo "write_checkpoint -force {{ckpt_dir}}/post_route" >> {{route_script}}
    @echo "report_timing_summary -file {{rpt_dir}}/post_route_timing.rpt" >> {{route_script}}
    @echo "report_timing -sort_by group -max_paths 100 -path_type summary -file {{rpt_dir}}/final_timing.rpt" >> {{route_script}}
    @echo "report_clock_utilization -file {{rpt_dir}}/final_clock_util.rpt" >> {{route_script}}
    @echo "report_power -file {{rpt_dir}}/final_power.rpt" >> {{route_script}}
    @echo "report_drc -file {{rpt_dir}}/final_drc.rpt" >> {{route_script}}
    @echo "write_bitstream -force {{work_dir}}/{{design}}.bit" >> {{route_script}}

# Write the upload.tcl script
_write_upload_script design: _prep
    @echo "open_hw_manager" > {{upload_script}}
    @echo "connect_hw_server" >> {{upload_script}}
    @echo "current_hw_target" >> {{upload_script}}
    @echo "open_hw_target" >> {{upload_script}}
    @echo "current_hw_device" >> {{upload_script}}
    @echo "set_property PROGRAM.FILE {{work_dir}}/{{design}}.bit [current_hw_device]" >> {{upload_script}}
    @echo "program_hw_device [current_hw_device]" >> {{upload_script}}

# Synthesize a design
synth design: (_write_synth_script design)
    {{vivado_path}}/vivado {{vivado_flags}} -source {{synth_script}}

# Place and route a design
pnr design: (synth design) (_write_place_script design) (_write_route_script design)
    {{vivado_path}}/vivado {{vivado_flags}} -source {{place_script}}
    {{vivado_path}}/vivado {{vivado_flags}} -source {{route_script}}

# Upload a synthesized bitstream to the device
upload design: (pnr design) (_write_upload_script design)
    {{vivado_path}}/vivado {{vivado_flags}} -source {{upload_script}}
