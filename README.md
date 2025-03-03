# Digilent Arty A7 Experiments

This repository contains experiments with the Digilient Arty A7 FPGA development board, which
features a Xilinx Artix-7 FPGA. The justfile enables a fully open-source flow using f4pga tools.

## Getting started

There are a handful of software dependencies you'll need to have installed in order to use the
flows in this repo. For simulation setup, see [penguin](https://github.com/infinitymdm/penguin?tab=readme-ov-file#getting-started).

- [Project X-Ray](https://github.com/f4pga/prjxray) for working with 7 series FPGAs
- [yosys](https://github.com/YosysHQ/yosys) for synthesis
- [nextpnr-xilinx](https://github.com/gatecat/nextpnr-xilinx) for place & route
- [OpenOCD](https://github.com/openocd-org/openocd) for uploading bitstreams

Once you've got all those installed, run `just --list` to see available recipes. Maybe try
`just pnr top_test` to make sure everything is working.

## Other Resources

- [Digilent Arty A7 Reference Manual](https://digilent.com/reference/programmable-logic/arty-a7/reference-manual)
