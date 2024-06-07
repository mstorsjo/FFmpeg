;******************************************************************************
;* Copyright (c) 2024 Ramiro Polla
;*
;* This file is part of FFmpeg.
;*
;* FFmpeg is free software; you can redistribute it and/or
;* modify it under the terms of the GNU Lesser General Public
;* License as published by the Free Software Foundation; either
;* version 2.1 of the License, or (at your option) any later version.
;*
;* FFmpeg is distributed in the hope that it will be useful,
;* but WITHOUT ANY WARRANTY; without even the implied warranty of
;* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;* Lesser General Public License for more details.
;*
;* You should have received a copy of the GNU Lesser General Public
;* License along with FFmpeg; if not, write to the Free Software
;* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
;******************************************************************************

%include "libavutil/x86/x86util.asm"

; NOTE: there is no need to clamp the input when converting to jpeg range
;       (like we do in the C code) because packssdw will saturate the output.

;-----------------------------------------------------------------------------
; lumConvertRange
;
; void ff_lumRangeToJpeg_<opt>(int16_t *dst, int width);
; void ff_lumRangeFromJpeg_<opt>(int16_t *dst, int width);
;
;-----------------------------------------------------------------------------

%macro LUMCONVERTRANGE 4
SECTION_RODATA
mult_%1:        times 4 dd %2
offset_%1:      times 4 dd %3
SECTION .text
cglobal %1, 2, 3, 3, dst, width, x
    movsxdifnidn widthq, widthd
    xor              xq, xq
    mova             m1, [mult_%1]
    mova             m2, [offset_%1]
.loop:
    pmovsxwd         m0, [dstq+xq*2]
    pmulld           m0, m1
    paddd            m0, m2
    psrad            m0, %4
    packssdw         m0, m0
    movh    [dstq+xq*2], m0
    add              xq, mmsize / 4
    cmp              xd, widthd
    jl .loop
    RET
%endmacro

;-----------------------------------------------------------------------------
; chrConvertRange
;
; void ff_chrRangeToJpeg_<opt>(int16_t *dstU, int16_t *dstV, int width);
; void ff_chrRangeFromJpeg_<opt>(int16_t *dstU, int16_t *dstV, int width);
;
;-----------------------------------------------------------------------------

%macro CHRCONVERTRANGE 4
SECTION_RODATA
mult_%1:        times 4 dd %2
offset_%1:      times 4 dd %3
SECTION .text
cglobal %1, 3, 4, 4, dstU, dstV, width, x
    movsxdifnidn widthq, widthd
    xor              xq, xq
    mova             m1, [mult_%1]
    mova             m2, [offset_%1]
.loop:
    pmovsxwd         m0, [dstUq+xq*2]
    pmulld           m0, m1
    paddd            m0, m2
    psrad            m0, %4
    packssdw         m0, m0
    movh   [dstUq+xq*2], m0
    pmovsxwd         m0, [dstVq+xq*2]
    pmulld           m0, m1
    paddd            m0, m2
    psrad            m0, %4
    packssdw         m0, m0
    movh   [dstVq+xq*2], m0
    add              xq, mmsize / 4
    cmp              xd, widthd
    jl .loop
    RET
%endmacro

%if ARCH_X86_64
INIT_XMM sse4
LUMCONVERTRANGE lumRangeToJpeg,   19077, -39057361, 14
CHRCONVERTRANGE chrRangeToJpeg,    4663,  -9289992, 12
LUMCONVERTRANGE lumRangeFromJpeg, 14071,  33561947, 14
CHRCONVERTRANGE chrRangeFromJpeg,  1799,   4081085, 11
%endif
