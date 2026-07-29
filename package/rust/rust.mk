################################################################################
#
# rust
#
################################################################################

# When updating this version, check whether support/download/cargo-post-process
# still generates the same archives.
RUST_VERSION = 1.96.0
RUST_SOURCE = rustc-$(RUST_VERSION)-src.tar.xz
RUST_SITE = https://static.rust-lang.org/dist
RUST_LICENSE = Apache-2.0 or MIT
RUST_LICENSE_FILES = LICENSE-APACHE LICENSE-MIT
RUST_CPE_ID_VENDOR = rust-lang

HOST_RUST_PROVIDES = host-rustc

HOST_RUST_DEPENDENCIES = \
	toolchain \
	host-pkgconf \
	host-python3 \
	host-rust-bin \
	host-openssl \
	host-zlib \
	$(BR2_CMAKE_HOST_DEPENDENCY)

HOST_RUST_VERBOSITY = $(if $(VERBOSE),2,0)

# Clang external toolchains only expose "<tuple>-clang"/"<tuple>-clang++"
# wrappers (no "<tuple>-gcc"/"-g++"), so point rust's target C/C++
# compilers at clang. The C++ compiler is required to build the target
# libunwind from the in-tree LLVM sources for musl targets.
ifeq ($(BR2_TOOLCHAIN_USES_CLANG),y)
HOST_RUST_TARGET_CC = $(TARGET_CROSS)clang
HOST_RUST_TARGET_CXX = $(TARGET_CROSS)clang++
else
HOST_RUST_TARGET_CC = $(TARGET_CROSS)gcc
HOST_RUST_TARGET_CXX = $(TARGET_CROSS)g++
endif

# hexagon-unknown-linux-musl is a Tier 3 target that has no prebuilt
# unwinder; per its platform-support docs, std must be built with the
# in-tree LLVM libunwind. Also, the external toolchain's sysroot keeps
# libc.a/crt*.o under <sysroot>/usr/lib (not <sysroot>/lib), so point
# rust's per-target musl-root at $(STAGING_DIR)/usr where x.py expects
# to find <musl-root>/lib/libc.a.
# https://doc.rust-lang.org/rustc/platform-support/hexagon-unknown-linux-musl.html
ifeq ($(BR2_hexagon),y)
define HOST_RUST_TARGET_EXTRA_CONFIG
	echo 'llvm-libunwind = "in-tree"'; \
	echo 'musl-root = "$(STAGING_DIR)/usr"';
endef

# This toolchain's hexagon musl uses native 64-bit time_t with plain symbol
# names (stat, fstat, ...); it is NOT built with musl's _REDIR_TIME64 scheme,
# so it does not export the __*_time64 redirect symbols. rust's vendored libc
# crate, however, hard-codes hexagon into MUSL_REDIR_TIME64_ARCHES and thus
# makes std reference __stat_time64 etc., which fail to link against this musl.
# Drop hexagon from that list (and fix the vendored per-file checksum) so std
# references the plain symbols this musl actually provides. Only the symbol
# names change; the 64-bit-time struct layouts (musl_v1_2_3) are unaffected.
define HOST_RUST_FIXUP_LIBC_TIME64
	$(Q)for brs in $(@D)/vendor/libc-*/build.rs; do \
		grep -q '"arm", "hexagon",' $$brs || continue ; \
		sed -i 's/&\["arm", "hexagon",/\&["arm",/' $$brs ; \
		python3 -c 'import json,hashlib,os,sys; b=sys.argv[1]; d=os.path.dirname(b); j=os.path.join(d,".cargo-checksum.json"); D=json.load(open(j)); D["files"]["build.rs"]=hashlib.sha256(open(b,"rb").read()).hexdigest(); json.dump(D,open(j,"w"))' $$brs ; \
	done
endef
HOST_RUST_POST_PATCH_HOOKS += HOST_RUST_FIXUP_LIBC_TIME64
endif

define HOST_RUST_CONFIGURE_CMDS
	( \
		echo '[build]'; \
		echo 'target = ["$(RUSTC_TARGET_NAME)"]'; \
		echo 'cargo = "$(HOST_RUST_BIN_DIR)/cargo/bin/cargo"'; \
		echo 'rustc = "$(HOST_RUST_BIN_DIR)/rustc/bin/rustc"'; \
		echo 'python = "$(HOST_DIR)/bin/python$(PYTHON3_VERSION_MAJOR)"'; \
		echo 'submodules = false'; \
		echo 'vendor = true'; \
		echo 'extended = true'; \
		echo 'tools = ["cargo"]'; \
		echo 'compiler-docs = false'; \
		echo 'docs = false'; \
		echo 'verbose = $(HOST_RUST_VERBOSITY)'; \
		echo 'local-rebuild = true'; \
		echo '[install]'; \
		echo 'prefix = "$(HOST_DIR)"'; \
		echo 'sysconfdir = "$(HOST_DIR)/etc"'; \
		echo '[rust]'; \
		echo 'channel = "stable"'; \
		echo 'musl-root = "$(STAGING_DIR)"' ; \
		echo '[target.$(RUSTC_TARGET_NAME)]'; \
		echo 'cc = "$(HOST_RUST_TARGET_CC)"'; \
		echo 'cxx = "$(HOST_RUST_TARGET_CXX)"'; \
		$(HOST_RUST_TARGET_EXTRA_CONFIG) \
		echo '[llvm]'; \
		echo 'download-ci-llvm = false'; \
		echo 'ninja = false'; \
		echo 'ldflags = "$(HOST_LDFLAGS)"'; \
	) > $(@D)/config.toml
endef

define HOST_RUST_BUILD_CMDS
	cd $(@D); $(HOST_MAKE_ENV) $(HOST_PKG_CARGO_ENV) \
		$(HOST_DIR)/bin/python$(PYTHON3_VERSION_MAJOR) x.py build
endef

HOST_RUST_INSTALL_OPTS = \
	--prefix=$(HOST_DIR) \
	--disable-ldconfig

define HOST_RUST_INSTALL_RUSTC
	cd $(@D)/build/tmp/tarball/rust/$(RUSTC_HOST_NAME)/rust-$(RUST_VERSION)-$(RUSTC_HOST_NAME); \
		./install.sh $(HOST_RUST_INSTALL_OPTS) --components=rustc,cargo,rust-std-$(RUSTC_HOST_NAME)
endef

ifeq ($(BR2_PACKAGE_HOST_RUSTC_TARGET_ARCH_SUPPORTS),y)
define HOST_RUST_INSTALL_LIBSTD_TARGET
	cd $(@D)/build/tmp/tarball/rust-std/$(RUSTC_TARGET_NAME)/rust-std-$(RUST_VERSION)-$(RUSTC_TARGET_NAME); \
		./install.sh $(HOST_RUST_INSTALL_OPTS)
endef
endif

define HOST_RUST_INSTALL_CMDS
	cd $(@D); $(HOST_MAKE_ENV) $(HOST_DIR)/bin/python$(PYTHON3_VERSION_MAJOR) x.py dist
	$(HOST_RUST_INSTALL_RUSTC)
	$(HOST_RUST_INSTALL_LIBSTD_TARGET)
endef

$(eval $(host-generic-package))
