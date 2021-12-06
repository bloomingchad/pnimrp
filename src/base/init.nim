from os import fileExists,findExe,dirExists
from strformat import fmt
from terminal import showCursor,hideCursor
import term

proc checkFileIter(x:seq[string]):bool =
 for f in x:
  if not fileExists fmt"assets/{f}.json": return false
 return true

proc init* =
 #remove checking files?
 var amog = @["blues","bollywood","classical","country","electronic",
 "fm181/comedy181","fm181/easy181","fm181/latin181","fm181/oldies181",
 "fm181/rock181","fm181/country181","fm181/eight181","fm181/nine181",
 "fm181/pop181","fm181/urban181","fm181/techno181","hits","jazz",
 "listener/listener1","listener/listener2","listener/listener3",
 "listener/listener4","metal","news","oldies","reggae","rock",
 "soma/soma1","soma/soma2","soma/soma3","urban"]

 if not dirExists("assets") or not checkFileIter(amog):
  error "data or config files dont exist"

 #disable volControl in koch?
 when defined(linux) and not defined(android):
  if findExe("amixer") == "":
   error "alsa mixer utilities not found. please install it for volume control"

 when defined dragonfly:
  {.error: """PNimRP is not supported under DragonFlyBSD
  Please see user.rst for more information""".}

 hideCursor()
