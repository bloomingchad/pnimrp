import
  terminal,
  client,
  random,
  json,
  strutils,
  os

type
  UIError* = object of CatchableError
  MenuOptions* = seq[string]
  QuoteData = object
    quotes: seq[string]
    authors: seq[string]

const
  AppName* = "Poor Mans Radio Player"
  AppNameShort* = "PNimRP"
  DefaultErrorMsg = "INVALID CHOICE"
  MinTerminalWidth = 40
  
  # Characters for menu options
  MenuChars = @[
    '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
    'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
    'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ]

proc loadQuotes(filePath: string): QuoteData =
  ## Loads and validates quotes from JSON file
  try:
    let jsonData = parseJArray(filePath)
    if jsonData.len mod 2 != 0:
      raise newException(UIError, "Quote data must have matching quotes and authors")
    
    result = QuoteData(quotes: @[], authors: @[])
    for i in 0 .. jsonData.high:
      if i mod 2 == 0:
        result.quotes.add(jsonData[i])
      else:
        result.authors.add(jsonData[i])
        
    # Validate quotes and authors
    for i in 0 ..< result.quotes.len:
      if result.quotes[i].len == 0:
        raise newException(UIError, "Empty quote found at index " & $i)
      if result.authors[i].len == 0:
        raise newException(UIError, "Empty author found for quote at index " & $i)
        
  except IOError:
    raise newException(UIError, "Failed to load quotes: File not found")
  except JsonParsingError:
    raise newException(UIError, "Failed to parse quotes: Invalid JSON format")

proc clear* =
  ## Clears the screen and resets cursor position
  eraseScreen()
  setCursorPos(0, 0)

proc error*(message: string) {.noReturn.} =
  ## Displays error message and exits program
  styledEcho(fgRed, "Error: ", message)
  quit(QuitFailure)

proc warn*(message: string, xOffset = 4, color = fgRed) =
  ## Displays warning message with delay
  if xOffset >= 0:
    setCursorXPos(xOffset)
  styledEcho(color, message)
  sleep(750)

proc showInvalidChoice*(message = DefaultErrorMsg) =
  ## Shows invalid choice message and repositions cursor
  cursorDown(2)
  warn(message)
  cursorUp()
  eraseLine()
  cursorUp(2)

proc say*(
  message: string,
  color = fgYellow,
  xOffset = 5,
  shouldEcho = true
) =
  ## Displays styled text at specified position
  if color in {fgBlue, fgGreen}:
    setCursorXPos(xOffset)
    if color == fgGreen and not shouldEcho:
      stdout.styledWrite(fgGreen, message)
    else:
      styledEcho(color, message)
  else:
    styledEcho(color, message)

proc drawHeader* =
  ## Draws application header with decorative lines
  let termWidth = terminalWidth()
  if termWidth < MinTerminalWidth:
    raise newException(UIError, "Terminal width too small")
    
  say(AppName & " " & '-'.repeat(termWidth div 8))
  say(
    '-'.repeat(termWidth div 8) & '>'.repeat(termWidth div 12),
    fgGreen,
    xOffset = 2
  )

proc displayMenu*(
  options: MenuOptions,
  showReturnOption = true,
  highlightActive = true
) =
  ## Displays menu options with optional return and quit choices
  var optionNum = 0
  for option in options:
    if option != "Notes":
      say(($MenuChars[optionNum] & " ") & option, fgBlue)
    else:
      say("N Notes", fgBlue)
    inc optionNum

  if showReturnOption:
    say("R Return", fgBlue)
  say("Q Quit", fgBlue)

proc drawMenu*(
  section: string,
  options: string | MenuOptions,
  subsection = "",
  showNowPlaying = true
) =
  ## Draws complete menu with header and options
  clear()
  
  # Draw header
  let header = if subsection == "":
    AppNameShort & " > " & section
  else:
    AppNameShort & " > " & section & " > " & subsection
  say(header)
  
  drawHeader()
  
  # Show now playing if needed
  if showNowPlaying:
    let displaySection = if subsection == "": section else: subsection
    say(displaySection & " Stations Playing Music:", fgGreen)
  
  # Display options
  when options is string:
    for line in splitLines(options):
      say(line, fgBlue)
  else:
    displayMenu(options)

proc showExitMessage* =
  ## Shows exit message with random quote
  showCursor()
  echo ""
  
  try:
    randomize()
    let 
      quotePath = getAppDir() / "assets" / "quote.json"
      quoteData = loadQuotes(quotePath)
      randomIndex = rand(0 ..< quoteData.quotes.len)
    
    when not defined(release) or not defined(danger):
      echo "Memory Statistics:"
      echo "  Free: ", getFreeMem() div 1024, " kB"
      echo "  Total: ", getTotalMem() div 1024, " kB"
      echo "  Occupied: ", getOccupiedMem() div 1024, " kB"
    
    styledEcho(fgCyan, quoteData.quotes[randomIndex], "...")
    setCursorXPos(15)
    styledEcho(fgGreen, "—", quoteData.authors[randomIndex])
    
  except UIError as e:
    error("Failed to show exit message: " & e.msg)

proc exit*(ctx: ptr Handle, isPaused: bool) =
  ## Cleanly exits the application
  if not isPaused:
    ctx.terminateDestroy()
  showExitMessage()
  quit(QuitSuccess)

proc showNotes* =
  ## Displays application notes/about section
  while true:
    var shouldReturn = false
    drawMenu(
      "Notes",
      """PNimRP Copyright (C) 2021-2024 antonl05/bloomingchad
This program comes with ABSOLUTELY NO WARRANTY
This is free software, and you are welcome to redistribute
under certain conditions.""",
      showNowPlaying = false
    )
    
    while true:
      case getch():
        of 'r', 'R':
          shouldReturn = true
          break
        of 'q', 'Q':
          showExitMessage()
        else:
          showInvalidChoice()
    
    if shouldReturn:
      break

when isMainModule:
  # Example usage
  try:
    drawMenu("Main", @["Play", "Stop", "Settings"])
    showNotes()
  except UIError as e:
    error(e.msg)
