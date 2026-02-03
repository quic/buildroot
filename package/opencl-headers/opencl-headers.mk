################################################################################
#
# opencl-headers
#
################################################################################

OPENCL_HEADERS_VERSION = 2024.05.08
OPENCL_HEADERS_SITE = $(call github,KhronosGroup,OpenCL-Headers,v$(OPENCL_HEADERS_VERSION))
OPENCL_HEADERS_LICENSE = Apache-2.0
OPENCL_HEADERS_LICENSE_FILES = LICENSE
OPENCL_HEADERS_INSTALL_STAGING = YES
OPENCL_HEADERS_INSTALL_TARGET = NO

OPENCL_HEADERS_CONF_OPTS = \
	-DBUILD_TESTING=OFF

$(eval $(cmake-package))
