import client

template cE*(s: cint) = checkError s

proc init*(ctx: ptr Handle, parm: string) =
  let file = allocCStringArray ["loadfile", parm] #couldbe file,link,parm
  var val: cint = 1
  cE ctx.setOption("osc", fmtFlag, addr val)
  cE initialize ctx
  cE ctx.cmd file
proc pause*(ctx: ptr Handle; a: bool) =
  var val: cint = if a: 1 else: 0
  cE ctx.setProperty("pause", fmtFlag, addr val)

proc mute*(ctx: ptr Handle; a: bool) =
  var val: cint = if a: 1 else: 0
  cE ctx.setProperty("mute", fmtFlag, addr val)

proc volume*(ctx: ptr Handle, a: bool): cint =
  var volumeChanged: cint
  cE ctx.getProperty("volume", fmtInt64,
      addr volumeChanged)
  if a: volumeChanged += 5 else: volumeChanged -= 5
  cE ctx.setProperty("volume", fmtInt64, addr volumeChanged)
  volumeChanged
