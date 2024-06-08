PROJ_DIR = $(abspath .)
QEMU_BUILD_DIR = $(PROJ_DIR)/qemu_build
QEMU = $(QEMU_BUILD_DIR)/qemu-system-riscv64
DRIVER_DIR = moic_driver
include $(DRIVER_DIR)/Makefrag


build_qemu:
	cd $(QEMU_BUILD_DIR) && make -j4

