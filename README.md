# CUSTOM_SoC_Platform

**Version 1.1** Support CBO.clean, CBO.flush, CBO.invalidate, fence.i operations <br></br>
**Version 1.0** Original version

## Environment Setup

### Step 0: Initial Preparation
Prepare a clean directory in your Linux environment and navigate into it.

### Step 1: Install RISC-V toolchain ([Download linux-ubuntu](https://github.com/sifive/freedom-tools/releases/tag/v2020.08.0))
Open your terminal and execute the following commands to download and extract the toolchain:
![](https://hackmd.io/_uploads/rk517Ux02.png)

Download the August 2020 toolchain from freedom-tools and unpack the binaries to your home directory:
``` bash
$ tar xvfz ~/Downloads/riscv64-unknown-elf-gcc-10.1.0-2020.08.2-x86_64-linux-ubuntu14.tar.gz
```

Add the toolchain to your PATH in your `.bashrc` or `.zshrc`:
``` bash
export PATH=$PATH:$HOME/riscv64-unknown-elf-gcc-10.1.0-2020.08.2-x86_64-linux-ubuntu14/bin
```

**Note:** `This Step 1 was just copied from CSIC30066: Accelerator Architectures for Machine Learning`<br></br>


### Step 2: Clone the Repository
```bash
touch {your folder name}
cd {your folder name}
git clone {this repo}
```

### Step 3: Set Permissions
```bash
cd CUSTOM_SoC_Platform/Platform
chmod +x hw/run_hw.sh
```

## Structure Introduction
### hw folder
```text
hw/        
├── boot/
├── srcs/
├── build_SoC.tcl
├── program.tcl
└── run_hw.sh
```
This folder contains all boot-related and Verilog files.
* To modify the boot sequence, edit linker_bram.ld, start.s in the boot/ folder.


### sw folder
This folder contains all software-related source files and the application code to be executed on the SoC.

## Getting Started
Once the environment is set up, navigate to the CUSTOM_SoC_Platform/Platform directory. You can manage the workflow using the following make commands:

### make command
**prog** : Synthesize the SoC hardware and program the bitstream into the FPGA. <br></br>
**run** : Compile the software application and initiate interaction with the FPGA. <br></br>
**sw_clean** : Remove software-related build artifacts from the build/ directory. <br></br>
**hw_clean** : Remove hardware-related boot files from the build/ directory. <br></br>
**clean** : Completely remove all hardware and software build files. <br></br>

## SoC Specification
Need someone to add more details.

1. System Frequency@50MHz.

## Memory Mapping
<img width="440" height="580" alt="image" src="https://github.com/user-attachments/assets/09116d81-30c0-4f12-ba76-043dab1ee0c6" />

## Appendix
The longest path: IF1->IF2->ID->EX->MEM1->MEM2->MEM3->MEM4->WB<br></br>
**alu_bench:** (8 addi instructions + 2 loop-related instructions)*10M<br></br>
**dep_bench:** (5 instructions for RAW + 2 loop-related instructions)*10M<br></br>
**load_bench:** (lw t1, 0(%0) + addi t1,t1,1 + 2 loop-related instructions)*10M<br></br>
<img width="1057" height="203" alt="image" src="https://github.com/user-attachments/assets/d8f8e8cd-88e0-4a3b-9222-41fd6eb3ba1e" />
