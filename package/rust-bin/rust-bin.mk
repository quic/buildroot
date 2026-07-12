################################################################################
#
# rust-bin
#
################################################################################

# When updating this version, check whether support/download/cargo-post-process
# still generates the same archives.
RUST_BIN_VERSION = 1.96.0
RUST_BIN_SITE = https://static.rust-lang.org/dist
RUST_BIN_LICENSE = Apache-2.0 or MIT
RUST_BIN_LICENSE_FILES = LICENSE-APACHE LICENSE-MIT

HOST_RUST_BIN_PROVIDES = host-rustc

HOST_RUST_BIN_SOURCE = rust-$(RUST_BIN_VERSION)-$(RUSTC_HOST_NAME).tar.xz

# Tier 3 targets (e.g. hexagon-unknown-linux-musl) ship no prebuilt
# rust-std, so there is nothing to download -- host-rust builds the target
# std from source and only uses host-rust-bin as the bootstrap compiler.
# Attempting the download would 404. Tier 1/2 targets do have prebuilt std.
ifneq ($(BR2_PACKAGE_HOST_RUSTC_TARGET_TIER3_PLATFORMS),y)
ifeq ($(BR2_PACKAGE_HOST_RUSTC_TARGET_ARCH_SUPPORTS),y)
HOST_RUST_BIN_EXTRA_DOWNLOADS += rust-std-$(RUST_BIN_VERSION)-$(RUSTC_TARGET_NAME).tar.xz
endif
endif

HOST_RUST_BIN_LIBSTD_HOST_PREFIX = rust-std-$(RUSTC_HOST_NAME)

define HOST_RUST_BIN_LIBSTD_EXTRACT
	mkdir -p $(@D)/std
	$(foreach f,$(HOST_RUST_BIN_EXTRA_DOWNLOADS), \
		$(call suitable-extractor,$(f)) $(HOST_RUST_BIN_DL_DIR)/$(f) | \
			$(TAR) -C $(@D)/std $(TAR_OPTIONS) -
	)
	mkdir -p $(@D)/rustc/lib/rustlib/$(RUSTC_HOST_NAME)/lib
	cp -al $(@D)/$(HOST_RUST_BIN_LIBSTD_HOST_PREFIX)/lib/rustlib/$(RUSTC_HOST_NAME)/lib/* \
		$(@D)/rustc/lib/rustlib/$(RUSTC_HOST_NAME)/lib/
endef

HOST_RUST_BIN_POST_EXTRACT_HOOKS += HOST_RUST_BIN_LIBSTD_EXTRACT

HOST_RUST_BIN_INSTALL_COMMON_OPTS = \
	--prefix=$(HOST_DIR) \
	--disable-ldconfig

HOST_RUST_BIN_INSTALL_OPTS = \
	$(HOST_RUST_BIN_INSTALL_COMMON_OPTS) \
	--components=rustc,cargo,rust-std-$(RUSTC_HOST_NAME)

define HOST_RUST_BIN_INSTALL_RUSTC
	(cd $(@D); \
		./install.sh $(HOST_RUST_BIN_INSTALL_OPTS))
endef

# See the EXTRA_DOWNLOADS note above: no prebuilt target std exists for
# Tier 3 targets, so there is nothing to install here for them.
ifneq ($(BR2_PACKAGE_HOST_RUSTC_TARGET_TIER3_PLATFORMS),y)
ifeq ($(BR2_PACKAGE_HOST_RUSTC_TARGET_ARCH_SUPPORTS),y)
define HOST_RUST_BIN_INSTALL_LIBSTD_TARGET
	(cd $(@D)/std/rust-std-$(RUST_BIN_VERSION)-$(RUSTC_TARGET_NAME); \
		./install.sh $(HOST_RUST_BIN_INSTALL_COMMON_OPTS))
endef
endif
endif

define HOST_RUST_BIN_INSTALL_CMDS
	$(HOST_RUST_BIN_INSTALL_RUSTC)
	$(HOST_RUST_BIN_INSTALL_LIBSTD_TARGET)
endef

HOST_RUST_BIN_POST_INSTALL_HOOKS += HOST_RUST_INSTALL_CARGO_CONFIG

$(eval $(host-generic-package))
