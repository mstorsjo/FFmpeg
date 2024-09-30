add_compile_definitions(HAVE_AV_CONFIG_H)
set(swscale_src
    alphablend.c
    hscale.c
    hscale_fast_bilinear.c
    gamma.c
    half2float.c
    input.c
    options.c
    output.c
    rgb2rgb.c
    slice.c
    swscale.c
    swscale_unscaled.c
    utils.c
    version.c
    yuv2rgb.c
    vscale.c)
if (CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
  list(APPEND swscale_src
      aarch64/rgb2rgb.c
      aarch64/swscale.c
      aarch64/swscale_unscaled.c
      aarch64/hscale.S
      aarch64/input.S
      aarch64/output.S
      aarch64/range_convert_neon.S
      aarch64/rgb2rgb_neon.S
      aarch64/swscale_unscaled_neon.S
      aarch64/yuv2rgb_neon.S
      )
elseif (CMAKE_SYSTEM_PROCESSOR STREQUAL "arm")
  list(APPEND swscale_src
       arm/swscale.c
       arm/swscale_unscaled.c
       arm/rgb2yuv_neon_32.S
       arm/rgb2yuv_neon_16.S
       arm/hscale.S
       arm/output.S
       arm/yuv2rgb_neon.S)
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "i386")
  list(APPEND swscale_src
      x86/rgb2rgb.c
      x86/swscale.c
      x86/yuv2rgb.c
      x86/hscale_fast_bilinear_simd.c)
  if (CMAKE_ASM_NASM_COMPILER)
    set(x86_nasm_sources
        x86/input.asm
        x86/output.asm
        x86/scale.asm
        x86/scale_avx2.asm
        x86/range_convert.asm
        x86/rgb_2_rgb.asm
        x86/yuv_2_rgb.asm
        x86/yuv2yuvX.asm)
    list(APPEND swscale_src
        ${x86_nasm_sources})
    set_source_files_properties(${x86_nasm_sources} PROPERTIES LANGUAGE ASM_NASM)
  endif()
endif()
add_library(swscale ${swscale_src})
