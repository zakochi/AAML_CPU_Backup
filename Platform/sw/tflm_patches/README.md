# TFLM Patch Overlay

Files in this directory are copied over the prepared TFLM source tree under
`../build/sw/src` before the Makefile runs compatibility fixes.

Keep the path below this directory identical to the path inside the TFLM source
tree. For example:

```text
tflm_patches/tensorflow/lite/.../conv.h
```

overlays:

```text
../build/sw/src/tensorflow/lite/.../conv.h
```
