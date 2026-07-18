/*
 * Copyright (c) 2026, Qualcomm Innovation Center, Inc. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Test-table driver for the known-answer HVX binaries.
 */

#include <unistd.h>

#include "hvx_test.h"

static const struct hvx_test *find_test(const char *name)
{
	unsigned int i;

	for (i = 0; i < hvx_test_count; i++) {
		if (!strcmp(hvx_tests[i].name, name))
			return &hvx_tests[i];
	}
	return NULL;
}

static void usage(const char *argv0)
{
	fprintf(stderr,
		"usage: %s [-n iterations] [-s seed] [-t test] [-l] [-v]\n",
		argv0);
}

int hvx_test_main(int argc, char **argv)
{
	unsigned long iterations = 1;
	uint32_t seed = 1;
	const char *only = NULL;
	int verbose = 0;
	unsigned long failures = 0;
	unsigned long iter;
	int opt;

	while ((opt = getopt(argc, argv, "n:s:t:lvh")) != -1) {
		switch (opt) {
		case 'n':
			iterations = strtoul(optarg, NULL, 0);
			break;
		case 's':
			seed = (uint32_t)strtoul(optarg, NULL, 0);
			break;
		case 't':
			only = optarg;
			break;
		case 'l': {
			unsigned int i;

			for (i = 0; i < hvx_test_count; i++)
				printf("%s\n", hvx_tests[i].name);
			return 0;
		}
		case 'v':
			verbose = 1;
			break;
		default:
			usage(argv[0]);
			return 2;
		}
	}

	if (only && !find_test(only)) {
		fprintf(stderr, "%s: no such test '%s'\n", argv[0], only);
		return 2;
	}

	for (iter = 0; iter < iterations; iter++) {
		uint32_t iter_seed = seed + (uint32_t)iter;
		unsigned int i;

		for (i = 0; i < hvx_test_count; i++) {
			const struct hvx_test *t = &hvx_tests[i];
			int rc;

			if (only && strcmp(t->name, only))
				continue;

			rc = t->fn(iter_seed);
			if (rc) {
				failures++;
				/* The test itself has already described the
				 * mismatch on stderr. */
			} else if (verbose) {
				printf("ok %s (seed 0x%08x)\n", t->name,
				       iter_seed);
			}
		}
	}

	if (failures) {
		fprintf(stderr, "%s: %lu failure(s)\n", argv[0], failures);
		return failures > 125 ? 125 : (int)failures;
	}
	return 0;
}
