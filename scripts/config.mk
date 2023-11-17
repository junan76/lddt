export ARCH=arm
export CROSS_COMPILE=arm-linux-gnueabihf-

QEMU := qemu-system-arm
QEMU_OPTIONS = -machine $(machine_type) \
				-smp cpus=$(NCPU) \
				-kernel $(kernel_image) \
				-dtb $(dtb_file) \
				-drive file=$(rootfs_image),format=raw,if=none,id=hda \
				-device virtio-blk-device,drive=hda \
				-fsdev local,id=lddt,path=$(modules_src_dir),security_model=passthrough \
				-device virtio-9p-device,fsdev=lddt,mount_tag=lddt \
				-append "root=/dev/vda ro console=ttyAMA0 init=/bin/init.sh" \
				-nographic

machine_type = vexpress-a9
NCPU ?= 4
kernel_image = $(shell find $(LDDT_ROOT)/deps -name zImage)
dtb_file = $(shell find $(LDDT_ROOT)/deps -name vexpress-v2p-ca9.dtb)
rootfs_image = $(shell find $(LDDT_ROOT)/deps -name rootfs.ext4)
modules_src_dir = $(LDDT_ROOT)/src