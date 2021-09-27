{.passL: "-lmpv".}

type
  mpv_handle* = distinct pointer
  mpv_event_id* = enum
    MPV_EVENT_NONE = 0, MPV_EVENT_SHUTDOWN = 1, MPV_EVENT_LOG_MESSAGE = 2,
    MPV_EVENT_GET_PROPERTY_REPLY = 3, MPV_EVENT_SET_PROPERTY_REPLY = 4,
    MPV_EVENT_COMMAND_REPLY = 5, MPV_EVENT_START_FILE = 6, MPV_EVENT_END_FILE = 7,
    MPV_EVENT_FILE_LOADED = 8, MPV_EVENT_TRACKS_CHANGED = 9,
    MPV_EVENT_TRACK_SWITCHED = 10, MPV_EVENT_IDLE = 11, MPV_EVENT_PAUSE = 12,
    MPV_EVENT_UNPAUSE = 13, MPV_EVENT_TICK = 14, MPV_EVENT_SCRIPT_INPUT_DISPATCH = 15,
    MPV_EVENT_CLIENT_MESSAGE = 16, MPV_EVENT_VIDEO_RECONFIG = 17,
    MPV_EVENT_AUDIO_RECONFIG = 18, MPV_EVENT_METADATA_UPDATE = 19,
    MPV_EVENT_SEEK = 20, MPV_EVENT_PLAYBACK_RESTART = 21,
    MPV_EVENT_PROPERTY_CHANGE = 22, MPV_EVENT_CHAPTER_CHANGE = 23,
    MPV_EVENT_QUEUE_OVERFLOW = 24, MPV_EVENT_HOOK = 25
  mpv_event* {.bycopy.} = object
    event_id*: mpv_event_id
    error*: cint
    reply_userdata*: cint
    data*: pointer

  mpv_format* = enum
    MPV_FORMAT_NONE = 0, MPV_FORMAT_STRING = 1, MPV_FORMAT_OSD_STRING = 2,
    MPV_FORMAT_FLAG = 3, MPV_FORMAT_INT64 = 4, MPV_FORMAT_DOUBLE = 5,
    MPV_FORMAT_NODE = 6, MPV_FORMAT_NODE_ARRAY = 7, MPV_FORMAT_NODE_MAP = 8,
    MPV_FORMAT_BYTE_ARRAY = 9

proc mpv_create*(): ptr mpv_handle {.header: "<mpv/client.h>", importc: "mpv_create", varargs.}
proc mpv_initialize*(ctx: ptr mpv_handle): cint {.header: "<mpv/client.h>", importc: "mpv_initialize", varargs.}
proc mpv_set_option*(ctx: ptr mpv_handle; name: cstring; format: mpv_format;
        data: pointer): cint {.header: "<mpv/client.h>", importc: "mpv_set_option", varargs.}
proc mpv_command*(ctx: ptr mpv_handle; args: cstringArray): cint {.header: "<mpv/client.h>", importc: "mpv_command", varargs.}
proc mpv_wait_event*(ctx: ptr mpv_handle; timeout: cdouble): ptr mpv_event {.header: "<mpv/client.h>", importc: "mpv_wait_event", varargs.}
