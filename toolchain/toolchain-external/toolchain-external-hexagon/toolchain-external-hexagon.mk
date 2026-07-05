################################################################################
#
# toolchain-external-hexagon
#
################################################################################

TOOLCHAIN_EXTERNAL_HEXAGON_VERSION = 22.1.4
# The codelinaro artifactory release directory for this version has a
# trailing underscore, unlike the version number embedded in the tarball name
TOOLCHAIN_EXTERNAL_HEXAGON_SITE= https://artifacts.codelinaro.org/artifactory/codelinaro-toolchain-for-hexagon/$(TOOLCHAIN_EXTERNAL_HEXAGON_VERSION)_
TOOLCHAIN_EXTERNAL_HEXAGON_SOURCE = clang+llvm-$(TOOLCHAIN_EXTERNAL_HEXAGON_VERSION)-cross-$(TOOLCHAIN_EXTERNAL_PREFIX).tar.zst

$(eval $(toolchain-external-package))
