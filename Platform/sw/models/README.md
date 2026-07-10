# Models And Profiles

This directory contains bundled `.tflite` model files and their profile code.
Each `*_profile.cc` file provides input and verification behavior for one model
family. The Makefile compiles exactly one profile into the firmware.

Bundled profiles:

```text
ad01          ad01_int8.tflite fixture input and golden output
vww_96        vww_96_int8.tflite zero input, output verification skipped
generic_zero  fallback for new models while bring-up data is not ready
```

To add a model profile:

1. Copy the `.tflite` file into this directory.
2. Create `models/<profile>_profile.cc`.
3. Implement `const ModelProfile* model_profile_get(void)`.
4. For simple int8 models, fill `input_data` and `expected_output`.
5. For custom tensor types, generated inputs, or multi-output checks, set the
   `prepare_input` or `verify_output` function pointers.
6. Select it with `make MODEL_FILE=<model>.tflite MODEL_PROFILE=<profile>`.
7. If the model should auto-select this profile, add the mapping in the
   software Makefile.
