import client

using
  ctx: ptr Handle

proc init*(ctx; parm: string) =
  let file = allocCStringArray ["loadfile", parm] #couldbe file,link,parm
  var val: cint = 1
  cE ctx.setOption("osc", fmtFlag, addr val)
  cE initialize ctx
  cE ctx.cmd file

proc pause*(ctx; a: bool) =
  var val: cint = if a: 1 else: 0
  cE ctx.setProperty("pause", fmtFlag, addr val)

proc mute*(ctx; a: bool) =
  var val: cint = if a: 1 else: 0
  cE ctx.setProperty("mute", fmtFlag, addr val)

proc volume*(ctx; a: bool): cint =
  var volumeChanged: cint
  cE ctx.getProperty("volume", fmtInt64,
      addr volumeChanged)
  if a: volumeChanged += 5 else: volumeChanged -= 5
  cE ctx.setProperty("volume", fmtInt64, addr volumeChanged)
  volumeChanged

proc seeIfSongTitleChanges*(ctx) =
  cE ctx.observeProperty(0, "media-title", fmtNone)

proc seeIfCoreIsIdling*(ctx): cint =
  cE ctx.getProperty("idle-active", fmtFlag, addr result)

proc getCurrentSongv2*(ctx): cstring =
  cE ctx.getProperty("media-title", fmtString, addr result)

export cE
