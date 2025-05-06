################################################################################
#
# Hexagon Linux Loader
#
################################################################################

HEXAGON_LINUX_LOADER_VERSION = mathbern/64-bits-fix
HEXAGON_LINUX_LOADER_SITE = git@github.com:quic/musl.git
HEXAGON_LINUX_LOADER_SITE_METHOD = git
HEXAGON_LINUX_LOADER_INSTALL_IMAGES = YES

HEXAGON_LINUX_LOADER_CFLAGS=-G0 -O0 -mv68 -fno-builtin -mlong-calls \
			    --target=hexagon-unknown-linux-musl \
			    -Wno-switch-bool -Wno-unsupported-floating-point-opt

define HEXAGON_LINUX_LOADER_BUILD_CMDS
	( \
		cd $(@D) && \
		./configure --target=hexagon \
			AR=llvm-ar RANLIB=llvm-ranlib STRIP=llvm-strip \
			CC=hexagon-unknown-linux-musl-clang \
			CROSS_COMPILE=hexagon-unknown-linux-musl- \
			CROSS_CFLAGS="$(HEXAGON_LINUX_LOADER_CFLAGS)" \
			--prefix=./install --syslibdir=./install \
	)
	$(MAKE) -C $(@D) install -j
endef

define HEXAGON_LINUX_LOADER_INSTALL_IMAGES_CMDS
	cp $(@D)/install/lib/libc.so $(BINARIES_DIR)/ld-musl-hexagon.so.1
endef

$(eval $(generic-package))
