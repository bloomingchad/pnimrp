from os import fileExists,findExe,dirExists
from strformat import fmt
from terminal import showCursor,hideCursor

proc checkFileIter*(x:seq[string]):bool =
 var i:uint8 = 0
 for f in x:
  if fileExists fmt"pnimrp.d/{x[i]}.json": inc i
  else: return false
 return true

proc init* =
 var amog = @["fm181/comedy181","fm181/easy181","fm181/latin181","fm181/oldies181",
 "fm181/rock181","fm181/country181","fm181/eight181","fm181/nine181","fm181/pop181","fm181/urban181"]

 if not dirExists("pnimrp.d") or not checkFileIter(amog):
  echo "data and config files dont exist"
  quit QuitFailure

 hideCursor()
