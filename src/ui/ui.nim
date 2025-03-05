# ui.nim

import
  terminal,  random, os,
  strutils, times, 

  ../audio/libmpv,
  ../utils/[
    utils,
    jsonutils
  ]

when not defined(simple):
  import theme, stationstatus, scroll, animation

using str: string

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

  let quotesData = loadQuotes(getAppDir() / "assets" / "config" / "qoute.json")
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

proc drawSeperatorUI*(xpos = -1; sep = '='; offset = 5; color = fgGreen) =
  if not xpos == -1: setCursorXPos xpos
  say(sep.repeat(termWidth), color, offset)

proc drawHeader*() =
  ## Draws the application header with decorative lines and emojis.
  updateTermWidth()
  if termWidth < MinTerminalWidth:
    raise newException(UIError, "Terminal width too small.")

  # Draw the top border using the theme's separator color
  drawSeperatorUI(xpos = -1, offset = 0, color = currentTheme.separator)

  # Draw the application title with emojis using the theme's header color
  let title =
    when not defined(noEmoji): "       🎧 " & AppName & " 🎧"
    else: "          " & AppName
  say(title, currentTheme.header, xOffset = (termWidth - title.len) div 2)

  # Draw the bottom border of the header using the theme's separator color
  drawSeperatorUI(xpos = -1, offset = 0, color = currentTheme.separator)

var lastTermWidth = termWidth  # Track the last terminal width

proc updateTermWidth* =
  ## Updates the terminal width if it has changed significantly.
  let newWidth = terminalWidth()
  if abs(newWidth - lastTermWidth) >= 5:  # Only update if the change is significant
    termWidth = newWidth
    lastTermWidth = newWidth

proc renderMenuOptions(options: MenuOptions, numColumns: int,
    maxColumnLengths: seq[int], spacing: int) =
  ## Renders the menu options in a multi-column layout.
  when not defined(simple):
    emojiPositions = @[]  # Clear previous positions
  let itemsPerColumn = (options.len + numColumns - 1) div numColumns

  # Wait for the terminal width to stabilize
  var stableWidth = false
  while not stableWidth:
    updateTermWidth()
    if abs(termWidth - lastTermWidth) < 5:  # Terminal width is stable
      stableWidth = true
    else:
      sleep(100)  # Wait for 100ms before checking again

  var currentY = 5  # Starting Y coordinate (after header and category title)

  for row in 0 ..< itemsPerColumn:
    var currentLine = ""
    for col in 0 ..< numColumns:
      let index = row + col * itemsPerColumn
      if index < options.len:
        # Calculate the prefix for the menu option
        var prefix =
          if index < 9: $(index + 1) & "."  # Use numbers 1-9
          else:
            if index < MenuChars.len: $MenuChars[index] & "."  # Use A-Z
            else: "?"  # Fallback

        when not defined(simple):
          # Calculate X position for the emoji
          var emojiX = 0
          for i in 0..<col:
            emojiX += maxColumnLengths[i] + spacing

          emojiX += prefix.len + 1 # +1 for the space after the number/letter

          # Add to emojiPositions.  currentY is calculated *before* adding the line.
          emojiPositions.add((emojiX, currentY))

        prefix = " " & prefix

        # Truncate and format
        let truncatedName = truncateName(options[index], maxColumnLengths[col] - prefix.len)
        let formattedOption = prefix & truncatedName
        let padding = maxColumnLengths[col] - formattedOption.len
        currentLine.add(formattedOption & " ".repeat(padding))

      else:
        # Add empty space
        currentLine.add(" ".repeat(maxColumnLengths[col]))

      # Add spacing between columns
      if col < numColumns - 1:
        currentLine.add(" ".repeat(spacing))

    # Render the line
    say(currentLine, fgBlue)
    currentY += 1  # Increment Y *after* drawing the line

proc getFooterOptions*(isMainMenu, isPlayerUI: bool): string =
  ## Returns footer options string based on context (main menu/submenu/player).
  result =
    if isMainMenu: "[Q] Quit | [N] Notes | [U] Help | [S] ChooseForMe"
    elif isPlayerUI:
      "[Q] Quit | [R] Return | [P] Pause/Play | [-/+] Vol | [L] Like"
    else: "[Q] Quit | [R] Return | [U] Help | [S] ChooseForMe"

proc displayMenu*(
  options: MenuOptions,
  showReturnOption = true,
  highlightActive = true,
  isMainMenu = false,
  isPlayerUI = false,
  isHandlingJSON = false
) =
  ## Displays menu options in a formatted multi-column layout.
  updateTermWidth()

  var options = options

  # 1. Initialization
  var currentY = 1  # Start at the top

  # Draw the "Station Categories" section header
  let categoriesHeader =
    when not defined(noEmoji): "         📻 Station Categories 📻"
    else: "         \\[o=] Station Categories [o=]/"
  say(categoriesHeader, fgCyan, xOffset = (termWidth - categoriesHeader.len) div 2)
  currentY += 1  # Increment after header

  # Draw the separator line
  drawSeperatorUI(xpos = -1, sep = '-', offset = 0)
  currentY += 1  # Increment after separator

  # Calculate column layout and render menu options
  let (numColumns, maxColumnLengths, spacing) = calculateColumnLayout(options)
  renderMenuOptions(options, numColumns, maxColumnLengths, spacing)

  # 3. Counting Rows (after rendering)
  let itemsPerColumn = (options.len + numColumns - 1) div numColumns
  currentY += itemsPerColumn

  when not defined(simple):
    if isHandlingJSON:
      initDrawMenuEmojis() # Draw yellow emojis *after* rendering text
  echo ""
  currentY += 1 # Increment after the empty line
  # 4. Tracking the Separator's Y
  # footerSeparatorLineY = currentY  # Store the Y position *before* drawing
  lastMenuSeparatorY = currentY # Store the Y position *before* drawing, renamed variable
  # Draw the separator line
  #say(separatorLine, fgGreen, xOffset = 0)
  drawSeperatorUI(xpos = -1, sep = '-', offset = 0)
  currentY += 1 #increment after second separator

  # Display the footer options
  let footerOptions = getFooterOptions(isMainMenu, isPlayerUI)  # Pass isPlayerUI here
  say(footerOptions, fgYellow, xOffset = (termWidth - footerOptions.len) div 2)
  currentY += 1

  # Draw the bottom border
  drawSeperatorUI(xpos = -1, offset = 0)
  currentY += 1 #we are not tracking this, but it's good practice

 
proc drawMenu*(
  section: string,
  options: string | MenuOptions,
  subsection = "",
  showNowPlaying = true,
  isMainMenu = false,
  isPlayerUI = false,
  isHandlingJSON = false
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
    displayMenu(options, isMainMenu = isMainMenu, isPlayerUI = isPlayerUI, isHandlingJSON = isHandlingJSON)

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
  drawSeperatorUI(xpos = -1, '-', offset = 0, separatorColor)

  # Add footer with controls at the bottom
  setCursorPos(0, lineToDraw + 1)
  let footerOptions = getFooterOptions(isMainMenu, isPlayerUI)
  say(footerOptions, footerColor, xOffset = (termWidth - footerOptions.len) div 2)

  # Draw bottom border
  setCursorPos(0, lineToDraw + 2)
  drawSeperatorUI(xpos = -1, '=', offset = 0, separatorColor)

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
      """PNimRP Copyright (C) 2021-2025 antonl05/bloomingchad
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
  drawSeperatorUI(xpos = -1, '-')

proc volumeColor(volume: int): ForegroundColor =
  if volume > 110: fgRed
  elif volume < 60: fgBlue
  else:
    fgGreen

var
  animationFrame: int = 0 # Tracks the current frame of the animation
  lastAnimationUpdate: DateTime = now() # Tracks the last time the animation was updated

proc drawHeaderPlayerUI(section: string) =
  ## Draws the header section of the player UI.
  
  # Draw header if section is provided
  if section.len > 0:
    setCursorPos(0, 0)  # Line 0
    say(AppNameShort & " > " & section, fgYellow)

proc drawStatusAndVolumePlayerUI(status: string, volume: int) =
  ## Draws the status and volume section of the player UI.
  
  setCursorPos(0, 3)
  eraseLine()
  setCursorPos(0, 3)
  let volumeColor = volumeColor(volume)
  say("Status: " & status & " | Volume: ", fgGreen, xOffset = 0, shouldEcho = false)
  styledEcho(volumeColor, $volume & "%")

proc drawNowPlayingPlayerUI(nowPlaying: string) =
  when defined(simple):
    stdout.styledWrite(fgCyan, "Now Playing:   ", nowPlaying.truncateMe())

  else:
    # In normal mode, use the existing approach
    stdout.styledWrite(fgCyan, "   Now Playing:  ")
    if terminalSupportsEmoji:
      startingX = "  Now Playing: ".len + 1  # +1 for emoji space
    else:
      startingX = "  Now Playing: ".len + 3 # +3 because "[>]" is 3 chars long

proc updateVolumePlayerUI*(newVolume: int) =
  setCursorPos(21, 3)
  let volumeColor = volumeColor(newVolume)
  when defined(noEmoji):
    stdout.write "  "
  stdout.styledWrite(volumeColor, $newVolume & "% ") #when go from 100 to less
  stdout.flushFile()

proc updateCurrentSongPlayerUI*(songName: string) =
  setCursorPos(0, 2)  # Line 2 (below the separator)
  eraseLine()
  setCursorPos(0, 2)  #explicit duplicate setting just to be consistent across OSes
  drawNowPlayingPlayerUI(songName)
  stdout.flushFile()

proc drawPlayerUIInternal(section, nowPlaying, status: string, volume: int) =
  ## Internal function that handles the common logic for drawing and updating the player UI.
  updateTermWidth()  # Ensure the terminal width is up-to-date

  # Clear the screen and reset cursor position
  clear()

  # Draw header if section is provided
  drawHeaderPlayerUI(section)

  # Draw top separator
  drawSeperatorUI(xpos = 1, '-', offset = 0) # Line 1

  # Display "Now Playing" with truncation if necessary
  setCursorPos(0, 2)  # Line 2 (below the separator)
  eraseLine()
  drawNowPlayingPlayerUI(nowPlaying)

  # Display status and volume on the same line
  drawStatusAndVolumePlayerUI(status, volume)

  # Draw separator after status/volume
  drawSeperatorUI(xpos = 4, '-', offset = 0) # Line 4

  # Display footer options
  setCursorPos(0, 5)  # Line 5
  let footerOptions = "[P] Pause/Play   [V] Adjust Volume   [Q] Quit"
  say(footerOptions, fgYellow, xOffset = (termWidth - footerOptions.len) div 2)

  # Draw the bottom border
  drawSeperatorUI(xpos = 6, offset = 0)


proc updatePlayerUI*(nowPlaying, status: string, volume: int) =
  ## Updates the player UI with new information without redrawing the entire screen.

  # Update Now Playing line
  setCursorPos(0, 2)
  eraseLine()
  
  drawNowPlayingPlayerUI(nowPlaying)

  # Update Status and Volume line
  drawStatusAndVolumePlayerUI(status, volume)

  # Reset cursor position after updates
  setCursorPos(0, 5)

  # Reset scrollOffset when a new song starts
  when not defined(simple):
    scrollOffset = 0

proc drawPlayerUI*(section, nowPlaying, status: string, volume: int) =
  ## Draws the modern music player UI with dynamic layout and visual enhancements.
  clear()
  drawPlayerUIInternal(section, nowPlaying, status, volume)
