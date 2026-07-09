# Project Sources

This directory is the local project layer, similar to a `proj/<name>/src`
directory in CFU-Playground.

Use it for code that is specific to this NPU platform:

```text
proj_menu.*   Top-level project submenu
user_menu.*   First extension point for local demos and experiments
npu_ops.h     Semantic wrappers over raw CUSTOM-0 `cfu_op(...)`
npu_tests.*   Functional and stress tests for this NPU interface
tflm_ops.*    TFLM operator resolver registration for selected models
```

Framework code belongs in `../app`. Model-specific input and output handling
belongs in `../models`.
