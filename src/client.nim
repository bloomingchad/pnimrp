##[
This module binds libmpv's client.h which is used to play streams.

.. warning::
  - module does NOT wrap deprecated functions.

.. note::
  - this module renames procedures to camelCase (eg. sdl2 module)
  - please refer to official documentation available in mpv/client.h for
    most information
  - Cites and Tools Used:
    - c2nim -> wrapped most of objects
  - order of code:
    - templates > consts > types > procedures

Imports
-------
* terminal
  - showCursor

Type Context
------------
.. code-block:: nim
  - ctx: ptr Handle
  - replyUserData,error: cint
  - argsArr: cstringArray
  - result, Node: ptr Node
  - argsStr, name: cstring
  - data: pointer
  - format: format

Terms Used
----------
- libmpv > official mpv documentation
- isStaticConst > it returns static const string
     (needless of dealloc() & is always valid)
     !!making static is not implemented yet!!
]##

from terminal import showCursor

const dynlibName =
  when defined windows: "mpv-1.dll"
  elif defined(macos) or defined(macosx): "libmpv.dylib" #havent tested
  else: "libmpv.so"

{.push dynlib: dynlibName.}

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
  Error* = enum ##errors codes returned by api procs
    errGeneric              = -20, ##unspecified error
    errNotImplemented       = -19, ##proc called was stub-only

    errUnsupported          = -18, ##(was system requirements met?)
    errUnknownFormat        = -17, ##file format could not be determined
     ##(was file broken?)

    errNothingToPlay        = -16, ##no video/audio to play,
     ##(was a stream selected?)
    errVOInitFailed         = -15, ##failed to init video output

    errAOInitFailed         = -14, ##failed to init audio output
    errLoadFailed           = -13, ##loading failed (used with EventEndFile.error)

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
    errEventQueueFull       = -1,  ##client is choked & cant receive any Events.
        ##many unanswered asynchronous requests.is api frozen?, is it an api bug? 
    errSuccess              =  0   ##no error occured, '>= 0' means success

  Format* = enum ##type for options and properties, can get set properties and
  ##options, support multiple formats

    fmtNone       = 0, ##invalid, used for empty values

    fmtString     = 1, ##[
     basic type is cstring, returning raw property string, see libmpv/input.rst,
     nil isnt allowed. not always is the encoding in UTF8, atleast on linux,
     but are always in windows (see libmpv/Encoding of Filenames)

     readableExample:
      var result: cstring = nil
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

    fmtOSDString  = 2, ##[
     basic type is cstring, returns OSD property string (see libmpv/input.rst),
     mostly its a string, but sometimes is formatted for OSD display, being
     human-readable and not meant to be parsed. is only valid when doing read
     access.
   ]##

    fmtFlag       = 3, ##[
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

    fmtInt64      = 4, ##basic type is int64
    fmtFloat64    = 5, ##(shouldbe called formatDouble), basic type is float64

    fmtNode       = 6, ##[
     type is Node. you should pass a pointer to a stack-allocated Node value to
     api,and then call freeNodeContents(addr Node). do not write data, copy
     it manually if needed to. check Node.format member. properties might
     change their type in future versions of api, or even runtime.

     readableExample:
      var result:Node
      if ctx.getProperty("property", formatNode, addr result) < 0:
       echo "error"
      echo "format=", cast[int](result.format)
      freeNodeContents(addr result)

     you should make a Node manually, pass pointer to api. api will never
     write to your data (can use any allocation mechanism)

     runnableExample:
      var value: Node
      value.format = formatString
      value.u.str = "hello"
      ctx.setProperty("property", formatNone, addr value)
   ]##

    fmtNodeArray  = 7, ##used with Node (not directly!)
    fmtNodeMap    = 8, ##see formatNodeArray
    fmtByteArray  = 9  ##raw, untyped byteArray, used with Node (used for
    ##screenshot-raw command)

  EventID* = enum ##Event type
    IDNone              = 0,  ##nothing happened (when timeouts or
     ##sporadic wakeups)
    IDShutdown          = 1,  ##[ when player quits, it tries to
     disconnect all clients but most requests to player will fail, so
     client should quit with destroy()
    ]##

    IDLogMessage        = 2,  ##see requestLogMessages()
    IDGetPropertyReply  = 3,  ##reply to getPropertyAsync(),
     ##(see Event, EventProperty)

    IDSetPropertyReply  = 4,  ##reply to setPropertyAsync(),
     ##EventProperty is not used
    IDCommandReply      = 5,  ##reply to commandAsync() or
     ##commandNodeAsync() (see EventID, EventCmd)

    IDStartFile         = 6,  ##notification before playback start of
     ##file (before loading)
    IDEndFile           = 7,  ##notification after playback ends,after
     ##unloading, see EventID
    IDFileLoaded        = 8,  ##notification when file has been
     ##loaded (headers read..)

    IDClientMessage     = 16, ##[
     triggered by script-message input command, it uses first argument
     of command as clientName (see getclientName()). to dispatch mesage.
     passes all arguments from second arguemnt as strings.
     (see Event, ecentClientMessage)
   ]##

    IDVideoReConfig     = 17, ##[
     happens when video gets changed. resolution, pixel format or video
     filter changes. Event is sent after video filters & VO are
     reconfigured. if using mpv window, app should listen this Event
     so to resize window if needed. this can happen sporadically and
     should manually check if video parameters changed
   ]##

    IDAudioReConfig     = 18, ##similar as EventIDVideoReConfig
    IDSeek              = 20, ##happens when a seek was initiated
     ##and will resume using EventIDPlaybackRestart when seek is finished

    IDPlayBackRestart   = 21, ##[
     there was discontinuity like a seek, so playback was reinitialized
     (happens after seeking, chapter switches). mainly allows client
     to detect if seek is finished
    ]##

    IDEventPropertyChange    = 22, ##Event sent due to observeProperty().m
     ##see Event,EventProperty
    IDQueueOverFlow          = 24, ##[
     happens if internal Handle ringBuffer OverFlows, then atleast 1
     Event has to be dropped, this can happen if client doesnt read
     Event queue quickly with waitEvent() or client makes very large
     number of asynchronous calls at once. every delivery will continue
     normally once Event gets returned, this forces client to empty queue
  ]##

    IDEventHook              = 25  ##[
     triggered if hook Handler was registered with hookAdd()
     and hook is invoked. this must be manually Handled and continue
     hook with hookContinue() (see Event, EventHook)
    ]##

  EndFileReason* = enum ##end file reason enum (since 1.9)
    efrEOF         = 0, ##reaching end of file. network issues,
     ##corrupted packets?

    efrStop        = 2, ##external action (controls?)l
    efrQuit        = 3, ##quitted
    efrError       = 4, ##some error made it stop.
    efrReDirect    = 5  ##playlist endofFile redirect mechanism

  LogLevel* = enum ##[
   enum describing log level verbosity (see requestLogMessages())
   lower number = more important message, unused values are for future use
  ]##
    llNone   = 0,  ##no messages, never used when receiving messages
    llFatal  = 10, ##fatal/abortive erres
    llError  = 20, ##simple errors
    llWarn   = 30, ##possible problem warnings
    llInfo   = 40, ##info
    llV      = 50, ##noisy info
    llDebug  = 60, ##more noisy verbose info
    llTrace  = 70  ##extermely verbose

#non-enum type objects
  Handle* = distinct pointer ##(private) basic type, used by api to
   ##infer the context

  ClientUnionType* {.bycopy, union.} = object
    str*: cstring
    flag*, int*: cint
    double*: cdouble
    list*: ptr NodeList
    ba*: ptr ByteArray

  Node* {.bycopy.} = object
    u*: ClientUnionType
    format*: Format

  NodeList* {.bycopy.} = object
    num*: cint
    values*: ptr Node
    keys*: cstringArray

  ByteArray* {.bycopy.} = object
    data*: pointer
    size*: csize_t

  EventProperty* {.bycopy.} = object
    name*: cstring
    format*: Format
    data*: pointer

  EventLogMessage* {.bycopy.} = object
    prefix*, level*, text*: cstring
    logLevel*: LogLevel

  EventEndFile* {.bycopy.} = object
    reason*, error*: cint

  EventClientMessage* {.bycopy.} = object
    numArgs*: cint
    args*: cstringArray

  EventHook* {.bycopy.} = object
    name*: cstring
    id*: cint

  EventCmd* {.bycopy.} = object
    result*: Node

  Event* {.bycopy.} = object
    eventID*: EventID
    error*: int
    replyUserData*: uint64
    data*: pointer

#procs
using
  ctx: ptr Handle
  replyUserData: uint64
  error: cint
  argsArr: cstringArray
  result, node: ptr Node
  argsStr, name: cstring
  data: pointer
  fmt: Format

proc abortAsyncCmd*(ctx; replyUserData)
    {.importc: "mpv_abort_async_command".}

#{.push discardable.}
proc cmd*(ctx; argsArr): cint
    {.importc: "mpv_command".}

proc cmdAsync*(ctx; replyUserData; argsArr): cint
    {.importc: "mpv_command_async".}

proc cmdNode*(ctx; argsArr; result): cint
    {.importc: "mpv_command_node".}

proc cmdNodeAsync*(ctx; replyUserData; result): cint
    {.importc: "mpv_command_node_async".}

proc cmdRet*(ctx; argsArr; result): cint
    {.importc: "mpv_command_ret".}

proc cmdString*(ctx; argsStr): cint
    {.importc: "mpv_command_string".}

#{.pop.}
proc create*: ptr Handle
    {.importc: "mpv_create".} ##[
  create and return a Handle used to control the instance
  instance is in preinitialized state. and needs more initialisation
  for use with other procs. (see errUnitialised, libmpv/examples/simple.c)
  this gives more control over configuration. (see more..)
  NO concurrent accesses on uninitialised Handle.
  returns nil when out of memory
 ]##

proc createClient*(ctx; name): ptr Handle
    {.importc: "mpv_create_client".}

proc createWeakClient*(ctx; name): ptr Handle
    {.importc: "mpv_create_weak_client".}

proc destroy*(ctx)
    {.importc: "mpv_destroy".}
  ##finish the Handle, ctx will be deallocated.

proc errorString*(error): cstring
    {.importc: "mpv_error_string".} ##[
  return string describing error, if unknown: returns "unknown string",
  isStaticConst, (see error: enum)
 ]##

proc eventName*(Event: EventID): cstring
    {.importc: "mpv_event_name".}

proc free*(data)
    {.importc: "mpv_free".} ##[
  general proc to dealloc() returned by api procs. !!explicitly used!!,
  if called on not mpv's memory: undefined behavoiur happens
  valid pointer returned or nil
 ]##

proc freeNodeContents*(node)
    {.importc: "mpv_free_node_contents".}

proc getClientApiVersion*: culong
    {.importc: "mpv_client_api_version".}
 ##return api version of libmpv

proc getClientName*(ctx): cstring
    {.importc: "mpv_client_name".}
 ##return the unique client Handle name. isStaticConst

proc getProperty*(ctx; name; fmt; data): cint
    {.importc: "mpv_get_property".}

proc getPropertyAsync*(ctx; replyUserData; name; fmt): cint
    {.importc: "mpv_get_property_async".}

proc getPropertyOSDString*(ctx; name): cstring
    {.importc: "mpv_get_property_osd_string".}

proc getPropertyString*(ctx; name): cstring
    {.importc: "mpv_get_property_string".}

proc getTimeUS*(ctx): cint
    {.importc: "mpv_get_time_us".}

proc hookAdd*(ctx; replyUserData; name; priority: cint): cint
    {.importc: "mpv_hook_add".}

proc hookContinue*(ctx; id: cint): cint
    {.importc: "mpv_hook_continue".}

proc initialize*(ctx): cint
    {.importc: "mpv_initialize".} ##[
  initialise a preinit instance. error returned if instance is running,
  very important proc for usage if used create() to preinit
 ]##

#{.push discardable.}

proc loadConfigFile*(ctx; filename: cstring): cint
    {.importc: "mpv_load_config_file".}

proc observeProperty*(ctx; replyUserData; name; fmt): cint
    {.importc: "mpv_observe_property".}

proc requestEvent*(ctx; Event: EventID; enable: cint): cint
    {.importc: "mpv_request_event".}

proc requestLogMsgs*(ctx; minLevel: cstring): cint
    {.importc: "mpv_request_log_messages".}

proc setOption*(ctx; name; fmt; data): cint
    {.importc: "mpv_set_option".}

proc setOptionString*(ctx; name; data: cstring): cint
    {.importc: "mpv_set_option_string".}

proc setProperty*(ctx; name; fmt; data): cint
    {.importc: "mpv_set_property".}

proc setPropertyAsync*(ctx; replyUserData; name; fmt; data): cint
    {.importc: "mpv_set_property_async".}

proc setPropertyString*(ctx; name; data: cstring): cint
    {.importc: "mpv_set_property_string".}

proc setWakeupCallback*(ctx; cb: proc (d: pointer); d: pointer)
    {.importc: "mpv_set_wakeup_callback".}

proc terminateDestroy*(ctx)
    {.importc: "mpv_terminate_destroy".}

proc unobserveProperty*(ctx; registeredReplyUserData: uint64): cint
    {.importc: "mpv_unobserve_property".}

#{.pop.}
proc waitAsyncRequests*(ctx)
    {.importc: "mpv_wait_async_requests".}

proc waitEvent*(ctx; timeout: cdouble = 0): ptr Event
    {.importc: "mpv_wait_event".}

proc wakeup*(ctx)
    {.importc: "mpv_wakeup".} ##[
  interrupt current waitEvent(), this will wakeup thread currently
  waiting in waitEvent(). waiting thread is woken up. if no thread is
  waiting, next waitEvent() will return to avoid lost wakeups. waitEvent()
  will get a EventNone if woken up due to this call. but this dummy
  Event might by skipped if there are others queued
 ]##

proc checkError*(status: cint) = ##[
  unofficial: checks the return value of input proc,
  quit with failure exit status if less than 0
 ]##
 if status < 0:
   showCursor()
   raise newException(CatchableError, "mpv API error: " & $errorString status)

{.pop.}
