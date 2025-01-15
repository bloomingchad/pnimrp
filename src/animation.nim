import times

type
  AnimationFrame* = object
    frame: int
    lastUpdate: DateTime

const
  AsciiFrames* = ["♪♫", "♫♪"]  # ASCII fallback animation frames
  EmojiFrames* = ["🎵", "🎶"]  # Emoji animation frames

var
  animationFrame*: int = 0  # Tracks the current frame of the animation
  lastAnimationUpdate*: DateTime = now()  # Tracks the last time the animation was updated

# Check if the terminal supports emojis
proc checkEmojiSupport(): bool =
    let testEmojis = ["🔊", "⏸", "🔇", "🎵", "🎶"]

    for emoji in testEmojis:
        let testOutput = $emoji
        if testOutput != emoji:
            return false
    return true

# Global variable to store whether the terminal supports emojis
var terminalSupportsEmoji* = checkEmojiSupport()

proc updateJinglingAnimation*(status: string): string =
  ## Updates the jingling animation and returns the current frame.
  ## Returns an empty string if the player is not in the StatusPlaying state.
  let currentTime = now()  # Get the current time as DateTime

  # Calculate the time difference in milliseconds
  let timeDiff = currentTime - lastAnimationUpdate
  let timeDiffMs = timeDiff.inMilliseconds

  # Check if it's time to update the animation frame (2 FPS = every 500ms)
  if timeDiffMs >= 500:
    animationFrame = (animationFrame + 1) mod 2  # Alternate between 0 and 1
    lastAnimationUpdate = currentTime  # Update the last animation time

  # Determine the animation symbol based on terminal support and player status
  if status == "StatusPlaying":
    if terminalSupportsEmoji:
      return EmojiFrames[animationFrame]  # Use emoji frames
    else:
      return AsciiFrames[animationFrame]  # Use ASCII frames
  else:
    return ""  # No animation for other statuses