################################################################################
#
# toolchain-external-hexagon
#
################################################################################

TOOLCHAIN_EXTERNAL_HEXAGON_VERSION = 19.1.2
TOOLCHAIN_EXTERNAL_HEXAGON_SITE= https://artifacts.codelinaro.org/artifactory/codelinaro-toolchain-for-hexagon/$(TOOLCHAIN_EXTERNAL_HEXAGON_VERSION)
TOOLCHAIN_EXTERNAL_HEXAGON_SOURCE = clang+llvm-$(TOOLCHAIN_EXTERNAL_HEXAGON_VERSION)-cross-$(TOOLCHAIN_EXTERNAL_PREFIX).tar.xz

# No trampoline support in lld yet, so for now:
TOOLCHAIN_EXTERNAL_HEXAGON_CFLAGS += -mlong-calls

$(eval $(toolchain-external-package))
