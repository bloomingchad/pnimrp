import
  terminal, client, random,
  json, strutils, os, times,
  strformat, animation, utils,
  theme

using str: string

# Global variable to hold the current theme
var currentTheme*: Theme

proc say*(
  message: string,
  color = fgYellow,
  xOffset = 5,
  shouldEcho = true
) =
  ## Displays styled text at a specified position.
  ##
  ## Args:
  ##   message: The text to display.
  ##   color: The foreground color of the text (default: fgYellow).
  ##   xOffset: The horizontal offset for the cursor (default: 5).
  ##   shouldEcho: Whether to echo the message to stdout (default: true).
  if color in {fgBlue, fgGreen}:
    setCursorXPos(xOffset)
    if color == fgGreen and not shouldEcho:
      stdout.styledWrite(fgGreen, message)
    else:
      styledEcho(color, message)
  else:
    styledEcho(color, message)

proc showExitMessage* =
  ## Displays an exit message with a random quote from the quotes file.
  setCursorPos(0, 15)
  showCursor()
  echo ""
  randomize()

  let quotesData = loadQuotes(getAppDir() / "assets" / "qoute.json")
  let rand = rand(0 .. quotesData.quotes.high)

  when not defined(release) or not defined(danger):
    echo "free mem: ", $(getFreeMem() / 1024), " kB"
    echo "total/max mem: ", $(getTotalMem() / 1024), " kB"
    echo "occupied mem: ", $(getOccupiedMem() / 1024), " kB"

  if quotesData.quotes[rand] == "":
    error("no quote found")

  styledEcho(fgCyan, quotesData.quotes[rand], "...")
  setCursorXPos(15)
  styledEcho(fgGreen, "—", quotesData.authors[rand])

  if quotesData.authors[rand] == "":
    error("there can be no quote without an author")
    if rand * 2 != -1:
      error("@ line: " & $(rand * 2) & " in qoute.json")

  quit(QuitSuccess)

proc drawHeader*() =
  ## Draws the application header with decorative lines and emojis.
  updateTermWidth()
  if termWidth < MinTerminalWidth:
    raise newException(UIError, "Terminal width too small.")

  # Draw the top border using the theme's separator color
  say("=".repeat(termWidth), currentTheme.separator, xOffset = 0)

  # Draw the application title with emojis using the theme's header color
  let title = "       🎧 " & AppName & " 🎧"
  say(title, currentTheme.header, xOffset = (termWidth - title.len) div 2)

  # Draw the bottom border of the header using the theme's separator color
  say("=".repeat(termWidth), currentTheme.separator, xOffset = 0)

proc calculateColumnLayout(options: MenuOptions): (int, seq[int], int) =
  ## Calculates the number of columns, max column lengths, and spacing.
  const minColumns = 2
  const maxColumns = 3
  var numColumns = maxColumns

  # Calculate the maximum length of items including prefix
  var maxItemLength = 0
  for i in 0 ..< options.len:
    let prefix =
      if i < 9: $(i + 1) & "." # Use numbers 1-9 for the first 9 options
      else:
        if i < MenuChars.len: $MenuChars[i] & "." # Use A-Z for the next options
        else: "?"              # Fallback
    let itemLength = prefix.len + 1 + options[i].len # Include prefix and space
    if itemLength > maxItemLength:
      maxItemLength = itemLength

  # Calculate the minimum required width for 3 columns
  let minWidthFor3Columns = maxItemLength * 3 + 9 # 9 = 4.5 spaces between columns * 2

  # Switch to 2 columns if:
  # 1. Terminal width is less than the minimum required for 3 columns, or
  # 2. The longest item is more than 1/4.5 of the terminal width
  if termWidth < minWidthFor3Columns or maxItemLength > int(float(termWidth) / 4.5):
    numColumns = minColumns
  else:
    numColumns = maxColumns # Otherwise, use 3 columns

  # Calculate the number of items per column
  let itemsPerColumn = (options.len + numColumns - 1) div numColumns

  # Find the maximum length of items in each column (including prefix)
  var maxColumnLengths = newSeq[int](numColumns)
  for i in 0 ..< options.len:
    let columnIndex = i div itemsPerColumn
    let prefix =
      if i < 9: $(i + 1) & "." # Use numbers 1-9 for the first 9 options
      else:
        if i < MenuChars.len: $MenuChars[i] & "." # Use A-Z for the next options
        else: "?"              # Fallback
    let itemLength = prefix.len + 1 + options[i].len # Include prefix and space
    if itemLength > maxColumnLengths[columnIndex]:
      maxColumnLengths[columnIndex] = itemLength

  # Calculate the total width required for all columns (without spacing)
  var totalWidth = 0
  for length in maxColumnLengths:
    totalWidth += length

  # Calculate the required spacing between columns
  const minSpacing = 4 # Minimum spacing between columns
  const maxSpacing = 6 # Maximum spacing between columns
  var spacing = maxSpacing

  # Adjust spacing if the terminal width is too small
  while spacing >= minSpacing:
    let totalWidthWithSpacing = totalWidth + spacing * (numColumns - 1)
    if totalWidthWithSpacing <= termWidth:
      break # We have enough space with the current spacing
    spacing -= 1 # Reduce spacing and try again

  # Check if we have enough space even with the minimum spacing
  if spacing < minSpacing:
    raise newException(UIError, "Terminal width too small to display menu without overlap. Required width: " &
        $(totalWidth + minSpacing * (numColumns - 1)) & ", available width: " & $termWidth)

  return (numColumns, maxColumnLengths, spacing)

proc renderMenuOptions(options: MenuOptions, numColumns: int,
    maxColumnLengths: seq[int], spacing: int) =
  ## Renders the menu options in a multi-column layout.
  let itemsPerColumn = (options.len + numColumns - 1) div numColumns

  for row in 0 ..< itemsPerColumn:
    var currentLine = ""
    for col in 0 ..< numColumns:
      let index = row + col * itemsPerColumn
      if index < options.len:
        # Calculate the prefix for the menu option
        let prefix =
          if index < 9: $(index + 1) & "." # Use numbers 1-9 for the first 9 options
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

proc getFooterOptions*(isMainMenu, isPlayerUI: bool): string =
  ## Returns the footer options based on the context (main menu or submenu).
  #echo "DEBUG: getFooterOptions - isMainMenu = ", isMainMenu, ", isPlayerUI = ", isPlayerUI  # Debug log
  result =
    if isMainMenu: "[Q] Quit   [N] Notes   [U] Help"
    elif isPlayerUI: "[Q] Quit   [R] Return   [P] Pause/Play   [-/+] Adjust Volume"
    else: "[Q] Quit   [R] Return   [U] Help"

proc displayMenu*(
  options: MenuOptions,
  showReturnOption = true,
  highlightActive = true,
  isMainMenu = false,
  isPlayerUI = false  # Add this parameter
) =
  ## Displays menu options in a formatted multi-column layout.
  updateTermWidth()

  var options = options
  if isMainMenu:
    options.delete(options.len - 1) # Remove notes

  # Draw the "Station Categories" section header
  let categoriesHeader = "         📻 Station Categories 📻"
  say(categoriesHeader, fgCyan, xOffset = (termWidth - categoriesHeader.len) div 2)

  # Draw the separator line
  let separatorLine = "-".repeat(termWidth)
  say(separatorLine, fgGreen, xOffset = 0)

  # Calculate column layout and render menu options
  let (numColumns, maxColumnLengths, spacing) = calculateColumnLayout(options)
  renderMenuOptions(options, numColumns, maxColumnLengths, spacing)

  # Draw the separator line
  say(separatorLine, fgGreen, xOffset = 0)

  # Display the footer options
  let footerOptions = getFooterOptions(isMainMenu, isPlayerUI)  # Pass isPlayerUI here
  say(footerOptions, fgYellow, xOffset = (termWidth - footerOptions.len) div 2)

  # Draw the bottom border
  say("=".repeat(termWidth), fgGreen, xOffset = 0)

proc drawMenu*(
  section: string,
  options: string | MenuOptions,
  subsection = "",
  showNowPlaying = true,
  isMainMenu = false,
  isPlayerUI = false  # Add this parameter
) =
  ## Draws a complete menu with header and options.
  clear()

  # Draw header
  drawHeader()
  # Display menu options
  when options is string:
    for line in splitLines(options):
      say(line, fgBlue)
  else:
    displayMenu(options, isMainMenu = isMainMenu, isPlayerUI = isPlayerUI)

proc showFooter*(
  lineToDraw = 4,
  isMainMenu = false,
  isPlayerUI = false,
  separatorColor = fgGreen,
  footerColor = fgYellow
) =
  ## Displays the footer with dynamic options based on the context.
  updateTermWidth()
  setCursorPos(0, lineToDraw)
  say("-".repeat(termWidth), separatorColor, xOffset = 0)

  # Add footer with controls at the bottom
  setCursorPos(0, lineToDraw + 1)
  let footerOptions = getFooterOptions(isMainMenu, isPlayerUI)
  say(footerOptions, footerColor, xOffset = (termWidth - footerOptions.len) div 2)

  # Draw bottom border
  setCursorPos(0, lineToDraw + 2)
  say("=".repeat(termWidth), separatorColor, xOffset = 0)

proc exit*(ctx: ptr Handle, isPaused: bool) =
  ## Cleanly exits the application.
  showExitMessage()
  quit(QuitSuccess)

proc showNotes* =
  ## Displays application notes/about section.
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
    showFooter(lineToDraw = 9, isMainMenu = true)

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
  ## Draws the application header with the current section.
  updateTermWidth()

  if termWidth < MinTerminalWidth:
    raise newException(UIError, "Terminal width too small")

  # Draw header
  say(AppNameShort & " > " & section, fgGreen)
  say("-".repeat(termWidth), fgGreen)

# Module-level variable to track the previous volume
var lastVolume*: int = -1

proc volumeColor(volume: int): ForegroundColor =
  if volume > 110: fgRed
  elif volume < 60: fgBlue
  else:
    fgGreen

var
  animationFrame: int = 0 # Tracks the current frame of the animation
  lastAnimationUpdate: DateTime = now() # Tracks the last time the animation was updated

proc drawPlayerUIInternal(section, nowPlaying, status: string, volume: int) =
  ## Internal function that handles the common logic for drawing and updating the player UI.
  updateTermWidth()

  # Draw header if section is provided
  if section.len > 0:
    setCursorPos(0, 0)  # Line 0
    say(AppNameShort & " > " & section, fgYellow)

  # Draw separator
  setCursorPos(0, 1)  # Line 1
  say("-".repeat(termWidth), fgGreen, xOffset = 0)

  # Display "Now Playing" with truncation if necessary
  setCursorPos(0, 2)  # Line 2 (below the separator)
  eraseLine()
  let nowPlayingText = "Now Playing: " & nowPlaying
  if nowPlayingText.len > termWidth:
    say(nowPlayingText[0 ..< termWidth - 3] & "...", fgCyan)  # Truncate and add ellipsis
  else:
    say(nowPlayingText, fgCyan)

  # Display status and volume
  setCursorPos(0, 4)  # Line 4
  eraseLine()
  let volumeColor = volumeColor(volume)
  say("Status: " & status & " | Volume: ", fgGreen, xOffset = 0, shouldEcho = false)
  styledEcho(volumeColor, $volume & "%")

  showFooter(isPlayerUI = true)  # Ensure the footer is drawn with isPlayerUI = true

proc drawPlayerUI*(section, nowPlaying, status: string, volume: int) =
  ## Draws the modern music player UI with dynamic layout and visual enhancements.
  clear()
  drawPlayerUIInternal(section, nowPlaying, status, volume)

proc updatePlayerUI*(nowPlaying, status: string, volume: int) =
  ## Updates the player UI with new information.
  let animationSymbol = updateJinglingAnimation(status) # Get the animation symbol
  let nowPlayingText = animationSymbol & " " & nowPlaying # Move animation to the start

  # Draw the UI with the updated "Now Playing" text
  drawPlayerUIInternal("", nowPlayingText, status, volume)

  # Display status and volume
  setCursorPos(0, 4)  # Line 4
  eraseLine()
  let volumeColor = volumeColor(volume)
  say("Status: " & status & " | Volume: ", fgGreen, xOffset = 0, shouldEcho = false)
  styledEcho(volumeColor, $volume & "%")

when isMainModule:
  import unittest

  suite "UI Tests":
    test "say procedure":
      # Test basic functionality
      say("Hello, World!", fgGreen)
      say("This is a test.", fgBlue, xOffset = 10)

      # Test with shouldEcho = false
      say("This should not echo", fgGreen, shouldEcho = false)

    test "showExitMessage procedure":
      # Test with a valid quotes file
      showExitMessage()

      # Test with an empty quotes file (should raise an error)
      let emptyQuotesFile = getAppDir() / "assets" / "empty_quotes.json"
      writeFile(emptyQuotesFile, """{"pnimrp": []}""")
      expect UIError:
        showExitMessage()
      removeFile(emptyQuotesFile)

    test "drawHeader procedure":
      # Test with a valid terminal width
      drawHeader()

      # Test with a terminal width that's too small (should raise an error)
      let originalTermWidth = termWidth
      termWidth = MinTerminalWidth - 1
      expect UIError:
        drawHeader()
      termWidth = originalTermWidth

    test "calculateColumnLayout procedure":
      let options = @["Option 1", "Option 2", "Option 3", "Option 4", "Option 5"]

      # Test with a wide terminal
      termWidth = 100
      let (numColumns, maxColumnLengths, spacing) = calculateColumnLayout(options)
      check numColumns == 3
      check maxColumnLengths.len == 3
      check spacing >= 4

      # Test with a narrow terminal
      termWidth = 50
      let (numColumnsNarrow, maxColumnLengthsNarrow, spacingNarrow) = calculateColumnLayout(options)
      check numColumnsNarrow == 2
      check maxColumnLengthsNarrow.len == 2
      check spacingNarrow >= 4

      # Test with too few options
      let singleOption = @["Option 1"]
      let (numColumnsSingle, maxColumnLengthsSingle, spacingSingle) = calculateColumnLayout(singleOption)
      check numColumnsSingle == 1
      check maxColumnLengthsSingle.len == 1
      check spacingSingle >= 4

    test "renderMenuOptions procedure":
      let options = @["Option 1", "Option 2", "Option 3", "Option 4", "Option 5"]
      let numColumns = 2
      let maxColumnLengths = @[10, 10]
      let spacing = 4

      # Test rendering
      renderMenuOptions(options, numColumns, maxColumnLengths, spacing)

    test "displayMenu procedure":
      let options = @["Option 1", "Option 2", "Option 3", "Option 4", "Option 5"]

      # Test with isMainMenu = false
      displayMenu(options)

      # Test with isMainMenu = true
      displayMenu(options, isMainMenu = true)

    test "drawMenu procedure":
      # Test with string options
      drawMenu("Test Section", "Line 1\nLine 2\nLine 3")

      # Test with MenuOptions
      let options = @["Option 1", "Option 2", "Option 3"]
      drawMenu("Test Section", options)

    test "getFooterOptions procedure":
      # Test for main menu
      check getFooterOptions(true, false) == "[Q] Quit   [N] Notes"

      # Test for player UI
      check getFooterOptions(false, true) == "[Q] Quit   [R] Return   [P] Pause/Play [-/+] Adjust Volume"

      # Test for submenu
      check getFooterOptions(false, false) == "[Q] Quit   [R] Return"

    test "showFooter procedure":
      # Test with default parameters
      showFooter()

      # Test with custom parameters
      showFooter(lineToDraw = 10, isMainMenu = true, isPlayerUI = false, separatorColor = fgRed, footerColor = fgBlue)

    test "exit procedure":
      # Test with isPaused = true
      let ctx = create()
      exit(ctx, isPaused = true)

      # Test with isPaused = false
      exit(ctx, isPaused = false)

    test "showNotes procedure":
      # Test displaying notes
      showNotes()

    test "volumeColor procedure":
      # Test low volume
      check volumeColor(50) == fgBlue

      # Test medium volume
      check volumeColor(80) == fgGreen

      # Test high volume
      check volumeColor(120) == fgRed

    test "drawPlayerUI procedure":
      # Test with a valid section and nowPlaying text
      drawPlayerUI("Test Section", "Now Playing: Song Title", "Playing", 75)

      # Test with a long nowPlaying text
      let longNowPlaying = "Now Playing: " & "A".repeat(100)
      drawPlayerUI("Test Section", longNowPlaying, "Playing", 75)

    test "updatePlayerUI procedure":
      # Test updating the player UI
      updatePlayerUI("Now Playing: Song Title", "Playing", 75)