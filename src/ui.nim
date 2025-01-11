import
  terminal,
  client,
  random,
  json,
  strutils,
  os

type
  UIError* = object of CatchableError  # Custom error type for UI-related issues
  MenuOptions* = seq[string]           # Sequence of strings representing menu options
  QuoteData = object                   # Structure to hold quotes and authors
    quotes: seq[string]
    authors: seq[string]

using str: string  # Convenience alias for string type

const
  AppName* = "Poor Mans Radio Player"  # Full name of the application
  AppNameShort* = "PNimRP"             # Short name of the application
  DefaultErrorMsg = "INVALID CHOICE"   # Default error message for invalid choices
  MinTerminalWidth = 40                # Minimum terminal width for proper display
  
  # Characters used for menu options
  MenuChars = @[
    '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
    'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
    'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ]

proc error*(message: string) =
  ## Displays an error message and exits the program.
  styledEcho(fgRed, "Error: ", message)
  quit(QuitFailure)

proc parseJArray*(str): seq[string] =
  ## Parses a JSON array from a file and returns it as a sequence of strings.
  try:
    result = to(parseJson(readFile(str)){"pnimrp"}, seq[string])
  except IOError:
    error "Base assets do not exist."

  if result.len mod 2 != 0:
    error "JArrayResult.len is not even."

proc loadQuotes(filePath: string): QuoteData =
  ## Loads and validates quotes and authors from a JSON file.
  try:
    let jsonData = parseJArray(filePath)
    if jsonData.len mod 2 != 0:
      raise newException(UIError, "Quote data must have matching quotes and authors.")
    
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
    raise newException(UIError, "Failed to load quotes: File not found.")
  except JsonParsingError:
    raise newException(UIError, "Failed to parse quotes: Invalid JSON format.")

proc clear* =
  ## Clears the terminal screen and resets the cursor position.
  eraseScreen()
  setCursorPos(0, 0)

proc warn*(message: string, xOffset = 4, color = fgRed) =
  ## Displays a warning message with a delay.
  if xOffset >= 0:
    setCursorXPos(xOffset)
  styledEcho(color, message)
  sleep(750)

proc showInvalidChoice*(message = DefaultErrorMsg) =
  ## Displays an invalid choice message and repositions the cursor.
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
  ## Displays styled text at a specified position.
  if color in {fgBlue, fgGreen}:
    setCursorXPos(xOffset)
    if color == fgGreen and not shouldEcho:
      stdout.styledWrite(fgGreen, message)
    else:
      styledEcho(color, message)
  else:
    styledEcho(color, message)

proc exitEcho* =
  ## Displays a random quote and exits the program.
  showCursor()
  echo ""
  randomize()

  let seq = parseJArray(getAppDir() / "assets" / "qoute.json")
  var quotes, authors: seq[string] = @[]

  for i in 0 .. seq.high:
    case i mod 2:
      of 0: quotes.add(seq[i])
      else: authors.add(seq[i])

  let rand = rand(0 .. quotes.high)

  when not defined(release) or not defined(danger):
    echo "Memory Statistics:"
    echo "  Free: ", getFreeMem() div 1024, " kB"
    echo "  Total: ", getTotalMem() div 1024, " kB"
    echo "  Occupied: ", getOccupiedMem() div 1024, " kB"

  if quotes[rand] == "":
    error "No quote found."

  styledEcho(fgCyan, quotes[rand], "...")
  setCursorXPos(15)
  styledEcho(fgGreen, "—", authors[rand])

  if authors[rand] == "":
    error "There cannot be a quote without an author."
    if rand * 2 != -1:
      error "@ line: " & $(rand * 2) & " in qoute.json"

  quit(QuitSuccess)

proc drawHeader* =
  ## Draws the application header with decorative lines.
  let termWidth = terminalWidth()
  if termWidth < MinTerminalWidth:
    raise newException(UIError, "Terminal width too small.")
    
  say(AppName & " " & '-'.repeat(termWidth div 8))
  say('-'.repeat(termWidth div 8) & '>'.repeat(termWidth div 12), fgGreen, xOffset = 2)

proc displayMenu*(
  options: MenuOptions,
  showReturnOption = true,
  highlightActive = true
) =
  ## Displays menu options with optional return and quit choices.
  var optionNum = 0
  for option in options:
    if option != "Notes":
      say(($MenuChars[optionNum] & " ") & option, fgBlue)
    else:
      say("N Notes", fgBlue)
    inc(optionNum)

  if showReturnOption:
    say("R Return", fgBlue)
  say("Q Quit", fgBlue)

proc drawMenu*(
  section: string,
  options: string | MenuOptions,
  subsection = "",
  showNowPlaying = true
) =
  ## Draws a complete menu with header and options.
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
  ## Displays an exit message with a random quote.
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
  ## Cleanly exits the application.
  if not isPaused:
    ctx.terminateDestroy()
  showExitMessage()
  quit(QuitSuccess)

proc showNotes* =
  ## Displays the application notes/about section.
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

proc drawHeader*(section: string) =
  ## Draws the application header with the current section.
  let termWidth = terminalWidth()
  if termWidth < MinTerminalWidth:
    raise newException(UIError, "Terminal width too small.")
  
  # Draw header
  say(AppNameShort & " > " & section, fgGreen)
  say("-".repeat(termWidth), fgGreen)

proc drawPlayerUI*(section, nowPlaying, status: string, volume: int) =
  ## Draws the modern music player UI.
  clear()
  
  # Draw header
  setCursorPos(0, 0)  # Line 0
  say(AppNameShort & " > " & section, fgYellow)
  
  # Draw separator
  setCursorPos(1, 1)  # Line 1
  say("-".repeat(terminalWidth() - 1), fgGreen, xOffSet = 0)
  
  # Display "Now Playing"
  setCursorPos(0, 2)  # Line 2 (below the separator)
  say("Now Playing: " & nowPlaying, fgCyan)
  
  # Display status and volume
  setCursorPos(0, 3)  # Line 3
  say("Status: " & status & " | Volume: " & $volume & "%", fgGreen, xOffSet = 0)
  
  # Draw separator
  setCursorPos(0, 4)  # Line 4
  say("-".repeat(terminalWidth() - 1), fgGreen, xOffSet = 0)
  
  # Move cursor to input handling area (below the separator)
  setCursorPos(0, 5)  # Line 5

proc updatePlayerUI*(nowPlaying, status: string, volume: int) =
  ## Updates the player UI with new information.
  # Update "Now Playing"
  setCursorPos(0, 2)  # Line 2
  eraseLine()
  say("Now Playing: " & nowPlaying, fgCyan)
  
  # Update status and volume
  setCursorPos(0, 3)  # Line 3
  eraseLine()
  say("Status: " & status & " | Volume: " & $volume & "%", fgGreen, xOffSet = 0)
  
  # Move cursor back to input handling area (below the separator)
  setCursorPos(0, 5)  # Line 5
