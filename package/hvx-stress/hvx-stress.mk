################################################################################
#
# hvx-stress
#
################################################################################

HVX_STRESS_VERSION = 1.0
HVX_STRESS_SITE = package/hvx-stress/src
HVX_STRESS_SITE_METHOD = local

HVX_STRESS_LICENSE = BSD-3-Clause
HVX_STRESS_LICENSE_FILES = LICENSE

# 128-byte vectors match what the QEMU virt machine advertises
# (hvx_vec_log_length = 7 in the machine cfgtable).
HVX_STRESS_HVX_CFLAGS = -mhvx -mhvx-length=128B

# The IEEE floating point HVX instructions, and the Q6_Vsf_* intrinsics that
# reach them, only exist from v68 onwards; on older cores clang rejects the
# option outright. The two tests that use them compile out via
# __HVX_IEEE_FP__ when it is absent.
ifneq ($(BR2_HEXAGON_v68)$(BR2_HEXAGON_v69)$(BR2_HEXAGON_v71)$(BR2_HEXAGON_v73),)
HVX_STRESS_HVX_CFLAGS += -mhvx-ieee-fp
endif

define HVX_STRESS_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) \
		HVX_CFLAGS="$(HVX_STRESS_HVX_CFLAGS)" \
		CFLAGS="$(TARGET_CFLAGS)" LDFLAGS="$(TARGET_LDFLAGS)" \
		-C $(@D) all
endef

define HVX_STRESS_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) \
		DESTDIR=$(TARGET_DIR) prefix=/usr \
		-C $(@D) install
endef

$(eval $(generic-package))
