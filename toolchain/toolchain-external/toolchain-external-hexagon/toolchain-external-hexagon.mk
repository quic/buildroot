################################################################################
#
# toolchain-external-hexagon
#
################################################################################

TOOLCHAIN_EXTERNAL_HEXAGON_VERSION = 18.1.0-rc1
TOOLCHAIN_EXTERNAL_HEXAGON_SITE= https://artifacts.codelinaro.org/artifactory/codelinaro-toolchain-for-hexagon/18.1.0-rc1_02/clang+llvm-18.1.0-rc1-cross-$(TOOLCHAIN_EXTERNAL_PREFIX).tar.xz
TOOLCHAIN_EXTERNAL_HEXAGON_SOURCE = clang+llvm-$(TOOLCHAIN_EXTERNAL_HEXAGON_VERSION)-cross-$(TOOLCHAIN_EXTERNAL_PREFIX).tar.xz

# No trampoline support in lld yet, so for now:
TOOLCHAIN_EXTERNAL_CFLAGS += -mlong-calls

$(eval $(toolchain-external-package))
