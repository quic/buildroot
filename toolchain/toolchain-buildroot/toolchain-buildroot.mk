################################################################################
#
# toolchain-buildroot
#
################################################################################

BR_LIBC = $(call qstrip,$(BR2_TOOLCHAIN_BUILDROOT_LIBC))

ifeq ($(BR2_TOOLCHAIN_BUILDROOT_CLANG),y)
# Unlike gcc, a single host-clang binary cross-compiles to any LLVM-supported
# target via --target=/triple-prefixed argv0, so there's no per-target
# initial/final gcc-style bootstrap here: host-clang + host-lld plus a
# dragged-in prebuilt sysroot is the whole toolchain.
TOOLCHAIN_BUILDROOT_DEPENDENCIES = host-clang host-lld toolchain-buildroot-hexagon-sysroot
else
# Triggering the build of the gcc-final will automatically do the
# build of binutils, uClibc, kernel headers and all the intermediate
# gcc steps.
TOOLCHAIN_BUILDROOT_DEPENDENCIES = gcc-final
endif

TOOLCHAIN_BUILDROOT_ADD_TOOLCHAIN_DEPENDENCY = NO

# Not really a virtual package, but we use the virtual package infra here so
# both the build log and build directory look nicer (toolchain-buildroot-virtual
# instead of toolchain-buildroot-undefined)
$(eval $(virtual-package))
