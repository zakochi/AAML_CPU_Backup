# CUSTOM SoC Software

This directory is organized to feel similar to CFU-Playground: stable framework
code lives in `app/`, project-specific code lives in `project/`, model profiles
live in `models/`, and generated files are written under `../build/sw`.

## Quick Start

```sh
make help
make config
make models
make profiles
make templates
make host-check
make host-tflm-check
make validate
make check-env
make MODEL_FILE=ad01_int8.tflite
make run MODEL_FILE=ad01_int8.tflite
```

Useful build overrides:

```sh
MODEL_FILE=ad01_int8.tflite
MODEL_PROFILE=ad01
TENSOR_ARENA_SIZE=262144
PLATFORM_CLOCK_HZ=50000000
CBO_BLOCK_BYTES=64
MODEL_TOLERANCE=2
ACCEL_STRESS_LOOPS=10000
USE_SOFTWARE_CFU=1
TARGET_PREFIX=riscv64-unknown-elf
HOST_CXX=c++
APP_DEFINES="-DMY_FLAG=1"
APP_EXTRA_SRCS="project/my_extra_file.cc"
```

For repeated local settings, copy `project.mk.example` to `project.mk` and edit
that file. `project.mk` is ignored by git, and command-line variables still
override it:

```sh
cp project.mk.example project.mk
make config
make
make MODEL_FILE=ad01_int8.tflite MODEL_PROFILE=ad01
```

`make config` prints the resolved build settings, including the selected model
profile source.

`make validate` runs the host-side checks and list/config targets that are safe
to use before the RISC-V embedded toolchain is installed.

`make host-check` syntax-checks the non-TFLM app/menu/custom-op code using the
host C++ compiler.

`make host-tflm-check` syntax-checks `app/model_io.*`, `app/tflm_runner.*`,
`project/tflm_ops.*`, and the selected model profile against the prepared TFLM
source tree. These host checks do not replace the embedded build, but they catch
common extension mistakes before the RISC-V toolchain is installed.

## Platform Configuration

Default platform constants live in `app/platform_config.h`. Override them from
the Makefile command line or `APP_DEFINES` instead of editing framework code.

Common knobs:

```sh
make PLATFORM_CLOCK_HZ=75000000
make CBO_BLOCK_BYTES=32
make MODEL_TOLERANCE=4
make ACCEL_STRESS_LOOPS=50000 ACCEL_STRESS_PROGRESS_INTERVAL=5000
```

UART base/offset/mask values, reboot delay, tensor arena defaults, and
accelerator test buffer sizing are also centralized in `app/platform_config.h`.

## File Layout

`main.cc` is intentionally small. It owns only the top-level menu, system info,
and reboot entry.

`app/menu.*` provides the UART menu runner.

`project/proj_menu.*` owns the built-in project menu entries for accelerator
tests, TFLM inference, and the user extension menu.

`project/user_menu.*` is the intended first place to add a new project-specific
test, demo, or experiment.

`app/cfu.*`, `app/software_cfu.*`, and `project/accel_ops.h` wrap CUSTOM-0 access.
Call `cfu_op(rs1, rs2, func)` for raw custom operations, or add semantic
helpers in `accel_ops.h`.

`app/cbo.h` wraps Zicbom clean/invalidate operations. Use these helpers before
or after accelerator AXI accesses that interact with cached DRAM data.

`app/perf.*` wraps `mcycle/mcycleh` and contains a small performance test menu.

`app/tflm_runner.*` owns model loading, tensor arena setup, inference, and
cycle measurement.

`project/tflm_ops.*` owns TFLM operator resolver registration. Add operators here
when a new model uses a kernel that is not currently registered.

`app/model_io.*` owns the common input/output flow. Model-specific fixture data
and golden-output behavior live in `models/<profile>_profile.cc`.

`app/platform_config.h` owns board-level defaults and test tunables. Prefer
Makefile overrides for normal bring-up and keep source edits for new defaults.

`project/` owns this platform's accelerator-specific menus, tests, and semantic
custom instruction wrappers. `npu_ops.h` and `npu_tests.h` remain as
compatibility wrappers for the current NPU example.

`models/` owns model profiles. The Makefile compiles exactly one profile into
the firmware, selected by `MODEL_PROFILE` or inferred from `MODEL_FILE`.

`templates/` contains starting points for new model profiles and extra app
sources.

`tflm_patches/` contains overlay files copied into the prepared TFLM source
tree before compatibility fixes run.

## Adding A Menu Item

Edit `project/user_menu.cc`:

```c++
void do_my_test(void) {
  // Project-specific test code.
}

const MenuItem kUserItems[] = {
    MENU_ITEM('m', "my test", do_my_test),
    MENU_END,
};
```

Rebuild and open the firmware menu:

1. Select `1` for Project menu.
2. Select `u` for User extension menu.
3. Select your new entry.

For a larger test, start from `templates/app_extension_template.cc`, add the new
file through `APP_EXTRA_SRCS`, and register its function in
`project/user_menu.cc`.

## Adding A Custom Instruction Helper

1. Add a function ID to `app/cfu.h`.
2. Implement the hardware encoding in `app/cfu.cc`.
3. Implement the software fallback in `app/software_cfu.cc`.
4. Add a readable wrapper in `project/accel_ops.h`.
5. Add a test entry in `project/user_menu.cc` or `project/accel_tests.cc`.

Build with `USE_SOFTWARE_CFU=1` when you want to test the software fallback
without issuing CUSTOM-0 instructions.

## Adding Or Switching Models

List bundled models:

```sh
make models
make profiles
make templates
```

Build a specific model:

```sh
make MODEL_FILE=ad01_int8.tflite
```

Select a profile explicitly:

```sh
make MODEL_FILE=my_model.tflite MODEL_PROFILE=generic_zero
make MODEL_FILE=ad01_int8.tflite MODEL_PROFILE=ad01
```

When adding a new `.tflite` file:

1. Copy it into `Platform/sw`.
2. Register any missing kernels in `project/tflm_ops.cc`.
3. Start with `MODEL_PROFILE=generic_zero` if fixture data is not ready.
4. Add `models/<profile>_profile.cc` when the model needs fixture input,
   generated input, custom tensor handling, or golden-output verification.
   Use `templates/model_profile_template.cc` as the starting pattern.
5. Set `TENSOR_ARENA_SIZE` if the model needs a larger arena.
6. Run `make validate`, then build with `make MODEL_FILE=<name>.tflite`.

To make a new model auto-select its profile, add a `MODEL_BASENAME` mapping in
the Makefile.

## Generated Files

The Makefile generates:

```text
../build/sw/generated/model_data.h
../build/sw/model_data.c
../build/sw/main.elf
../build/sw/main.bin
```

Do not edit generated files directly. Change `MODEL_FILE`, source files, or
Makefile variables instead.
