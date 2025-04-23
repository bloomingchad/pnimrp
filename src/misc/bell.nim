# SPDX-License-Identifier: MPL-2.0
import
  os,
  terminal,
  ../audio/mpv/[
    player,
    libmpv
  ]

proc warnBell* =
  ## Plays a warning sound using a temporary MPV instance without interrupting main playback
  var tmpMpvCtx = initGlobalMpv()
  try:
    let assetsDir = getAppDir() / "assets"
    let bellPath = assetsDir / "config" / "sounds" / "bell.ogg"

    # Play sound in temporary instance
    tmpMpvCtx.allocateJobMpv(bellPath)

    # Wait for completion
    var event: ptr Event
    while true:
      event = tmpMpvCtx.waitEvent()
      if event.eventID in {IDEndFile}:
        break

  except Exception as e:
    stderr.writeLine "Warning bell error: ", e.msg
  finally:
    tmpMpvCtx.terminateDestroy()
    hideCursor() #somehow we need this ._.
