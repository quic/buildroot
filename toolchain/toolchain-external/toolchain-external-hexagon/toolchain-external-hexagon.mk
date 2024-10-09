################################################################################
#
# toolchain-external-hexagon
#
################################################################################

TOOLCHAIN_EXTERNAL_HEXAGON_VERSION = 20.1.4
TOOLCHAIN_EXTERNAL_HEXAGON_SITE= https://artifacts.codelinaro.org/artifactory/codelinaro-toolchain-for-hexagon/$(TOOLCHAIN_EXTERNAL_HEXAGON_VERSION)
TOOLCHAIN_EXTERNAL_HEXAGON_SOURCE = clang+llvm-$(TOOLCHAIN_EXTERNAL_HEXAGON_VERSION)-cross-$(TOOLCHAIN_EXTERNAL_PREFIX).tar.zst

$(eval $(toolchain-external-package))
