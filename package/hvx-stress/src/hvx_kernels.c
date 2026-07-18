/*
 * Copyright (c) 2026, Qualcomm Innovation Center, Inc. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Known-answer HVX tests.  Each test runs a vector kernel over a buffer and
 * checks every lane against a scalar reference computed in plain C, so a
 * miscompiled intrinsic, a wrong QEMU helper or a corrupted vector register
 * all surface as a lane mismatch naming the exact element.
 *
 * Where an instruction's exact lane mapping is easy to state (elementwise
 * arithmetic, shifts, reductions) the reference is written out directly.
 * Where it is a permutation whose lane map is awkward to restate correctly,
 * the test asserts an invariant instead -- an identity control, or a
 * round-trip through the inverse operation -- which is still a strict
 * pass/fail check but does not depend on transcribing a table by hand.
 */

#include "hvx_test.h"

static HVX_Vector buf_a[HVX_NVEC] HVX_ALIGNED;
static HVX_Vector buf_b[HVX_NVEC] HVX_ALIGNED;
static HVX_Vector buf_c[HVX_NVEC] HVX_ALIGNED;

static void fill_inputs(uint32_t seed)
{
	hvx_fill_random(buf_a, sizeof(buf_a), seed);
	hvx_fill_random(buf_b, sizeof(buf_b), seed ^ 0x5bd1e995u);
	memset(buf_c, 0, sizeof(buf_c));
}

/*
 * Elementwise binary op.  refexpr is evaluated with x and y bound to the
 * corresponding input lanes.
 */
#define BINOP_TEST(name, ctype, intrin, refexpr)				\
static int test_##name(uint32_t seed)					\
{									\
	const ctype *a = (const ctype *)buf_a;				\
	const ctype *b = (const ctype *)buf_b;				\
	const ctype *c = (const ctype *)buf_c;				\
	const size_t n = sizeof(buf_a) / (sizeof(ctype));			\
	size_t i;							\
									\
	fill_inputs(seed);						\
	for (i = 0; i < HVX_NVEC; i++)					\
		buf_c[i] = intrin(buf_a[i], buf_b[i]);			\
									\
	for (i = 0; i < n; i++) {					\
		ctype x = a[i];						\
		ctype y = b[i];						\
		ctype want = (refexpr);					\
									\
		if (c[i] != want)					\
			return hvx_mismatch(#name, seed, i,		\
					    (long long)want,		\
					    (long long)c[i]);		\
	}								\
	return 0;							\
}

/* Elementwise unary op. */
#define UNOP_TEST(name, ctype, intrin, refexpr)				\
static int test_##name(uint32_t seed)					\
{									\
	const ctype *a = (const ctype *)buf_a;				\
	const ctype *c = (const ctype *)buf_c;				\
	const size_t n = sizeof(buf_a) / (sizeof(ctype));			\
	size_t i;							\
									\
	fill_inputs(seed);						\
	for (i = 0; i < HVX_NVEC; i++)					\
		buf_c[i] = intrin(buf_a[i]);				\
									\
	for (i = 0; i < n; i++) {					\
		ctype x = a[i];						\
		ctype want = (refexpr);					\
									\
		if (c[i] != want)					\
			return hvx_mismatch(#name, seed, i,		\
					    (long long)want,		\
					    (long long)c[i]);		\
	}								\
	return 0;							\
}

/* Elementwise vector-by-scalar op; r is bound to the scalar operand. */
#define VSOP_TEST(name, ctype, intrin, rexpr, refexpr)			\
static int test_##name(uint32_t seed)					\
{									\
	const ctype *a = (const ctype *)buf_a;				\
	const ctype *c = (const ctype *)buf_c;				\
	const size_t n = sizeof(buf_a) / (sizeof(ctype));			\
	uint32_t state = seed;						\
	int32_t r;							\
	size_t i;							\
									\
	fill_inputs(seed);						\
	r = (int32_t)(rexpr);						\
	for (i = 0; i < HVX_NVEC; i++)					\
		buf_c[i] = intrin(buf_a[i], r);				\
									\
	for (i = 0; i < n; i++) {					\
		ctype x = a[i];						\
		ctype want = (refexpr);					\
									\
		if (c[i] != want)					\
			return hvx_mismatch(#name, seed, i,		\
					    (long long)want,		\
					    (long long)c[i]);		\
	}								\
	(void)state;							\
	return 0;							\
}

/*
 * Integer arithmetic.  Hexagon's non-saturating adds and subtracts wrap, so
 * the references are written in unsigned arithmetic to keep the wraparound
 * defined rather than relying on signed overflow.
 */
BINOP_TEST(vadd_b, int8_t,   Q6_Vb_vadd_VbVb,
	   (int8_t)((uint8_t)x + (uint8_t)y))
BINOP_TEST(vadd_h, int16_t,  Q6_Vh_vadd_VhVh,
	   (int16_t)((uint16_t)x + (uint16_t)y))
BINOP_TEST(vadd_w, int32_t,  Q6_Vw_vadd_VwVw,
	   (int32_t)((uint32_t)x + (uint32_t)y))
BINOP_TEST(vsub_b, int8_t,   Q6_Vb_vsub_VbVb,
	   (int8_t)((uint8_t)x - (uint8_t)y))
BINOP_TEST(vsub_h, int16_t,  Q6_Vh_vsub_VhVh,
	   (int16_t)((uint16_t)x - (uint16_t)y))
BINOP_TEST(vsub_w, int32_t,  Q6_Vw_vsub_VwVw,
	   (int32_t)((uint32_t)x - (uint32_t)y))
BINOP_TEST(vmpyi_h, int16_t, Q6_Vh_vmpyi_VhVh,
	   (int16_t)((uint16_t)x * (uint16_t)y))

/* vavg/vnavg truncate rather than round; vavgr is the rounding form. */
BINOP_TEST(vavg_h, int16_t,  Q6_Vh_vavg_VhVh,
	   (int16_t)(((int32_t)x + (int32_t)y) >> 1))
BINOP_TEST(vnavg_h, int16_t, Q6_Vh_vnavg_VhVh,
	   (int16_t)(((int32_t)x - (int32_t)y) >> 1))

BINOP_TEST(vabsdiff_ub, uint8_t, Q6_Vub_vabsdiff_VubVub,
	   (uint8_t)(x > y ? x - y : y - x))
BINOP_TEST(vmax_w, int32_t,  Q6_Vw_vmax_VwVw, (x > y ? x : y))
BINOP_TEST(vmin_w, int32_t,  Q6_Vw_vmin_VwVw, (x < y ? x : y))
BINOP_TEST(vmax_h, int16_t,  Q6_Vh_vmax_VhVh, (x > y ? x : y))
BINOP_TEST(vmax_ub, uint8_t, Q6_Vub_vmax_VubVub, (x > y ? x : y))

/* Bitwise ops are lane-width agnostic; view them as words. */
BINOP_TEST(vand, uint32_t, Q6_V_vand_VV, (x & y))
BINOP_TEST(vor,  uint32_t, Q6_V_vor_VV,  (x | y))
BINOP_TEST(vxor, uint32_t, Q6_V_vxor_VV, (x ^ y))

UNOP_TEST(vnot, uint32_t, Q6_V_vnot_V, (uint32_t)~x)
/* vabs without :sat wraps at INT32_MIN, so negate in unsigned arithmetic. */
UNOP_TEST(vabs_w, int32_t, Q6_Vw_vabs_Vw,
	  (int32_t)(x < 0 ? 0u - (uint32_t)x : (uint32_t)x))

/* Shift amounts come from the low five bits of the scalar register. */
VSOP_TEST(vasl_w, int32_t, Q6_Vw_vasl_VwR, hvx_rand(&state) & 31,
	  (int32_t)((uint32_t)x << (r & 31)))
VSOP_TEST(vasr_w, int32_t, Q6_Vw_vasr_VwR, hvx_rand(&state) & 31,
	  (int32_t)(x >> (r & 31)))

/*
 * vrmpy: each 32-bit lane is the sum of the four unsigned byte products in
 * the corresponding byte positions.
 */
static int test_vrmpy_ubub(uint32_t seed)
{
	const uint8_t *a = (const uint8_t *)buf_a;
	const uint8_t *b = (const uint8_t *)buf_b;
	const uint32_t *c = (const uint32_t *)buf_c;
	const size_t words = sizeof(buf_a) / (sizeof(uint32_t));
	size_t i;

	fill_inputs(seed);
	for (i = 0; i < HVX_NVEC; i++)
		buf_c[i] = Q6_Vuw_vrmpy_VubVub(buf_a[i], buf_b[i]);

	for (i = 0; i < words; i++) {
		uint32_t want = 0;
		unsigned int j;

		for (j = 0; j < 4; j++)
			want += (uint32_t)a[4 * i + j] * (uint32_t)b[4 * i + j];

		if (c[i] != want)
			return hvx_mismatch("vrmpy_ubub", seed, i, want, c[i]);
	}
	return 0;
}

/*
 * Predicate generation and select: vmux(vcmp.gt(a, b), a, b) is a signed max,
 * which gives an independent cross-check of the predicate path against
 * vmax.w.
 */
static int test_vcmp_gt_vmux_w(uint32_t seed)
{
	const int32_t *a = (const int32_t *)buf_a;
	const int32_t *b = (const int32_t *)buf_b;
	const int32_t *c = (const int32_t *)buf_c;
	const size_t words = sizeof(buf_a) / (sizeof(int32_t));
	size_t i;

	fill_inputs(seed);
	for (i = 0; i < HVX_NVEC; i++) {
		HVX_VectorPred q = Q6_Q_vcmp_gt_VwVw(buf_a[i], buf_b[i]);

		buf_c[i] = Q6_V_vmux_QVV(q, buf_a[i], buf_b[i]);
	}

	for (i = 0; i < words; i++) {
		int32_t want = a[i] > b[i] ? a[i] : b[i];

		if (c[i] != want)
			return hvx_mismatch("vcmp_gt_vmux_w", seed, i, want,
					    c[i]);
	}
	return 0;
}

/*
 * vsetq builds a predicate true for the first Rt bytes of the vector, so
 * selecting with it splices a at the front of b at a known byte offset.
 */
static int test_vsetq_vmux(uint32_t seed)
{
	const uint8_t *a = (const uint8_t *)buf_a;
	const uint8_t *b = (const uint8_t *)buf_b;
	const uint8_t *c = (const uint8_t *)buf_c;
	uint32_t state = seed;
	size_t i;
	int32_t r;

	fill_inputs(seed);
	r = (int32_t)(hvx_rand(&state) % (HVX_VLEN + 1));

	for (i = 0; i < HVX_NVEC; i++) {
		HVX_VectorPred q = Q6_Q_vsetq_R(r);

		buf_c[i] = Q6_V_vmux_QVV(q, buf_a[i], buf_b[i]);
	}

	for (i = 0; i < sizeof(buf_a); i++) {
		size_t lane = i % HVX_VLEN;
		uint8_t want = lane < (size_t)r ? a[i] : b[i];

		if (c[i] != want)
			return hvx_mismatch("vsetq_vmux", seed, i, want, c[i]);
	}
	return 0;
}

/*
 * vror rotates by a byte count; rotating by r and then by VLEN - r must be
 * the identity.  Stating it as a round trip avoids depending on the rotation
 * direction, while still failing if any byte is dropped or duplicated.
 */
static int test_vror_roundtrip(uint32_t seed)
{
	uint32_t state = seed;
	int32_t r;
	size_t i;

	fill_inputs(seed);
	r = (int32_t)(1 + hvx_rand(&state) % (HVX_VLEN - 1));

	for (i = 0; i < HVX_NVEC; i++) {
		HVX_Vector rotated = Q6_V_vror_VR(buf_a[i], r);

		buf_c[i] = Q6_V_vror_VR(rotated, HVX_VLEN - r);
	}

	return hvx_memcmp("vror_roundtrip", seed, buf_a, buf_c, sizeof(buf_a));
}

/*
 * A zero control selects each byte from its own position, so vdelta and
 * vrdelta with a zero control are both the identity.  This exercises the
 * permute network without restating its lane map.
 */
static int test_vdelta_identity(uint32_t seed)
{
	const HVX_Vector zero = Q6_V_vzero();
	size_t i;

	fill_inputs(seed);
	for (i = 0; i < HVX_NVEC; i++)
		buf_c[i] = Q6_V_vdelta_VV(buf_a[i], zero);

	if (hvx_memcmp("vdelta_identity", seed, buf_a, buf_c, sizeof(buf_a)))
		return 1;

	for (i = 0; i < HVX_NVEC; i++)
		buf_c[i] = Q6_V_vrdelta_VV(buf_a[i], zero);

	return hvx_memcmp("vrdelta_identity", seed, buf_a, buf_c,
			  sizeof(buf_a));
}

/*
 * Unaligned vector load/store round trip.  Copying through a byte-offset
 * pointer exercises the unaligned vector memory path, which has to assemble
 * each result from two aligned accesses.
 */
static int test_vmemu_roundtrip(uint32_t seed)
{
	/* Two extra vectors of slack for the shifted window. */
	static uint8_t scratch[(HVX_NVEC + 2) * HVX_VLEN] HVX_ALIGNED;
	uint32_t state = seed;
	size_t offset;
	size_t i;

	fill_inputs(seed);
	memset(scratch, 0, sizeof(scratch));
	offset = 1 + hvx_rand(&state) % (HVX_VLEN - 1);

	for (i = 0; i < HVX_NVEC; i++) {
		HVX_UVector *dst =
			(HVX_UVector *)(scratch + offset + i * HVX_VLEN);

		*dst = buf_a[i];
	}
	for (i = 0; i < HVX_NVEC; i++) {
		const HVX_UVector *src =
			(const HVX_UVector *)(scratch + offset + i * HVX_VLEN);

		buf_c[i] = *src;
	}

	return hvx_memcmp("vmemu_roundtrip", seed, buf_a, buf_c,
			  sizeof(buf_a));
}

#if __HEXAGON_ARCH__ >= 68
/*
 * Floating point.  Inputs are built as finite values in a moderate range
 * rather than random bit patterns, so the references do not have to reason
 * about NaN and infinity propagation.
 */
static void fill_floats(uint32_t seed)
{
	float *a = (float *)buf_a;
	float *b = (float *)buf_b;
	const size_t n = sizeof(buf_a) / (sizeof(float));
	uint32_t state = seed ? seed : 1u;
	size_t i;

	for (i = 0; i < n; i++) {
		a[i] = (float)((int32_t)(hvx_rand(&state) % 20001) - 10000) /
		       100.0f;
		b[i] = (float)((int32_t)(hvx_rand(&state) % 20001) - 10000) /
		       100.0f;
	}
	memset(buf_c, 0, sizeof(buf_c));
}

#ifdef __HVX_IEEE_FP__
/* IEEE single-precision add is exactly specified, so compare bit-exactly. */
static int test_vadd_sf(uint32_t seed)
{
	const float *a = (const float *)buf_a;
	const float *b = (const float *)buf_b;
	const float *c = (const float *)buf_c;
	const size_t n = sizeof(buf_a) / (sizeof(float));
	size_t i;

	fill_floats(seed);
	for (i = 0; i < HVX_NVEC; i++)
		buf_c[i] = Q6_Vsf_vadd_VsfVsf(buf_a[i], buf_b[i]);

	for (i = 0; i < n; i++) {
		float want = a[i] + b[i];

		if (c[i] != want)
			return hvx_mismatch("vadd_sf", seed, i,
					    (long long)(want * 100.0f),
					    (long long)(c[i] * 100.0f));
	}
	return 0;
}

static int test_vmpy_sf(uint32_t seed)
{
	const float *a = (const float *)buf_a;
	const float *b = (const float *)buf_b;
	const float *c = (const float *)buf_c;
	const size_t n = sizeof(buf_a) / (sizeof(float));
	size_t i;

	fill_floats(seed);
	for (i = 0; i < HVX_NVEC; i++)
		buf_c[i] = Q6_Vsf_vmpy_VsfVsf(buf_a[i], buf_b[i]);

	for (i = 0; i < n; i++) {
		float want = a[i] * b[i];

		if (c[i] != want)
			return hvx_mismatch("vmpy_sf", seed, i,
					    (long long)(want * 100.0f),
					    (long long)(c[i] * 100.0f));
	}
	return 0;
}
#endif /* __HVX_IEEE_FP__ */

/*
 * qf32 is a Qualcomm-specific intermediate format whose rounding differs
 * slightly from IEEE, so this one is checked against a relative tolerance
 * rather than bit-exactly.
 */
static int test_vadd_qf32(uint32_t seed)
{
	const float *a = (const float *)buf_a;
	const float *b = (const float *)buf_b;
	const float *c = (const float *)buf_c;
	const size_t n = sizeof(buf_a) / (sizeof(float));
	size_t i;

	fill_floats(seed);
	for (i = 0; i < HVX_NVEC; i++) {
		HVX_Vector q = Q6_Vqf32_vadd_VsfVsf(buf_a[i], buf_b[i]);

		buf_c[i] = Q6_Vsf_equals_Vqf32(q);
	}

	for (i = 0; i < n; i++) {
		float want = a[i] + b[i];
		float got = c[i];
		float diff = want > got ? want - got : got - want;
		float scale = want < 0.0f ? -want : want;

		if (scale < 1.0f)
			scale = 1.0f;
		if (diff / scale > 1.0e-5f)
			return hvx_mismatch("vadd_qf32", seed, i,
					    (long long)(want * 1000.0f),
					    (long long)(got * 1000.0f));
	}
	return 0;
}
#endif /* __HEXAGON_ARCH__ >= 68 */

const struct hvx_test hvx_tests[] = {
	{ "vadd_b",		test_vadd_b },
	{ "vadd_h",		test_vadd_h },
	{ "vadd_w",		test_vadd_w },
	{ "vsub_b",		test_vsub_b },
	{ "vsub_h",		test_vsub_h },
	{ "vsub_w",		test_vsub_w },
	{ "vmpyi_h",		test_vmpyi_h },
	{ "vavg_h",		test_vavg_h },
	{ "vnavg_h",		test_vnavg_h },
	{ "vabsdiff_ub",	test_vabsdiff_ub },
	{ "vmax_w",		test_vmax_w },
	{ "vmin_w",		test_vmin_w },
	{ "vmax_h",		test_vmax_h },
	{ "vmax_ub",		test_vmax_ub },
	{ "vand",		test_vand },
	{ "vor",		test_vor },
	{ "vxor",		test_vxor },
	{ "vnot",		test_vnot },
	{ "vabs_w",		test_vabs_w },
	{ "vasl_w",		test_vasl_w },
	{ "vasr_w",		test_vasr_w },
	{ "vrmpy_ubub",		test_vrmpy_ubub },
	{ "vcmp_gt_vmux_w",	test_vcmp_gt_vmux_w },
	{ "vsetq_vmux",		test_vsetq_vmux },
	{ "vror_roundtrip",	test_vror_roundtrip },
	{ "vdelta_identity",	test_vdelta_identity },
	{ "vmemu_roundtrip",	test_vmemu_roundtrip },
#if __HEXAGON_ARCH__ >= 68
#ifdef __HVX_IEEE_FP__
	{ "vadd_sf",		test_vadd_sf },
	{ "vmpy_sf",		test_vmpy_sf },
#endif
	{ "vadd_qf32",		test_vadd_qf32 },
#endif
};

const unsigned int hvx_test_count =
	sizeof(hvx_tests) / sizeof(hvx_tests[0]);

int main(int argc, char **argv)
{
	return hvx_test_main(argc, argv);
}
