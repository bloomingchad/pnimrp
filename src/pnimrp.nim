import term, os, terminal, strutils

if not dirExists "assets":
  error "data or config files dont exist"

when defined dragonfly:
  {.error: """PNimRP is not supported under DragonFlyBSD (see user.rst)""".}

hideCursor()

let indx = initIndx()

clear()
say "Poor Mans Radio Player in Nim-lang " & '-'.repeat int terminalWidth() / 8

sayPos 4, "Station Categories:"
sayIter indx[0], ret = false

menu(
  indx[0], #names 
  indx[1], #files
  indx[2]   #dirs
)
