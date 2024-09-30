add_compile_definitions(HAVE_AV_CONFIG_H)
set(avdevice_src
    alldevices.c
    avdevice.c
    utils.c
    version.c
    lavfi.c)
add_library(avdevice ${avdevice_src})
