################################################################################
#
# Hexagon MiniVM
#
################################################################################

HEXAGONMVM_VERSION = 0.1.5
HEXAGONMVM_SOURCE = $(HEXAGONMVM_VERSION).tar.gz
HEXAGONMVM_SITE = $(call github,quic,hexagonMVM,v$(HEXAGONMVM_VERSION))

HEXAGONMVM_LICENSE = BSD-3-Clause
HEXAGONMVM_LICENSE_FILES = LICENSE

HEXAGONMVM_DEPENDENCIES =

define HEXAGONMVM_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) CC=hexagon-unknown-none-elf-clang AS=hexagon-unknown-none-elf-clang -C $(@D)
endef

define HEXAGONMVM_INSTALL_TARGET_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) DESTDIR=$(TARGET_DIR) -C $(@D) install
endef

$(eval $(generic-package))
