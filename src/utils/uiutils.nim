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

proc warn*(message: string, xOffset = 4, color = fgYellow, delayMs = 750) =
  ## Displays a warning message with a delay.
  if xOffset >= 0:
    setCursorXPos(xOffset)
  styledEcho(color, message)
  warnBell()
  sleep(delayMs)

proc showInvalidChoice*(message = DefaultErrorMsg) =
  ## Shows an invalid choice message and repositions the cursor.
  cursorDown(5)
  warn(message, color = fgRed)
  cursorUp()
  eraseLine()
  cursorUp(5)

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
