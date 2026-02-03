################################################################################
#
# opencl-icd-loader
#
################################################################################

OPENCL_ICD_LOADER_VERSION = 2024.05.08
OPENCL_ICD_LOADER_SITE = $(call github,KhronosGroup,OpenCL-ICD-Loader,v$(OPENCL_ICD_LOADER_VERSION))
OPENCL_ICD_LOADER_LICENSE = Apache-2.0
OPENCL_ICD_LOADER_LICENSE_FILES = LICENSE
OPENCL_ICD_LOADER_INSTALL_STAGING = YES
OPENCL_ICD_LOADER_DEPENDENCIES = opencl-headers

OPENCL_ICD_LOADER_CONF_OPTS = \
	-DBUILD_TESTING=OFF \
	-DOPENCL_ICD_LOADER_BUILD_TESTING=OFF

$(eval $(cmake-package))
