# Makefile
ROOT_DIR   := $(shell pwd)
BUILD_DIR  := $(ROOT_DIR)/build
SW_DIR     := $(ROOT_DIR)/sw
BOOT_DIR   := $(ROOT_DIR)/hw/boot

prog:
	@echo ">> [BOOT] Building Bootloader (HEX for Custom CPU)..."
	$(MAKE) -C $(BOOT_DIR) all BUILD_DIR=$(BUILD_DIR)/boot
	@echo ">> [HW] Running Hardware Pipeline..."
	bash ./hw/run_hw.sh
	rm -f *.str *.debug *.log *.jou *.pb vivado*.backup.*

run:
	@echo ">> [SW] Building Application with $(THREADS) threads..."
	@mkdir -p $(BUILD_DIR)/sw
	$(MAKE) -C $(SW_DIR) all BUILD_DIR=$(BUILD_DIR)/sw
	@echo ">> [UART] Starting pipeline..."
	rm -f *.str *.debug *.log *.jou *.pb vivado*.backup.*
	python3 $(SW_DIR)/upload.py $(BUILD_DIR)/sw/main.bin

all_clean:
	@echo ">> Cleaning everything..."
	rm -rf $(BUILD_DIR)
	rm -f *.str *.debug *.log *.jou *.pb vivado*.backup.*

sw_clean:
	@echo ">> Cleaning Software build artifacts..."
	$(MAKE) -C $(SW_DIR) clean BUILD_DIR=$(BUILD_DIR)/sw

hw_clean:
	@echo ">> Cleaning Hardware/Bootloader build artifacts..."
	$(MAKE) -C $(BOOT_DIR) clean BUILD_DIR=$(BUILD_DIR)/boot

clean: all_clean

.PHONY: prog run get_new_SoC clean all_clean sw_clean hw_clean
