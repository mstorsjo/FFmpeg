add_compile_definitions(HAVE_AV_CONFIG_H)
set(postproc_src
    postprocess.c
    version.c)
add_library(postproc ${postproc_src})
