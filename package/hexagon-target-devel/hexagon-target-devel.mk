################################################################################
#
# hexagon-target-devel
#
# Installs the C/C++ library development files (musl + libc++ headers,
# static libraries, compiler-rt runtime libraries and CRT startup objects)
# from the external toolchain's staging directory onto the target, so that
# an on-target clang (BR2_PACKAGE_CLANG_TARGET_COMPILER) + lld
# (BR2_PACKAGE_LLD) can actually compile and link code from within the
# booted rootfs.
#
################################################################################

HEXAGON_TARGET_DEVEL_ADD_TOOLCHAIN_DEPENDENCY = NO
HEXAGON_TARGET_DEVEL_DEPENDENCIES = toolchain
ifeq ($(BR2_PACKAGE_CLANG_TARGET_COMPILER),y)
HEXAGON_TARGET_DEVEL_DEPENDENCIES += clang
endif
ifeq ($(BR2_PACKAGE_LLD),y)
HEXAGON_TARGET_DEVEL_DEPENDENCIES += lld
endif

# Static libraries and CRT objects actually needed to use clang as a bare
# on-target compiler+linker: musl, libc++/libc++abi/libunwind, compiler-rt
# runtime variants, and CRT startup objects. Deliberately excludes the 160+
# libLLVM*.a/libclang*.a static libraries also present in staging -- those
# are LLVM/clang's own internal build libraries, needed only to build
# LLVM/clang from source, not to run clang as a compiler, and would bloat
# the target rootfs for no benefit.
HEXAGON_TARGET_DEVEL_LIB_NAMES = \
	libc.a libm.a libpthread.a libdl.a librt.a libcrypt.a libresolv.a \
	libutil.a libxnet.a libbz2.a \
	libc++.a libc++abi.a libc++experimental.a libunwind.a

# LLVM/clang's own C/C++ API headers (~78M) are needed only to build
# LLVM/clang from source, not to use clang as a compiler -- excluded for
# the same bloat reasons as the internal static libs above.
HEXAGON_TARGET_DEVEL_INCLUDE_EXCLUDES = \
	llvm llvm-c clang clang-c LLVMSPIRVLib spirv spirv-tools CL

define HEXAGON_TARGET_DEVEL_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/include
	rsync -a \
		$(foreach d,$(HEXAGON_TARGET_DEVEL_INCLUDE_EXCLUDES),--exclude=/$(d)) \
		$(STAGING_DIR)/usr/include/ $(TARGET_DIR)/usr/include/

	mkdir -p $(TARGET_DIR)/usr/lib
	$(foreach lib,$(HEXAGON_TARGET_DEVEL_LIB_NAMES), \
		cp -a $(STAGING_DIR)/usr/lib/$(lib) $(TARGET_DIR)/usr/lib/ 2>/dev/null; \
	)
	cp -a $(STAGING_DIR)/usr/lib/libclang_rt.*-hexagon.a $(TARGET_DIR)/usr/lib/
	cp -a $(STAGING_DIR)/usr/lib/crt1.o $(STAGING_DIR)/usr/lib/crti.o \
		$(STAGING_DIR)/usr/lib/crtn.o $(STAGING_DIR)/usr/lib/rcrt1.o \
		$(STAGING_DIR)/usr/lib/Scrt1.o $(TARGET_DIR)/usr/lib/
endef

$(eval $(generic-package))
