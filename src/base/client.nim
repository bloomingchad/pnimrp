##[
this module contains bindings for libmpvs client.h used to play streams.
the module does not wrap deprecated functions.
first templates, consts, then types, procedures at last.
this module renames procedures so to better look with language,
like seen in SDL2 module.
Please refer to official documentation available in mpv/client.h for most information

Cites
- c2nim -> wrapped most of the types
]##

from terminal import showCursor

when defined posix: {.push dynlib: "libmpv.so".}
when defined windows: {.push dynlib: "mpv-1.dll".}

#templates
template makeVersion*(major, minor: untyped): untyped = major shl 16 or minor or 0'u32

#consts
const clientApiVersion* = makeVersion(1, 107)

#types
type #enums
  error* = enum ##errors codes returned by api functions
    errGeneric              = -20,
    errNotImplemented       = -19,
    errUnsupported          = -18,
    errUnknownFormat        = -17,
    errNothingToPlay        = -16,
    errVOInitFailed         = -15,
    errAOInitFailed         = -14,
    errLoadFaile            = -13,
    errCmd                  = -12,
    errOnProperty           = -11,
    errPropertyUnavailable  = -10,
    errPropertyFormat       = -9,
    errPropertyNotFound     = -8,
    errOnOption             = -7,
    errOptionFormat         = -6,
    errOptionNotFound       = -5,
    errInvalidParameter     = -4, ##error when parameter is invalid or unsupported
    errUninitialized        = -3, ##set an option that doesnt exist
    errNoMem                = -2, ##memory allocation failed
    errEventQueueFull       = -1,
    errSuccess              =  0   ##no error, >= 0 means success

  format* = enum
    formatNone       = 0,
    formatString     = 1,
    formatOSDString  = 2,
    formatFlag       = 3,
    formatInt64      = 4,
    formatFloat64    = 5,
    formatNode       = 6,
    formatNodeArray  = 7,
    formatNodeMap    = 8,
    formatByteArray  = 9

  eventID* = enum
    eventIDNone              = 0,
    eventIDShutdown          = 1,
    eventIDLogMessage        = 2,
    eventIDGetPropertyReply  = 3,
    eventIDSetPropertyReply  = 4,
    eventIDCommandReply      = 5,
    eventIDStartFile         = 6,
    eventIDEndFile           = 7,
    eventIDFileLoaded        = 8,
    eventIDIdle              = 11,
    eventIDClientMessage     = 16,
    eventIDVideoReConfig     = 17,
    eventIDAudioReConfig     = 18,
    eventIDSeek              = 20,
    eventIDPlayBackRestart   = 21,
    eventIDPropertyChange    = 22,
    eventIDQueueOverFlow     = 24,
    eventIDHook              = 25

  endFileReason* = enum
    endFileReasonEOF         = 0, ##reaching end of file. network issues, corrupted packets?
    endFileReasonStop        = 2, ##external action (controls?)
    endFileReasonQuit        = 3, ##quitted
    endFileReasonError       = 4, ##some error made it stop.
    endFileReasonReDirect    = 5  ##playlist endofFile redirect mechanism

  logLevel* = enum
    logLevelNone   = 0,  ##no messages
    logLevelFatal  = 10, ##fatal/abortive erres
    logLevelError  = 20, ##simple errors
    logLevelWarn   = 30, ##possible problem warnings
    logLevelInfo   = 40, ##info
    logLevelV      = 50, ##noisy info
    logLevelDebug  = 60, ##more noisy verbose info
    logLevelTrace  = 70  ##extermely verbose

#Type Objects
  handle* =  distinct pointer  ##basic type that is essential, used to infer the context

  clientUnionType* {.bycopy, union.} = object
    str*: cstring
    flag*, integer*: cint
    double*: cdouble
    list*: ptr nodeList
    ba*: ptr byteArray

  node* {.bycopy.} = object
    u*: clientUnionType
    format*: format

  nodeList* {.bycopy.} = object
    num*: cint
    values*: ptr node
    keys*: cstringArray

  byteArray* {.bycopy.} = object
    data*: pointer
    size*: csize_t

  eventProperty* {.bycopy.} = object
    name*: cstring
    format*: format
    data*: pointer

  eventLogMessage* {.bycopy.} = object
    prefix*, level*, text*: cstring
    logLevel*: logLevel

  eventEndFile* {.bycopy.} = object
    reason*, error*: cint

  eventClientMessage* {.bycopy.} = object
    num_args*: cint
    args*: cstringArray

  eventHook* {.bycopy.} = object
    name*: cstring
    id*: cint

  eventCmd* {.bycopy.} = object
    result*: node

  event* {.bycopy.} = object
    eventID*: eventID
    error*, replyUserData*: cint
    data*: pointer

#procs
proc abortAsyncCmd*(ctx: ptr handle; replyUserData: cint)
   {.importc: "mpv_abort_async_command".}

proc getClientName*(ctx: ptr handle): cstring
    {.importc: "mpv_client_name".}
 ##return the unique client handle name

proc cmd*(ctx: ptr handle; args: cstringArray): cint
    {.importc: "mpv_command".}

proc cmdAsync*(ctx: ptr handle; reply_userdata: cint; args: cstringArray): cint
   {.importc: "mpv_command_async".}

proc cmdNode*(ctx: ptr handle; args, result: ptr node): cint
    {.importc: "mpv_command_node".}

proc cmdNodeAsync*(ctx: ptr handle; replyUserData: cint; args: ptr node): cint
   {.importc: "mpv_command_node_async".}

proc cmdRet*(ctx: ptr handle; args: cstringArray; result: ptr node): cint
    {.importc: "mpv_command_ret".}

proc cmdString*(ctx: ptr handle; args: cstring): cint
   {.importc: "mpv_command_string".}

proc create*: ptr handle
    {.importc: "mpv_create".}
 ##create and return a handle used to control the instance

proc createClient*(ctx: ptr handle; name: cstring): ptr handle
    {.importc: "mpv_create_client".}

proc createWeakClient*(ctx: ptr handle; name: cstring): ptr handle
    {.importc: "mpv_create_weak_client".}

proc destroy*(ctx: ptr handle)
    {.importc: "mpv_destroy".}

proc errorString*(error: cint): cstring
    {.importc: "mpv_error_string".}

proc eventName*(event: eventID): cstring 
   {.importc: "mpv_event_name".}

proc free*(data: pointer)
    {.importc: "mpv_free".}

proc freeNodeContents*(node: ptr node)
    {.importc: "mpv_free_node_contents".}

proc getClientApiVersion*: culong
 {.importc: "mpv_client_api_version".}
 ##return api version of libmpv

proc getProperty*(ctx: ptr handle; name: cstring; format: format; data: pointer): cint 
   {.importc: "mpv_get_property".}

proc getPropertyAsync*(ctx: ptr handle; replyUserData: cint; name: cstring; format: format): cint
   {.importc: "mpv_get_property_async".}

proc getPropertyOSDString*(ctx: ptr handle; name: cstring): cstring 
   {.importc: "mpv_get_property_osd_string".}

proc getPropertyString*(ctx: ptr handle; name: cstring): cstring
   {.importc: "mpv_get_property_string".}

proc getTimeUS*(ctx: ptr handle): cint
    {.importc: "mpv_get_time_us".}

proc hookAdd*(ctx: ptr handle; replyUserData: cint; name: cstring; priority: cint): cint
   {.importc: "mpv_hook_add".}

proc hookContinue*(ctx: ptr handle; id: cint): cint
   {.importc: "mpv_hook_continue".}

proc initialize*(ctx: ptr handle): cint
    {.importc: "mpv_initialize".}

proc loadConfigFile*(ctx: ptr handle; filename: cstring): cint
    {.importc: "mpv_load_config_file".}

proc observeProperty*(mpv: ptr handle; replyUserData: cint; name: cstring; format: format): cint 
   {.importc: "mpv_observe_property".}

proc requestEvent*(ctx: ptr handle; event: eventID; enable: cint): cint
   {.importc: "mpv_request_event".}

proc requestLogMsgs*(ctx: ptr handle; min_level: cstring): cint
   {.importc: "mpv_request_log_messages".}

proc setOption*(ctx: ptr handle; name: cstring; format: format; data: pointer): cint
    {.importc: "mpv_set_option".}

proc setOptionString*(ctx: ptr handle; name: cstring; data: cstring): cint
    {.importc: "mpv_set_option_string".}

proc setProperty*(ctx: ptr handle; name: cstring; format: format; data: pointer): cint 
   {.importc: "mpv_set_property".}

proc setPropertyAsync*(ctx: ptr handle; replyUserData: cint; name: cstring; format: format; data: pointer): cint 
   {.importc: "mpv_set_property_async".}

proc setPropertyString*(ctx: ptr handle; name: cstring; data: cstring): cint 
   {.importc: "mpv_set_property_string".}

proc setWakeupCallback*(ctx: ptr handle; cb: proc (d: pointer); d: pointer) 
   {.importc: "mpv_set_wakeup_callback".}

proc terminateDestroy*(ctx: ptr handle)
    {.importc: "mpv_terminate_destroy".}

proc unobserveProperty*(mpv: ptr handle; registeredReplyUserData: cint): cint 
   {.importc: "mpv_unobserve_property".}

proc waitAsyncRequests*(ctx: ptr handle)
   {.importc: "mpv_wait_async_requests".}

proc waitEvent*(ctx: ptr handle; timeout: cdouble): ptr event
   {.importc: "mpv_wait_event".}

proc wakeup*(ctx: ptr handle)
   {.importc: "mpv_wakeup".}

proc checkError*(status: cint) =
 ##unofficial: checks the return value of enclosed function,
 ##and if less than 0 quit with failure exit status
 if status < 0:
  echo "mpv API error: ", errorString status
  showCursor()
  quit QuitFailure

{.pop.}
