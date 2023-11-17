include $(LDDT_ROOT)/scripts/config.mk

__all:

ifeq ($(KERNELRELEASE),)
KDIR := $(shell find $(LDDT_ROOT)/deps -type d -name "linux-5.*")/build

modules:
	$(MAKE) -C $(KDIR) M=$(PWD) $@

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) $@

endif

.PHONY: qemu_run
qemu_run:
	$(QEMU) $(QEMU_OPTIONS)

.PHONY: qemu_debug
qemu_debug:
	$(QEMU) $(QEMU_OPTIONS) -s -S

.PHONY: prepare_deps
prepare_deps:
	$(LDDT_ROOT)/scripts/build.sh -fcb -t k
	$(LDDT_ROOT)/scripts/build.sh -fcb -t b
	$(LDDT_ROOT)/scripts/build.sh -t r

.PHONY: kernel
kernel:
	$(LDDT_ROOT)/scripts/build.sh -b -t k

.PHONY: busybox
busybox:
	$(LDDT_ROOT)/scripts/build.sh -b -t b

.PHONY: rootfs
rootfs:
	$(LDDT_ROOT)/scripts/build.sh -t r

.PHONY: k_mconf
k_mconf:
	$(LDDT_ROOT)/scripts/build.sh -m -t k

.PHONY: b_mconf
b_mconf:
	$(LDDT_ROOT)/scripts/build.sh -m -t b