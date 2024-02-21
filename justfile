# Device information
dev_family := "artix7"
dev_model := "xc7a100t"
dev_submodel := dev_model + "csg324-1"

# Project X-ray tools
xray_dir := "../prjxray"
xray_utils_dir := xray_dir + "/utils"
xray_tools_dir := xray_dir + "/build/tools"
xray_db_dir := xray_dir + "/database"

# nextpnr-xilinx tools
nextpnr_dir := "../nextpnr-xilinx"

sources := `find src -name *.sv`

build-chipdb: 
    pypy3 {{nextpnr_dir}}/xilinx/python/bbaexport.py --device {{dev_submodel}} --bba {{dev_model}}.bba
    bbasm --l {{dev_model}}.bba {{dev_model}}.bin

# Synthesize and layout the design
synth top:
    #! /usr/bin/env bash
    XRAY_DATABASE={{dev_family}} XRAY_PART={{dev_submodel}} source {{xray_utils_dir}}/environment.sh
    yosys -q -p "synth_xilinx -flatten -nowidelut -abc9 -arch xc7 -top {{top}}; write_json {{dev_model}}.json" {{sources}}
    nextpnr-xilinx -q --chipdb {{dev_model}}.bin --xdc constraints/arty.xdc --json {{dev_model}}.json --write {{dev_model}}_routed.json --fasm {{dev_model}}.fasm
    {{xray_utils_dir}}/fasm2frames.py --db-root {{xray_db_dir}}/{{dev_family}} --part {{dev_submodel}} {{dev_model}}.fasm > {{dev_model}}.frames
    {{xray_tools_dir}}/xc7frames2bit --part_file {{xray_db_dir}}/{{dev_family}}/{{dev_submodel}}/part.yaml --part_name {{dev_submodel}} --frm_file {{dev_model}}.frames --output_file {{dev_model}}.bit

# Upload the synthesized bitstream to the device
upload top: (synth top)
    openFPGALoader -b arty {{dev_model}}.bit
