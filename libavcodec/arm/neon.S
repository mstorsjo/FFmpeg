/*
 * Copyright (c) 2008 Mans Rullgard <mans@mansr.com>
 *
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

.macro  transpose_8x8   r0, r1, r2, r3, r4, r5, r6, r7
        vtrn.32         \r0, \r4
        vtrn.32         \r1, \r5
        vtrn.32         \r2, \r6
        vtrn.32         \r3, \r7
        vtrn.16         \r0, \r2
        vtrn.16         \r1, \r3
        vtrn.16         \r4, \r6
        vtrn.16         \r5, \r7
        vtrn.8          \r0, \r1
        vtrn.8          \r2, \r3
        vtrn.8          \r4, \r5
        vtrn.8          \r6, \r7
.endm

.macro  transpose_4x4   r0, r1, r2, r3
        vtrn.16         \r0, \r2
        vtrn.16         \r1, \r3
        vtrn.8          \r0, \r1
        vtrn.8          \r2, \r3
.endm

.macro  swap4           r0, r1, r2, r3, r4, r5, r6, r7
        vswp            \r0, \r4
        vswp            \r1, \r5
        vswp            \r2, \r6
        vswp            \r3, \r7
.endm

.macro  transpose16_4x4 r0, r1, r2, r3, r4, r5, r6, r7
        vtrn.32         \r0, \r2
        vtrn.32         \r1, \r3
        vtrn.32         \r4, \r6
        vtrn.32         \r5, \r7
        vtrn.16         \r0, \r1
        vtrn.16         \r2, \r3
        vtrn.16         \r4, \r5
        vtrn.16         \r6, \r7
.endm

.macro call_c func, line, msg, first, last, ptr, offset
        push            {lr}
        mov             lr,  sp
        push            {lr}
        push            {r0-r12}
        mrs             lr,  cpsr
        push            {lr}
        vpush           {d16-d31}
        vpush           {d0-d15}
        add             r0,  \ptr, #\offset
        push            {r0}
        ldr             r0,  =\line
        adr             r1,  777f
        mov             r2,  \first
        mov             r3,  \last
        bl              X(ff_\func)
        pop             {r0}
        vpop            {d0-d15}
        vpop            {d16-d31}
        pop             {lr}
        msr             cpsr, lr
        pop             {r0-r12}
        add             sp,  sp,  #4
        pop             {lr}
.endm

#define CALL_C(func, msg, first, last, ptr, offset) \
        call_c func, __LINE__, msg, first, last, ptr, offset; \
        b 778f; \
    777: \
        .asciz msg; \
        .align 2; \
        .ltorg; \
    778:

#define DUMP_SIMD_S8(msg, first, last)  CALL_C(dump_simd_s8,  msg, first, last, sp, 0)
#define DUMP_SIMD_U8(msg, first, last)  CALL_C(dump_simd_u8,  msg, first, last, sp, 0)
#define DUMP_SIMD_S16(msg, first, last) CALL_C(dump_simd_s16, msg, first, last, sp, 0)
#define DUMP_SIMD_U16(msg, first, last) CALL_C(dump_simd_u16, msg, first, last, sp, 0)
#define DUMP_SIMD_S32(msg, first, last) CALL_C(dump_simd_s32, msg, first, last, sp, 0)
#define DUMP_MEM_S16(msg, reg, n)       CALL_C(dump_simd_s16, msg, 0, n-1, reg, 0)
#define DUMP_GPR(msg, first, last)      CALL_C(dump_gpr,      msg, first, last, sp, 260)
