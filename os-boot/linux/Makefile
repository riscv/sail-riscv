RISCV_COMPILER_PREFIX := riscv64-buildroot-linux-gnu-
RISCV_COMPILER_URL ?= https://toolchains.bootlin.com/downloads/releases/toolchains/riscv64-lp64d/tarballs/riscv64-lp64d--glibc--stable-2024.05-1.tar.xz

LINUX_VERSION ?= 6.14.4
OPENSBI_VERSION ?= 1.6

# This is the final bootable OpenSBI + Linux image.
elf := build/fw_payload.elf

.PHONY: all
all: $(elf)

downloads/gcc.tar.xz:
	mkdir -p downloads
ifeq (, $(wildcard downloads/gcc.tar.xz))
	curl -L $(RISCV_COMPILER_URL) -o downloads/gcc.tar.xz
endif

build/riscv/bin/$(RISCV_COMPILER_PREFIX)gcc: downloads/gcc.tar.xz
	mkdir -p build/riscv
	tar --touch --directory build/riscv --strip-components=1 --extract --file downloads/gcc.tar.xz

downloads/linux.tar.xz:
	mkdir -p downloads
ifeq (, $(wildcard downloads/linux.tar.xz))
	curl -L https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(LINUX_VERSION).tar.xz -o downloads/linux.tar.xz
endif

build/linux-$(LINUX_VERSION)/Makefile: downloads/linux.tar.xz
	mkdir -p build
	tar --touch --directory build --extract --file downloads/linux.tar.xz

downloads/opensbi.tar.xz:
	mkdir -p downloads
ifeq (, $(wildcard downloads/opensbi.tar.xz))
	curl -L https://github.com/riscv-software-downloads/opensbi/archive/refs/tags/v$(OPENSBI_VERSION).tar.gz -o downloads/opensbi.tar.xz
endif

build/opensbi-$(OPENSBI_VERSION)/Makefile: downloads/opensbi.tar.xz
	mkdir -p build
	tar --touch --directory build --extract --file downloads/opensbi.tar.xz

CROSS_COMPILE := $(shell pwd)/build/riscv/bin/$(RISCV_COMPILER_PREFIX)

# Number of instructions to run.
LIMIT_INSTRUCTIONS ?= 1500000

build/linux-$(LINUX_VERSION)/arch/riscv/boot/Image: build/linux-$(LINUX_VERSION)/Makefile build/riscv/bin/$(RISCV_COMPILER_PREFIX)gcc
	$(MAKE) -C build/linux-$(LINUX_VERSION) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=riscv defconfig
	$(MAKE) -C build/linux-$(LINUX_VERSION) CROSS_COMPILE=$(CROSS_COMPILE) CONFIG_HVC_RISCV_SBI=y ARCH=riscv Image

# FW_TEXT_START is 0 by default which doesn't leave space for the emulator bootloader.
# 0x80000000 is the default start of Spike's memory.
build/opensbi-$(OPENSBI_VERSION)/build/platform/generic/firmware/fw_payload.elf: build/opensbi-$(OPENSBI_VERSION)/Makefile build/linux-$(LINUX_VERSION)/arch/riscv/boot/Image build/riscv/bin/$(RISCV_COMPILER_PREFIX)gcc
	$(MAKE) -C build/opensbi-$(OPENSBI_VERSION) FW_TEXT_START=0x80000000 FW_PAYLOAD=y FW_PAYLOAD_PATH=../linux-$(LINUX_VERSION)/arch/riscv/boot/Image PLATFORM=generic CROSS_COMPILE=$(CROSS_COMPILE)

$(elf): build/opensbi-$(OPENSBI_VERSION)/build/platform/generic/firmware/fw_payload.elf
	cp build/opensbi-$(OPENSBI_VERSION)/build/platform/generic/firmware/fw_payload.elf $(elf)

sail.dtb: sail.dts
	dtc < sail.dts -o sail.dtb

.PHONY: sail
sail: sail.dtb $(elf)
	../../build/c_emulator/riscv_sim_rv64d --no-trace -p -l $(LIMIT_INSTRUCTIONS) --device-tree-blob sail.dtb -t /dev/stdout $(elf)

.PHONY: spike
spike: $(elf)
	spike --instructions=$(LIMIT_INSTRUCTIONS) $(elf)

.PHONY: qemu
qemu: $(elf)
	qemu-system-riscv64 -M virt -m 256M -nographic -bios $(elf)

.PHONY: clean
clean:
	rm -rf build
	rm -f sail.dtb

.PHONY: dist-clean
dist-clean:
	rm -rf build
	rm -f sail.dtb
	rm -rf downloads
