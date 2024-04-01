import os, terminal, src/[ui, menu]

if not dirExists getAppDir() & "/assets":
  error "data or config files dont exist"

when defined dragonfly:
  {.error: """PNimRP is not supported under DragonFlyBSD (see user.rst)""".}

hideCursor()

drawMainMenu()
