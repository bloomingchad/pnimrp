{.push dynlib: "(libmpv.so|mpv-1.dll)", importc.}

type
  drmModeAtomicReq* = distinct pointer
  mpv_opengl_init_params* {.bycopy.} = object
    get_proc_address*: proc (ctx: pointer; name: cstring): pointer
    get_proc_address_ctx*: pointer
    extra_exts*: cstring

  mpv_opengl_fbo* {.bycopy.} = object
    fbo*, w*, h*, internal_format*: cint

  mpv_opengl_drm_params* {.bycopy.} = object
    fd*, crtc_id*, connector_id*, render_fd*: cint
    atomic_request_ptr*: ptr ptr drmModeAtomicReq

  mpv_opengl_drm_draw_surface_size* {.bycopy.} = object
    width*, height*: cint

  mpv_opengl_drm_params_v2* {.bycopy.} = object
    fd*, crtc_id*, connector_id*, render_fd*: cint
    atomic_request_ptr*: ptr ptr drmModeAtomicReq

  mpv_opengl_drm_osd_size* = mpv_opengl_drm_draw_surface_size
