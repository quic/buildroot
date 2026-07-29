################################################################################
#
# toolchain-buildroot-hexagon-sysroot
#
# Drags in the prebuilt Hexagon musl sysroot (headers, libc, libc++,
# libunwind and the compiler-rt static archives) from the same CodeLinaro
# clang+llvm release used by toolchain-external-hexagon, for use by the
# BR2_TOOLCHAIN_BUILDROOT_CLANG from-source toolchain flavor. There is no
# from-source hexagon musl build yet, so this package is the sole source of
# the target C/C++ runtime for that flavor.
#
################################################################################

TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_VERSION = 23.1.0-rc1
TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_SITE = https://artifacts.codelinaro.org/artifactory/codelinaro-toolchain-for-hexagon/$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_VERSION)
TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_SOURCE = clang+llvm-$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_VERSION)-cross-hexagon-unknown-linux-musl.tar.zst
# No LICENSE file ships in the extracted tree; same as
# toolchain-external-hexagon.mk, which also declares no license fields for
# this release.
TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_LICENSE = Apache-2.0 with exceptions (LLVM), MIT (musl)

# Prebuilt binaries only, nothing to build.
TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_INSTALL_STAGING = YES

# This package is itself a dependency of toolchain-buildroot (like musl, see
# package/musl/musl.mk), so it must not pull in the 'toolchain' dependency or
# the build would be circular.
TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_ADD_TOOLCHAIN_DEPENDENCY = NO

TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_DIR = x86_64-ubuntu-22.04
TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_TARGET_DIR = $(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_DIR)/target/hexagon-unknown-linux-musl

# Runtime .so's mirrored from the hexagon+musl block of
# TOOLCHAIN_EXTERNAL_LIBS in toolchain/toolchain-external/pkg-toolchain-external.mk.
TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_RUNTIME_LIBS = \
	libc.so libclang_rt.builtins-hexagon.so* \
	libc++.so* libc++abi.so* libunwind.so* \
	ld-musl-*.so*

define TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_INSTALL_STAGING_CMDS
	# musl + libc++ headers
	cp -a $(@D)/$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_TARGET_DIR)/usr/include \
		$(STAGING_DIR)/usr/

	# Static libs, CRT objects, and dev symlinks. usr/lib/scs (the
	# shadow-call-stack ABI variant) is intentionally not copied here;
	# nothing in this toolchain flavor currently opts into it.
	cp -a $(@D)/$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_TARGET_DIR)/usr/lib/*.a \
		$(@D)/$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_TARGET_DIR)/usr/lib/*.o \
		$(@D)/$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_TARGET_DIR)/usr/lib/*.syms \
		$(STAGING_DIR)/usr/lib/
	cp -a $(@D)/$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_TARGET_DIR)/usr/lib/libc++.modules.json \
		$(STAGING_DIR)/usr/lib/
	cp -a $(@D)/$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_TARGET_DIR)/usr/share/. \
		$(STAGING_DIR)/usr/share/
	$(foreach f,$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_RUNTIME_LIBS), \
		cp -dR $(@D)/$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_TARGET_DIR)/usr/lib/$(f) \
			$(STAGING_DIR)/usr/lib/ 2>/dev/null || true
	)
	cp -a $(@D)/$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_TARGET_DIR)/lib/. \
		$(STAGING_DIR)/lib/

	# host-clang resolves compiler-rt (libclang_rt.builtins etc.) via its
	# own -print-resource-dir, which for this prebuilt release is
	# lib/clang/23 regardless of buildroot's from-source host-clang major
	# version (CLANG_VERSION_MAJOR) -- mirroring the same approach already
	# used for BR2_TOOLCHAIN_EXTERNAL_CLANG hexagon builds in
	# TOOLCHAIN_EXTERNAL_INSTALL_CLANG_RUNTIME (pkg-toolchain-external.mk).
	mkdir -p $(HOST_DIR)/lib/clang/23/lib/hexagon-unknown-linux-musl
	cp -a $(@D)/$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_DIR)/lib/clang/23/lib/hexagon-unknown-linux-musl/. \
		$(HOST_DIR)/lib/clang/23/lib/hexagon-unknown-linux-musl/
endef

define TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_INSTALL_TARGET_CMDS
	$(foreach f,$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_RUNTIME_LIBS), \
		cp -dR $(@D)/$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_TARGET_DIR)/usr/lib/$(f) \
			$(TARGET_DIR)/usr/lib/ 2>/dev/null || true
	)
	cp -dR $(@D)/$(TOOLCHAIN_BUILDROOT_HEXAGON_SYSROOT_REL_TARGET_DIR)/lib/ld-musl-hexagon.so.1 \
		$(TARGET_DIR)/lib/
endef

$(eval $(generic-package))
