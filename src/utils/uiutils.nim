import utilstypes, terminal, ../audio/player, os, strutils

proc getSymbol*(status: PlayerStatus, useEmoji: bool): string =
  if useEmoji:
    case status
    of StatusPlaying:     "🔊"
    of StatusMuted:       "🔇"
    of StatusPaused:      "⏸"
    of StatusPausedMuted: "⏸ 🔇"
  else:
    case status
    of StatusPlaying:      "[>]"
    of StatusMuted:        "[X]"
    of StatusPaused:       "||"
    of StatusPausedMuted:  "||[X]"

var terminalSupportsEmoji* =
  when defined(noEmoji): false
  else: true

proc currentStatusEmoji*(status: PlayerStatus): string =
  return getSymbol(status, terminalSupportsEmoji)

proc error*(message: string) =
  ## Displays an error message and exits the program.
  styledEcho(fgRed, "Error: ", message)
  quit(QuitFailure)

proc updateTermWidth* =
  ## Updates the terminal width only if it has changed.
  let newWidth = terminalWidth()
  if newWidth != termWidth:
    termWidth = newWidth

proc clear* =
  ## Clears the screen and resets the cursor position.
  eraseScreen()
  setCursorPos(0, 0)

proc warn*(message: string, xOffset = 4, color = fgYellow, delayMs = 750; dontRing = false) =
  ## Displays a warning message with a delay.
  if xOffset >= 0:
    setCursorXPos(xOffset)
  styledEcho(color, message)
  if not dontRing: warnBell()
  sleep(delayMs)

proc showInvalidChoice*(message = DefaultErrorMsg) =
  ## Shows an invalid choice message and repositions the cursor.
  cursorDown(5)
  warn(message, color = fgRed)
  cursorUp()
  eraseLine()
  cursorUp(5)
  stdout.flushFile()

proc centerText*(text: string, width: int = termWidth): string =
  ## Centers the given text within the specified width.
  let padding = (width - text.len) div 2
  result = " ".repeat(max(0, padding)) & text

proc showSpinner*(delayMs: int = 100) =
  ## Displays a simple spinner animation.
  const spinner = @["-", "\\", "|", "/"]
  var frame = 0
  while true:
    stdout.write("\r" & spinner[frame] & " Working...")
    stdout.flushFile()
    frame = (frame + 1) mod spinner.len
    sleep(delayMs)

proc truncateName*(name: string, maxLength: int): string =
  ## Truncates a station name to the specified maximum length and adds ellipsis.
  if termWidth <= MinTerminalWidth or name.len > maxLength:
    name[0 ..< maxLength - 3] #& "..."  # Always truncate at minimum width
  else: name

proc calculateColumnLayout*(options: MenuOptions): (int, seq[int], int) =
  ## Calculates the number of columns, max column lengths, and spacing.
  const minColumns = 2
  const maxColumns = 3
  var numColumns = maxColumns

  # Calculate the maximum length of items including prefix
  var maxItemLength = 0
  for i in 0 ..< options.len:
    let prefix =
      if i < 9: $(i + 1) & "."                    # Use numbers 1-9 for the first 9 options
      else:
        if i < MenuChars.len: $MenuChars[i] & "." # Use A-Z for the next options
        else: "?"                                 # Fallback
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
      if i < 9: $(i + 1) & "."
      else: $MenuChars[i] & "."
    let itemLength = prefix.len + 1 + options[i].len # +1 for emoji/space
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

  # make more resillient to unstable middle.
  # we this will make the menu items begin truncating
  # when nearing end
  spacing = spacing - 3

  while spacing >= minSpacing:
    let totalWidthWithSpacing = totalWidth + spacing * (numColumns - 1)
    if totalWidthWithSpacing <= termWidth:
      break # We have enough space with the current spacing
    spacing -= 1 # Reduce spacing and try again

  # Check if we have enough space even with the minimum spacing
  if spacing < minSpacing:
    # Calculate maxAllowedLength *outside* the loop.  This gives it a type.
    var maxAllowedLength: int
    for i in 0 ..< maxColumnLengths.len:
      # *Assign* to maxAllowedLength inside the loop.
      maxAllowedLength = (termWidth div numColumns - spacing) - 3 # Bias
      if maxColumnLengths[i] > maxAllowedLength:
        maxColumnLengths[i] = maxAllowedLength

  return (numColumns, maxColumnLengths, spacing)
