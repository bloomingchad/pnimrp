import
  terminal, client, random,
  json, strutils, os, times,
  strformat, animation, utils

using str: string

# Fallback symbols for each state
proc getFallbackSymbol*(status: PlayerStatus): string =
  case status
  of StatusPlaying: return "[>]"
  of StatusMuted: return "[X]"
  of StatusPaused: return "||"
  of StatusPausedMuted: return "||[X]"

proc getEmojiSymbol*(status: PlayerStatus): string =
  case status
  of StatusPlaying: return "🔊"
  of StatusMuted: return "🔇"
  of StatusPaused: return "⏸"
  of StatusPausedMuted: return "⏸ 🔇"

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

proc showExitMessage* =
  setCursorPos 0, 15
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
  updateTermWidth()
  if termWidth < MinTerminalWidth:
    raise newException(UIError, "Terminal width too small.")
  
  # Draw the top border
  say("=".repeat(termWidth), fgGreen, xOffset = 0)
  
  # Draw the application title with emojis
  let title = "       🎧 " & AppName & " 🎧"
  say(title, fgYellow, xOffset = (termWidth - title.len) div 2)
  
  # Draw the bottom border of the header
  say("=".repeat(termWidth), fgGreen, xOffset = 0)

proc calculateColumnLayout(options: MenuOptions): (int, seq[int], int) =
  ## Calculates the number of columns, max column lengths, and spacing.
  const minColumns = 2
  const maxColumns = 3
  var numColumns = maxColumns

  # Calculate the maximum length of items including prefix
  var maxItemLength = 0
  for i in 0 ..< options.len:
    let prefix =
      if i < 9: $(i + 1) & "."  # Use numbers 1-9 for the first 9 options
      else:
        if i < MenuChars.len: $MenuChars[i] & "." # Use A-Z for the next options
        else: "?" # Fallback
    let itemLength = prefix.len + 1 + options[i].len  # Include prefix and space
    if itemLength > maxItemLength:
      maxItemLength = itemLength

  # Calculate the minimum required width for 3 columns
  let minWidthFor3Columns = maxItemLength * 3 + 9  # 9 = 4.5 spaces between columns * 2 (halfway between 8 and 10)

  # Switch to 2 columns if:
  # 1. Terminal width is less than the minimum required for 3 columns, or
  # 2. The longest item is more than 1/4.5 of the terminal width (slightly tighter threshold)
  if termWidth < minWidthFor3Columns or maxItemLength > int(float(termWidth) / 4.5):
    numColumns = minColumns
  else:
    numColumns = maxColumns  # Otherwise, use 3 columns

  # Calculate the number of items per column
  let itemsPerColumn = (options.len + numColumns - 1) div numColumns

  # Find the maximum length of items in each column (including prefix)
  var maxColumnLengths = newSeq[int](numColumns)
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

  return (numColumns, maxColumnLengths, spacing)

proc renderMenuOptions(options: MenuOptions, numColumns: int, maxColumnLengths: seq[int], spacing: int) =
  ## Renders the menu options in a multi-column layout.
  let itemsPerColumn = (options.len + numColumns - 1) div numColumns

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

proc displayMenu*(
  optionss: MenuOptions,
  showReturnOption = true,
  highlightActive = true,
  isMainMenu = false
) =
  ## Displays menu options in a formatted multi-column layout.
  updateTermWidth()
  
  var options = optionss
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

proc getFooterOptions*(isMainMenu, isPlayerUI: bool): string =
  ## Returns the footer options based on the context (main menu or submenu).
  result =
    if isMainMenu: "[Q] Quit   [N] Notes"
    elif isPlayerUI: "[Q] Quit   [R] Return   [P] Pause/ Play [-/+] Adjust Volume "
    else: "[Q] Quit   [R] Return"

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
  ## Draws the application header with the current section
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
  animationFrame: int = 0  # Tracks the current frame of the animation
  lastAnimationUpdate: DateTime = now()  # Tracks the last time the animation was updated

# Animation frames for emoji and ASCII
const
  AsciiFrames = ["♪♫", "♫♪"]  # ASCII fallback animation frames
  EmojiFrames = AsciiFrames   # ["🎵", "🎶"]  # Emoji animation frames

proc drawPlayerUIInternal(section, nowPlaying, status: string, volume: int) =
  ## Internal function that handles the common logic for drawing and updating the player UI.
  # Draw header if section is provided
  updateTermWidth()
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
  setCursorPos(0, 4)
  eraseLine()
  let volumeColor = volumeColor(volume)
  say("Status: " & status & " | Volume: ", fgGreen, xOffset = 0, shouldEcho = false)
  styledEcho(volumeColor, $volume & "%")
  
  showFooter(linetoDraw = 5)

# Function to get the appropriate symbol based on terminal support
proc currentStatusEmoji*(status: PlayerStatus): string =
  if terminalSupportsEmoji:
    return getEmojiSymbol(status)
  else:
    return getFallbackSymbol(status)

proc drawPlayerUI*(section, nowPlaying, status: string, volume: int) =
  ## Draws the modern music player UI with dynamic layout and visual enhancements.
  ## Adjusts layout for wide and narrow screens, colors volume percentage, and anchors the footer to the bottom.
  clear()
  drawPlayerUIInternal(section, nowPlaying, status, volume)

proc updatePlayerUI*(nowPlaying, status: string, volume: int) =
  ## Updates the player UI with new information.
  let animationSymbol = updateJinglingAnimation(status)  # Get the animation symbol
  let nowPlayingText = animationSymbol & " " & nowPlaying  # Move animation to the start

  # Draw the UI with the updated "Now Playing" text
  drawPlayerUIInternal("", nowPlayingText, status, volume)