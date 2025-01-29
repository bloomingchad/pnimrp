# scrolling.nim
import terminal, times, strutils, os

const
  SCROLL_SPEED = 500
  NOW_PLAYING_PREFIX* = "   Now Playing: "

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

proc scrollTextOnce*(
  text: string,
  status: string,
  volume: int,
  updateUICallback: proc (text: string, status: string, volume: int) {.nimcall.}
): bool =
  ## Scrolls the text once.
  var
    scrollOffset = 0
    lastWidth = terminalWidth()
    needsScrolling = text.len > (lastWidth - NOW_PLAYING_PREFIX.len - 4)

  if not needsScrolling:
    updateUICallback(text, status, volume) # No prefix needed here
    sleep(SCROLL_SPEED)
    return true

  while scrollOffset <= text.len + lastWidth:
    let currentWidth = terminalWidth()

    if currentWidth != lastWidth:
      scrollOffset = 0
      lastWidth = currentWidth
      needsScrolling = text.len > (currentWidth - NOW_PLAYING_PREFIX.len - 4)
      if not needsScrolling:
        updateUICallback(text, status, volume) # No prefix needed here
        sleep(SCROLL_SPEED)
        return true

    let currentText = getVisibleChunk(text, scrollOffset, currentWidth)
    updateUICallback(currentText, status, volume) # No prefix needed here

    scrollOffset += 1
    sleep(SCROLL_SPEED)

  return true