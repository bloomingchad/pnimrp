# SPDX-License-Identifier: MPL-2.0
# scroll.nim

import strutils, terminal, illwill

proc clearLineForScroll(start: int, len: int, indentLevel: int = 0) =
  ## Clears a specific portion of the line for scrolling.

  # Ensure start is within bounds
  if start >= 0 and start < terminalWidth():
    setCursorPos(start, 2)

    # Ensure we don't clear beyond the terminal width
    let clearLen = min(len, terminalWidth() - start)

    if clearLen > 0:
      stdout.write(" ".repeat(clearLen))
      stdout.flushFile()

func getVisibleChunk(
    text: string,
    offset, width: int,
    indentLevel: int = 0
): string =
  ## Gets the visible portion of the text to be scrolled.

  if text.len <= width:
    result = text
  else:
    let loopedText = text & " • "
    let start = offset mod loopedText.len
    let endIdx = start + width

    result =
      if endIdx <= loopedText.len:
        loopedText[start ..< endIdx]
      else:
        loopedText[start ..^ 1] & loopedText[0 ..< endIdx - loopedText.len]

proc scrollTextOnce*(
    text: string,
    offset, width, xStart: int,
    indentLevel: int = 0
) =
  ## Calculates and prints a single frame of the scrolled text.
  let visibleChunk = getVisibleChunk(text, offset, width - xStart - 3, indentLevel + 1)
  let clearStart = xStart

  # Ensure visibleChunk length does not exceed terminal width
  let clearLen = min(visibleChunk.len, terminalWidth() - clearStart)

  # Clear only the portion where the text will be displayed
  clearLineForScroll(clearStart, clearLen, indentLevel + 1)

  # Position cursor and write the text
  setCursorPos(clearStart, 2)
  stdout.styledWrite(fgCyan, visibleChunk)
  stdout.flushFile()
