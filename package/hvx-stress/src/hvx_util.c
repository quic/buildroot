/*
 * Copyright (c) 2026, Qualcomm Innovation Center, Inc. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Comparison and reporting helpers shared by every HVX stress binary.
 * Kept apart from the test-table driver so that binaries which supply no
 * test table (hvx_ctxsw) can link these without pulling it in.
 */

#include "hvx_test.h"

int hvx_mismatch(const char *test, uint32_t seed, size_t index,
		 long long want, long long got)
{
	fprintf(stderr,
		"FAIL %s: seed 0x%08x element %zu: want %lld, got %lld\n",
		test, seed, index, want, got);
	return 1;
}

int hvx_memcmp(const char *test, uint32_t seed, const void *want,
	       const void *got, size_t bytes)
{
	const unsigned char *w = want;
	const unsigned char *g = got;
	size_t i;

	for (i = 0; i < bytes; i++) {
		if (w[i] != g[i])
			return hvx_mismatch(test, seed, i, w[i], g[i]);
	}
	return 0;
}

