# Project Sources

This directory is the local project layer, similar to a `proj/<name>/src`
directory in CFU-Playground.

Use it for code that is specific to this custom ML accelerator platform:

```text
proj_menu.*   Top-level project submenu
user_menu.*   First extension point for local demos and experiments
accel_ops.h   Semantic wrappers over raw CUSTOM-0 `cfu_op0..cfu_op7(...)`
accel_tests.* Functional and stress tests for the accelerator interface
tflm_ops.*    TFLM operator resolver registration for selected models
```

`npu_ops.h` and `npu_tests.h` are compatibility wrappers for the current NPU
example. Prefer `accel_*` names for new accelerator work.

Framework code belongs in `../app`. Model-specific input and output handling
belongs in `../models`.
