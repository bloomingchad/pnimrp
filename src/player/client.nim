#client.h nim binding for libmpv
{.passL: "-lmpv".}

template MPV_MAKE_VERSION*(major, minor: untyped): untyped = (((major) shl 16) or (minor) or 0'u32)

const MPV_CLIENT_API_VERSION* = MPV_MAKE_VERSION(1, 107)

#types gofirst
#mpv_depreciated has been merged without a when block
type
  mpv_handle = distinct pointer

  INNER_C_UNION_client_1* {.bycopy, union.} = object
    string*: cstring
    flag*: cint
    int64*: cint
    double*: cdouble
    list*: ptr mpv_node_list
    ba*: ptr mpv_byte_array

  mpv_error* = enum
    MPV_ERROR_GENERIC               = -20,
    MPV_ERROR_NOT_IMPLEMENTED       = -19,
    MPV_ERROR_UNSUPPORTED           = -18,
    MPV_ERROR_UNKNOWN_FORMAT        = -17,
    MPV_ERROR_NOTHING_TO_PLAY       = -16,
    MPV_ERROR_VO_INIT_FAILED        = -15,
    MPV_ERROR_AO_INIT_FAILED        = -14,
    MPV_ERROR_LOADING_FAILED        = -13,
    MPV_ERROR_COMMAND               = -12,
    MPV_ERROR_PROPERTY_ERROR        = -11,
    MPV_ERROR_PROPERTY_UNAVAILABLE  = -10,
    MPV_ERROR_PROPERTY_FORMAT       = -9,
    MPV_ERROR_PROPERTY_NOT_FOUND    = -8,
    MPV_ERROR_OPTION_ERROR          = -7,
    MPV_ERROR_OPTION_FORMAT         = -6,
    MPV_ERROR_OPTION_NOT_FOUND      = -5,
    MPV_ERROR_INVALID_PARAMETER     = -4,
    MPV_ERROR_UNINITIALIZED         = -3,
    MPV_ERROR_NOMEM                 = -2,
    MPV_ERROR_EVENT_QUEUE_FULL      = -1,
    MPV_ERROR_SUCCESS = 0

  mpv_format* = enum
    MPV_FORMAT_NONE                 = 0,
    MPV_FORMAT_STRING               = 1,
    MPV_FORMAT_OSD_STRING           = 2,
    MPV_FORMAT_FLAG                 = 3,
    MPV_FORMAT_INT64                = 4,
    MPV_FORMAT_DOUBLE               = 5,
    MPV_FORMAT_NODE                 = 6,
    MPV_FORMAT_NODE_ARRAY           = 7,
    MPV_FORMAT_NODE_MAP             = 8,
    MPV_FORMAT_BYTE_ARRAY           = 9

  mpv_event_id* = enum
    MPV_EVENT_NONE                  = 0,
    MPV_EVENT_SHUTDOWN              = 1,
    MPV_EVENT_LOG_MESSAGE           = 2,
    MPV_EVENT_GET_PROPERTY_REPLY    = 3,
    MPV_EVENT_SET_PROPERTY_REPLY    = 4,
    MPV_EVENT_COMMAND_REPLY         = 5,
    MPV_EVENT_START_FILE            = 6,
    MPV_EVENT_END_FILE              = 7,
    MPV_EVENT_FILE_LOADED           = 8,
    MPV_EVENT_TRACKS_CHANGED        = 9,
    MPV_EVENT_TRACK_SWITCHED        = 10,
    MPV_EVENT_IDLE                  = 11,
    MPV_EVENT_PAUSE                 = 12,
    MPV_EVENT_UNPAUSE               = 13,
    MPV_EVENT_TICK                  = 14,
    MPV_EVENT_SCRIPT_INPUT_DISPATCH = 15,
    MPV_EVENT_CLIENT_MESSAGE        = 16,
    MPV_EVENT_VIDEO_RECONFIG        = 17,
    MPV_EVENT_AUDIO_RECONFIG        = 18,
    MPV_EVENT_METADATA_UPDATE       = 19,
    MPV_EVENT_SEEK                  = 20,
    MPV_EVENT_PLAYBACK_RESTART      = 21,
    MPV_EVENT_PROPERTY_CHANGE       = 22,
    MPV_EVENT_CHAPTER_CHANGE        = 23,
    MPV_EVENT_QUEUE_OVERFLOW        = 24,
    MPV_EVENT_HOOK                  = 25

  mpv_end_file_reason* = enum
    MPV_END_FILE_REASON_EOF         = 0,
    MPV_END_FILE_REASON_STOP        = 2,
    MPV_END_FILE_REASON_QUIT        = 3,
    MPV_END_FILE_REASON_ERROR       = 4,
    MPV_END_FILE_REASON_REDIRECT    = 5

  mpv_node* {.bycopy.} = object
    u*: INNER_C_UNION_client_1
    format*: mpv_format

  mpv_node_list* {.bycopy.} = object
    num*: cint
    values*: ptr mpv_node
    keys*: cstringArray

  mpv_byte_array* {.bycopy.} = object
    data*: pointer
    size*: csize_t

  mpv_event_property* {.bycopy.} = object
    name*: cstring
    format*: mpv_format
    data*: pointer

  mpv_log_level* = enum
    MPV_LOG_LEVEL_NONE              = 0,
    MPV_LOG_LEVEL_FATAL             = 10,
    MPV_LOG_LEVEL_ERROR             = 20,
    MPV_LOG_LEVEL_WARN              = 30,
    MPV_LOG_LEVEL_INFO              = 40,
    MPV_LOG_LEVEL_V                 = 50,
    MPV_LOG_LEVEL_DEBUG             = 60,
    MPV_LOG_LEVEL_TRACE             = 70

  mpv_event_log_message* {.bycopy.} = object
    prefix*: cstring
    level*: cstring
    text*: cstring
    log_level*: mpv_log_level

  mpv_event_end_file* {.bycopy.} = object
    reason*: cint
    error*: cint

  mpv_event_client_message* {.bycopy.} = object
    num_args*: cint
    args*: cstringArray

  mpv_event_hook* {.bycopy.} = object
    name*: cstring
    id*: cint

  mpv_event_command* {.bycopy.} = object
    result*: mpv_node

  mpv_event* {.bycopy.} = object
    event_id*: mpv_event_id
    error*: cint
    reply_userdata*: cint
    data*: pointer

  mpv_event_script_input_dispatch* {.bycopy.} = object
    arg0*: cint
    `type`*: cstring

  mpv_sub_api* = enum
    MPV_SUB_API_OPENGL_CB = 1

#procs
proc mpv_get_wakeup_pipe*(ctx: ptr mpv_handle): cint
    {.header: "<mpv/client.h>", importc: "mpv_get_wakeup_pipe", varargs.}

proc mpv_client_api_version*(): culong
    {.header: "<mpv/client.h>", importc: "mpv_client_api_version", varargs.}

proc mpv_error_string*(error: cint): cstring
    {.header: "<mpv/client.h>", importc: "mpv_error_string", varargs.}

proc mpv_free*(data: pointer)
    {.header: "<mpv/client.h>", importc: "mpv_free", varargs.}

proc mpv_client_name*(ctx: ptr mpv_handle): cstring
    {.header: "<mpv/client.h>", importc: "mpv_client_name", varargs.}

proc mpv_create*(): ptr mpv_handle
    {.header: "<mpv/client.h>", importc: "mpv_create", varargs.}

proc mpv_initialize*(ctx: ptr mpv_handle): cint
    {.header: "<mpv/client.h>", importc: "mpv_initialize", varargs.}

proc mpv_destroy*(ctx: ptr mpv_handle)
    {.header: "<mpv/client.h>", importc: "mpv_destroy", varargs.}

proc mpv_terminate_destroy*(ctx: ptr mpv_handle)
    {.header: "<mpv/client.h>", importc: "mpv_terminate_destroy", varargs.}

proc mpv_create_client*(ctx: ptr mpv_handle; name: cstring): ptr mpv_handle
    {.header: "<mpv/client.h>", importc: "mpv_create_client", varargs.}

proc mpv_create_weak_client*(ctx: ptr mpv_handle; name: cstring): ptr mpv_handle
    {.header: "<mpv/client.h>", importc: "mpv_create_weak_client", varargs.}

proc mpv_load_config_file*(ctx: ptr mpv_handle; filename: cstring): cint
    {.header: "<mpv/client.h>", importc: "mpv_load_config_file", varargs.}

proc mpv_get_time_us*(ctx: ptr mpv_handle): cint
    {.header: "<mpv/client.h>", importc: "mpv_get_time_us", varargs.}

proc mpv_free_node_contents*(node: ptr mpv_node)
    {.header: "<mpv/client.h>", importc: "mpv_free_node_contents", varargs.}

proc mpv_set_option*(ctx: ptr mpv_handle; name: cstring; format: mpv_format; data: pointer): cint
    {.header: "<mpv/client.h>", importc: "mpv_set_option", varargs.}

proc mpv_set_option_string*(ctx: ptr mpv_handle; name: cstring; data: cstring): cint
    {.header: "<mpv/client.h>", importc: "mpv_set_option_string", varargs.}

proc mpv_command*(ctx: ptr mpv_handle; args: cstringArray): cint
    {.header: "<mpv/client.h>", importc: "mpv_command", varargs.}

proc mpv_command_node*(ctx: ptr mpv_handle; args: ptr mpv_node; result: ptr mpv_node): cint
    {.header: "<mpv/client.h>", importc: "mpv_command_node", varargs.}

proc mpv_command_ret*(ctx: ptr mpv_handle; args: cstringArray; result: ptr mpv_node): cint
    {.header: "<mpv/client.h>", importc: "mpv_command_ret", varargs.}

proc mpv_command_string*(ctx: ptr mpv_handle; args: cstring): cint
   {.header: "<mpv/client.h>", importc: "mpv_command_string", varargs.}

proc mpv_command_async*(ctx: ptr mpv_handle; reply_userdata: cint; args: cstringArray): cint
   {.header: "<mpv/client.h>", importc: "mpv_command_async", varargs.}

proc mpv_command_node_async*(ctx: ptr mpv_handle; reply_userdata: cint; args: ptr mpv_node): cint
   {.header: "<mpv/client.h>", importc: "mpv_command_node_async", varargs.}

proc mpv_abort_async_command*(ctx: ptr mpv_handle; reply_userdata: cint)
   {.header: "<mpv/client.h>", importc: "mpv_abort_async_command", varargs.}

proc mpv_set_property*(ctx: ptr mpv_handle; name: cstring; format: mpv_format; data: pointer): cint 
   {.header: "<mpv/client.h>", importc: "mpv_set_property", varargs.}

proc mpv_set_property_string*(ctx: ptr mpv_handle; name: cstring; data: cstring): cint 
   {.header: "<mpv/client.h>", importc: "mpv_set_property_string", varargs.}

proc mpv_set_property_async*(ctx: ptr mpv_handle; reply_userdata: cint; name: cstring; format: mpv_format; data: pointer): cint 
   {.header: "<mpv/client.h>", importc: "mpv_set_property_async", varargs.}

proc mpv_get_property*(ctx: ptr mpv_handle; name: cstring; format: mpv_format; data: pointer): cint 
   {.header: "<mpv/client.h>", importc: "mpv_get_property", varargs.}

proc mpv_get_property_string*(ctx: ptr mpv_handle; name: cstring): cstring
   {.header: "<mpv/client.h>", importc: "mpv_get_property_string", varargs.}

proc mpv_get_property_osd_string*(ctx: ptr mpv_handle; name: cstring): cstring 
   {.header: "<mpv/client.h>", importc: "mpv_get_property_osd_string", varargs.}

proc mpv_get_property_async*(ctx: ptr mpv_handle; reply_userdata: cint; name: cstring; format: mpv_format): cint
   {.header: "<mpv/client.h>", importc: "mpv_get_property_async", varargs.}

proc mpv_observe_property*(mpv: ptr mpv_handle; reply_userdata: cint; name: cstring; format: mpv_format): cint 
   {.header: "<mpv/client.h>", importc: "mpv_observe_property", varargs.}

proc mpv_unobserve_property*(mpv: ptr mpv_handle; registered_reply_userdata: cint): cint 
   {.header: "<mpv/client.h>", importc: "mpv_unobserve_property", varargs.}

proc mpv_event_name*(event: mpv_event_id): cstring 
   {.header: "<mpv/client.h>", importc: "mpv_event_name", varargs.}

proc mpv_detach_destroy*(ctx: ptr mpv_handle) 
   {.header: "<mpv/client.h>", importc: "mpv_detach_destroy", varargs.}

proc mpv_suspend*(ctx: ptr mpv_handle) 
   {.header: "<mpv/client.h>", importc: "mpv_suspend", varargs.}

proc mpv_resume*(ctx: ptr mpv_handle)
   {.header: "<mpv/client.h>", importc: "mpv_resume", varargs.}

proc mpv_get_sub_api*(ctx: ptr mpv_handle; sub_api: mpv_sub_api): pointer 
   {.header: "<mpv/client.h>", importc: "mpv_get_sub_api", varargs.}

proc mpv_request_event*(ctx: ptr mpv_handle; event: mpv_event_id; enable: cint): cint
   {.header: "<mpv/client.h>", importc: "mpv_request_event", varargs.}

proc mpv_request_log_messages*(ctx: ptr mpv_handle; min_level: cstring): cint
   {.header: "<mpv/client.h>", importc: "mpv_request_log_messages", varargs.}

proc mpv_wait_event*(ctx: ptr mpv_handle; timeout: cdouble): ptr mpv_event 
   {.header: "<mpv/client.h>", importc: "mpv_wait_event", varargs.}

proc mpv_wakeup*(ctx: ptr mpv_handle) 
   {.header: "<mpv/client.h>", importc: "mpv_wakeup", varargs.}

proc mpv_set_wakeup_callback*(ctx: ptr mpv_handle; cb: proc (d: pointer); d: pointer) 
   {.header: "<mpv/client.h>", importc: "mpv_set_wakeup_callback", varargs.}

proc mpv_wait_async_requests*(ctx: ptr mpv_handle)
   {.header: "<mpv/client.h>", importc: "mpv_wait_async_requests", varargs.}

proc mpv_hook_add*(ctx: ptr mpv_handle; reply_userdata: cint; name: cstring; priority: cint): cint
   {.header: "<mpv/client.h>", importc: "mpv_hook_add", varargs.}

proc mpv_hook_continue*(ctx: ptr mpv_handle; id: cint): cint 
   {.header: "<mpv/client.h>", importc: "mpv_hook_continue", varargs.}
