import client

{.push dynlib: "(libmpv.so|mpv-1.dll)", importc.}

type
  mpv_render_context* = distinct pointer
  mpv_render_param_type* = enum
    MPV_RENDER_PARAM_INVALID = 0,
    MPV_RENDER_PARAM_API_TYPE = 1,
    MPV_RENDER_PARAM_OPENGL_INIT_PARAMS = 2,
    MPV_RENDER_PARAM_OPENGL_FBO = 3,
    MPV_RENDER_PARAM_FLIP_Y = 4,
    MPV_RENDER_PARAM_DEPTH = 5,
    MPV_RENDER_PARAM_ICC_PROFILE = 6,
    MPV_RENDER_PARAM_AMBIENT_LIGHT = 7,
    MPV_RENDER_PARAM_X11_DISPLAY = 8,
    MPV_RENDER_PARAM_WL_DISPLAY = 9,
    MPV_RENDER_PARAM_ADVANCED_CONTROL = 10,
    MPV_RENDER_PARAM_NEXT_FRAME_INFO = 11,
    MPV_RENDER_PARAM_BLOCK_FOR_TARGET_TIME = 12,
    MPV_RENDER_PARAM_SKIP_RENDERING = 13,
    MPV_RENDER_PARAM_DRM_DISPLAY = 14,
    MPV_RENDER_PARAM_DRM_DRAW_SURFACE_SIZE = 15,
    MPV_RENDER_PARAM_DRM_DISPLAY_V2 = 16

  mpv_render_frame_info_flag* = enum
    MPV_RENDER_FRAME_INFO_PRESENT = 1 shl 0, MPV_RENDER_FRAME_INFO_REDRAW = 1 shl 1,
    MPV_RENDER_FRAME_INFO_REPEAT = 1 shl 2,
    MPV_RENDER_FRAME_INFO_BLOCK_VSYNC = 1 shl 3

  mpv_render_param* {.bycopy.} = object
    `type`*: mpv_render_param_type
    data*: pointer

  mpv_render_frame_info* {.bycopy.} = object
    flags*: uint64
    target_time*: int64

const MPV_RENDER_PARAM_DRM_OSD_SIZE* = MPV_RENDER_PARAM_DRM_DRAW_SURFACE_SIZE
const MPV_RENDER_API_TYPE_OPENGL* = "opengl"

proc mpv_render_context_create*(res: ptr ptr mpv_render_context; mpv: ptr handle;
                               params: ptr mpv_render_param): cint

proc mpv_render_context_set_parameter*(ctx: ptr mpv_render_context;
                                      param: mpv_render_param): cint

proc mpv_render_context_get_info*(ctx: ptr mpv_render_context;
                                 param: mpv_render_param): cint
type mpv_render_update_fn* = proc (cb_ctx: pointer)

proc mpv_render_context_set_update_callback*(ctx: ptr mpv_render_context;
    callback: mpv_render_update_fn; callback_ctx: pointer)

proc mpv_render_context_update*(ctx: ptr mpv_render_context): uint64

type
  mpv_render_context_flag* = enum
    MPV_RENDER_UPDATE_FRAME = 1 shl 0

proc mpv_render_context_render*(ctx: ptr mpv_render_context;
                               params: ptr mpv_render_param): cint

proc mpv_render_context_report_swap*(ctx: ptr mpv_render_context)

proc mpv_render_context_free*(ctx: ptr mpv_render_context)
{.pop.}
