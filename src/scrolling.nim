# scrolling.nim
import terminal, times, strutils

const
  SCROLL_SPEED* = 5  # Milliseconds between updates
  NOW_PLAYING_PREFIX* = " "

proc getVisibleChunk*(text: string, offset: int, width: int): string =
  ## Calculates the visible portion of the text for scrolling.
  let visibleWidth = width - NOW_PLAYING_PREFIX.len - 4

  if text.len <= visibleWidth:
    return text

  let loopedText = text & " • "
  let start = offset mod loopedText.len
  let endIdx = start + visibleWidth

  return if endIdx <= loopedText.len:
           loopedText[start..<endIdx]
         else:
           loopedText[start..^1] & loopedText[0..<endIdx - loopedText.len]