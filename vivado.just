# Device configuration
dev_series  := "artix7"
dev_model   := "xc7a100t"
dev_part    := dev_model + "csg324-1"
constraints := `find constraints -name "*.xdc" | tr '\n' ' '`

# dirs
synth_dir   := 'synth'

# parse source files
include_dirs    := `find hdl/{src,include} -name '*.svh' -printf '-I%h\n' | sort -u | tr '\n' ' '`
src_sv          := `find hdl/src -name "*.sv" | tr '\n' ' '`


## Private recipes

_default:
    @just --list

_prep:
    @mkdir -p {{synth_dir}}

# Clean up generated files
clean:
    rm -rf {{synth_dir}}

# Synthesize a design
synth design *FLAGS: _prep
    #! /opt/xilinx/Vivado/2024.2/bin/xtclsh
    set f [open {{synth_dir}}/test "a"];
    puts $f "test test 123"
    close $f
