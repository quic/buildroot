################################################################################
#
# libc-test
#
################################################################################

LIBC_TEST_VERSION = f2bac7711bec93467b73bec1465579ea0b8d5071
LIBC_TEST_SITE = git://repo.or.cz/libc-test
LIBC_TEST_SITE_METHOD = git

LIBC_TEST_LICENSE = MIT
LIBC_TEST_LICENSE_FILES = COPYRIGHT

# Upstream's Makefile has no install target, and its default "all"/"run"
# targets both try to execute every test binary on the build machine to
# generate the pass/fail report -- which does not work for a cross build.
# RUN_TEST=true skips that execution (each test's report line just goes
# empty rather than PASS/FAIL) without touching the rest of the recipe: a
# failed compile or link for an individual test already can't fail the
# overall `make` (each compile/link recipe ends in `|| echo BUILDERROR ...;
# cat ...err`, so make always sees exit 0), so tests unsupported on this
# target/libc are silently skipped rather than blocking the package build.
#
# The Makefile sets its own CFLAGS with a plain "CFLAGS:=-I$(B)/common
# -Isrc/common" (no "override"), which a command-line CFLAGS -- like the
# one $(TARGET_CONFIGURE_OPTS) passes -- silently defeats. Without those
# two -I flags, test.h/mtest.h/options.h (in src/common/) aren't found and
# nearly every test fails at the first #include, so repeat them here.
define LIBC_TEST_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS) -Isrc/common -Isrc" \
		RUN_TEST=true \
		-C $(@D) all
endef

# No upstream install target: copy the built test binaries (src/*/*.exe)
# into the target, preserving the functional/math/musl/regression layout,
# for the user to run manually on-target.
define LIBC_TEST_INSTALL_TARGET_CMDS
	cd $(@D)/src && find . -name '*.exe' -exec sh -c ' \
		for f; do \
			$(INSTALL) -D -m 0755 "$$f" "$(TARGET_DIR)/usr/lib/libc-test/$$f"; \
		done' sh {} +
endef

$(eval $(generic-package))
