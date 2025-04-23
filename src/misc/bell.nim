# SPDX-License-Identifier: MPL-2.0
import
  os,
  terminal,
  ../audio/mpv/[
    player,
    libmpv
  ]

template milSecToSec(ms: int): float = ms / 1000

const
  KeyTimeout = 25
  mpvEventLoopTimeout = KeyTimeout.milSecToSec()

proc warnBell* =
  #dont interrupt main player
  var tmpMpvCtx = initGlobalMpv()
  try:
    let assetsDir = getAppDir() / "assets"
    let bellPath = assetsDir / "config" / "sounds" / "bell.ogg"

    tmpMpvCtx.allocateJobMpv(bellPath)

    var event: ptr Event
    while true:
      event = tmpMpvCtx.waitEvent(mpvEventLoopTimeout)
      if event.eventID in {IDEndFile}:
        break

  except Exception as e:
    stderr.writeLine "Warning bell error: ", e.msg
  finally:
    tmpMpvCtx.terminateDestroy()
    hideCursor() #somehow we need this ._.
