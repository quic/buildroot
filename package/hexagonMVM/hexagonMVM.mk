################################################################################
#
# Hexagon MiniVM
#
################################################################################

HEXAGONMVM_VERSION = 0.3.0
HEXAGONMVM_SOURCE = $(HEXAGONMVM_VERSION).tar.gz
HEXAGONMVM_SITE = $(call github,quic,hexagonMVM,v$(HEXAGONMVM_VERSION))

HEXAGONMVM_LICENSE = BSD-3-Clause
HEXAGONMVM_LICENSE_FILES = LICENSE

HEXAGONMVM_DEPENDENCIES =
HEXAGONMVM_INSTALL_IMAGES = YES

HEXAGONMVM_CFLAGS=-fno-pie -fno-pic

define HEXAGONMVM_BUILD_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) CFLAGS="$(HEXAGONMVM_CFLAGS)" -C $(@D) minivm
endef

define HEXAGONMVM_INSTALL_IMAGES_CMDS
	$(MAKE) $(TARGET_CONFIGURE_OPTS) CFLAGS="$(HEXAGONMVM_CFLAGS)" bindir=$(BINARIES_DIR) -C $(@D) install
endef

$(eval $(generic-package))
