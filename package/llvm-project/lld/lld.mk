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
LLD_DEPENDENCIES = llvm

# build as static libs as is done in llvm & clang
HOST_LLD_CONF_OPTS += -DBUILD_SHARED_LIBS=OFF
LLD_CONF_OPTS += -DBUILD_SHARED_LIBS=OFF

HOST_LLD_CONF_OPTS += -DLLVM_COMMON_CMAKE_UTILS=$(HOST_DIR)/lib/cmake/llvm
LLD_CONF_OPTS += -DLLVM_COMMON_CMAKE_UTILS=$(HOST_DIR)/lib/cmake/llvm

LLD_CONF_OPTS += \
	-DCMAKE_CROSSCOMPILING=1 \
	-DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_MODULE_PATH=$(HOST_DIR)/lib/cmake/llvm \
	-DLLVM_DIR=$(STAGING_DIR)/usr/lib/cmake/llvm \
	-DLLVM_MAIN_SRC_DIR=$(BUILD_DIR)/llvm-$(LLVM_PROJECT_VERSION) \
	-DLLVM_TABLEGEN_EXE:FILEPATH=$(HOST_DIR)/bin/llvm-tblgen

# Link ld.lld against the target libLLVM.so dylib built by llvm.mk, rather
# than statically pulling in every LLVM component it touches.
LLD_CONF_OPTS += \
	-DLLVM_LINK_LLVM_DYLIB=ON \
	-DLLVM_DYLIB_COMPONENTS=all

# lld's default install path expects a plain "ld" for tools (e.g. clang)
# that don't pass -fuse-ld=lld explicitly.
define LLD_INSTALL_TARGET_SYMLINK
	ln -sf ld.lld $(TARGET_DIR)/usr/bin/ld
endef
LLD_POST_INSTALL_TARGET_HOOKS += LLD_INSTALL_TARGET_SYMLINK

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

$(eval $(cmake-package))
$(eval $(host-cmake-package))
