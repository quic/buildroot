# Copyright (c) 2026, Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

CC ?= clang
prefix ?= /usr
bindir ?= $(prefix)/bin

# -mhvx-length=128B matches the vector length the QEMU virt machine
# advertises (hvx_vec_log_length = 7).  -fno-strict-aliasing is required
# because the tests deliberately view the same vector buffers through
# several element types when checking lane values.
HVX_CFLAGS ?= -mhvx -mhvx-length=128B
CFLAGS ?= -O2 -g
ALL_CFLAGS = $(CFLAGS) $(HVX_CFLAGS) -Wall -fno-strict-aliasing

BINARIES = hvx_kernels hvx_ctxsw

all: $(BINARIES)

hvx_kernels: hvx_kernels.c hvx_test.c hvx_util.c hvx_test.h
	$(CC) $(ALL_CFLAGS) $(LDFLAGS) -o $@ hvx_kernels.c hvx_test.c hvx_util.c

hvx_ctxsw: hvx_ctxsw.c hvx_util.c hvx_test.h
	$(CC) $(ALL_CFLAGS) $(LDFLAGS) -pthread -o $@ hvx_ctxsw.c hvx_util.c

install: $(BINARIES)
	install -d $(DESTDIR)$(bindir)
	install -m 0755 $(BINARIES) $(DESTDIR)$(bindir)
	install -m 0755 hvx-stress-run $(DESTDIR)$(bindir)

clean:
	rm -f $(BINARIES)

.PHONY: all install clean
