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

using str :string
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
proc error*(message: string) =
  ## Displays error message and exits program
  styledEcho(fgRed, "Error: ", message)
  quit(QuitFailure)

proc parseJArray*(str): seq[string] =
  try:
    result = to(
      parseJson(readFile(str)){"pnimrp"},
      seq[string]
    )
  except IOError: error "base assets dont exist?"

  if result.len mod 2 != 0:
    error "JArrayResult.len not even"

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

proc drawHeader* =
  ## Draws the application header with decorative lines and emojis.
  let termWidth = terminalWidth()
  if termWidth < MinTerminalWidth:
    raise newException(UIError, "Terminal width too small.")
  
  # Draw the top border
  say("=".repeat(termWidth), fgGreen, xOffset = 0)
  
  # Draw the application title with emojis
  let title = "       🎧 " & AppName & " 🎧"
  say(title, fgYellow, xOffset = (termWidth - title.len) div 2)
  
  # Draw the bottom border of the header
  say("=".repeat(termWidth), fgGreen, xOffset = 0)

proc displayMenu*(
  optionss: MenuOptions,
  showReturnOption = true,
  highlightActive = true,
  isMainMenu = false
) =
  ## Displays menu options in a formatted multi-column layout.
  ## Columns are dynamically spaced based on the longest item in each column.
  ## Spacing between columns adjusts dynamically (minimum 4 spaces).
  ## Errors out if the terminal width is too small to display the menu.
  let termWidth = terminalWidth()
  
  var options = optionss
  if isMainMenu:
    options.delete(options.len - 1) # Remove notes

  # Draw the "Station Categories" section header
  let categoriesHeader = "          📻 Station Categories 📻"
  say(categoriesHeader, fgCyan, xOffset = (termWidth - categoriesHeader.len) div 2)

  # Draw the separator line
  let separatorLine = "-".repeat(termWidth)
  say(separatorLine, fgGreen, xOffset = 0)

  # Calculate the number of columns
  const numColumns = 3
  let itemsPerColumn = (options.len + numColumns - 1) div numColumns

  # Find the maximum length of items in each column (including prefix)
  var maxColumnLengths: array[numColumns, int]
  for i in 0 ..< options.len:
    let columnIndex = i div itemsPerColumn
    let prefix =
      if i < 9: $(i + 1) & "."  # Use numbers 1-9 for the first 9 options
      else:
        if i < MenuChars.len: $MenuChars[i] & "." # Use A-Z for the next options
        else: "?" # Fallback
    let itemLength = prefix.len + 1 + options[i].len  # Include prefix and space
    if itemLength > maxColumnLengths[columnIndex]:
      maxColumnLengths[columnIndex] = itemLength

  # Calculate the total width required for all columns (without spacing)
  var totalWidth = 0
  for length in maxColumnLengths:
    totalWidth += length

  # Calculate the required spacing between columns
  let minSpacing = 4  # Minimum spacing between columns
  let maxSpacing = 6  # Maximum spacing between columns
  var spacing = maxSpacing

  # Adjust spacing if the terminal width is too small
  while spacing >= minSpacing:
    let totalWidthWithSpacing = totalWidth + spacing * (numColumns - 1)
    if totalWidthWithSpacing <= termWidth:
      break  # We have enough space with the current spacing
    spacing -= 1  # Reduce spacing and try again

  # Check if we have enough space even with the minimum spacing
  if spacing < minSpacing:
    raise newException(UIError, "Terminal width too small to display menu without overlap. Required width: " & $(totalWidth + minSpacing * (numColumns - 1)) & ", available width: " & $termWidth)

  # Calculate the starting position for each column
  var columnPositions: array[numColumns, int]
  columnPositions[0] = 0
  for i in 1 ..< numColumns:
    columnPositions[i] = columnPositions[i - 1] + maxColumnLengths[i - 1] + spacing

  # Display menu options in a multi-column layout
  for row in 0 ..< itemsPerColumn:
    var currentLine = ""
    for col in 0 ..< numColumns:
      let index = row + col * itemsPerColumn
      if index < options.len:
        # Calculate the prefix for the menu option
        let prefix =
          if index < 9: $(index + 1) & "."  # Use numbers 1-9 for the first 9 options
          else:
            if index < MenuChars.len: $MenuChars[index] & "." # Use A-Z for the next options
            else: "?" # Fallback

        let formattedOption = prefix & " " & options[index]
        let padding = maxColumnLengths[col] - formattedOption.len
        currentLine.add(formattedOption & " ".repeat(padding))
      else:
        # Add empty space if there are no more items in this column
        currentLine.add(" ".repeat(maxColumnLengths[col]))

      # Add spacing between columns (dynamic spacing)
      if col < numColumns - 1:
        currentLine.add(" ".repeat(spacing))

    say(currentLine, fgBlue)

  # Draw the separator line
  say(separatorLine, fgGreen, xOffset = 0)

  # Display the footer options
  let footerOptions = "[Q] Quit   [R] Return   [N] Notes"
  say(footerOptions, fgYellow, xOffset = (termWidth - footerOptions.len) div 2)

  # Draw the bottom border
  say("=".repeat(termWidth), fgGreen, xOffset = 0)

proc drawMenu*(
  section: string,
  options: string | MenuOptions,
  subsection = "",
  showNowPlaying = true,
  isMainMenu = false) =
  ## Draws a complete menu with header and options.
  clear()
  
  # Draw header
  drawHeader()
  # Display menu options
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

proc drawHeader*(section: string) =
  ## Draws the application header with the current section
  let termWidth = terminalWidth()
  if termWidth < MinTerminalWidth:
    raise newException(UIError, "Terminal width too small")
  
  # Draw header
  say(AppNameShort & " > " & section, fgGreen)
  say("-".repeat(termWidth), fgGreen)

proc drawPlayerUI*(section, nowPlaying, status: string, volume: int) =
  ## Draws the modern music player UI
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
  ## Updates the player UI with new information
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