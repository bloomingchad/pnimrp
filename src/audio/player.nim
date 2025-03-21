# player.nim

import libmpv, os
export cE # Export the error-checking macro for external use

type
  PlayerError* = object of CatchableError # Custom error type for player-related issues
  MediaInfo* = object # Structure to hold media player state
    title*: string    # Current media title
    isIdle*: bool     # Whether the player is idle
    volume*: int      # Current volume level
    isMuted*: bool    # Whether the player is muted
    isPaused*: bool   # Whether the player is paused

const
  VolumeStep* = 5  # Step size for volume adjustments
  MinVolume* = 0   # Minimum allowed volume
  MaxVolume* = 150 # Maximum allowed volume

var lastVolume* {.global.} = 100 # Default volume is 100
var fullMediaTitle* {.global.} = ""
var mpvCtx* {.global.}: ptr Handle

proc validateVolume(volume: int): int =
  ## Ensures the volume stays within valid bounds (0-150).
  result = max(MinVolume, min(MaxVolume, volume))

proc setAllyOptionsToMpv(ctx: ptr Handle) =
  # Core audio settings
  cE mpvCtx.setOptionString("audio-display", "no")
  cE mpvCtx.setOptionString("vid", "no")
  cE mpvCtx.setOptionString("vo", "null")
  cE mpvCtx.setOptionString("audio-stream-silence", "yes")
  cE mpvCtx.setOptionString("gapless-audio", "weak")
  cE mpvCtx.setOptionString("audio-fallback-to-null", "no")

  # Network configuration
  var netTimeout = 5.0
  cE mpvCtx.setOption("network-timeout", fmtFloat64, netTimeout.addr)
  cE mpvCtx.setOptionString("demuxer-lavf-o", "reconnect=1,reconnect_streamed=1,reconnect_delay_max=5")
  cE mpvCtx.setOptionString("user-agent", "pnimrp/0.1")

  # Performance settings
  cE mpvCtx.setOptionString("ytdl", "no")
  cE mpvCtx.setOptionString("demuxer-thread", "yes")

  # Audio processing
  cE mpvCtx.setOptionString("audio-normalize-downmix", "yes")
  cE mpvCtx.setOptionString("volume-max", "150")
  var replayGain = 6.0
  cE mpvCtx.setOption("replaygain-preamp", fmtFloat64, replayGain.addr)

  # Terminal/interface settings
  cE mpvCtx.setOptionString("terminal", "yes")
  cE mpvCtx.setOptionString("really-quiet", "yes")
  cE mpvCtx.setOptionString("osd-level", "0") # Disable OSD completely

    # Input controls
  cE mpvCtx.setOptionString("input-default-bindings", "no")
  cE mpvCtx.setOptionString("input-vo-keyboard", "no")
  cE mpvCtx.setOptionString("input-media-keys", "no")

  cE mpvCtx.setOptionString("demuxer-max-bytes", "2097152") #2MB #thanks to github.com/florianjacob
  cE mpvCtx.setOptionString("demuxer-max-back-bytes", "2097152") #see https://github.com/mpv-player/mpv/issues/5359

proc initGlobalMpv* =
  try:
    mpvCtx = create()

    mpvCtx.setAllyOptionsToMpv()

    # Initialize MPV context
    cE mpvCtx.initialize()

  except Exception as e:
    raise newException(PlayerError, "MPV initialization failed: " & e.msg)

proc allocateJobMpv*(source: string; mpvCtx = mpvCtx) =
  let fileArgs = allocCStringArray(["loadfile", source])
  try:
    cE mpvCtx.cmd(fileArgs)
  finally:
    deallocCStringArray(fileArgs)

proc stopCurrentJob* =
  let cmdArgs = allocCStringArray(["stop"])
  #discard mpvCtx.waitEvent(1)
  try:
    cE mpvCtx.cmd(cmdArgs)
  finally:
    deallocCStringArray(cmdArgs)

proc pause*(ctx: ptr Handle; shouldPause: bool) {.raises: [PlayerError].} =
  ## Toggles the pause state of the player.
  ##
  ## Args:
  ##   ctx: Player handle
  ##   shouldPause: True to pause, False to play
  try:
    var pauseState = cint(shouldPause)
    cE ctx.setProperty("pause", fmtFlag, addr pauseState)
  except Exception as e:
    raise newException(PlayerError, "Failed to set pause state: " & e.msg)

proc mute*(ctx: ptr Handle; shouldMute: bool) {.raises: [PlayerError].} =
  ## Toggles the mute state of the player.
  ##
  ## Args:
  ##   ctx: Player handle
  ##   shouldMute: True to mute, False to unmute
  try:
    var muteState = cint(shouldMute)
    cE ctx.setProperty("mute", fmtFlag, addr muteState)
  except Exception as e:
    raise newException(PlayerError, "Failed to set mute state: " & e.msg)

proc observeMediaTitle*(ctx: ptr Handle) {.raises: [PlayerError].} =
  ## Starts observing changes to the media title.
  ##
  ## Args:
  ##   ctx: Player handle
  try:
    cE ctx.observeProperty(0, "media-title", fmtNone)
  except Exception as e:
    raise newException(PlayerError, "Failed to observe media title: " & e.msg)

proc observeMetadata*(ctx: ptr Handle) {.raises: [PlayerError].} =
  try:
    cE ctx.observeProperty(0, "metadata", fmtNone)
  except Exception as e:
    raise newException(PlayerError, "Failed to observe metadata: " & e.msg)

proc isIdle*(ctx: ptr Handle): bool {.raises: [PlayerError].} =
  ## Checks if the player is currently idle.
  ##
  ## Args:
  ##   ctx: Player handle
  ##
  ## Returns:
  ##   True if the player is idle, False otherwise
  try:
    var idleState: cint
    cE ctx.getProperty("idle-active", fmtFlag, addr idleState)
    result = bool(idleState)
  except Exception as e:
    raise newException(PlayerError, "Failed to check idle state: " & e.msg)

proc getCurrentMediaTitle*(ctx: ptr Handle): string {.raises: [].} =
  ## Retrieves the current media title.
  ##
  ## Args:
  ##   ctx: Player handle
  ##
  ## Returns:
  ##   Current media title or an empty string if none
  try:
    var title: cstring
    cE ctx.getProperty("media-title", fmtString, addr title)

    # Convert the cstring to a Nim string immediately to ensure GC safety
    result = if title != nil: $title else: ""
    fullMediaTitle = result

    # Free the cstring allocated by libmpv
    if title != nil:
      libmpv.free(title)

  except Exception: #as e:
    #raise newException(PlayerError, "Failed to get media title: " & e.msg)
    discard

proc getMediaInfo*(ctx: ptr Handle): MediaInfo {.raises: [PlayerError].} =
  ## Retrieves comprehensive information about the media player's current state.
  ##
  ## Args:
  ##   ctx: Player handle
  ##
  ## Returns:
  ##   MediaInfo object containing the current player state
  try:
    var
      volume: int
      muteState: cint
      pauseState: cint

    cE ctx.getProperty("volume", fmtInt64, addr volume)
    cE ctx.getProperty("mute", fmtFlag, addr muteState)
    cE ctx.getProperty("pause", fmtFlag, addr pauseState)

    result = MediaInfo(
      title: getCurrentMediaTitle(ctx),
      isIdle: isIdle(ctx),
      volume: volume,
      isMuted: bool(muteState),
      isPaused: bool(pauseState)
    )

  except Exception as e:
    raise newException(PlayerError, "Failed to get media info: " & e.msg)

proc setVolumeOfBellRelativeToMainCtx(tmpMpv: ptr Handle) =
  #set 1.5 times the last vol
  var newVolume = cstring $(float(lastVolume) * 1.5)
  cE tmpMpv.setOptionString("volume", newVolume)
    #some platforms will might cmplain about type error and cause `mpv API error:`
    #by having the cost of string conversions, we are offloading the dirty work
    #to libmpv, which is very robust

proc warnBell* =
  ## Plays a warning sound using a temporary MPV instance without interrupting main playback
  var tmpMpv: ptr Handle
  try:
    # Create temporary MPV instance
    tmpMpv = create()

    # Global Config for bell playback
    tmpMpv.setAllyOptionsToMpv()

    # Set volume relative to currentVol directly on temporary instance
    tmpMpv.setVolumeOfBellRelativeToMainCtx()
    cE tmpMpv.initialize()

    let assetsDir = getAppDir() / "assets"
    let bellPath = assetsDir / "config" / "sounds" / "bell.ogg"

    # Play sound in temporary instance
    allocateJobMpv(bellPath, tmpMpv)

    # Wait for completion
    var event: ptr Event
    while true:
      event = tmpMpv.waitEvent()
      if event.eventID in {IDEndFile}:
        break

  except Exception as e:
    stderr.writeLine "Warning bell error: ", e.msg
  finally:
    tmpMpv.destroy()
