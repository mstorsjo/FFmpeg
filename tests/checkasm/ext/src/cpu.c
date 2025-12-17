/*
 * Copyright © 2018, VideoLAN and dav1d authors
 * Copyright © 2018, Two Orioles, LLC
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "checkasm_config.h"

#if HAVE_GETAUXVAL || HAVE_ELF_AUX_INFO
  #include <sys/auxv.h>
#endif
#ifdef __APPLE__
  #include <sys/sysctl.h>
#endif

#include "cpu.h"
#include "internal.h"

COLD unsigned long checkasm_getauxval(unsigned long type)
{
#if HAVE_GETAUXVAL
    return getauxval(type);
#elif HAVE_ELF_AUX_INFO
    unsigned long aux = 0;
    elf_aux_info(type, &aux, sizeof(aux));
    return aux;
#else
    (void) type;
    return 0;
#endif
}

COLD const char *checkasm_get_brand_string(char *buf, size_t buflen, int affinity)
{
#ifdef __APPLE__
    if (sysctlbyname("machdep.cpu.brand_string", buf, &buflen, NULL, 0) != 0) {
        return NULL;
    }
    return buf;
#elif (ARCH_ARM || ARCH_AARCH64) && defined(__linux__)
    return checkasm_get_arm_cpuinfo(buf, buflen, affinity);
#elif (ARCH_ARM || ARCH_AARCH64) && defined(_WIN32)
    return checkasm_get_arm_win32_reg(buf, buflen, affinity);
#else
    return NULL;
#endif
}

struct jedec_vendor {
    unsigned char bank;
    unsigned char offset;
    char name[14];
};

static const struct jedec_vendor vendors[] = {
    /* From JEDEC JEP106 (see OpenOCD's `jep106.inc` for a free equivalent). */
    /* /!\ Must be sorted by bank then offset /!\ */
    {  0, 0x01, "AMD"           },
    {  0, 0x09, "Intel"         },
    {  0, 0x29, "Microchip"     },
    {  0, 0x48, "Apple"         },
    {  2, 0x27, "MIPS"          },
    {  3, 0x6B, "NVIDIA"        },
    {  4, 0x3B, "ARM"           },
    {  6, 0x1E, "Andes Tech"    },
    {  9, 0x09, "SiFive Inc"    },
    { 10, 0x03, "Codasip GmbH"  },
    { 11, 0x37, "T-Head"        }, // formerly C-Sky
    { 14, 0x10, "SpacemiT"      },
    { 15, 0x21, "Tenstorrent"   },
};

static COLD int jvcmp(const void *pa, const void *pb)
{
    const struct jedec_vendor *va = pa, *vb = pb;
    int a = (va->bank << 7) | va->offset;
    int b = (vb->bank << 7) | vb->offset;

    return a - b;
}

COLD const char *checkasm_get_jedec_vendor_name(unsigned bank, unsigned offset)
{
    const struct jedec_vendor key = { bank, offset, "" };
    const struct jedec_vendor *v = bsearch(&key, vendors, ARRAY_SIZE(vendors),
                                           sizeof (*v), jvcmp);

    return (v != NULL) ? v->name : "unknown";
}
