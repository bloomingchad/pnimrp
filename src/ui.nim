import
  terminal, client, random,
  json, strutils, os

proc clear* =
  eraseScreen()
  setCursorPos 0, 0

proc error*(str: string) =
  styledEcho fgRed, "Error: ", str
  quit QuitFailure

proc parseJArray*(file: string): seq[string] =
  try:
    result = to(
      parseJson(readFile(file)){"pnimrp"},
      seq[string]
    )
  except IOError: error "base assets dont exist?"

  if result.len mod 2 != 0:
    error "JArrayResult.len not even"

proc exitEcho* =
  showCursor()
  echo ""
  randomize()

  let seq = parseJArray getAppDir() / "assets" / "qoute.json"
  var qoutes, authors: seq[string] = @[]

  for i in 0 .. seq.high:
    case i mod 2:
      of 0: qoutes.add seq[i]
      else: authors.add seq[i]

  let rand = rand 0 .. qoutes.high

  when not defined(release) or
    not defined(danger):
    echo ("free mem: " & $(getFreeMem() / 1024)) & " kB"
    echo ("total/max mem: " & $(getTotalMem() / 1024)) & " kB"
    echo ("occupied mem: " & $(getOccupiedMem() / 1024)) & " kB"

  if qoutes[rand] == "": error "no qoute"

  styledEcho fgCyan, qoutes[rand], "..."
  setCursorXPos 15
  styledEcho fgGreen, "—", authors[rand]

  if authors[rand] == "":
    error "there can no be qoute without man"
    if rand*2 != -1:
      error ("@ line: " & $(rand*2)) & " in qoute.json"

  quit QuitSuccess

proc say*(txt: string; color = fgYellow; x = 5; echo = true) =
  if color == fgBlue: setCursorXPos x
  if color == fgGreen:
    setCursorXPos x
    if echo: styledEcho fgGreen, txt
    else: stdout.styledWrite fgGreen, txt
  else: styledEcho color, txt #fgBlue would get true here

proc sayIter(txt: string) =
  for f in splitLines txt:
    say f, fgBlue

proc sayIter*(txt: seq[string]; ret = true) =
  const chars =
    @[
      '1', '2', '3', '4', '5',
      '6', '7', '8', '9', 'A',
      'B', 'C', 'D', 'E', 'F',
      'G', 'H', 'I', 'J', 'K',
      'L', 'M', 'N', 'O', 'P',
      'Q', 'R', 'S', 'T', 'U',
      'V', 'W', 'X', 'Y', 'Z'
    ]
  var num = 0
  for f in txt:
    if f != "Notes": say ($chars[num] & " ") & f, fgBlue
    else: say "N Notes", fgBlue
    inc num
  if ret: say "R Return", fgBlue
  say "Q Quit", fgBlue

proc warn*(txt: string; x = 4; colour = fgRed) =
  if x != -1: setCursorXPos x
  styledEcho colour, txt
  #if echo == false: stdout.styledWrite fgRed,txt
  #default Args dosent seem to be working?
  sleep 750

proc inv* =
  cursorDown()
  warn "INVALID CHOICE"
  cursorUp()
  eraseLine()
  cursorUp()

template sayTermDraw8*() =
  say "Poor Mans Radio Player in Nim-lang " &
      '-'.repeat int terminalWidth() / 8

proc sayTermDraw12*() =
  say('-'.repeat((terminalWidth()/8).int) &
      '>'.repeat int terminalWidth() / 12, fgGreen, x = 2)

proc drawMenu*(sub: string, x: string | seq[string], sect = ""; playingMusic = true) =
  clear()
  if sect == "": say "PNimRP > " & sub
  else: say ("PNimRP > " & sub) & (" > " & sect)

  sayTermDraw12()
  if playingMusic:
    say( (if sect == "": sub else: sect) &
      " Stations Playing Music:", fgGreen)
  sayIter x

proc exit*(ctx: ptr Handle, isPaused: bool) =
  if not isPaused: ctx.terminateDestroy
  exitEcho()

proc notes* =
  while true:
    var returnBack = false

    drawMenu "Notes", """PNimRP Copyright (C) 2021-2024 antonl05/bloomingchad
This program comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute
under certain conditions.""", playingMusic = false
    while true:
      case getch():
        of 'r', 'R': returnBack = true; break
        of 'Q', 'q': exitEcho()
        else: inv()
    if returnBack: break
