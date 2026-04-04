#!/bin/bash
# hw/run_hw.sh
XILINX_SETTING="/home/yc/Xilinx/Vivado/2024.1/settings64.sh"
source "$XILINX_SETTING" || { echo ">> [ERROR] Vivado settings not found!"; exit 1; }

ROOT_DIR=$(pwd)
export BUILD_DIR="$ROOT_DIR/build"
HW_DIR="$ROOT_DIR/hw"
BIT_FINAL="$BUILD_DIR/out.bit"
BOOT_HEX="$BUILD_DIR/boot/boot.hex"

NEEDS_SYNTH=true
if [ -f "$BIT_FINAL" ]; then
    RTL_CHANGES=$(find "$HW_DIR/srcs" -newer "$BIT_FINAL" 2>/dev/null)
    
    HEX_CHANGES=""
    if [ -f "$BOOT_HEX" ]; then
        HEX_CHANGES=$(find "$BOOT_HEX" -newer "$BIT_FINAL" 2>/dev/null)
    fi

    if [ -z "$RTL_CHANGES" ] && [ -z "$HEX_CHANGES" ]; then
        echo ">> [HW] RTL and Bootloader (Hex) are up to date. Skipping Full Synthesis."
        NEEDS_SYNTH=false
    fi
fi

if [ "$NEEDS_SYNTH" = true ]; then
    if [ -n "$HEX_CHANGES" ] && [ -z "$RTL_CHANGES" ]; then
        echo ">> [HW] Bootloader updated! Starting Full Synthesis to bake new ROM into Bitstream..."
    else
        echo ">> [HW] Hardware changes detected! Starting Full Synthesis..."
    fi
    
    mkdir -p "$BUILD_DIR/hw"
    cd "$BUILD_DIR/hw" || exit
    vivado -mode batch -source "$HW_DIR/build_SoC.tcl" -notrace -nolog -nojournal
    cd "$ROOT_DIR"
fi

echo ">> [HW] Programming FPGA with $BIT_FINAL..."
vivado -mode batch -source "$HW_DIR/program.tcl" -notrace -tclargs "$BIT_FINAL"