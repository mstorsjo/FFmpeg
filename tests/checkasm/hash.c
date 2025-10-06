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

#include "checkasm.h"
#include "libavutil/crc.h"

#define BUF_SIZE (8192 + 11)

static void check_crc(void)
{
    uint8_t buf[BUF_SIZE];

    for (int i = 0; i < sizeof(buf); i++)
        buf[i] = rnd();

    AVCRCCtx ctx;
    uint32_t crc0 = UINT32_MAX;
    uint32_t crc1 = UINT32_MAX;
    av_crc_get(AV_CRC_32_IEEE_LE, &ctx);

    declare_func(uint32_t, const AVCRC *crctab, uint32_t crc,
                 const uint8_t *buffer, size_t length);
    /* Leave crctab as NULL is an optimization for real usecase, but doesn't
     * work with call_ref.
     */
    if (!ctx.crctab)
        ctx.crctab = av_crc_get_table(AV_CRC_32_IEEE_LE);
    if (check_func(ctx.fn, "crc_32_ieee_le")) {
        crc0 = call_ref(ctx.crctab, crc0, buf, sizeof(buf));
        crc1 = call_new(ctx.crctab, crc1, buf, sizeof(buf));
        if (crc0 != crc1)
            fail();
        bench_new(ctx.crctab, UINT32_MAX, buf, sizeof(buf));
    }
}

void checkasm_check_hash(void)
{
    check_crc();
    report("crc");
}
