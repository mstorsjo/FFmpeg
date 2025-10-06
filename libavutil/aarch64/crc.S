/*
 * Copyright (c) 2025 Zhao Zhili <quinkblack@foxmail.com>
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with FFmpeg; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "asm.S"

function ff_crc32_aarch64, export=1
        bic             x5, x3, #15
        and             x4, x3, #15
        mov             w0, w1
        cbz             x5, 2f
1:
        ldp             x6, x7, [x2], #16
        subs            x5, x5, #16
        crc32x          w0, w0, x6
        crc32x          w0, w0, x7
        b.ne            1b
2:
        cbz             x4, 4f
3:
        ldrb            w5, [x2], #1
        subs            x4, x4, #1
        crc32b          w0, w0, w5
        b.ne            3b
4:
        ret
endfunc
