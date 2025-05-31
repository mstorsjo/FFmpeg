/*
 * Copyright (c) 2024 Zhao Zhili <quinkblack@foxmail.com>
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

#include "libavutil/aarch64/asm.S"

.macro rgb_to_yuv_load_rgb src, element=3
    .if \element == 3
        ld3             { v16.16b, v17.16b, v18.16b }, [\src], #48
    .else
        ld4             { v16.16b, v17.16b, v18.16b, v19.16b }, [\src], #64
    .endif
        uxtl            v19.8h, v16.8b             // v19: r
        uxtl            v20.8h, v17.8b             // v20: g
        uxtl            v21.8h, v18.8b             // v21: b
        uxtl2           v22.8h, v16.16b            // v22: r
        uxtl2           v23.8h, v17.16b            // v23: g
        uxtl2           v24.8h, v18.16b            // v24: b
.endm

.macro argb_to_yuv_load_rgb src
        ld4             { v16.16b, v17.16b, v18.16b, v19.16b }, [\src], #64
        uxtl            v21.8h, v19.8b             // v21: b
        uxtl2           v24.8h, v19.16b            // v24: b
        uxtl            v19.8h, v17.8b             // v19: r
        uxtl            v20.8h, v18.8b             // v20: g
        uxtl2           v22.8h, v17.16b            // v22: r
        uxtl2           v23.8h, v18.16b            // v23: g
.endm

.macro rgb_to_yuv_product r, g, b, dst1, dst2, dst, coef0, coef1, coef2, right_shift
        mov             \dst1\().16b, v6.16b                    // dst1 = const_offset
        mov             \dst2\().16b, v6.16b                    // dst2 = const_offset
        smlal           \dst1\().4s, \coef0\().4h, \r\().4h     // dst1 += rx * r
        smlal           \dst1\().4s, \coef1\().4h, \g\().4h     // dst1 += gx * g
        smlal           \dst1\().4s, \coef2\().4h, \b\().4h     // dst1 += bx * b
        smlal2          \dst2\().4s, \coef0\().8h, \r\().8h     // dst2 += rx * r
        smlal2          \dst2\().4s, \coef1\().8h, \g\().8h     // dst2 += gx * g
        smlal2          \dst2\().4s, \coef2\().8h, \b\().8h     // dst2 += bx * b
        sqshrn          \dst\().4h, \dst1\().4s, \right_shift   // dst_lower_half = dst1 >> right_shift
        sqshrn2         \dst\().8h, \dst2\().4s, \right_shift   // dst_higher_half = dst2 >> right_shift
.endm

// interleaved product version of the rgb to yuv gives slightly better performance on non-performant mobile cores
.macro rgb_to_uv_interleaved_product r, g, b, u_coef0, u_coef1, u_coef2, v_coef0, v_coef1, v_coef2, u_dst1, u_dst2, v_dst1, v_dst2, u_dst, v_dst, right_shift
        smlal           \u_dst1\().4s, \u_coef0\().4h, \r\().4h     // U += ru * r (first 4)
        smlal           \v_dst1\().4s, \v_coef0\().4h, \r\().4h     // V += rv * r (first 4)
        smlal2          \u_dst2\().4s, \u_coef0\().8h, \r\().8h     // U += ru * r (second 4)
        smlal2          \v_dst2\().4s, \v_coef0\().8h, \r\().8h     // V += rv * r (second 4)

        smlal           \u_dst1\().4s, \u_coef1\().4h, \g\().4h     // U += gu * g (first 4)
        smlal           \v_dst1\().4s, \v_coef1\().4h, \g\().4h     // V += gv * g (first 4)
        smlal2          \u_dst2\().4s, \u_coef1\().8h, \g\().8h     // U += gu * g (second 4)
        smlal2          \v_dst2\().4s, \v_coef1\().8h, \g\().8h     // V += gv * g (second 4)

        smlal           \u_dst1\().4s, \u_coef2\().4h, \b\().4h     // U += bu * b (first 4)
        smlal           \v_dst1\().4s, \v_coef2\().4h, \b\().4h     // V += bv * b (first 4)
        smlal2          \u_dst2\().4s, \u_coef2\().8h, \b\().8h     // U += bu * b (second 4)
        smlal2          \v_dst2\().4s, \v_coef2\().8h, \b\().8h     // V += bv * b (second 4)

        sqshrn          \u_dst\().4h, \u_dst1\().4s, \right_shift   // U first 4 pixels
        sqshrn2         \u_dst\().8h, \u_dst2\().4s, \right_shift   // U all 8 pixels
        sqshrn          \v_dst\().4h, \v_dst1\().4s, \right_shift   // V first 4 pixels
        sqshrn2         \v_dst\().8h, \v_dst2\().4s, \right_shift   // V all 8 pixels
.endm

.macro rgbToY_neon fmt_bgr, fmt_rgb, element, alpha_first=0
function ff_\fmt_bgr\()ToY_neon, export=1
        cbz             w4, 3f                  // check width > 0
        ldp             w12, w11, [x5]          // w12: ry, w11: gy
        ldr             w10, [x5, #8]           // w10: by
        b               4f
endfunc

function ff_\fmt_rgb\()ToY_neon, export=1
        cbz             w4, 3f                  // check width > 0
        ldp             w10, w11, [x5]          // w10: ry, w11: gy
        ldr             w12, [x5, #8]           // w12: by
4:
        mov             w9, #256                // w9 = 1 << (RGB2YUV_SHIFT - 7)
        movk            w9, #8, lsl #16         // w9 += 32 << (RGB2YUV_SHIFT - 1)
        dup             v6.4s, w9               // w9: const_offset

        cmp             w4, #16
        dup             v0.8h, w10
        dup             v1.8h, w11
        dup             v2.8h, w12
        b.lt            2f
1:
    .if \alpha_first
        argb_to_yuv_load_rgb x1
    .else
        rgb_to_yuv_load_rgb x1, \element
    .endif
        rgb_to_yuv_product v19, v20, v21, v25, v26, v16, v0, v1, v2, #9
        rgb_to_yuv_product v22, v23, v24, v27, v28, v17, v0, v1, v2, #9
        sub             w4, w4, #16             // width -= 16
        cmp             w4, #16                 // width >= 16 ?
        stp             q16, q17, [x0], #32     // store to dst
        b.ge            1b
        cbz             x4, 3f
2:
    .if \alpha_first
        ldrb            w13, [x1, #1]           // w13: r
        ldrb            w14, [x1, #2]           // w14: g
        ldrb            w15, [x1, #3]           // w15: b
    .else
        ldrb            w13, [x1]               // w13: r
        ldrb            w14, [x1, #1]           // w14: g
        ldrb            w15, [x1, #2]           // w15: b
    .endif

        smaddl          x13, w13, w10, x9       // x13 = ry * r + const_offset
        smaddl          x13, w14, w11, x13      // x13 += gy * g
        smaddl          x13, w15, w12, x13      // x13 += by * b
        asr             w13, w13, #9            // x13 >>= 9
        sub             w4, w4, #1              // width--
        add             x1, x1, #\element
        strh            w13, [x0], #2           // store to dst
        cbnz            w4, 2b
3:
        ret
endfunc
.endm

rgbToY_neon bgr24, rgb24, element=3

rgbToY_neon bgra32, rgba32, element=4

rgbToY_neon abgr32, argb32, element=4, alpha_first=1

.macro rgb_set_uv_coeff half
    .if \half
        mov             w9, #512
        movk            w9, #128, lsl #16       // w9: const_offset
    .else
        mov             w9, #256
        movk            w9, #64, lsl #16        // w9: const_offset
    .endif
        dup             v0.8h, w10
        dup             v1.8h, w11
        dup             v2.8h, w12
        dup             v3.8h, w13
        dup             v4.8h, w14
        dup             v5.8h, w15
        dup             v6.4s, w9
.endm

.macro rgb_load_add_half off_r1, off_r2, off_g1, off_g2, off_b1, off_b2
        ldrb            w2, [x3, #\off_r1]     // w2: r1
        ldrb            w4, [x3, #\off_r2]     // w4: r2
        add             w2, w2, w4             // w2 = r1 + r2

        ldrb            w4, [x3, #\off_g1]     // w4: g1
        ldrb            w7, [x3, #\off_g2]     // w7: g2
        add             w4, w4, w7             // w4 = g1 + g2

        ldrb            w7, [x3, #\off_b1]     // w7: b1
        ldrb            w8, [x3, #\off_b2]     // w8: b2
        add             w7, w7, w8             // w7 = b1 + b2
.endm

.macro rgbToUV_half_neon fmt_bgr, fmt_rgb, element, alpha_first=0
function ff_\fmt_bgr\()ToUV_half_neon, export=1
        cbz             w5, 3f

        ldp             w12, w11, [x6, #12]
        ldp             w10, w15, [x6, #20]
        ldp             w14, w13, [x6, #28]
        b               4f
endfunc

function ff_\fmt_rgb\()ToUV_half_neon, export=1
        cmp             w5, #0
        b.le            3f

        ldp             w10, w11, [x6, #12]
        ldp             w12, w13, [x6, #20]
        ldp             w14, w15, [x6, #28]
4:
        rgb_set_uv_coeff half=1

        cmp             w5, #16
        b.lt            2f

1:
    .if \element == 3
        ld3             { v16.16b, v17.16b, v18.16b }, [x3], #48
        ld3             { v26.16b, v27.16b, v28.16b }, [x3], #48
    .else
        ld4             { v16.16b, v17.16b, v18.16b, v19.16b }, [x3], #64
        ld4             { v26.16b, v27.16b, v28.16b, v29.16b }, [x3], #64
    .endif

    .if \alpha_first
        uaddlp          v21.8h, v19.16b
        uaddlp          v20.8h, v18.16b
        uaddlp          v19.8h, v17.16b
        uaddlp          v31.8h, v29.16b
        uaddlp          v30.8h, v28.16b
        uaddlp          v29.8h, v27.16b
    .else
        uaddlp          v19.8h, v16.16b
        uaddlp          v20.8h, v17.16b
        uaddlp          v21.8h, v18.16b
        uaddlp          v29.8h, v26.16b
        uaddlp          v30.8h, v27.16b
        uaddlp          v31.8h, v28.16b
    .endif

        mov             v7.16b, v6.16b
        mov             v16.16b, v6.16b
        mov             v17.16b, v6.16b
        mov             v18.16b, v6.16b
        mov             v26.16b, v6.16b
        mov             v27.16b, v6.16b
        mov             v28.16b, v6.16b
        mov             v25.16b, v6.16b

        smlal           v7.4s, v0.4h, v19.4h
        smlal           v17.4s, v3.4h, v19.4h
        smlal           v26.4s, v0.4h, v29.4h
        smlal           v28.4s, v3.4h, v29.4h

        smlal2          v16.4s, v0.8h, v19.8h
        smlal2          v18.4s, v3.8h, v19.8h
        smlal2          v27.4s, v0.8h, v29.8h
        smlal2          v25.4s, v3.8h, v29.8h

        smlal           v7.4s, v1.4h, v20.4h
        smlal           v17.4s, v4.4h, v20.4h
        smlal           v26.4s, v1.4h, v30.4h
        smlal           v28.4s, v4.4h, v30.4h

        smlal2          v16.4s, v1.8h, v20.8h
        smlal2          v18.4s, v4.8h, v20.8h
        smlal2          v27.4s, v1.8h, v30.8h
        smlal2          v25.4s, v4.8h, v30.8h

        smlal           v7.4s, v2.4h, v21.4h
        smlal           v17.4s, v5.4h, v21.4h
        smlal           v26.4s, v2.4h, v31.4h
        smlal           v28.4s, v5.4h, v31.4h

        smlal2          v16.4s, v2.8h, v21.8h
        smlal2          v18.4s, v5.8h, v21.8h
        smlal2          v27.4s, v2.8h, v31.8h
        smlal2          v25.4s, v5.8h, v31.8h

        sqshrn          v19.4h, v7.4s, #10
        sqshrn          v20.4h, v17.4s, #10
        sqshrn          v22.4h, v26.4s, #10
        sqshrn          v23.4h, v28.4s, #10

        sqshrn2         v19.8h, v16.4s, #10
        sqshrn2         v20.8h, v18.4s, #10
        sqshrn2         v22.8h, v27.4s, #10
        sqshrn2         v23.8h, v25.4s, #10

        stp             q19, q22, [x0], #32
        stp             q20, q23, [x1], #32

        sub             w5, w5, #16
        cmp             w5, #16
        b.ge            1b
        cbz             w5, 3f

2:
.if \alpha_first
        rgb_load_add_half 1, 5, 2, 6, 3, 7
.else
    .if \element == 3
        rgb_load_add_half 0, 3, 1, 4, 2, 5
    .else
        rgb_load_add_half 0, 4, 1, 5, 2, 6
    .endif
.endif
        smaddl          x8, w2, w10, x9
        smaddl          x16, w2, w13, x9

        smaddl          x8, w4, w11, x8
        smaddl          x16, w4, w14, x16

        smaddl          x8, w7, w12, x8
        smaddl          x16, w7, w15, x16

        asr             w8, w8, #10
        asr             w16, w16, #10

        strh            w8, [x0], #2
        strh            w16, [x1], #2

        sub             w5, w5, #1
        add             x3, x3, #(2*\element)
        cbnz            w5, 2b
3:
        ret
endfunc
.endm

rgbToUV_half_neon bgr24, rgb24, element=3

rgbToUV_half_neon bgra32, rgba32, element=4

rgbToUV_half_neon abgr32, argb32, element=4, alpha_first=1

.macro rgbToUV_neon fmt_bgr, fmt_rgb, element, alpha_first=0
function ff_\fmt_bgr\()ToUV_neon, export=1
        cmp             w5, #0                  // check width > 0
        b.le            3f

        ldp             w12, w11, [x6, #12]     // bu, gu
        ldp             w10, w15, [x6, #20]     // ru, bv
        ldp             w14, w13, [x6, #28]     // gv, rv
        b               4f
endfunc

function ff_\fmt_rgb\()ToUV_neon, export=1
        cmp             w5, #0                  // check width > 0
        b.le            3f

        ldp             w10, w11, [x6, #12]     // w10: ru, w11: gu
        ldp             w12, w13, [x6, #20]     // w12: bu, w13: rv
        ldp             w14, w15, [x6, #28]     // w14: gv, w15: bv
4:
        cmp             w5, #16
        rgb_set_uv_coeff half=0
        b.lt            2f
1:
    .if \alpha_first
        argb_to_yuv_load_rgb x3
    .else
        rgb_to_yuv_load_rgb x3, \element
    .endif
        // process 2 groups of 8 pixels
        mov             v25.16b, v6.16b         // U_dst1 = const_offset (32-bit accumulators)
        mov             v26.16b, v6.16b         // U_dst2 = const_offset
        mov             v27.16b, v6.16b         // V_dst1 = const_offset
        mov             v28.16b, v6.16b         // V_dst2 = const_offset
        rgb_to_uv_interleaved_product v19, v20, v21, v0, v1, v2, v3, v4, v5, v25, v26, v27, v28, v16, v18, #9

        mov             v25.16b, v6.16b
        mov             v26.16b, v6.16b
        mov             v27.16b, v6.16b
        mov             v28.16b, v6.16b
        rgb_to_uv_interleaved_product v22, v23, v24, v0, v1, v2, v3, v4, v5, v25, v26, v27, v28, v17, v19, #9

        sub             w5, w5, #16             // width -= 16
        cmp             w5, #16                 // width >= 16 ?
        stp             q16, q17, [x0], #32     // store to dst_u (post-increment)
        stp             q18, q19, [x1], #32     // store to dst_v (post-increment)
        b.ge            1b
        cbz             w5, 3f                  // No pixels left? Exit

2:
    .if \alpha_first
        ldrb            w16, [x3, #1]           // w16: r
        ldrb            w17, [x3, #2]           // w17: g
        ldrb            w4, [x3, #3]            // w4: b
    .else
        ldrb            w16, [x3]               // w16: r
        ldrb            w17, [x3, #1]           // w17: g
        ldrb            w4, [x3, #2]            // w4: b
    .endif

        smaddl          x8, w16, w10, x9        // x8 = ru * r + const_offset
        smaddl          x8, w17, w11, x8        // x8 += gu * g
        smaddl          x8, w4, w12, x8         // x8 += bu * b
        asr             x8, x8, #9              // x8 >>= 9
        strh            w8, [x0], #2            // store to dst_u

        smaddl          x8, w16, w13, x9        // x8 = rv * r + const_offset
        smaddl          x8, w17, w14, x8        // x8 += gv * g
        smaddl          x8, w4, w15, x8         // x8 += bv * b
        asr             w8, w8, #9              // x8 >>= 9
        sub             w5, w5, #1              // width--
        add             x3, x3, #\element
        strh            w8, [x1], #2            // store to dst_v
        cbnz            w5, 2b
3:
        ret
endfunc
.endm

rgbToUV_neon bgr24, rgb24, element=3

rgbToUV_neon bgra32, rgba32, element=4

rgbToUV_neon abgr32, argb32, element=4, alpha_first=1

#if HAVE_DOTPROD
ENABLE_DOTPROD

function ff_bgra32ToY_neon_dotprod, export=1
        cmp             w4, #0                  // check width > 0
        ldp             w12, w11, [x5]          // w12: ry, w11: gy
        ldr             w10, [x5, #8]           // w10: by
        b.gt            4f
        ret
endfunc

function ff_rgba32ToY_neon_dotprod, export=1
        cmp             w4, #0                  // check width > 0
        ldp             w10, w11, [x5]          // w10: ry, w11: gy
        ldr             w12, [x5, #8]           // w12: by
        b.le            3f
4:
        mov             w9, #256                // w9 = 1 << (RGB2YUV_SHIFT - 7)
        movk            w9, #8, lsl #16         // w9 += 32 << (RGB2YUV_SHIFT - 1)
        dup             v6.4s, w9               // w9: const_offset

        cmp             w4, #16
        mov             w7, w10
        bfi             w7, w11, 8, 8           // the bfi instructions are used to assemble
        bfi             w7, w12, 16, 8          // 4 byte r,g,b,0 mask to be then used by udot.
        dup             v0.4s, w7               // v0 holds the lower byte of each coefficient

        lsr             w6, w10, #8
        lsr             w7, w11, #8
        lsr             w8, w12, #8

        bfi             w6, w7, 8, 8
        bfi             w6, w8, 16, 8
        dup             v1.4s, w6               // v1 holds the upper byte of each coefficient
        b.lt            2f
1:
        ld1             { v16.16b, v17.16b, v18.16b, v19.16b }, [x1], #64
        sub             w4, w4, #16             // width -= 16

        mov             v2.16b, v6.16b
        mov             v3.16b, v6.16b
        mov             v4.16b, v6.16b
        mov             v5.16b, v6.16b
        cmp             w4, #16                 // width >= 16 ?

        udot            v2.4s, v16.16b, v0.16b
        udot            v3.4s, v17.16b, v0.16b
        udot            v4.4s, v18.16b, v0.16b
        udot            v5.4s, v19.16b, v0.16b

        ushr            v2.4s, v2.4s, #8
        ushr            v3.4s, v3.4s, #8
        ushr            v4.4s, v4.4s, #8
        ushr            v5.4s, v5.4s, #8

        udot            v2.4s, v16.16b, v1.16b
        udot            v3.4s, v17.16b, v1.16b
        udot            v4.4s, v18.16b, v1.16b
        udot            v5.4s, v19.16b, v1.16b

        sqshrn          v16.4h, v2.4s, #1
        sqshrn2         v16.8h, v3.4s, #1
        sqshrn          v17.4h, v4.4s, #1
        sqshrn2         v17.8h, v5.4s, #1

        stp             q16, q17, [x0], #32     // store to dst
        b.ge            1b
        cbz             x4, 3f
2:
        ldrb            w13, [x1]               // w13: r
        ldrb            w14, [x1, #1]           // w14: g
        ldrb            w15, [x1, #2]           // w15: b

        smaddl          x13, w13, w10, x9       // x13 = ry * r + const_offset
        smaddl          x13, w14, w11, x13      // x13 += gy * g
        smaddl          x13, w15, w12, x13      // x13 += by * b
        asr             w13, w13, #9            // x13 >>= 9
        sub             w4, w4, #1              // width--
        add             x1, x1, #4
        strh            w13, [x0], #2           // store to dst
        cbnz            w4, 2b
3:
        ret
endfunc

DISABLE_DOTPROD
#endif

