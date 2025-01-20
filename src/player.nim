import client, utils, terminal, os
export cE  # Export the error-checking macro for external use

type
  PlayerError* = object of CatchableError  # Custom error type for player-related issues
  MediaInfo* = object                      # Structure to hold media player state
    title*: string                         # Current media title
    isIdle*: bool                          # Whether the player is idle
    volume*: int                           # Current volume level
    isMuted*: bool                         # Whether the player is muted
    isPaused*: bool                        # Whether the player is paused

const
  VolumeStep* = 5  # Step size for volume adjustments
  MinVolume* = 0   # Minimum allowed volume
  MaxVolume* = 150 # Maximum allowed volume

proc validateVolume(volume: int): int =
  ## Ensures the volume stays within valid bounds (0-150).
  result = max(MinVolume, min(MaxVolume, volume))

proc init*(ctx: ptr Handle, source: string) {.raises: [PlayerError].} =
  ## Initializes the media player with the given source.
  ##
  ## Args:
  ##   ctx: Player handle
  ##   source: Path to media file or URL
  ##
  ## Raises:
  ##   PlayerError: If initialization fails
  try:
    let fileArgs = allocCStringArray(["loadfile", source])
    defer: deallocCStringArray(fileArgs)

    var oscEnabled = cint(1)
    cE ctx.setOption("osc", fmtFlag, addr oscEnabled)
    cE initialize(ctx)
    cE ctx.cmd(fileArgs)
  except Exception as e:
    raise newException(PlayerError, "Failed to initialize player: " & e.msg)

proc pause*(ctx: ptr Handle, shouldPause: bool) {.raises: [PlayerError].} =
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

proc mute*(ctx: ptr Handle, shouldMute: bool) {.raises: [PlayerError].} =
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

proc adjustVolume*(ctx: ptr Handle, increase: bool): int {.raises: [PlayerError].} =
  ## Adjusts the volume up or down by `VolumeStep`.
  ##
  ## Args:
  ##   ctx: Player handle
  ##   increase: True to increase volume, False to decrease
  ##
  ## Returns:
  ##   New volume level
  try:
    var currentVolume: int
    cE ctx.getProperty("volume", fmtInt64, addr currentVolume)

    var newVolume = validateVolume(
      if increase: currentVolume + VolumeStep
      else: currentVolume - VolumeStep
    )

    cE ctx.setProperty("volume", fmtInt64, addr newVolume)
    result = newVolume
  except Exception as e:
    raise newException(PlayerError, "Failed to adjust volume: " & e.msg)

proc observeMediaTitle*(ctx: ptr Handle) {.raises: [PlayerError].} =
  ## Starts observing changes to the media title.
  ##
  ## Args:
  ##   ctx: Player handle
  try:
    cE ctx.observeProperty(0, "media-title", fmtNone)
  except Exception as e:
    raise newException(PlayerError, "Failed to observe media title: " & e.msg)

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

proc getCurrentMediaTitle*(ctx: ptr Handle): string {.raises: [PlayerError].} =
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
    result = if title != nil: $title else: ""
    result = result.substr(0, int(terminalWidth().toFloat() / 1.65)) & "..."
      #1.65 good factor to stop nowplaying overflow, inc 1.65 if does 
  except Exception as e:
    raise newException(PlayerError, "Failed to get media title: " & e.msg)

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

# Unit tests for player.nim
when isMainModule:
  import unittest

  suite "Player Tests":
    test "validateVolume":
      check validateVolume(-10) == 0
      check validateVolume(50) == 50
      check validateVolume(200) == 150

    test "adjustVolume":
      var ctx: ptr Handle
      init(ctx, "example.mp3")
      let initialVolume = getMediaInfo(ctx).volume
      let newVolume = adjustVolume(ctx, true)
      check newVolume == initialVolume + VolumeStep
      ctx.terminateDestroy()