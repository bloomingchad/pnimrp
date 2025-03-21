import ../audio/[libmpv, player], os

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

