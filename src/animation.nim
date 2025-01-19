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


proc getSymbol*(status: PlayerStatus, useEmoji: bool): string =
  ## Returns the appropriate symbol for the player status.
  ##
  ## Args:
  ##   status: The player status (e.g., StatusPlaying, StatusMuted).
  ##   useEmoji: Whether to use emoji symbols or fallback ASCII symbols.
  ##
  ## Returns:
  ##   The symbol corresponding to the player status.
  if useEmoji:
    case status
    of StatusPlaying: return "🔊"
    of StatusMuted: return "🔇"
    of StatusPaused: return "⏸"
    of StatusPausedMuted: return "⏸ 🔇"
  else:
    case status
    of StatusPlaying: return "[>]"
    of StatusMuted: return "[X]"
    of StatusPaused: return "||"
    of StatusPausedMuted: return "||[X]"

var terminalSupportsEmoji* = checkEmojiSupport()

proc currentStatusEmoji*(status: PlayerStatus): string =
  ## Returns the appropriate symbol for the player status based on terminal emoji support.
  ##
  ## Args:
  ##   status: The player status (e.g., StatusPlaying, StatusMuted).
  ##
  ## Returns:
  ##   The symbol corresponding to the player status.
  return getSymbol(status, terminalSupportsEmoji)
# Global variable to store whether the terminal supports emojis


# Function to get the appropriate symbol based on terminal support


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
