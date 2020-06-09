include ../buildenv

KERNEL_DIR := ti-linux-kernel
DEPLOY_DIR := $(CURDIR)/deploy
DEFCONFIG := multi_v7_defconfig
CONFIG_FRAGMENTS := multi_v7_prune.cfg baseport.cfg ipc.cfg connectivity.cfg omap_soc.cfg lpae.cfg dra7_only.cfg titanium.cfg systemd.cfg

MAKE_KERNEL = $(MAKE) $(PARALLEL_BUILD) -C $(KERNEL_DIR) ARCH=arm CROSS_COMPILE=$(CC)

UTS_RELEASE = $(shell cat $(KERNEL_DIR)/include/generated/utsrelease.h | cut -d '"' -f 2)

CONFIGFILE := $(KERNEL_DIR)/.config

define create_archive
	@echo "Creating $(1) archive"
	@cd $(DEPLOY_DIR)/$(1) && tar czf ../$(UTS_RELEASE)-$(1).tar.gz *
	@rm -rf $(DEPLOY_DIR)/$(1)
endef

all: install

image: $(CONFIGFILE)
	$(MAKE_KERNEL) zImage modules dtbs

install: image
	rm -rf $(DEPLOY_DIR)/modules $(DEPLOY_DIR)/firmware $(DEPLOY_DIR)/dtbs
	$(MAKE_KERNEL) \
		modules_install INSTALL_MOD_PATH=$(DEPLOY_DIR)/modules \
		dtbs_install INSTALL_DTBS_PATH=$(DEPLOY_DIR)/dtbs
	@cp $(KERNEL_DIR)/arch/arm/boot/zImage "$(DEPLOY_DIR)/$(UTS_RELEASE).zImage"
	@cp $(KERNEL_DIR)/.config "$(DEPLOY_DIR)/config-$(UTS_RELEASE)"
	$(call create_archive,modules)
	$(call create_archive,dtbs)
	@echo "[export kernel_version=$(UTS_RELEASE)]"
	ls -lh $(DEPLOY_DIR)/$(UTS_RELEASE)*

$(CONFIGFILE): $(KERNEL_DIR)/arch/arm/configs/$(DEFCONFIG) $(addprefix $(KERNEL_DIR)/ti_config_fragments/,$(CONFIG_FRAGMENTS))
	$(MAKE_KERNEL) $(DEFCONFIG)
	cd $(KERNEL_DIR) && scripts/kconfig/merge_config.sh -m .config $(addprefix ti_config_fragments/,$(CONFIG_FRAGMENTS))
	$(MAKE_KERNEL) olddefconfig

defconfig: $(CONFIGFILE)

menuconfig: $(CONFIGFILE)
	$(MAKE_KERNEL) menuconfig
