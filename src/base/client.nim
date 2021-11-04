##[
this module contains bindings for libmpvs client.h used to play streams.
the module does not wrap deprecated functions.
first templates, consts, then types, procedures at last.
this module renames procedures so to better look with language,
like seen in SDL2 module.
Please refer to official documentation available in mpv/client.h for most information
libmpv shall mean official mpv documentation throught.

Cites
- c2nim -> wrapped most of the non-enum types objects

Imports
=======
* terminal
  - showCursor
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
  error* = enum ##errors codes returned by api procs
    errGeneric              = -20, ##unspecified error
    errNotImplemented       = -19, ##proc called was stub-only
    errUnsupported          = -18, ##(was system requirements met?)
    errUnknownFormat        = -17, ##file format could not be determined (was file broken?)
    errNothingToPlay        = -16, ##no video/audio to play, (was a stream selected?)
    errVOInitFailed         = -15, ##failed to init video output
    errAOInitFailed         = -14, ##failed to init audio output
    errLoadFailed           = -13, ##loading failed (used with eventEndFile.error)
    errCmd                  = -12, ##error when running a command with cmd()
    errOnProperty           = -11, ##error when set or get property
    errPropertyUnavailable  = -10, ##property exists but is unavailable
    errPropertyFormat       = -9,  ##set or get property using unsupported format
    errPropertyNotFound     = -8,  ##said property not found
    errOnOption             = -7,  ##setting option failed (parsing errors?)
    errOptionFormat         = -6,  ##set option using unsupported format
    errOptionNotFound       = -5,  ##set option that dosent exist
    errInvalidParameter     = -4,  ##error when parameter is invalid or unsupported
    errUninitialized        = -3,  ##api wasnt initialized yet
    errNoMem                = -2,  ##memory allocation failed
    errEventQueueFull       = -1,  ##client is choked & cant receive any events.
        ##many unanswered asynchronous requests. (is api frozen?, is it an api bug?) 
    errSuccess              =  0   ##no error occured, '>= 0' means success

  format* = enum
   ##type for options and properties, can get set properties and options, support multiple formats
    formatNone       = 0, ##invalid, used for empty values
    formatString     = 1,
   ##[ basic type is cstring, returning raw property string, see libmpv/input.rst, nil isnt allowed
       not always is the encoding in UTF8, atleast on linux,but are always in windows
       (see libmpv/Encoding of Filenames)

        readableExample:
         var result = nil #char*
         if ctx.getProperty("property", formatString, addr result) < 0:
          echo "error"
         echo result
         free result

        runnableExample:
         var value: cstring = "new value"
         #pass addr to var, needed for other types and getProperty()
         ctx.setProperty("property", formatString, addr value)
       or use setPropertyString()
   ]##

    formatOSDString  = 2,
   ##[ basic type is cstring, returns OSD property string (see libmpv/input.rst), mostly its a string,
       but sometimes is formatted for OSD display, being human-readable and not meant to be parsed.
       is only valid when doing read access.
   ]##

    formatFlag       = 3,
   ##[ basic type is int, allowed values are 0=no and 1=yes

        readableExample:
         var result: int #int in C, bool in Nim, needs to be tested and edited!
         if ctx.getProperty("property", formatFlag, addr result) < 0:
          echo "error"
         echo if result: "true" else: "false"

        runnableExample:
         var flag: cint = 1
         ctx.setProperty("property", formatFlag, addr flag)
   ]##

    formatInt64      = 4, ##basic type is int64
    formatFloat64    = 5, ##(shouldbe called formatDouble), basic type is flaot64
    formatNode       = 6,
   ##[ type is node
       you should pass a pointer to a stack-allocated node value to api, and then call freeNodeContents(addr node).
       do not write data, copy it manually if needed to. check node.format member. properties might change their type
       in future versions of api, or even runtime.

       readableExample:
        var result:node
        if ctx.getProperty("property", formatNode, addr result) < 0:
         echo "error"
        echo "format=", cast[int](result.format)
        freeNodeContents(addr result)

       you should make a node manually, pass pointer to api. api will never write to your data
       (can use any allocation mechanism)

       runnableExample:
        var value: node
        value.format = formatString
        value.u.str = "hello"
        ctx.setProperty("property", formatNone, addr value)
   ]##

    formatNodeArray  = 7, ##used with node (not directly!)
    formatNodeMap    = 8, ##see formatNodeArray
    formatByteArray  = 9  ##raw, untyped byteArray, used with node (used for screenshot-raw command)

  eventID* = enum ##
    eventIDNone              = 0,  ##nothing happened (when timeouts or sporadic wakeups)
    eventIDShutdown          = 1,  ##when player quits, player tries to disconnect all clients but most requests
           ##to player will fail, so client should quit with destroy()
    eventIDLogMessage        = 2,  ##see requestLogMessages()
    eventIDGetPropertyReply  = 3,  ##reply to getPropertyASync(), (see event, eventProperty)
    eventIDSetPropertyReply  = 4,  ##reply to setPropertyAsync(), eventProperty is not used
    eventIDCommandReply      = 5,  ##
    eventIDStartFile         = 6,  ##
    eventIDEndFile           = 7,  ##
    eventIDFileLoaded        = 8,  ##
    eventIDIdle              = 11, ##
    eventIDClientMessage     = 16, ##
    eventIDVideoReConfig     = 17, ##
    eventIDAudioReConfig     = 18, ##
    eventIDSeek              = 20, ##
    eventIDPlayBackRestart   = 21, ##
    eventIDPropertyChange    = 22, ##
    eventIDQueueOverFlow     = 24, ##
    eventIDHook              = 25  ##

  endFileReason* = enum ##
    endFileReasonEOF         = 0, ##reaching end of file. network issues, corrupted packets?
    endFileReasonStop        = 2, ##external action (controls?)
    endFileReasonQuit        = 3, ##quitted
    endFileReasonError       = 4, ##some error made it stop.
    endFileReasonReDirect    = 5  ##playlist endofFile redirect mechanism

  logLevel* = enum ##
    logLevelNone   = 0,  ##no messages
    logLevelFatal  = 10, ##fatal/abortive erres
    logLevelError  = 20, ##simple errors
    logLevelWarn   = 30, ##possible problem warnings
    logLevelInfo   = 40, ##info
    logLevelV      = 50, ##noisy info
    logLevelDebug  = 60, ##more noisy verbose info
    logLevelTrace  = 70  ##extermely verbose

#non-enum types objects
  handle* = distinct pointer ##(private) basic type, used by api to infer the context

  clientUnionType* {.bycopy, union.} = object
    str*: cstring
    flag*, int*: cint
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
 ##

proc getClientName*(ctx: ptr handle): cstring
    {.importc: "mpv_client_name".}
 ##return the unique client handle name

proc cmd*(ctx: ptr handle; args: cstringArray): cint
    {.importc: "mpv_command".}
 ##

proc cmdAsync*(ctx: ptr handle; reply_userdata: cint; args: cstringArray): cint
   {.importc: "mpv_command_async".}
 ##

proc cmdNode*(ctx: ptr handle; args, result: ptr node): cint
    {.importc: "mpv_command_node".}
 ##

proc cmdNodeAsync*(ctx: ptr handle; replyUserData: cint; args: ptr node): cint
   {.importc: "mpv_command_node_async".}
 ##

proc cmdRet*(ctx: ptr handle; args: cstringArray; result: ptr node): cint
    {.importc: "mpv_command_ret".}
 ##

proc cmdString*(ctx: ptr handle; args: cstring): cint
   {.importc: "mpv_command_string".}
 ##

proc create*: ptr handle
    {.importc: "mpv_create".}
 ##create and return a handle used to control the instance

proc createClient*(ctx: ptr handle; name: cstring): ptr handle
    {.importc: "mpv_create_client".}
 ##

proc createWeakClient*(ctx: ptr handle; name: cstring): ptr handle
    {.importc: "mpv_create_weak_client".}
 ##

proc destroy*(ctx: ptr handle)
    {.importc: "mpv_destroy".}
 ##

proc errorString*(error: cint): cstring
    {.importc: "mpv_error_string".}
 ##

proc eventName*(event: eventID): cstring 
   {.importc: "mpv_event_name".}
 ##

proc free*(data: pointer)
    {.importc: "mpv_free".}
 ##

proc freeNodeContents*(node: ptr node)
    {.importc: "mpv_free_node_contents".}
 ##

proc getClientApiVersion*: culong
 {.importc: "mpv_client_api_version".}
 ##return api version of libmpv

proc getProperty*(ctx: ptr handle; name: cstring; format: format; data: pointer): cint 
   {.importc: "mpv_get_property".}
 ##

proc getPropertyAsync*(ctx: ptr handle; replyUserData: cint; name: cstring; format: format): cint
   {.importc: "mpv_get_property_async".}
 ##

proc getPropertyOSDString*(ctx: ptr handle; name: cstring): cstring 
   {.importc: "mpv_get_property_osd_string".}
 ##

proc getPropertyString*(ctx: ptr handle; name: cstring): cstring
   {.importc: "mpv_get_property_string".}
 ##

proc getTimeUS*(ctx: ptr handle): cint
    {.importc: "mpv_get_time_us".}
 ##

proc hookAdd*(ctx: ptr handle; replyUserData: cint; name: cstring; priority: cint): cint
   {.importc: "mpv_hook_add".}
 ##

proc hookContinue*(ctx: ptr handle; id: cint): cint
   {.importc: "mpv_hook_continue".}
 ##

proc initialize*(ctx: ptr handle): cint
    {.importc: "mpv_initialize".}
 ##

proc loadConfigFile*(ctx: ptr handle; filename: cstring): cint
    {.importc: "mpv_load_config_file".}
 ##

proc observeProperty*(mpv: ptr handle; replyUserData: cint; name: cstring; format: format): cint 
   {.importc: "mpv_observe_property".}
 ##

proc requestEvent*(ctx: ptr handle; event: eventID; enable: cint): cint
   {.importc: "mpv_request_event".}
 ##

proc requestLogMsgs*(ctx: ptr handle; min_level: cstring): cint
   {.importc: "mpv_request_log_messages".}
 ##

proc setOption*(ctx: ptr handle; name: cstring; format: format; data: pointer): cint
    {.importc: "mpv_set_option".}
 ##

proc setOptionString*(ctx: ptr handle; name: cstring; data: cstring): cint
    {.importc: "mpv_set_option_string".}
 ##

proc setProperty*(ctx: ptr handle; name: cstring; format: format; data: pointer): cint 
   {.importc: "mpv_set_property".}
 ##

proc setPropertyAsync*(ctx: ptr handle; replyUserData: cint; name: cstring; format: format; data: pointer): cint 
   {.importc: "mpv_set_property_async".}
 ##

proc setPropertyString*(ctx: ptr handle; name: cstring; data: cstring): cint 
   {.importc: "mpv_set_property_string".}
 ##

proc setWakeupCallback*(ctx: ptr handle; cb: proc (d: pointer); d: pointer) 
   {.importc: "mpv_set_wakeup_callback".}
 ##

proc terminateDestroy*(ctx: ptr handle)
    {.importc: "mpv_terminate_destroy".}
 ##

proc unobserveProperty*(mpv: ptr handle; registeredReplyUserData: cint): cint 
   {.importc: "mpv_unobserve_property".}
 ##

proc waitAsyncRequests*(ctx: ptr handle)
   {.importc: "mpv_wait_async_requests".}
 ##

proc waitEvent*(ctx: ptr handle; timeout: cdouble): ptr event
   {.importc: "mpv_wait_event".}
 ##

proc wakeup*(ctx: ptr handle)
   {.importc: "mpv_wakeup".}
 ##

proc checkError*(status: cint) =
 ##unofficial: checks the return value of enclosed function,
 ##if less than 0 quit with failure exit status
 if status < 0:
  echo "mpv API error: ", errorString status
  showCursor()
  quit QuitFailure

{.pop.}
