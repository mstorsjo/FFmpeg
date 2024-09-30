add_executable(ffmpeg
    cmdutils.c
    opt_common.c
    ffmpeg.c
    ffmpeg_dec.c
    ffmpeg_demux.c
    ffmpeg_enc.c
    ffmpeg_filter.c
    ffmpeg_hw.c
    ffmpeg_mux.c
    ffmpeg_mux_init.c
    ffmpeg_opt.c
    ffmpeg_sched.c
    objpool.c
    sync_queue.c
    thread_queue.c)
target_link_libraries(ffmpeg PRIVATE avdevice avfilter swscale swresample postproc avformat avcodec avutil)

install(TARGETS ffmpeg)
