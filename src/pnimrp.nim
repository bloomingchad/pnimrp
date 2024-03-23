import term, os, terminal

if not dirExists "assets":
  error "data or config files dont exist"

when defined dragonfly:
  {.error: """PNimRP is not supported under DragonFlyBSD (see user.rst)""".}

hideCursor()

#let indx = initIndx()

drawMainMenu(
  #indx[0], #names
  #indx[1], #files
  #indx[2]   #dirs
)
