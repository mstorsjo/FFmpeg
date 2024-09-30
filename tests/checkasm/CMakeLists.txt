#add_compile_definitions(HAVE_AV_CONFIG_H)
set(checkasm_src
    checkasm.c
    ac3dsp.c
    audiodsp.c
    blockdsp.c
    bswapdsp.c
    fdctdsp.c
    fmtconvert.c
    g722dsp.c
    h263dsp.c
    h264chroma.c
    h264dsp.c
    h264pred.c
    h264qpel.c
    idctdsp.c
    llauddsp.c
    llviddsp.c
    llviddspenc.c
    lpc.c
    motion.c
    mpegvideoencdsp.c
    vc1dsp.c
    vp8dsp.c
    videodsp.c
    aacpsdsp.c
    sbrdsp.c
    aacencdsp.c
    alacdsp.c
    synth_filter.c
    exrdsp.c
    flacdsp.c
    huffyuvdsp.c
    jpeg2000dsp.c
    opusdsp.c
    pixblockdsp.c
    hevc_add_res.c
    hevc_deblock.c
    hevc_idct.c
    hevc_sao.c
    hevc_pel.c
    rv34dsp.c
    rv40dsp.c
    svq1enc.c
    takdsp.c
    utvideodsp.c
    v210dec.c
    v210enc.c
    vorbisdsp.c
    vp9dsp.c
    vvc_alf.c
    vvc_mc.c
    af_afir.c
    vf_blend.c
    vf_bwdif.c
    vf_colorspace.c
    vf_eq.c
    vf_gblur.c
    vf_hflip.c
    vf_threshold.c
    vf_nlmeans.c
    vf_convolution.c
    sw_gbrp.c
    sw_range_convert.c
    sw_rgb.c
    sw_scale.c
    sw_yuv2rgb.c
    sw_yuv2yuv.c
    av_tx.c
    fixed_dsp.c
    float_dsp.c
    lls.c)
if (CMAKE_SYSTEM_PROCESSOR STREQUAL "aarch64")
  list(APPEND checkasm_src
      aarch64/checkasm.S)
elseif (CMAKE_SYSTEM_PROCESSOR STREQUAL "arm")
  list(APPEND checkasm_src
      arm/checkasm.S)
elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86_64" OR CMAKE_SYSTEM_PROCESSOR STREQUAL "i386")
  if (CMAKE_ASM_NASM_COMPILER)
    set(x86_nasm_sources
        x86/checkasm.asm)
    list(APPEND checkasm_src
        ${x86_nasm_sources})
    set_source_files_properties(${x86_nasm_sources} PROPERTIES LANGUAGE ASM_NASM)
  endif()
endif()
add_executable(checkasm ${checkasm_src})
target_link_libraries(checkasm PRIVATE avdevice avfilter swscale swresample postproc avformat avcodec avutil)
