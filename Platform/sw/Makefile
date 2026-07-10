# sw/Makefile
SHELL := /bin/bash
TARGET_PREFIX ?= riscv64-unknown-elf
CC      = $(TARGET_PREFIX)-gcc
CXX     = $(TARGET_PREFIX)-g++
OBJCOPY = $(TARGET_PREFIX)-objcopy
MKDIR   = mkdir -p
COPY    = cp -r

PROJECT_CONFIG ?= project.mk

# --- Set Model ---
MODEL_DIR ?= models
MODEL_FILE ?= vww_96_int8.tflite
MODEL_PROFILE ?= auto
TENSOR_ARENA_SIZE ?= 262144
USE_SOFTWARE_CFU ?= 0
# ------------------

-include $(PROJECT_CONFIG)

BUILD_DIR      ?= $(abspath ../build/sw)
GEN_DIR        := $(BUILD_DIR)/generated
MODEL_RESOLVED := $(if $(findstring /,$(MODEL_FILE)),$(MODEL_FILE),$(MODEL_DIR)/$(MODEL_FILE))
MODEL_PATH     := $(MODEL_RESOLVED)
MODEL_ABS      := $(abspath $(MODEL_PATH))
MODEL_BASENAME := $(notdir $(MODEL_PATH))
MODEL_STAMP    := $(BUILD_DIR)/model_data.$(MODEL_BASENAME).stamp
MODEL_SELECTED := $(BUILD_DIR)/model_data.selected
MICRO_SRC_DIR := $(BUILD_DIR)/src
TFLM_OBJ_DIR  := $(BUILD_DIR)/obj
TFLM_SRC_ROOT := $(abspath ../../tflite-micro)

TFLM_PATCH_DIR := tflm_patches
APP_SRC_DIR := app
PROJECT_SRC_DIR := project
RUNTIME_DIR := runtime
MODEL_PROFILE_DIR ?= models
APP_EXTRA_SRCS ?=
APP_DEFINES ?=

MODEL_PROFILE_SRC ?= $(MODEL_PROFILE_DIR)/$(MODEL_PROFILE)_profile.cc
PROJECT_CONFIG_STATUS := $(if $(wildcard $(PROJECT_CONFIG)),$(PROJECT_CONFIG),not found)
LINKER_SCRIPT := $(RUNTIME_DIR)/linker.ld
STARTUP_SRC := $(RUNTIME_DIR)/crt0.s
STARTUP_OBJ := $(TFLM_OBJ_DIR)/$(RUNTIME_DIR)/crt0.o
SYSCALLS_SRC := $(RUNTIME_DIR)/syscalls.c
SYSCALLS_OBJ := $(TFLM_OBJ_DIR)/$(RUNTIME_DIR)/syscalls.o

# RISC-V Compiled Params
ARCH_FLAGS   := -march=rv32im -mabi=ilp32 -mcmodel=medany
DEFINES      := -DMODEL_NAME=\"$(MODEL_BASENAME)\" \
                -DTENSOR_ARENA_SIZE=$(TENSOR_ARENA_SIZE) \
                -DMODEL_PROFILE_NAME=\"$(MODEL_PROFILE)\" \
                $(APP_DEFINES)
ifeq ($(USE_SOFTWARE_CFU),1)
DEFINES      += -DCFU_SOFTWARE_DEFINED
endif
COMMON_FLAGS := $(ARCH_FLAGS) -O3 -g -ffunction-sections -fdata-sections -fno-builtin \
                --param ggc-min-expand=0 --param ggc-min-heapsize=1024000 $(DEFINES)
CFLAGS        := $(COMMON_FLAGS) -std=c11
CXXFLAGS      := $(COMMON_FLAGS) -std=c++11 -fno-rtti -fno-exceptions -fpermissive
LDFLAGS       := $(ARCH_FLAGS) -T $(LINKER_SCRIPT) -nostartfiles -Wl,--gc-sections -Wl,--no-relax
LDLIBS        := -lm -lstdc++ -lc

INCLUDES := -I. -I$(APP_SRC_DIR) -I$(PROJECT_SRC_DIR) -I$(GEN_DIR) -I$(MICRO_SRC_DIR) \
            -I$(MICRO_SRC_DIR)/third_party/flatbuffers/include \
            -I$(MICRO_SRC_DIR)/third_party/gemmlowp \
            -I$(MICRO_SRC_DIR)/third_party/ruy

APP_CC_SRCS := main.cc $(sort $(shell find $(APP_SRC_DIR) $(PROJECT_SRC_DIR) -name "*.cc" 2>/dev/null) $(MODEL_PROFILE_SRC) $(APP_EXTRA_SRCS))
APP_CC_OBJS := $(patsubst %.cc,$(TFLM_OBJ_DIR)/%.o,$(APP_CC_SRCS))
APP_OBJS    := $(APP_CC_OBJS) $(TFLM_OBJ_DIR)/model_data.o $(SYSCALLS_OBJ)

TFLM_SRCS := $(shell find $(MICRO_SRC_DIR) -name "*.cc" -o -name "*.c" 2>/dev/null | \
                grep -vE "_test.cc|_benchmark.cc|arc_mli|ethosu|/tools/|/examples/|fft2d|spectrogram|debug_log.cc")
TFLM_OBJS := $(patsubst $(MICRO_SRC_DIR)/%.cc,$(TFLM_OBJ_DIR)/%.o,$(filter %.cc,$(TFLM_SRCS)))
TFLM_OBJS += $(patsubst $(MICRO_SRC_DIR)/%.c,$(TFLM_OBJ_DIR)/%.o,$(filter %.c,$(TFLM_SRCS)))

all: check-env
	@$(MAKE) build-binary

help:
	@printf "CUSTOM SoC Platform software build\n"
	@printf "\n"
	@printf "Common targets:\n"
	@printf "  make                 Build $(BUILD_DIR)/main.bin\n"
	@printf "  make run             Build and upload using upload.py\n"
	@printf "  make models          List available .tflite model files\n"
	@printf "  make profiles        List available model profile files\n"
	@printf "  make templates       List software extension templates\n"
	@printf "  make config          Print resolved build configuration\n"
	@printf "  make validate        Print resolved config and available assets\n"
	@printf "  make check-env       Check toolchain, TFLM source, and selected model\n"
	@printf "  make clean           Remove generated SW build files\n"
	@printf "\n"
	@printf "Useful overrides:\n"
	@printf "  MODEL_DIR=models\n"
	@printf "  MODEL_FILE=ad01_int8.tflite\n"
	@printf "  MODEL_PROFILE=ad01\n"
	@printf "  TENSOR_ARENA_SIZE=262144\n"
	@printf "  USE_SOFTWARE_CFU=1\n"
	@printf "  TARGET_PREFIX=riscv64-unknown-elf\n"
	@printf "  PROJECT_CONFIG=project.mk\n"
	@printf "  APP_DEFINES=\"-DMY_FLAG=1\"\n"
	@printf "  APP_EXTRA_SRCS=\"project/my_extra_file.cc\"\n"
	@printf "\n"
	@printf "Extension entry point: edit project/user_menu.cc for project-specific tests.\n"

models:
	@printf "Available models in Platform/sw/$(MODEL_DIR):\n"
	@find $(MODEL_DIR) -maxdepth 1 -name "*.tflite" -print | sed 's#^$(MODEL_DIR)/#  #'

profiles:
	@printf "Available model profiles in Platform/sw/models:\n"
	@find $(MODEL_PROFILE_DIR) -maxdepth 1 -name "*_profile.cc" -print | sed 's#^$(MODEL_PROFILE_DIR)/#  #; s#_profile.cc$$##'

templates:
	@printf "Available templates in Platform/sw/templates:\n"
	@find templates -maxdepth 1 -name "*_template.*" -print | sed 's#^templates/#  #'
	@if [ -d ../hw/templates ]; then \
		printf "Available templates in Platform/hw/templates:\n"; \
		find ../hw/templates -maxdepth 1 -name "*_template.*" -print | sed 's#^\.\./hw/templates/#  #'; \
	fi

config:
	@printf "PROJECT_CONFIG=%s\n" "$(PROJECT_CONFIG_STATUS)"
	@printf "TARGET_PREFIX=%s\n" "$(TARGET_PREFIX)"
	@printf "MODEL_DIR=%s\n" "$(MODEL_DIR)"
	@printf "MODEL_FILE=%s\n" "$(MODEL_FILE)"
	@printf "MODEL_PATH=%s\n" "$(MODEL_PATH)"
	@printf "MODEL_BASENAME=%s\n" "$(MODEL_BASENAME)"
	@printf "MODEL_PROFILE=%s\n" "$(MODEL_PROFILE)"
	@printf "MODEL_PROFILE_SRC=%s\n" "$(MODEL_PROFILE_SRC)"
	@printf "APP_SRC_DIR=%s\n" "$(APP_SRC_DIR)"
	@printf "PROJECT_SRC_DIR=%s\n" "$(PROJECT_SRC_DIR)"
	@printf "TFLM_PATCH_DIR=%s\n" "$(TFLM_PATCH_DIR)"
	@printf "TENSOR_ARENA_SIZE=%s\n" "$(TENSOR_ARENA_SIZE)"
	@printf "USE_SOFTWARE_CFU=%s\n" "$(USE_SOFTWARE_CFU)"
	@printf "BUILD_DIR=%s\n" "$(BUILD_DIR)"

validate:
	@$(MAKE) config
	@$(MAKE) models
	@$(MAKE) profiles
	@$(MAKE) templates

check-env:
	@printf "Checking SW build environment...\n"
	@command -v $(CC) >/dev/null || { printf "ERROR: missing %s in PATH\n" "$(CC)"; exit 1; }
	@command -v $(CXX) >/dev/null || { printf "ERROR: missing %s in PATH\n" "$(CXX)"; exit 1; }
	@command -v $(OBJCOPY) >/dev/null || { printf "ERROR: missing %s in PATH\n" "$(OBJCOPY)"; exit 1; }
	@test -d "$(TFLM_SRC_ROOT)/tensorflow" || { printf "ERROR: missing TFLM source at %s\n" "$(TFLM_SRC_ROOT)"; exit 1; }
	@test -d "$(MODEL_DIR)" || { printf "ERROR: missing model directory %s\n" "$(MODEL_DIR)"; exit 1; }
	@test -f "$(MODEL_PATH)" || { printf "ERROR: missing model file %s\n" "$(MODEL_PATH)"; exit 1; }
	@test -f "$(MODEL_PROFILE_SRC)" || { printf "ERROR: missing model profile source %s\n" "$(MODEL_PROFILE_SRC)"; exit 1; }
	@printf "OK: toolchain=%s, model=%s, profile=%s, arena=%s bytes\n" "$(TARGET_PREFIX)" "$(MODEL_PATH)" "$(MODEL_PROFILE)" "$(TENSOR_ARENA_SIZE)"

build-binary: prepare-src
	@$(MAKE) $(BUILD_DIR)/main.bin

$(BUILD_DIR)/main.bin: $(BUILD_DIR)/main.elf
	$(OBJCOPY) -O binary $< $@

$(BUILD_DIR)/main.elf: $(STARTUP_OBJ) $(APP_OBJS) $(TFLM_OBJS) $(LINKER_SCRIPT)
	@echo ">> [LINK] Finalizing ELF..."
	$(CXX) $(LDFLAGS) -o $@ $(filter-out $(LINKER_SCRIPT),$^) $(LDLIBS)

$(BUILD_DIR)/model_data.c $(GEN_DIR)/model_data.h: $(MODEL_STAMP)

$(MODEL_SELECTED):
	@$(MKDIR) $(BUILD_DIR) $(GEN_DIR)
	@touch $@

$(MODEL_STAMP): FORCE $(MODEL_PATH) Makefile $(MODEL_SELECTED)
	@$(MKDIR) $(BUILD_DIR) $(GEN_DIR)
	@if [ ! -f "$(BUILD_DIR)/model_data.c" ] || \
		[ ! -f "$(GEN_DIR)/model_data.h" ] || \
		[ "$$(cat "$(MODEL_SELECTED)" 2>/dev/null)" != "$(MODEL_ABS)" ] || \
		[ "$(MODEL_PATH)" -nt "$(BUILD_DIR)/model_data.c" ] || \
		[ "Makefile" -nt "$(BUILD_DIR)/model_data.c" ]; then \
		echo ">> Generating model_data.h and model_data.c from $(MODEL_PATH)..."; \
		python3 -c "import sys; data=open(sys.argv[1],'rb').read(); print('#include <stdint.h>\n#include \"model_data.h\"\nconst uint8_t g_model[] __attribute__((aligned(16))) = {'); print(','.join([hex(b) for b in data])); print('};\nconst int g_model_len = ' + str(len(data)) + ';')" "$(MODEL_PATH)" > "$(BUILD_DIR)/model_data.c"; \
		echo "#ifndef PLATFORM_SW_GENERATED_MODEL_DATA_H_" > "$(GEN_DIR)/model_data.h"; \
		echo "#define PLATFORM_SW_GENERATED_MODEL_DATA_H_" >> "$(GEN_DIR)/model_data.h"; \
		echo "#include <stdint.h>" >> "$(GEN_DIR)/model_data.h"; \
		echo "#ifdef __cplusplus" >> "$(GEN_DIR)/model_data.h"; \
		echo "extern \"C\" {" >> "$(GEN_DIR)/model_data.h"; \
		echo "#endif" >> "$(GEN_DIR)/model_data.h"; \
		echo "extern const uint8_t g_model[];" >> "$(GEN_DIR)/model_data.h"; \
		echo "extern const int g_model_len;" >> "$(GEN_DIR)/model_data.h"; \
		echo "#ifdef __cplusplus" >> "$(GEN_DIR)/model_data.h"; \
		echo "}" >> "$(GEN_DIR)/model_data.h"; \
		echo "#endif" >> "$(GEN_DIR)/model_data.h"; \
		echo "#endif" >> "$(GEN_DIR)/model_data.h"; \
		printf "%s\n" "$(MODEL_ABS)" > "$(MODEL_SELECTED)"; \
	fi
	@touch $@

$(TFLM_OBJ_DIR)/model_data.o: $(BUILD_DIR)/model_data.c $(GEN_DIR)/model_data.h
	@$(MKDIR) $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(TFLM_OBJ_DIR)/%.o: $(MICRO_SRC_DIR)/%.cc
	@$(MKDIR) $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(TFLM_OBJ_DIR)/%.o: $(MICRO_SRC_DIR)/%.c
	@$(MKDIR) $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(TFLM_OBJ_DIR)/%.o: %.cc $(GEN_DIR)/model_data.h
	@$(MKDIR) $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(SYSCALLS_OBJ): $(SYSCALLS_SRC)
	@$(MKDIR) $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(STARTUP_OBJ): $(STARTUP_SRC)
	@$(MKDIR) $(dir $@)
	$(CC) $(ARCH_FLAGS) -c $< -o $@

.PHONY: prepare-src
prepare-src:
	@if [ ! -d $(MICRO_SRC_DIR)/tensorflow ]; then \
		$(MKDIR) $(MICRO_SRC_DIR); \
		echo ">> Copying TFLM source..."; \
		cp -r $(TFLM_SRC_ROOT)/tensorflow $(MICRO_SRC_DIR)/; \
		cp -r $(TFLM_SRC_ROOT)/third_party $(MICRO_SRC_DIR)/; \
		if [ -d $(TFLM_PATCH_DIR) ]; then \
			cp -rv $(TFLM_PATCH_DIR)/* $(MICRO_SRC_DIR)/; \
		fi; \
		echo ">> Running compatibility fixes..."; \
		find $(MICRO_SRC_DIR) -type f \( -name "*.h" -o -name "*.cc" -o -name "*.c" \) -exec perl -pi -e 's/std::fmax/fmax/g; s/std::fmin/fmin/g; s/std::round/round/g; s/std::expm1/expm1/g; s/std::isnan/isnan/g; s/std::isinf/isinf/g' {} +; \
		perl -pi -e 's/TF_LITE_GLOBAL_STD_PREFIX std/TF_LITE_GLOBAL_STD_PREFIX/g' $(MICRO_SRC_DIR)/tensorflow/lite/kernels/internal/cppmath.h; \
		perl -pi -e 's/AddEthosU/ \/\/ AddEthosU/g' $(MICRO_SRC_DIR)/tensorflow/lite/micro/all_ops_resolver.cc; \
		perl -pi -e 's/AddAudio_Spectrogram/ \/\/ AddAudio_Spectrogram/g' $(MICRO_SRC_DIR)/tensorflow/lite/micro/all_ops_resolver.cc; \
		perl -pi -e 's/AddMFCC/ \/\/ AddMFCC/g' $(MICRO_SRC_DIR)/tensorflow/lite/micro/all_ops_resolver.cc; \
	fi

run: all
	@sudo chmod 666 /dev/ttyUSB1 2>/dev/null || true
	python3 upload.py $(BUILD_DIR)/main.bin

clean:
	rm -rf $(BUILD_DIR)

FORCE:

.PHONY: all clean prepare-src build-binary run help models profiles templates config validate check-env FORCE
