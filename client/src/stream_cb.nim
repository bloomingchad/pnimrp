import client

{.push dynlib: "(libmpv.so|mpv-1.dll)", importc.}

type
  mpv_stream_cb_read_fn* = proc (cookie: pointer; buf: cstring; nbytes: uint64): int64

  mpv_stream_cb_seek_fn* = proc (cookie: pointer; offset: int64): int64

  mpv_stream_cb_size_fn* = proc (cookie: pointer): int64

  mpv_stream_cb_close_fn* = proc (cookie: pointer)

  mpv_stream_cb_cancel_fn* = proc (cookie: pointer)

  mpv_stream_cb_info* {.bycopy.} = object
    cookie*: pointer
    read_fn*: mpv_stream_cb_read_fn
    seek_fn*: mpv_stream_cb_seek_fn
    size_fn*: mpv_stream_cb_size_fn
    close_fn*: mpv_stream_cb_close_fn
    cancel_fn*: mpv_stream_cb_cancel_fn

  mpv_stream_cb_open_ro_fn* = proc (user_data: pointer; uri: cstring;
                                 info: ptr mpv_stream_cb_info): cint


proc mpv_stream_cb_add_ro*(ctx: ptr handle; protocol: cstring; user_data: pointer;
                          open_fn: mpv_stream_cb_open_ro_fn): cint
{.pop.}
