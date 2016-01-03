include ../buildenv

UBOOT_DIR := u-boot
CONFIG :=  elesar_titanium_config

MAKE_UBOOT = $(MAKE) $(PARALLEL_BUILD) -C $(UBOOT_DIR) ARCH=arm CROSS_COMPILE=$(CC)

all: $(UBOOT_DIR)/.config
	$(MAKE_UBOOT)

distclean:
	$(MAKE_UBOOT) distclean

config $(UBOOT_DIR)/.config:
	$(MAKE_UBOOT) $(CONFIG)

menuconfig:
	$(MAKE_UBOOT) menuconfig