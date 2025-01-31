import illwill, times, os, strutils, terminal, strformat

const
  PREFIX_LEN = "🎵 Now Playing: ".len

var
  scrollOffset* = 0
  lastWidth* = 0
  startingX* = 0
  scrollCounter* = 0
  debugLogFile: File = open("debug.log", fmWrite)

proc logDebug*(msg: string, indentLevel: int = 0) =
  ## Writes a debug message to the debug log file with a timestamp and indentation.
  #let timestamp = now().format("yyyy-MM-dd HH:mm:ss.SSS")
  #let indent = "  ".repeat(indentLevel)  # Two spaces per indent level
  #debugLogFile.writeLine(indent & msg)
  #debugLogFile.flushFile()
  discard

proc setCursorForScroll(indentLevel: int = 0) =
  ## Sets the cursor position for scrolling.
  logDebug("setCursorForScroll() called", indentLevel)
  setCursorPos(PREFIX_LEN - 2, 2)
  logDebug(fmt"Side-effect: Cursor position set to ({PREFIX_LEN - 2}, 2)", indentLevel + 1)

proc clearLineForScroll(start: int, len: int, indentLevel: int = 0) =
  ## Clears a specific portion of the line for scrolling.
  logDebug(fmt"clearLineForScroll(start: {start}, len: {len}) called", indentLevel)

  # Ensure start is within bounds
  if start >= 0 and start < terminalWidth():
    setCursorPos(start, 2)
    logDebug(fmt"Side-effect: Cursor position set to ({start}, 2)", indentLevel + 1)

    # Ensure we don't clear beyond the terminal width
    let clearLen = min(len, terminalWidth() - start)
    logDebug(fmt"Calculated clearLen: {clearLen}", indentLevel + 1)

    if clearLen > 0:
      stdout.write(" ".repeat(clearLen))
      logDebug(fmt"Side-effect: Wrote {clearLen} spaces to stdout", indentLevel + 1)
      stdout.flushFile()
      logDebug(fmt"Side-effect: Flushed stdout", indentLevel + 1)
  else:
    logDebug("Warning: start position out of bounds", indentLevel + 1)

proc getVisibleChunk(text: string, offset: int, width: int, indentLevel: int = 0): string =
  ## Gets the visible portion of the text to be scrolled.
  logDebug(fmt"getVisibleChunk(text: {text}, offset: {offset}, width: {width}) called", indentLevel)

  if text.len <= width:
    logDebug(fmt"Text length ({text.len}) is less than or equal to width ({width}). Returning entire text.", indentLevel + 1)
    result = text
  else:
    let loopedText = text & " • "
    logDebug(fmt"Looped text: {loopedText}", indentLevel + 1)

    let start = offset mod loopedText.len
    logDebug(fmt"Calculated start index: {start}", indentLevel + 1)

    let endIdx = start + width
    logDebug(fmt"Calculated end index: {endIdx}", indentLevel + 1)

    result =
      if endIdx <= loopedText.len:
        loopedText[start..<endIdx]
      else:
        loopedText[start..^1] & loopedText[0..<endIdx - loopedText.len]

  logDebug(fmt"Returning visible chunk: {result}", indentLevel + 1)

proc scrollTextOnce*(text: string, offset: int, width: int, xStart: int, indentLevel: int = 0) =
  ## Calculates and prints a single frame of the scrolled text.
  logDebug(fmt"scrollTextOnce(text: {text}, offset: {offset}, width: {width}, xStart: {xStart}) called", indentLevel)

  let visibleChunk = getVisibleChunk(text, offset, width - xStart - 3, indentLevel + 1)
  logDebug(fmt"Visible chunk obtained: {visibleChunk}", indentLevel + 1)

  let clearStart = xStart
  logDebug(fmt"Calculated clearStart: {clearStart}", indentLevel + 1)

  # Ensure visibleChunk length does not exceed terminal width
  let clearLen = min(visibleChunk.len, terminalWidth() - clearStart)
  logDebug(fmt"Calculated clearLen: {clearLen}", indentLevel + 1)

  # Clear only the portion where the text will be displayed
  clearLineForScroll(clearStart, clearLen, indentLevel + 1)

  # Position cursor and write the text
  setCursorPos(clearStart, 2)
  logDebug(fmt"Side-effect: Cursor position set to ({clearStart}, 2)", indentLevel + 1)

  stdout.styledWrite(fgCyan, visibleChunk)
  logDebug(fmt"Side-effect: Wrote visible chunk to stdout: {visibleChunk}", indentLevel + 1)

  stdout.flushFile()
  logDebug(fmt"Side-effect: Flushed stdout", indentLevel + 1)

proc closeDebugLog() =
  ## Closes the debug log file.
  logDebug("closeDebugLog() called")
  debugLogFile.close()
  logDebug("  Debug log file closed.")
