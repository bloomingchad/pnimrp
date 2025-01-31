import illwill, times, os, strutils, terminal

const
  PREFIX_LEN = "🎵 Now Playing: ".len #not needed but will keep it for easy testing

var
  scrollOffset* = 0
  lastWidth* = 0
  startingX* = 0
  scrollCounter* = 0  # Counter to control scrolling

proc setCursorForScroll() =
  setCursorPos(PREFIX_LEN - 2, 2)

proc clearLineForScroll() =
  setCursorForScroll()
  styledEcho(" ".repeat PREFIX_LEN)
  cursorUp()

proc getVisibleChunk(text: string, offset: int, width: int): string =
  # 'width' is the available width for the text itself (after the offset)

  if text.len <= width:
    return text

  let loopedText = text & " • "  # Add separator for smooth looping
  let start = offset mod loopedText.len
  let endIdx = start + width

  result =
    if endIdx <= loopedText.len:
      loopedText[start..<endIdx]
    else:
      loopedText[start..^1] & loopedText[0..<endIdx - loopedText.len]

proc scrollTextOnce*(text: string, offset: int, width: int, xStart: int) =
  ## Calculates and prints a single frame of the scrolled text, anchored to the right.
  setCursorForScroll()
  let visibleChunk = getVisibleChunk(text, offset, width - xStart - 3)

  # Calculate the starting position for printing, anchored to the right
  let startPos = width - visibleChunk.len # This is the corrected calculation

  # Clear to the end of the line and print the visible text
  clearLineForScroll()
  setCursorForScroll()

  stdout.styledWrite(fgCyan, visibleChunk)