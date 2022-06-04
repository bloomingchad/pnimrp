import term, os, terminal, strutils

if not dirExists "assets":
  error "data or config files dont exist"

#disable volControl in koch?
when defined(linux) and not defined(android):
  if findExe("amixer") == "":
    error "install alsa mixer utils for volume control"

when defined dragonfly:
  {.error: """PNimRP is not supported under DragonFlyBSD (see user.rst)""".}

hideCursor()

let
  indx = initIndx()
  names = indx[0]
  files = indx[1]
  dirs = indx[2]

clear()
say "Poor Mans Radio Player in Nim-lang " & '-'.repeat int terminalWidth() / 8
sayPos 4,"Station Categories:"
sayIter names, ret = false
menu(names, files, dirs)
