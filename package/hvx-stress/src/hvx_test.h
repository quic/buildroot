/*
 * Copyright (c) 2026, Qualcomm Innovation Center, Inc. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Shared scaffolding for the HVX stress tests: a deterministic PRNG, aligned
 * vector buffers, a mismatch reporter and a main() that runs a table of tests.
 *
 * Every test is a function returning 0 on success and non-zero on failure, and
 * the exit status of the resulting binary is the number of failing tests (with
 * 125 as a saturating cap).  Nothing here parses stdout: a caller decides
 * pass/fail purely from the exit status.
 */

#ifndef HVX_TEST_H
#define HVX_TEST_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <hexagon_types.h>
#include <hvx_hexagon_protos.h>

/* This suite is built with -mhvx-length=128B throughout. */
#define HVX_VLEN 128

/* Vectors per test buffer.  Large enough that a test spans several pages --
 * and therefore several opportunities to be preempted -- while still leaving
 * the whole working set comfortably inside a few hundred KB so that many
 * workers can run concurrently. */
#define HVX_NVEC 64

#define HVX_ALIGNED __attribute__((aligned(HVX_VLEN)))

typedef int (*hvx_test_fn)(uint32_t seed);

struct hvx_test {
	const char *name;
	hvx_test_fn fn;
};

/* Provided by each test binary. */
extern const struct hvx_test hvx_tests[];
extern const unsigned int hvx_test_count;

/*
 * xorshift32.  Deliberately not rand(): the sequence must be identical on
 * every host and every run so that a reported seed reproduces a failure
 * exactly.
 */
static inline uint32_t hvx_rand(uint32_t *state)
{
	uint32_t x = *state;

	x ^= x << 13;
	x ^= x >> 17;
	x ^= x << 5;
	*state = x ? x : 0x2545f491u;
	return *state;
}

static inline void hvx_fill_random(void *buf, size_t bytes, uint32_t seed)
{
	uint32_t state = seed ? seed : 1u;
	uint32_t *p = (uint32_t *)buf;
	size_t i;

	for (i = 0; i < bytes / sizeof(*p); i++)
		p[i] = hvx_rand(&state);
}

/*
 * Report a mismatch.  Prints the element index and both values so a failure
 * names the exact lane that went wrong, plus the seed so the case can be
 * replayed with -s.
 */
int hvx_mismatch(const char *test, uint32_t seed, size_t index,
		 long long want, long long got);

/*
 * Compare two buffers byte for byte, reporting the first difference.
 */
int hvx_memcmp(const char *test, uint32_t seed, const void *want,
	       const void *got, size_t bytes);

/*
 * Runs the test table.  Options:
 *   -n N   repeat the whole table N times (default 1)
 *   -s S   base seed (default 1); iteration k uses seed S + k
 *   -t T   run only the test named T
 *   -l     list test names and exit
 *   -v     print a line per test rather than only failures
 */
int hvx_test_main(int argc, char **argv);

#endif /* HVX_TEST_H */
