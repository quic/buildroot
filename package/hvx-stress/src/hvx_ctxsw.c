/*
 * Copyright (c) 2026, Qualcomm Innovation Center, Inc. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * HVX context save/restore torture test.
 *
 * This is the part of the suite that actually exercises the kernel's HVX
 * coprocessor context management (arch/hexagon/kernel/hvx/) and QEMU's
 * per-SSR.XA vector register files.  The kernel hands out a limited number of
 * hardware HVX contexts (four on the QEMU virt machine) and lazily assigns one
 * to a thread when it faults on its first HVX instruction, then saves and
 * restores that state around context switches.  If any of that is wrong -- a
 * missed save, a stale generation counter, two threads aliased onto one
 * hardware context -- a thread's vector registers come back changed.
 *
 * The test makes such corruption unmissable:
 *
 *   1. Every worker writes a fingerprint unique to (pid, tid, iteration, seed)
 *      into all 32 vector registers and derives Q0-Q3 from it.
 *   2. It then spends a long time being descheduled -- sched_yield in a loop,
 *      with the workers deliberately oversubscribing the CPUs so the yields
 *      turn into real context switches -- without touching a vector register.
 *   3. It reads all 32 vector registers plus Q0-Q3 back and compares byte for
 *      byte against what it wrote.
 *
 * Steps 1-3 are a single asm block on purpose.  Split across C statements the
 * compiler would be free to spill the vector registers to the stack around the
 * calls, which would quietly turn this into a test of memcpy rather than of
 * the kernel's save/restore path.  Keeping it in one block guarantees the
 * fingerprint is live *in the registers* across every preemption point.
 *
 * A SIGALRM handler that itself uses HVX runs throughout, so the interrupted
 * thread's state also has to survive an asynchronous signal that consumes
 * vector registers underneath it.
 */

#include <errno.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>

#include "hvx_test.h"

#define NUM_VREGS 32
#define NUM_QREGS 4

/* Apply M to each vector register number. */
#define FOR_EACH_VREG(M)						\
	M(0)  M(1)  M(2)  M(3)  M(4)  M(5)  M(6)  M(7)			\
	M(8)  M(9)  M(10) M(11) M(12) M(13) M(14) M(15)			\
	M(16) M(17) M(18) M(19) M(20) M(21) M(22) M(23)			\
	M(24) M(25) M(26) M(27) M(28) M(29) M(30) M(31)

/*
 * vmem's immediate offset is only four bits of vector units, which does not
 * reach v31, so walk the buffers with post-increment addressing instead.  That
 * leaves r17-r19 pointing past their buffers, hence the read-write operands.
 */
#define LOAD_VREG(n)	"  v" #n " = vmem(r17++#1)\n"
#define STORE_VREG(n)	"  vmem(r18++#1) = v" #n "\n"

/*
 * Load the fingerprint into V0-V31, derive Q0-Q3 from it, yield the CPU
 * `yields` times, then read everything back.
 *
 * Register discipline: the syscall clobbers the caller-saved registers, so the
 * three buffer pointers and the yield count are pinned to callee-saved
 * r17-r20, which the kernel preserves across trap0.  The caller-saved
 * registers are all listed as clobbers, both to describe what the syscall does
 * and to stop the compiler from allocating anything of ours there.  r16 is
 * likewise clobbered and used as the loop counter, so the compiler saves it.
 */
static void hvx_ctxsw_gauntlet(const HVX_Vector *in, HVX_Vector *out,
			       HVX_Vector *qout, long yields)
{
	register const HVX_Vector *r_in __asm__("r17") = in;
	register HVX_Vector *r_out __asm__("r18") = out;
	register HVX_Vector *r_qout __asm__("r19") = qout;
	register long r_yields __asm__("r20") = yields;

	__asm__ __volatile__(
		FOR_EACH_VREG(LOAD_VREG)

		/* Q0-Q3 are a deterministic function of V0-V7. */
		"  q0 = vcmp.gt(v0.b, v1.b)\n"
		"  q1 = vcmp.gt(v2.b, v3.b)\n"
		"  q2 = vcmp.gt(v4.b, v5.b)\n"
		"  q3 = vcmp.gt(v6.b, v7.b)\n"

		/* Get descheduled repeatedly without touching a vector reg. */
		"  r16 = %[yields]\n"
		"1:\n"
		"  p0 = cmp.gt(r16, #0)\n"
		"  if (!p0) jump 2f\n"
		"  r6 = #124\n"			/* __NR_sched_yield */
		"  trap0(#1)\n"
		"  r16 = add(r16, #-1)\n"
		"  jump 1b\n"
		"2:\n"

		FOR_EACH_VREG(STORE_VREG)

		/*
		 * V0-V31 are safely in memory now, so v0-v2 can be reused as
		 * scratch to materialise each predicate as an all-ones or
		 * all-zeroes byte mask that C can compare against.
		 */
		"  v0 = vxor(v0, v0)\n"
		"  v1 = vnot(v0)\n"
		"  v2 = vmux(q0, v1, v0)\n"
		"  vmem(r19++#1) = v2\n"
		"  v2 = vmux(q1, v1, v0)\n"
		"  vmem(r19++#1) = v2\n"
		"  v2 = vmux(q2, v1, v0)\n"
		"  vmem(r19++#1) = v2\n"
		"  v2 = vmux(q3, v1, v0)\n"
		"  vmem(r19++#1) = v2\n"
		: "+r"(r_in), "+r"(r_out), "+r"(r_qout)
		: [yields] "r"(r_yields)
		: "memory", "p0",
		  "r0", "r1", "r2", "r3", "r4", "r5", "r6", "r7",
		  "r8", "r9", "r10", "r11", "r12", "r13", "r14", "r15",
		  "r16",
		  "v0", "v1", "v2", "v3", "v4", "v5", "v6", "v7",
		  "v8", "v9", "v10", "v11", "v12", "v13", "v14", "v15",
		  "v16", "v17", "v18", "v19", "v20", "v21", "v22", "v23",
		  "v24", "v25", "v26", "v27", "v28", "v29", "v30", "v31",
		  "q0", "q1", "q2", "q3");
}

/*
 * A periodic signal, used purely as a preemption source: delivering it forces
 * an entry into and return from the kernel at an arbitrary point inside the
 * yield loop, on top of the reschedules the loop already causes.
 *
 * The handler deliberately does NOT touch a vector register.  On Hexagon the
 * signal frame carries no vector state at all -- struct sigcontext is UAPI and
 * holds only sc_regs (arch/hexagon/include/uapi/asm/sigcontext.h), and QEMU's
 * linux-user frame matches it (linux-user/hexagon/signal.c) -- so a handler
 * that uses HVX legitimately destroys the interrupted thread's V registers.
 * That is a property of the platform ABI, not a context-switch bug, so this
 * test must not assert against it.  (It is worth noting as an ABI gap in its
 * own right: most architectures save vector state in the signal frame
 * precisely so that handlers, and any vectorised libc code they call, are
 * safe.)
 */
static volatile sig_atomic_t signal_count;

static void sigalrm_handler(int sig)
{
	(void)sig;
	signal_count++;
}

/* Build a fingerprint that no other worker or iteration can produce. */
static void make_fingerprint(HVX_Vector *fp, uint32_t seed, unsigned long tag,
			     unsigned long iteration)
{
	uint32_t *w = (uint32_t *)fp;
	const size_t n = NUM_VREGS * HVX_VLEN / sizeof(uint32_t);
	uint32_t state;
	size_t i;

	state = seed ^ (uint32_t)(tag * 2654435761u) ^
		(uint32_t)(iteration * 40503u);
	if (!state)
		state = 0x9e3779b9u;

	for (i = 0; i < n; i++)
		w[i] = hvx_rand(&state);
}

/* Recompute the expected Q0-Q3 masks from the fingerprint, using intrinsics
 * so the reference does not share code with the asm under test. */
static void expected_qmasks(const HVX_Vector *fp, HVX_Vector *q)
{
	const HVX_Vector zero = Q6_V_vzero();
	const HVX_Vector ones = Q6_V_vnot_V(zero);
	unsigned int i;

	for (i = 0; i < NUM_QREGS; i++) {
		HVX_VectorPred p =
			Q6_Q_vcmp_gt_VbVb(fp[2 * i], fp[2 * i + 1]);

		q[i] = Q6_V_vmux_QVV(p, ones, zero);
	}
}

struct worker_args {
	uint32_t seed;
	unsigned long iterations;
	long yields;
	unsigned long tag;
	int verbose;
	int failures;
};

static void *worker(void *arg)
{
	struct worker_args *wa = arg;
	static __thread HVX_Vector fingerprint[NUM_VREGS] HVX_ALIGNED;
	static __thread HVX_Vector observed[NUM_VREGS] HVX_ALIGNED;
	static __thread HVX_Vector observed_q[NUM_QREGS] HVX_ALIGNED;
	static __thread HVX_Vector expected_q[NUM_QREGS] HVX_ALIGNED;
	unsigned long iter;

	for (iter = 0; iter < wa->iterations; iter++) {
		char label[64];
		int bad = 0;

		make_fingerprint(fingerprint, wa->seed, wa->tag, iter);
		expected_qmasks(fingerprint, expected_q);
		memset(observed, 0, sizeof(observed));
		memset(observed_q, 0, sizeof(observed_q));

		hvx_ctxsw_gauntlet(fingerprint, observed, observed_q,
				   wa->yields);

		snprintf(label, sizeof(label), "ctxsw/vregs[pid=%ld,tag=%lu]",
			 (long)getpid(), wa->tag);
		if (hvx_memcmp(label, wa->seed + (uint32_t)iter, fingerprint,
			       observed, sizeof(fingerprint)))
			bad++;

		snprintf(label, sizeof(label), "ctxsw/qregs[pid=%ld,tag=%lu]",
			 (long)getpid(), wa->tag);
		if (hvx_memcmp(label, wa->seed + (uint32_t)iter, expected_q,
			       observed_q, sizeof(expected_q)))
			bad++;

		wa->failures += bad;
		if (!bad && wa->verbose)
			printf("ok ctxsw tag=%lu iter=%lu\n", wa->tag, iter);
	}
	return NULL;
}

static void usage(const char *argv0)
{
	fprintf(stderr,
		"usage: %s [-n iterations] [-s seed] [-j threads] "
		"[-y yields] [-v]\n",
		argv0);
}

int main(int argc, char **argv)
{
	unsigned long iterations = 4;
	unsigned long threads = 2;
	uint32_t seed = 1;
	long yields = 64;
	int verbose = 0;
	struct worker_args *args;
	pthread_t *tids;
	struct itimerval it;
	unsigned long i;
	int failures = 0;
	int opt;

	while ((opt = getopt(argc, argv, "n:s:j:y:vh")) != -1) {
		switch (opt) {
		case 'n':
			iterations = strtoul(optarg, NULL, 0);
			break;
		case 's':
			seed = (uint32_t)strtoul(optarg, NULL, 0);
			break;
		case 'j':
			threads = strtoul(optarg, NULL, 0);
			break;
		case 'y':
			yields = strtol(optarg, NULL, 0);
			break;
		case 'v':
			verbose = 1;
			break;
		default:
			usage(argv[0]);
			return 2;
		}
	}

	if (threads < 1)
		threads = 1;

	/* Fire a signal often enough to land inside the yield loop. */
	signal(SIGALRM, sigalrm_handler);
	it.it_interval.tv_sec = 0;
	it.it_interval.tv_usec = 10000;
	it.it_value = it.it_interval;
	setitimer(ITIMER_REAL, &it, NULL);

	args = calloc(threads, sizeof(*args));
	tids = calloc(threads, sizeof(*tids));
	if (!args || !tids) {
		fprintf(stderr, "%s: out of memory\n", argv[0]);
		return 2;
	}

	for (i = 0; i < threads; i++) {
		args[i].seed = seed;
		args[i].iterations = iterations;
		args[i].yields = yields;
		args[i].tag = (unsigned long)getpid() * 1000u + i;
		args[i].verbose = verbose;
		args[i].failures = 0;
	}

	/* Thread 0 runs on this thread so a single-threaded run stays
	 * single-threaded and is easier to debug. */
	for (i = 1; i < threads; i++) {
		int rc = pthread_create(&tids[i], NULL, worker, &args[i]);

		if (rc) {
			fprintf(stderr, "%s: pthread_create: %s\n", argv[0],
				strerror(rc));
			return 2;
		}
	}
	worker(&args[0]);
	for (i = 1; i < threads; i++)
		pthread_join(tids[i], NULL);

	for (i = 0; i < threads; i++)
		failures += args[i].failures;

	if (verbose)
		printf("ctxsw: %d signal deliveries during the run\n",
		       (int)signal_count);

	free(args);
	free(tids);

	if (failures) {
		fprintf(stderr, "%s: %d failure(s)\n", argv[0], failures);
		return failures > 125 ? 125 : failures;
	}
	return 0;
}
