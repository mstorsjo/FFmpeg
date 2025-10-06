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

#include "libavutil/aarch64/cpu.h"
#include "libavutil/attributes.h"
#include "libavutil/crc_internal.h"

uint32_t ff_crc32_aarch64(const AVCRC *crctab, uint32_t crc,
                          const uint8_t *buffer, size_t length);

av_cold void ff_crc_get_aarch64(AVCRCId crc_id, AVCRCCtx *ctx)
{
    if (crc_id != AV_CRC_32_IEEE_LE)
        return;

    int cpu_flags = av_get_cpu_flags();
    if (cpu_flags & AV_CPU_FLAG_CRC32)
        ctx->fn = ff_crc32_aarch64;
}
