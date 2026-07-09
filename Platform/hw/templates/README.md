# Hardware Templates

`custom_accelerator_template.v` is a compute-only accelerator skeleton with the
same CPU and AXI port shape as the current `srcs/NPU.v` example.

To use it as a drop-in replacement for the current Vivado block design, copy it
to `srcs/`, rename the module to match the block design IP name if needed, and
add your `funct3_i/funct7_i` cases.
