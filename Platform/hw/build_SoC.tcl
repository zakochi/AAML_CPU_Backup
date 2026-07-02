set origin_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize "$origin_dir/.."]
set hw_srcs "$origin_dir/srcs"
set proj_name "SoC"

create_project ${proj_name} ./${proj_name} -part xc7a100tcsg324-1 -force

# Source files
set v_files [glob -nocomplain "$hw_srcs/sources_1/imports/*.v"]
if {[llength $v_files] > 0} { add_files -norecurse $v_files }

set v_files [glob -nocomplain "$hw_srcs/*.v"]
if {[llength $v_files] > 0} { add_files -norecurse $v_files }

set ip_files [glob -nocomplain "$hw_srcs/sources_1/ip/*/*.xci"]
if {[llength $ip_files] > 0} { add_files -norecurse $ip_files }

add_files -norecurse [file normalize "$hw_srcs/sources_1/bd/MMIO/MMIO.bd"]
add_files -norecurse [file normalize "$hw_srcs/sources_1/imports/SoC.v"]
add_files -fileset constrs_1 [file normalize "$hw_srcs/constrs_1/new/Nexys-A7-100T-Master.xdc"]

# riscv_defs.v
set defs_file [file normalize "$hw_srcs/sources_1/riscv_defs.v"]
if {[file exists $defs_file]} {
    add_files -norecurse $defs_file
    set_property file_type "Verilog Header" [get_files $defs_file]
    set_property is_global_include true [get_files $defs_file]
}

set hex_path [file normalize "$root_dir/build/boot/boot.hex"]
if {[file exists $hex_path]} {
    add_files -norecurse $hex_path
} else {
    puts ">> \[TCL\] WARNING: boot.hex not found at $hex_path"
}

update_compile_order -fileset sources_1
open_bd_design [get_files MMIO.bd]


set elf_obj [get_files -quiet "*/bootloader.elf"]
if {$elf_obj != ""} {
    set_property SCOPED_TO_REF {} $elf_obj
    set_property SCOPED_TO_CELLS {} $elf_obj
}


assign_bd_address
validate_bd_design
save_bd_design
generate_target all [get_files MMIO.bd]
add_files -norecurse [make_wrapper -files [get_files MMIO.bd] -top]

set_property top SoC [current_fileset]
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

set bit_src [file normalize "./${proj_name}/${proj_name}.runs/impl_1/SoC.bit"]
if {[file exists $bit_src]} {
    file mkdir "$root_dir/build"
    file copy -force $bit_src "$root_dir/build/out.bit"
}
exit
