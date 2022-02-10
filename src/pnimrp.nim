import term, os, terminal, notes, strutils

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
 files.add file
 var ProcessingFile = file
 ProcessingFile.removePrefix "assets/"
 ProcessingFile[0] = toUpperAscii(ProcessingFile[0])
 ProcessingFile.removeSuffix ".json"
 if not(ProcessingFile == "Qoute") or
  not(ProcessingFile == "Prot"):
   names.add ProcessingFile
names.add "Quit"

while true:
  clear()
  say "Poor Mans Radio Player in Nim-lang " & '-'.repeat int terminalWidth() / 8
  sayPos 4,"Station Categories:"
  sayIter names
  var j = false
  #add tryblock to catch defect
  while true:
    case getch():
      of '1':
        menu names[0], files[0]
        break
      of '2':
        menu names[1], files[1]
        break
      of '3':
        menu names[2], files[2]
        break
      of '4':
        menu names[3], files[3]
        break
      of '5':
        menu names[4], files[4]
        break
      of '6':
        menu names[5], files[5]
        break
      of '7':
        menu names[6], files[6]
        break
      of '8':
        menu names[7], files[7]
        break
      of '9':
        menu names[8], files[8]
        break
      of 'A','a':
        menu names[9], files[9]
        break
      of 'B','b':
        menu names[10], files[10]
        break
      of 'C','c':
        menu names[11], files[11]
        break
      of 'D','d':
        menu names[12], files[12]
        break
      of 'E','e':
        menu names[13], files[13]
        break
      of 'F','f':
        menu names[14], files[14]
        break
      of 'N', 'n':
       notes()
       break
      of 'q', 'Q':
        exitEcho()
      else: inv()
