################################################################################
#
# Hexagon H2
#
################################################################################

HEXAGON_H2_VERSION = 585525d452d0bdd5e54e468696b42d0f63cf534e
HEXAGON_H2_SITE = git@github.qualcomm.com:Q6Auto/h2.git
HEXAGON_H2_SITE_METHOD = git
HEXAGON_H2_INSTALL_IMAGES = YES

LINUX_LINK_ADDR=0xa0000000
H2K_LOAD_ADDR=0x9b800000
LOADLINUX_FLAGS=TARGET=zebu_v68 UCOS= NULL_ANGEL_TRAP= DEMO_DISPLAY=1 \
		NO_LOAD=1 NO_PRINT=1 H2K_LOAD_ADDR=$(H2K_LOAD_ADDR) \
		LINUX_LINK_ADDR=$(LINUX_LINK_ADDR) all

define HEXAGON_H2_BUILD_CMDS
	# Mockup pkw (we don't really need it, just the invocation must succeed)
	mkdir -p $(@D)/my_bin && touch $(@D)/my_bin/pkw && chmod +x $(@D)/my_bin/pkw && \
	export PATH="$(@D)/my_bin:$$PATH:/prj/qct/llvm/devops/arch/bin" && \
	$(MAKE) -C $(@D) TARGET=zebu_v68 opt NULL_ANGEL_TRAP=1 ARCHV=68 && \
	$(MAKE) -C $(@D)/linux ARCHV=68 $(LOADLINUX_FLAGS)
endef

define HEXAGON_H2_INSTALL_IMAGES_CMDS
	cp $(@D)/linux/loadlinux $(BINARIES_DIR)
endef

$(eval $(generic-package))
