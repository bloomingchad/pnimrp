import times

type
  AnimationFrame* = object
    frame: int
    lastUpdate: DateTime
  PlayerStatus* = enum # Enumeration for player states
    StatusPlaying
    StatusMuted
    StatusPaused
    StatusPausedMuted

const
  AsciiFrames* = ["♪♫", "♫♪"] # ASCII fallback animation frames
  EmojiFrames* = ["🎵", "🎶"]     # Emoji animation frames

# Fallback symbols for each state
proc getFallbackSymbol*(status: PlayerStatus): string =
  case status
  of StatusPlaying: return "[>]"
  of StatusMuted: return "[X]"
  of StatusPaused: return "||"
  of StatusPausedMuted: return "||[X]"

proc getEmojiSymbol*(status: PlayerStatus): string =
  case status
  of StatusPlaying: return "🔊"
  of StatusMuted: return "🔇"
  of StatusPaused: return "⏸"
  of StatusPausedMuted: return "⏸ 🔇"

var
  animationFrame*: int = 0 # Tracks the current frame of the animation
  lastAnimationUpdate*: DateTime = now() # Tracks the last time the animation was updated

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

# Function to get the appropriate symbol based on terminal support
proc currentStatusEmoji*(status: PlayerStatus): string =
  if terminalSupportsEmoji:
    return getEmojiSymbol(status)
  else:
    return getFallbackSymbol(status)

proc updateJinglingAnimation*(status: string): string =
  ## Updates the jingling animation and returns the current frame.
  ## Returns an empty string if the player is not in the StatusPlaying state.
  let currentTime = now() # Get the current time as DateTime

  # Calculate the time difference in milliseconds
  let timeDiff = currentTime - lastAnimationUpdate
  let timeDiffMs = timeDiff.inMilliseconds

  # Check if it's time to update the animation frame (2 FPS = every 500ms)
  if timeDiffMs >= 1350:
    animationFrame = (animationFrame + 1) mod 2 # Alternate between 0 and 1
    lastAnimationUpdate = currentTime # Update the last animation time

  # Determine the animation symbol based on terminal support and player status
  if status == currentStatusEmoji(StatusPlaying):
    if terminalSupportsEmoji:
      return EmojiFrames[animationFrame] # Use emoji frames
    else:
      return AsciiFrames[animationFrame] # Use ASCII frames
  else:
    return "" # No animation for other statuses
