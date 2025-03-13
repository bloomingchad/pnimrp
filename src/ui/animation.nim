# animation.nim

import terminal, ../utils/utils




proc updateJinglingAnimation*(status: string, animationCounter: int): string =
  ## Updates the jingling animation and returns the current frame.
  ## Returns an empty string if the player is not in the StatusPlaying state.
  ##
  ## Args:
  ##   status: The player status (e.g., "🔊" for playing).
  ##   animationCounter: The current counter value (incremented every 25ms).
  ##
  ## Returns:
  ##   The current animation frame (emoji or ASCII).

  # Check if it's time to update the animation frame (1350ms / 50ms = 27 iterations)
  if animationCounter == 27:
    animationFrame = (animationFrame + 1) mod 2  # Alternate between 0 and 1

  # Determine the animation symbol based on terminal support and player status
  if status == currentStatusEmoji(StatusPlaying):
    if terminalSupportsEmoji:
      return EmojiFrames[animationFrame]  # Use emoji frames
    else:
      return AsciiFrames[animationFrame]  # Use ASCII frames
  else:
    return ""  # No animation for other statuses

proc updateAnimationOnly*(status, currentSong: string, animationCounter: int) =
  ## Updates only the animation symbol in the "Now Playing" section.
  ##
  ## Args:
  ##   status: The player status (e.g., "🔊" for playing).
  ##   currentSong: The currently playing song.
  ##   animationCounter: The current counter value (incremented every 25ms).
  let animationSymbol = updateJinglingAnimation(status, animationCounter)  # Get the animation symbol

  # Move the cursor to the start of the "Now Playing" line (line 2)
  setCursorPos(0, 2)
  
  # Write ONLY the animation symbol and 3 spaces, then erase to the end of the line
  stdout.styledWrite(fgCyan, animationSymbol)
  stdout.flushFile()
