import
  terminal, client, random,
  json, strutils, os

proc clear* =
  eraseScreen()
  setCursorPos 0, 0

proc error*(str: string) =
  styledEcho fgRed, "Error: ", str
  quit QuitFailure

proc sayBlue(strList: varargs[string]) =
  for str in strList:
    setCursorXPos 5
    styledEcho fgBlue, str

proc sayBye(str, auth: string, line = -1) =
  if str == "": error "no qoute"

  styledEcho fgCyan, str, "..."
  setCursorXPos 15
  styledEcho fgGreen, "—", auth

  if auth == "":
    error "there can no be qoute without man"
    if line != -1:
      error ("@ line: " & $line) & " in qoute.json"

  quit QuitSuccess

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

  let seq = parseJArray "assets/qoute.json"
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

  sayBye(
    qoutes[rand],
    authors[rand],
    rand * 2
  )

proc say*(txt: string) =
  styledEcho fgYellow, txt

proc sayPos*(a: string; x = 4; echo = true) =
  setCursorXPos x
  if echo: styledEcho fgGreen, a
  else: stdout.styledWrite fgGreen, a

proc sayIter(txt: string) =
  for f in splitLines txt:
    setCursorXPos 5
    styledEcho fgBlue, f

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
    if f != "Notes": sayBlue ($chars[num] & " ") & f
    else: sayBlue "N Notes"
    inc num
  if ret: sayBlue "R Return"
  sayBlue "Q Quit"

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
  sayPos '-'.repeat((terminalWidth()/8).int) &
      '>'.repeat int terminalWidth() / 12

proc drawMenu*(sub: string, x: string | seq[string], sect = "") =
  clear()
  if sect == "": say "PNimRP > " & sub
  else: say ("PNimRP > " & sub) & (" > " & sect)

  sayTermDraw12()
  sayPos( (if sect == "": sub else: sect) &
      " Station Playing Music:")
  sayIter x

proc exit*(ctx: ptr Handle, isPaused: bool) =
  if not isPaused:
    ctx.terminateDestroy
  exitEcho()

proc notes* =
  while true:
    var returnBack = false
    const sub = "Notes"
    clear()
    say "PNimRP > " & sub
    sayTermDraw12()

    sayIter """PNimRP Copyright (C) 2021-2024 antonl05/bloomingchad
This program comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute
under certain conditions."""
    while true:
      case getch():
        of 'r', 'R': returnBack = true; break
        of 'Q', 'q': exitEcho()
        else: inv()
    if returnBack: break
