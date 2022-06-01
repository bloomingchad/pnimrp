import term, os, terminal, strutils, parseutils

if not dirExists "assets":
  error "data or config files dont exist"

#disable volControl in koch?
when defined(linux) and not defined(android):
  if findExe("amixer") == "":
    error "install alsa mixer utils for volume control"

when defined dragonfly:
  {.error: """PNimRP is not supported under DragonFlyBSD
  Please see user.rst for more information""".}

hideCursor()

var files, names: seq[string]

for file in walkFiles "assets/*":
  if file != "assets/qoute.json":
    files.add file
  var procFile = file
  procFile.removePrefix "assets/"
  procFile[0] = procFile[0].toUpperAscii
  procFile.removeSuffix ".json"
  if procFile != "Qoute":
    names.add procFile

names.add "Notes"

var dirs: seq[string]

for dir in walkDirs "assets/*":
  var procDir = dir
  procDir.removePrefix "assets/"
  procDir.suffix("/")
  if not(procDir[0].isUpperAscii()):
    discard parseChar($procDir[0].toUpperAscii(), procDir[0])
  dirs.add procDir

clear()
say "Poor Mans Radio Player in Nim-lang " & '-'.repeat int terminalWidth() / 8
sayPos 4,"Station Categories:"
sayIter names, ret = false
menu(names, files, dirs, mainScreen = true)
