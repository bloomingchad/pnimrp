##[
this module contains bindings for libmpvs client.h used to play streams.
module does NOT wrap deprecated functions. first templates, consts, then
types, procedures at last. this module renames procedures so to better
look with language, like seen in SDL2 module.

Please refer to official documentation available in mpv/client.h for most
information, libmpv shall mean official mpv documentation throught.

Cites:
- c2nim -> wrapped most of the non-enum type objects

Imports
-------
* terminal
  - showCursor

Type Context
-------
* ctx: ptr handle
* replyUserData,error: cint
* argsArr: cstringArray
* result, node: ptr node
* argsStr, name: cstring
* data: pointer
* format: format
]##

from terminal import showCursor

when defined posix: {.push dynlib: "libmpv.so".}
when defined windows: {.push dynlib: "mpv-1.dll".}

#templates
template makeVersion*(major, minor: untyped): untyped =
 major shl 16 or minor or 0'u32 ##[
  version is incremented on each change, minor = 16 lower bits, major = 16
  higher bits. when api becomes incompatable with previous, major is
  incremented, affecting only C parts and not properties and options
  (see libmpv/docs/client-api-changes.rst for changelog)
]##

#consts
const clientApiVersion* = makeVersion(1, 107)

#types
type #enums
  error* = enum ##errors codes returned by api procs
    errGeneric              = -20, ##unspecified error
    errNotImplemented       = -19, ##proc called was stub-only

    errUnsupported          = -18, ##(was system requirements met?)
    errUnknownFormat        = -17, ##file format could not be determined
     ##(was file broken?)

    errNothingToPlay        = -16, ##no video/audio to play,
     ##(was a stream selected?)
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
        ##many unanswered asynchronous requests.is api frozen?, is it an api bug? 
    errSuccess              =  0   ##no error occured, '>= 0' means success

  format* = enum ##type for options and properties, can get set properties and
  ##options, support multiple formats

    formatNone       = 0, ##invalid, used for empty values

    formatString     = 1, ##[
     basic type is cstring, returning raw property string, see libmpv/input.rst,
     nil isnt allowed. not always is the encoding in UTF8, atleast on linux,
     but are always in windows (see libmpv/Encoding of Filenames)

     readableExample:
      var result:cstring = nil
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

    formatOSDString  = 2, ##[
     basic type is cstring, returns OSD property string (see libmpv/input.rst),
     mostly its a string, but sometimes is formatted for OSD display, being
     human-readable and not meant to be parsed. is only valid when doing read
     access.
   ]##

    formatFlag       = 3, ##[
     basic type is cint, allowed values are 0=no and 1=yes
     !!like bool!!

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
    formatFloat64    = 5, ##(shouldbe called formatDouble), basic type is float64

    formatNode       = 6, ##[
     type is node. you should pass a pointer to a stack-allocated node value to
     api,and then call freeNodeContents(addr node). do not write data, copy
     it manually if needed to. check node.format member. properties might
     change their type in future versions of api, or even runtime.

     readableExample:
      var result:node
      if ctx.getProperty("property", formatNode, addr result) < 0:
       echo "error"
      echo "format=", cast[int](result.format)
      freeNodeContents(addr result)

     you should make a node manually, pass pointer to api. api will never
     write to your data (can use any allocation mechanism)

     runnableExample:
      var value: node
      value.format = formatString
      value.u.str = "hello"
      ctx.setProperty("property", formatNone, addr value)
   ]##

    formatNodeArray  = 7, ##used with node (not directly!)
    formatNodeMap    = 8, ##see formatNodeArray
    formatByteArray  = 9  ##raw, untyped byteArray, used with node (used for
    ##screenshot-raw command)

  eventID* = enum ##event type
    eventIDNone              = 0,  ##nothing happened (when timeouts or
     ##sporadic wakeups)
    eventIDShutdown          = 1,  ##[ when player quits, it tries to
     disconnect all clients but most requests to player will fail, so
     client should quit with destroy()
    ]##

    eventIDLogMessage        = 2,  ##see requestLogMessages()
    eventIDGetPropertyReply  = 3,  ##reply to getPropertyAsync(),
     ##(see event, eventProperty)

    eventIDSetPropertyReply  = 4,  ##reply to setPropertyAsync(),
     ##eventProperty is not used
    eventIDCommandReply      = 5,  ##reply to commandAsync() or
     ##commandNodeAsync() (see eventID, eventCmd)

    eventIDStartFile         = 6,  ##notification before playback start of
     ##file (before loading)
    eventIDEndFile           = 7,  ##notification after playback ends,after
     ##unloading, see eventID
    eventIDFileLoaded        = 8,  ##notification when file has been
     ##loaded (headers read..)
    eventIDIdle              = 11, ##[
     entered idle mode. now, no file is played and playback core waits
     for commands, (mpv normally quits instead of going idleMode
     (not when --idle)). if ctx strated using create(),
     idleMode is not enabled by default
   ]##

    eventIDClientMessage     = 16, ##[
     triggered by script-message input command, it uses first argument
     of command as clientName (see getclientName()). to dispatch mesage.
     passes all arguments from second arguemnt as strings.
     (see event, ecentClientMessage)
   ]##

    eventIDVideoReConfig     = 17, ##[
     happens when video gets changed. resolution, pixel format or video
     filter changes. event is sent after video filters & VO are
     reconfigured. if using mpv window, app should listen this event
     so to resize window if needed. this can happen sporadically and
     should manually check if video parameters changed
   ]##

    eventIDAudioReConfig     = 18, ##similar as eventIDVideoReConfig
    eventIDSeek              = 20, ##happens when a seek was initiated
     ##and will resume using eventIDPlaybackRestart when seek is finished

    eventIDPlayBackRestart   = 21, ##[
     there was discontinuity like a seek, so playback was reinitialized
     (happens after seeking, chapter switches). mainly allows client
     to detect if seek is finished
    ]##

    eventIDPropertyChange    = 22, ##event sent due to observeProperty().m
     ##see event,eventProperty
    eventIDQueueOverFlow     = 24, ##[
     happens if internal handle ringBuffer OverFlows, then atleast 1
     event has to be dropped, this can happen if client doesnt read
     event queue quickly with waitEvent() or client makes very large
     number of asynchronous calls at once. every delivery will continue
     normally once event gets returned, this forces client to empty queue
  ]##

    eventIDHook              = 25  ##[
     triggered if hook handler was registered with hookAdd()
     and hook is invoked. this must be manually handled and continue
     hook with hookContinue() (see event, eventHook)
    ]##

  endFileReason* = enum ##end file reason enum (since 1.9)
    endFileReasonEOF         = 0, ##reaching end of file. network issues,
     ##corrupted packets?

    endFileReasonStop        = 2, ##external action (controls?)l
    endFileReasonQuit        = 3, ##quitted
    endFileReasonError       = 4, ##some error made it stop.
    endFileReasonReDirect    = 5  ##playlist endofFile redirect mechanism

  logLevel* = enum ##[
   enum describing log level verbosity (see requestLogMessages())
   lower number = more important message, unused values are for future use
  ]##
    logLevelNone   = 0,  ##no messages, never used when receiving messages
    logLevelFatal  = 10, ##fatal/abortive erres
    logLevelError  = 20, ##simple errors
    logLevelWarn   = 30, ##possible problem warnings
    logLevelInfo   = 40, ##info
    logLevelV      = 50, ##noisy info
    logLevelDebug  = 60, ##more noisy verbose info
    logLevelTrace  = 70  ##extermely verbose

#non-enum type objects
  handle* = distinct pointer ##(private) basic type, used by api to
   ##infer the context

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
    numArgs*: cint
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
using
 ctx: ptr handle
 replyUserData,error: cint
 argsArr: cstringArray
 result, node: ptr node
 argsStr, name: cstring
 data: pointer
 format: format

proc abortAsyncCmd*(ctx; replyUserData)
    {.importc: "mpv_abort_async_command".}
 ##

proc getClientName*(ctx): cstring
    {.importc: "mpv_client_name".}
 ##return the unique client handle name

proc cmd*(ctx; argsArr): cint
    {.importc: "mpv_command".}
 ##

proc cmdAsync*(ctx; replyUserData; argsArr): cint
   {.importc: "mpv_command_async".}
 ##

proc cmdNode*(ctx; argsArr; result): cint
    {.importc: "mpv_command_node".}
 ##

proc cmdNodeAsync*(ctx; replyUserData; result): cint
   {.importc: "mpv_command_node_async".}
 ##

proc cmdRet*(ctx; argsArr; result): cint
    {.importc: "mpv_command_ret".}
 ##

proc cmdString*(ctx; argsStr): cint
   {.importc: "mpv_command_string".}
 ##

proc create*: ptr handle
    {.importc: "mpv_create".} ##line 445
 ##create and return a handle used to control the instance

proc createClient*(ctx; name): ptr handle
    {.importc: "mpv_create_client".}
 ##

proc createWeakClient*(ctx; name): ptr handle
    {.importc: "mpv_create_weak_client".}
 ##

proc destroy*(ctx)
    {.importc: "mpv_destroy".}
 ##

proc errorString*(error): cstring
    {.importc: "mpv_error_string".}
 ##

proc eventName*(event: eventID): cstring 
   {.importc: "mpv_event_name".}
 ##

proc free*(data)
    {.importc: "mpv_free".}
 ##

proc freeNodeContents*(node)
    {.importc: "mpv_free_node_contents".}
 ##

proc getClientApiVersion*: culong
 {.importc: "mpv_client_api_version".}
 ##return api version of libmpv

proc getProperty*(ctx; name; format; data): cint
   {.importc: "mpv_get_property".}
 ##

proc getPropertyAsync*(ctx; replyUserData; name; format): cint
   {.importc: "mpv_get_property_async".}
 ##

proc getPropertyOSDString*(ctx; name): cstring
   {.importc: "mpv_get_property_osd_string".}
 ##

proc getPropertyString*(ctx; name): cstring
   {.importc: "mpv_get_property_string".}
 ##

proc getTimeUS*(ctx): cint
    {.importc: "mpv_get_time_us".}
 ##

proc hookAdd*(ctx; replyUserData; name; priority: cint): cint
   {.importc: "mpv_hook_add".}
 ##

proc hookContinue*(ctx; id: cint): cint
   {.importc: "mpv_hook_continue".}
 ##

proc initialize*(ctx): cint
    {.importc: "mpv_initialize".}
 ##

proc loadConfigFile*(ctx; filename: cstring): cint
    {.importc: "mpv_load_config_file".}
 ##

proc observeProperty*(ctx; replyUserData; name; format): cint
   {.importc: "mpv_observe_property".}
 ##

proc requestEvent*(ctx; event: eventID; enable: cint): cint
   {.importc: "mpv_request_event".}
 ##

proc requestLogMsgs*(ctx; minLevel: cstring): cint
   {.importc: "mpv_request_log_messages".}
 ##

proc setOption*(ctx; name; format; data): cint
    {.importc: "mpv_set_option".}
 ##

proc setOptionString*(ctx; name; data: cstring): cint
    {.importc: "mpv_set_option_string".}
 ##

proc setProperty*(ctx; name; format; data): cint
   {.importc: "mpv_set_property".}
 ##

proc setPropertyAsync*(ctx; replyUserData; name; format; data): cint
   {.importc: "mpv_set_property_async".}
 ##

proc setPropertyString*(ctx; name; data: cstring): cint
   {.importc: "mpv_set_property_string".}
 ##

proc setWakeupCallback*(ctx; cb: proc (d: pointer); d: pointer)
   {.importc: "mpv_set_wakeup_callback".}
 ##

proc terminateDestroy*(ctx)
    {.importc: "mpv_terminate_destroy".}
 ##

proc unobserveProperty*(ctx; registeredReplyUserData: cint): cint
   {.importc: "mpv_unobserve_property".}
 ##

proc waitAsyncRequests*(ctx)
   {.importc: "mpv_wait_async_requests".}
 ##

proc waitEvent*(ctx; timeout: cdouble): ptr event
   {.importc: "mpv_wait_event".}
 ##

proc wakeup*(ctx)
 {.importc: "mpv_wakeup".} ##[
  interrupt current waitEvent(), this will wakeup thread currently
  waiting in waitEvent(). waiting thread is woken up. if no thread is
  waiting, next waitEvent() will return to avoid lost wakeups. waitEvent()
  will get a eventNone if woken up due to this call. but this dummy
  event might by skipped if there are others queued
 ]##

proc checkError*(status: cint) = ##[
  unofficial: checks the return value of input proc,
  quit with failure exit status if less than 0
 ]##
 if status < 0:
  echo "mpv API error: ", errorString status
  showCursor()
  quit QuitFailure

{.pop.}
