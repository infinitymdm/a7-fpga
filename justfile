# Recipes for working with 🐧 hdl
mod hdl

# Device configuration
dev_series  := "artix7"
dev_model   := "xc7a100t"
dev_part    := dev_model + "csg324-1"
constraints := `find constraints -name "*.xdc" | tr '\n' ' '`

# paths
synth_dir   := "synth"
synth_name  := synth_dir + "/" + dev_part
xray_db     := "/usr/share/xray/database"
series_db   := xray_db + "/" + dev_series
part_file   := series_db + "/" + dev_part + "/part.yaml"
part_db     := "/usr/share/nextpnr/xilinx-chipdb/" + dev_part + ".bin"
board_cfg   := "config/arty_a7.cfg"

_default:
    @just --list

_prep:
    @mkdir -p {{synth_dir}}

# Clean up generated files
clean:
    @just hdl::clean
    rm -rf {{synth_dir}}

# Synthesize a design
synth design *SV2V_FLAGS: _prep
    @just hdl::preprocess {{design}} {{SV2V_FLAGS}} `find ~+/top -name {{design}}.sv`
    yosys -q -p "synth_xilinx -nowidelut -abc9 -arch xc7 -top {{design}}; write_json {{synth_name}}_{{design}}.json" `find . -name "*.v" | tr '\n' ' '`

# Place and route a design
pnr design *SV2V_FLAGS: (synth design SV2V_FLAGS)
    nextpnr-xilinx -q \
        --chipdb {{part_db}} \
        --xdc   {{constraints}} \
        --json  {{synth_name}}_{{design}}.json \
        --write {{synth_name}}_{{design}}_routed.json \
        --fasm  {{synth_name}}_{{design}}.fasm
    fasm2frames \
        --db-root {{series_db}} \
        --part {{dev_part}} \
        {{synth_name}}_{{design}}.fasm > {{synth_name}}_{{design}}.frames
    xc7frames2bit \
        --part_file     {{part_file}} \
        --part_name     {{dev_part}} \
        --frm_file      {{synth_name}}_{{design}}.frames \
        --output_file   {{synth_name}}_{{design}}.bit

# Upload a synthesized bitstream to the device
upload design *SV2V_FLAGS: (pnr design SV2V_FLAGS)
    @# openFPGALoader -b arty {{synth_name}}_{{design}}.bit
    openocd -f {{board_cfg}} -c "init;pld load 0 {{synth_name}}_{{design}}.bit;shutdown"
