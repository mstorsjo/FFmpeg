add_compile_definitions(HAVE_AV_CONFIG_H)
set(swresample_src
    audioconvert.c
    dither.c
    options.c
    rematrix.c
    resample.c
    resample_dsp.c
    swresample.c
    swresample_frame.c
    version.c)
if (CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
  list(APPEND swresample_src
      aarch64/audio_convert_init.c
      aarch64/resample_init.c
      aarch64/neontest.c
      aarch64/audio_convert_neon.S
      aarch64/resample.S
      )
elseif (CMAKE_SYSTEM_PROCESSOR STREQUAL "arm")
  list(APPEND swresample_src
      arm/audio_convert_init.c
      arm/resample_init.c
      arm/neontest.c
      arm/audio_convert_neon.S
      arm/resample.S)
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "i386")
  list(APPEND swresample_src
      x86/audio_convert_init.c
      x86/rematrix_init.c
      x86/resample_init.c)
  if (CMAKE_ASM_NASM_COMPILER)
    set(x86_nasm_sources
        x86/audio_convert.asm
        x86/rematrix.asm
        x86/resample.asm)
    list(APPEND swresample_src
        ${x86_nasm_sources})
    set_source_files_properties(${x86_nasm_sources} PROPERTIES LANGUAGE ASM_NASM)
  endif()
endif()
add_library(swresample ${swresample_src})
