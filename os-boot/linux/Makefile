##### Compilation #####

RISCV_COMPILER_PREFIX := riscv64-buildroot-linux-gnu-

# This is the final bootable OpenSBI + Linux image.
elf := build/fw_payload.elf

.PHONY: all
all: $(elf)

downloads/%.tar.xz: %.url
	mkdir -p downloads
	curl --location '$(shell cat $<)' --output $@

build/riscv/bin/$(RISCV_COMPILER_PREFIX)gcc: downloads/gcc.tar.xz
	mkdir -p build/riscv
	tar --touch --directory build/riscv --strip-components=1 --extract --file downloads/gcc.tar.xz

build/linux/Makefile: downloads/linux.tar.xz
	mkdir -p build/linux
	tar --touch --directory build/linux --strip-components=1 --extract --file downloads/linux.tar.xz

build/opensbi/Makefile: downloads/opensbi.tar.xz
	mkdir -p build/opensbi
	tar --touch --directory build/opensbi --strip-components=1 --extract --file downloads/opensbi.tar.xz

CROSS_COMPILE := $(shell pwd)/build/riscv/bin/$(RISCV_COMPILER_PREFIX)

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

.PHONY: clean
clean:
	rm -rf build
	rm -f sail.dtb

.PHONY: distclean
distclean:
	rm -rf build
	rm -f sail.dtb
	rm -rf downloads

##### Running #####

# Number of instructions to run.
LIMIT_INSTRUCTIONS := 1500000

.PHONY: sail
sail: sail.dtb $(elf)
	../../build/c_emulator/riscv_sim_rv64d --no-trace -p -l $(LIMIT_INSTRUCTIONS) --device-tree-blob sail.dtb $(elf)

.PHONY: spike
spike: $(elf)
	spike --instructions=$(LIMIT_INSTRUCTIONS) $(elf)

.PHONY: qemu
qemu: $(elf)
	qemu-system-riscv64 -M virt -m 256M -nographic -bios $(elf)
