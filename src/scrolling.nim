# scrolling.nim
import terminal, times, strutils

const
  ScrollSpeed* = 5 # Milliseconds between updates
  NowPlayingPrefix* = " "

proc getVisibleChunk*(text: string, offset: int, width: int): string =
  ## Calculates the visible portion of the text for scrolling.
  let visibleWidth = width - NowPlayingPrefix.len - 4

  if text.len <= visibleWidth:
    return text

  let loopedText = text & " • "
  let start = offset mod loopedText.len
  let endIdx = start + visibleWidth

  return if endIdx <= loopedText.len:
           loopedText[start..<endIdx]
         else:
           loopedText[start..^1] & loopedText[0..<endIdx - loopedText.len]
