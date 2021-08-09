/*
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

.macro  transpose_8x8B  r0, r1, r2, r3, r4, r5, r6, r7, r8, r9
        trn1            \r8\().8B,  \r0\().8B,  \r1\().8B
        trn2            \r9\().8B,  \r0\().8B,  \r1\().8B
        trn1            \r1\().8B,  \r2\().8B,  \r3\().8B
        trn2            \r3\().8B,  \r2\().8B,  \r3\().8B
        trn1            \r0\().8B,  \r4\().8B,  \r5\().8B
        trn2            \r5\().8B,  \r4\().8B,  \r5\().8B
        trn1            \r2\().8B,  \r6\().8B,  \r7\().8B
        trn2            \r7\().8B,  \r6\().8B,  \r7\().8B

        trn1            \r4\().4H,  \r0\().4H,  \r2\().4H
        trn2            \r2\().4H,  \r0\().4H,  \r2\().4H
        trn1            \r6\().4H,  \r5\().4H,  \r7\().4H
        trn2            \r7\().4H,  \r5\().4H,  \r7\().4H
        trn1            \r5\().4H,  \r9\().4H,  \r3\().4H
        trn2            \r9\().4H,  \r9\().4H,  \r3\().4H
        trn1            \r3\().4H,  \r8\().4H,  \r1\().4H
        trn2            \r8\().4H,  \r8\().4H,  \r1\().4H

        trn1            \r0\().2S,  \r3\().2S,  \r4\().2S
        trn2            \r4\().2S,  \r3\().2S,  \r4\().2S

        trn1            \r1\().2S,  \r5\().2S,  \r6\().2S
        trn2            \r5\().2S,  \r5\().2S,  \r6\().2S

        trn2            \r6\().2S,  \r8\().2S,  \r2\().2S
        trn1            \r2\().2S,  \r8\().2S,  \r2\().2S

        trn1            \r3\().2S,  \r9\().2S,  \r7\().2S
        trn2            \r7\().2S,  \r9\().2S,  \r7\().2S
.endm

.macro  transpose_8x16B r0, r1, r2, r3, r4, r5, r6, r7, t0, t1
        trn1            \t0\().16B, \r0\().16B, \r1\().16B
        trn2            \t1\().16B, \r0\().16B, \r1\().16B
        trn1            \r1\().16B, \r2\().16B, \r3\().16B
        trn2            \r3\().16B, \r2\().16B, \r3\().16B
        trn1            \r0\().16B, \r4\().16B, \r5\().16B
        trn2            \r5\().16B, \r4\().16B, \r5\().16B
        trn1            \r2\().16B, \r6\().16B, \r7\().16B
        trn2            \r7\().16B, \r6\().16B, \r7\().16B

        trn1            \r4\().8H,  \r0\().8H,  \r2\().8H
        trn2            \r2\().8H,  \r0\().8H,  \r2\().8H
        trn1            \r6\().8H,  \r5\().8H,  \r7\().8H
        trn2            \r7\().8H,  \r5\().8H,  \r7\().8H
        trn1            \r5\().8H,  \t1\().8H,  \r3\().8H
        trn2            \t1\().8H,  \t1\().8H,  \r3\().8H
        trn1            \r3\().8H,  \t0\().8H,  \r1\().8H
        trn2            \t0\().8H,  \t0\().8H,  \r1\().8H

        trn1            \r0\().4S,  \r3\().4S,  \r4\().4S
        trn2            \r4\().4S,  \r3\().4S,  \r4\().4S

        trn1            \r1\().4S,  \r5\().4S,  \r6\().4S
        trn2            \r5\().4S,  \r5\().4S,  \r6\().4S

        trn2            \r6\().4S,  \t0\().4S,  \r2\().4S
        trn1            \r2\().4S,  \t0\().4S,  \r2\().4S

        trn1            \r3\().4S,  \t1\().4S,  \r7\().4S
        trn2            \r7\().4S,  \t1\().4S,  \r7\().4S
.endm

.macro  transpose_4x16B r0, r1, r2, r3, t4, t5, t6, t7
        trn1            \t4\().16B, \r0\().16B,  \r1\().16B
        trn2            \t5\().16B, \r0\().16B,  \r1\().16B
        trn1            \t6\().16B, \r2\().16B,  \r3\().16B
        trn2            \t7\().16B, \r2\().16B,  \r3\().16B

        trn1            \r0\().8H,  \t4\().8H,  \t6\().8H
        trn2            \r2\().8H,  \t4\().8H,  \t6\().8H
        trn1            \r1\().8H,  \t5\().8H,  \t7\().8H
        trn2            \r3\().8H,  \t5\().8H,  \t7\().8H
.endm

.macro  transpose_4x8B  r0, r1, r2, r3, t4, t5, t6, t7
        trn1            \t4\().8B,  \r0\().8B,  \r1\().8B
        trn2            \t5\().8B,  \r0\().8B,  \r1\().8B
        trn1            \t6\().8B,  \r2\().8B,  \r3\().8B
        trn2            \t7\().8B,  \r2\().8B,  \r3\().8B

        trn1            \r0\().4H,  \t4\().4H,  \t6\().4H
        trn2            \r2\().4H,  \t4\().4H,  \t6\().4H
        trn1            \r1\().4H,  \t5\().4H,  \t7\().4H
        trn2            \r3\().4H,  \t5\().4H,  \t7\().4H
.endm

.macro  transpose_4x4H  r0, r1, r2, r3, r4, r5, r6, r7
        trn1            \r4\().4H,  \r0\().4H,  \r1\().4H
        trn2            \r5\().4H,  \r0\().4H,  \r1\().4H
        trn1            \r6\().4H,  \r2\().4H,  \r3\().4H
        trn2            \r7\().4H,  \r2\().4H,  \r3\().4H
        trn1            \r0\().2S,  \r4\().2S,  \r6\().2S
        trn2            \r2\().2S,  \r4\().2S,  \r6\().2S
        trn1            \r1\().2S,  \r5\().2S,  \r7\().2S
        trn2            \r3\().2S,  \r5\().2S,  \r7\().2S
.endm

.macro  transpose_8x8H  r0, r1, r2, r3, r4, r5, r6, r7, r8, r9
        trn1            \r8\().8H,  \r0\().8H,  \r1\().8H
        trn2            \r9\().8H,  \r0\().8H,  \r1\().8H
        trn1            \r1\().8H,  \r2\().8H,  \r3\().8H
        trn2            \r3\().8H,  \r2\().8H,  \r3\().8H
        trn1            \r0\().8H,  \r4\().8H,  \r5\().8H
        trn2            \r5\().8H,  \r4\().8H,  \r5\().8H
        trn1            \r2\().8H,  \r6\().8H,  \r7\().8H
        trn2            \r7\().8H,  \r6\().8H,  \r7\().8H

        trn1            \r4\().4S,  \r0\().4S,  \r2\().4S
        trn2            \r2\().4S,  \r0\().4S,  \r2\().4S
        trn1            \r6\().4S,  \r5\().4S,  \r7\().4S
        trn2            \r7\().4S,  \r5\().4S,  \r7\().4S
        trn1            \r5\().4S,  \r9\().4S,  \r3\().4S
        trn2            \r9\().4S,  \r9\().4S,  \r3\().4S
        trn1            \r3\().4S,  \r8\().4S,  \r1\().4S
        trn2            \r8\().4S,  \r8\().4S,  \r1\().4S

        trn1            \r0\().2D,  \r3\().2D,  \r4\().2D
        trn2            \r4\().2D,  \r3\().2D,  \r4\().2D

        trn1            \r1\().2D,  \r5\().2D,  \r6\().2D
        trn2            \r5\().2D,  \r5\().2D,  \r6\().2D

        trn2            \r6\().2D,  \r8\().2D,  \r2\().2D
        trn1            \r2\().2D,  \r8\().2D,  \r2\().2D

        trn1            \r3\().2D,  \r9\().2D,  \r7\().2D
        trn2            \r7\().2D,  \r9\().2D,  \r7\().2D

.endm

#undef x18
.macro call_c func, line, msg, first, last, ptr, offset
        stp             x29, x30, [sp, #-16]!
        stp             x27, x28, [sp, #-16]!
        stp             x25, x26, [sp, #-16]!
        stp             x23, x24, [sp, #-16]!
        stp             x21, x22, [sp, #-16]!
        stp             x19, x20, [sp, #-16]!
        stp             x17, x18, [sp, #-16]!
        stp             x15, x16, [sp, #-16]!
        stp             x13, x14, [sp, #-16]!
        stp             x11, x12, [sp, #-16]!
        stp             x9,  x10, [sp, #-16]!
        stp             x7,  x8,  [sp, #-16]!
        stp             x5,  x6,  [sp, #-16]!
        stp             x3,  x4,  [sp, #-16]!
        stp             x1,  x2,  [sp, #-16]!
        mrs             x30, nzcv
        stp             x30, x0,  [sp, #-16]!

        stp             q30, q31, [sp, #-32]!
        stp             q28, q29, [sp, #-32]!
        stp             q26, q27, [sp, #-32]!
        stp             q24, q25, [sp, #-32]!
        stp             q22, q23, [sp, #-32]!
        stp             q20, q21, [sp, #-32]!
        stp             q18, q19, [sp, #-32]!
        stp             q16, q17, [sp, #-32]!
        stp             q14, q15, [sp, #-32]!
        stp             q12, q13, [sp, #-32]!
        stp             q10, q11, [sp, #-32]!
        stp             q8,  q9,  [sp, #-32]!
        stp             q6,  q7,  [sp, #-32]!
        stp             q4,  q5,  [sp, #-32]!
        stp             q2,  q3,  [sp, #-32]!
        stp             q0,  q1,  [sp, #-32]!

        add             x4,  \ptr, #\offset
        ldr             x0,  =\line
        adr             x1,  777f
        mov             x2,  \first
        mov             x3,  \last
        bl              X(ff_\func)

        ldp             q0,  q1,  [sp], #32
        ldp             q2,  q3,  [sp], #32
        ldp             q4,  q5,  [sp], #32
        ldp             q6,  q7,  [sp], #32
        ldp             q8,  q9,  [sp], #32
        ldp             q10, q11, [sp], #32
        ldp             q12, q13, [sp], #32
        ldp             q14, q15, [sp], #32
        ldp             q16, q17, [sp], #32
        ldp             q18, q19, [sp], #32
        ldp             q20, q21, [sp], #32
        ldp             q22, q23, [sp], #32
        ldp             q24, q25, [sp], #32
        ldp             q26, q27, [sp], #32
        ldp             q28, q29, [sp], #32
        ldp             q30, q31, [sp], #32

        ldp             x30, x0,  [sp], #16
        msr             nzcv, x30
        ldp             x1,  x2,  [sp], #16
        ldp             x3,  x4,  [sp], #16
        ldp             x5,  x6,  [sp], #16
        ldp             x7,  x8,  [sp], #16
        ldp             x9,  x10, [sp], #16
        ldp             x11, x12, [sp], #16
        ldp             x13, x14, [sp], #16
        ldp             x15, x16, [sp], #16
        ldp             x17, x18, [sp], #16
        ldp             x19, x20, [sp], #16
        ldp             x21, x22, [sp], #16
        ldp             x23, x24, [sp], #16
        ldp             x25, x26, [sp], #16
        ldp             x27, x28, [sp], #16
        ldp             x29, x30, [sp], #16
.endm

#define CALL_C(func, msg, first, last, ptr, offset) \
        call_c func, __LINE__, msg, first, last, ptr, offset; \
        b 778f; \
    777: \
        .asciz msg; \
        .align 2; \
    778:

#define DUMP_SIMD_S8(msg, first, last)  CALL_C(dump_simd_s8,  msg, first, last, sp, 0)
#define DUMP_SIMD_U8(msg, first, last)  CALL_C(dump_simd_u8,  msg, first, last, sp, 0)
#define DUMP_SIMD_S16(msg, first, last) CALL_C(dump_simd_s16, msg, first, last, sp, 0)
#define DUMP_SIMD_U16(msg, first, last) CALL_C(dump_simd_u16, msg, first, last, sp, 0)
#define DUMP_SIMD_S32(msg, first, last) CALL_C(dump_simd_s32, msg, first, last, sp, 0)
#define DUMP_MEM_S16(msg, reg, n)       CALL_C(dump_simd_s16, msg, 0, n-1, reg, 0)
#define DUMP_GPR(msg, first, last)      CALL_C(dump_gpr,      msg, first, last, sp, 520)
