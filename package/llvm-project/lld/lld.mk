################################################################################
#
# lld
#
################################################################################

LLD_VERSION = $(LLVM_PROJECT_VERSION)
LLD_SITE = $(LLVM_PROJECT_SITE)
LLD_SOURCE = $(LLVM_PROJECT_SOURCE)
LLD_DL_SUBDIR = llvm-project
LLD_LICENSE = Apache-2.0 with exceptions
LLD_LICENSE_FILES = LICENSE.TXT
LLD_SUBDIR = lld
LLD_SUPPORTS_IN_SOURCE_BUILD = NO
HOST_LLD_DEPENDENCIES = host-llvm host-llvm-libunwind

# build as static libs as is done in llvm & clang
HOST_LLD_CONF_OPTS += -DBUILD_SHARED_LIBS=OFF

HOST_LLD_CONF_OPTS += -DLLVM_COMMON_CMAKE_UTILS=$(HOST_DIR)/lib/cmake/llvm

# GCC looks for tools in a different path from LLD's default installation path
define HOST_LLD_CREATE_SYMLINKS
	mkdir -p $(HOST_DIR)/$(GNU_TARGET_NAME)/bin
	ln -sfr $(HOST_DIR)/bin/lld $(HOST_DIR)/$(GNU_TARGET_NAME)/bin/lld
	ln -sfr $(HOST_DIR)/bin/lld $(HOST_DIR)/$(GNU_TARGET_NAME)/bin/ld.lld
endef

HOST_LLD_POST_INSTALL_HOOKS += HOST_LLD_CREATE_SYMLINKS

# For BR2_TOOLCHAIN_BUILDROOT_CLANG, host-lld doubles as TARGET_LD, invoked
# via TARGET_CROSS = $(HOST_DIR)/bin/$(GNU_TARGET_NAME)- (see package/Makefile.in),
# so it also needs to exist under its triple-prefixed name.
ifeq ($(BR2_TOOLCHAIN_BUILDROOT_CLANG),y)
define HOST_LLD_CREATE_TARGET_SYMLINK
	ln -sfr $(HOST_DIR)/bin/lld $(HOST_DIR)/bin/$(GNU_TARGET_NAME)-ld.lld
endef
HOST_LLD_POST_INSTALL_HOOKS += HOST_LLD_CREATE_TARGET_SYMLINK
endif

$(eval $(host-cmake-package))
