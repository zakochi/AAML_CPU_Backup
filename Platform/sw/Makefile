# sw/Makefile
SHELL := /bin/bash
TARGET_PREFIX := riscv64-unknown-elf
CC      = $(TARGET_PREFIX)-gcc
CXX     = $(TARGET_PREFIX)-g++
OBJCOPY = $(TARGET_PREFIX)-objcopy
MKDIR   = mkdir -p
COPY    = cp -r

# --- Set Model ---
MODEL_FILE := vww_96_int8.tflite
# ------------------

BUILD_DIR      ?= $(abspath ../build/sw)
MICRO_SRC_DIR := $(BUILD_DIR)/src
TFLM_OBJ_DIR  := $(BUILD_DIR)/obj
TFLM_SRC_ROOT := $(abspath ../../tflite-micro)

PATCH_DIR := src

# RISC-V Compiled Params
ARCH_FLAGS   := -march=rv32im -mabi=ilp32 -mcmodel=medany
COMMON_FLAGS := $(ARCH_FLAGS) -O3 -g -ffunction-sections -fdata-sections -fno-builtin \
                --param ggc-min-expand=0 --param ggc-min-heapsize=1024000
CFLAGS        := $(COMMON_FLAGS) -std=c11
CXXFLAGS      := $(COMMON_FLAGS) -std=c++11 -fno-rtti -fno-exceptions -fpermissive
LDFLAGS      := $(ARCH_FLAGS) -T linker.ld -nostartfiles -Wl,--gc-sections -Wl,--no-relax -lm -lstdc++ -lc

INCLUDES := -I. -I$(MICRO_SRC_DIR) \
            -I$(MICRO_SRC_DIR)/third_party/flatbuffers/include \
            -I$(MICRO_SRC_DIR)/third_party/gemmlowp \
            -I$(MICRO_SRC_DIR)/third_party/ruy

STARTUP_OBJ := $(TFLM_OBJ_DIR)/crt0.o
APP_OBJS    := $(TFLM_OBJ_DIR)/main.o $(TFLM_OBJ_DIR)/model_data.o $(TFLM_OBJ_DIR)/syscalls.o

TFLM_SRCS := $(shell find $(MICRO_SRC_DIR) -name "*.cc" -o -name "*.c" 2>/dev/null | \
                grep -vE "_test.cc|_benchmark.cc|arc_mli|ethosu|/tools/|/examples/|fft2d|spectrogram|debug_log.cc")
TFLM_OBJS := $(patsubst $(MICRO_SRC_DIR)/%.cc,$(TFLM_OBJ_DIR)/%.o,$(filter %.cc,$(TFLM_SRCS)))
TFLM_OBJS += $(patsubst $(MICRO_SRC_DIR)/%.c,$(TFLM_OBJ_DIR)/%.o,$(filter %.c,$(TFLM_SRCS)))

all: 
	@$(MAKE) prepare-src -j1
	@$(MAKE) build-binary

build-binary: $(BUILD_DIR)/main.bin

$(BUILD_DIR)/main.bin: $(BUILD_DIR)/main.elf
	$(OBJCOPY) -O binary $< $@

$(BUILD_DIR)/main.elf: $(STARTUP_OBJ) $(APP_OBJS) $(TFLM_OBJS)
	@echo ">> [LINK] Finalizing ELF..."
	$(CXX) $(LDFLAGS) -o $@ $^

$(BUILD_DIR)/model_data.c model.h: $(MODEL_FILE)
	@echo ">> Generating model.h and model_data.c..."
	@$(MKDIR) $(BUILD_DIR)
	@python3 -c "import sys; data=open(sys.argv[1],'rb').read(); \
	print('#include <stdint.h>\nconst uint8_t g_model[] __attribute__((aligned(16))) = {'); \
	print(','.join([hex(b) for b in data])); \
	print('};\nconst int g_model_len = ' + str(len(data)) + ';')" $< > $(BUILD_DIR)/model_data.c
	@echo "#ifndef MODEL_H" > model.h
	@echo "#define MODEL_H" >> model.h
	@echo "#include <stdint.h>" >> model.h
	@echo "extern const uint8_t g_model[];" >> model.h
	@echo "extern const int g_model_len;" >> model.h
	@echo "#endif" >> model.h

$(TFLM_OBJ_DIR)/model_data.o: $(BUILD_DIR)/model_data.c model.h
	@$(MKDIR) $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(TFLM_OBJ_DIR)/%.o: $(MICRO_SRC_DIR)/%.cc
	@$(MKDIR) $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(TFLM_OBJ_DIR)/%.o: $(MICRO_SRC_DIR)/%.c
	@$(MKDIR) $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(TFLM_OBJ_DIR)/main.o: main.cc model.h 
	@$(MKDIR) $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(TFLM_OBJ_DIR)/syscalls.o: syscalls.c
	@$(MKDIR) $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(TFLM_OBJ_DIR)/crt0.o: crt0.s
	@$(MKDIR) $(dir $@)
	$(CC) $(ARCH_FLAGS) -c $< -o $@

.PHONY: prepare-src
prepare-src:
	@if [ ! -d $(MICRO_SRC_DIR)/tensorflow ]; then \
		$(MKDIR) $(MICRO_SRC_DIR); \
		echo ">> Copying TFLM source..."; \
		cp -r $(TFLM_SRC_ROOT)/tensorflow $(MICRO_SRC_DIR)/; \
		cp -r $(TFLM_SRC_ROOT)/third_party $(MICRO_SRC_DIR)/; \
		if [ -d $(PATCH_DIR) ]; then \
			cp -rv $(PATCH_DIR)/* $(MICRO_SRC_DIR)/; \
		fi; \
		echo ">> Running compatibility fixes (sed)..."; \
		find $(MICRO_SRC_DIR) -type f \( -name "*.h" -o -name "*.cc" -o -name "*.c" \) -exec sed -i 's/std::fmax/fmax/g; s/std::fmin/fmin/g; s/std::round/round/g; s/std::expm1/expm1/g; s/std::isnan/isnan/g; s/std::isinf/isinf/g' {} +; \
		sed -i 's/TF_LITE_GLOBAL_STD_PREFIX std/TF_LITE_GLOBAL_STD_PREFIX/g' $(MICRO_SRC_DIR)/tensorflow/lite/kernels/internal/cppmath.h; \
		sed -i 's/AddEthosU/ \/\/ AddEthosU/g' $(MICRO_SRC_DIR)/tensorflow/lite/micro/all_ops_resolver.cc; \
		sed -i 's/AddAudio_Spectrogram/ \/\/ AddAudio_Spectrogram/g' $(MICRO_SRC_DIR)/tensorflow/lite/micro/all_ops_resolver.cc; \
		sed -i 's/AddMFCC/ \/\/ AddMFCC/g' $(MICRO_SRC_DIR)/tensorflow/lite/micro/all_ops_resolver.cc; \
	fi

run: build-binary
	@sudo chmod 666 /dev/ttyUSB1 2>/dev/null || true
	python3 upload.py $(BUILD_DIR)/main.bin

clean:
	rm -rf $(BUILD_DIR)
	rm -f model.h

.PHONY: all clean prepare-src build-binary run
