import
  terminal, strutils, net,
  tables,

  ui, illwill,

  ../audio/[
      player,
      libmpv,
    ],

  ../link/link,
  ../utils/[
    utils
    ],

  ../misc/like

when not defined(simple):
  import
    ../audio/metadata,
    ../ui/[
      scroll,
      animation,
      ]

template volume(inc = true) =
  if inc: state.volume = min(state.volume + VolumeStep, MaxVolume)
  else:   state.volume = max(state.volume - VolumeStep, MinVolume)
  lastVolume = state.volume

proc editBadFileHint(config: MenuConfig, extraMsg = "") =
  if extraMsg != "": warn(extraMsg)
  let fileHint = if config.currentSubsection != "": config.currentSubsection else: config.currentSection
  setCursorPos(0, terminalHeight() - 4)

  warn("Failed to access station: " & config.stationName, delayMs = 0, dontRing = true)
  warn("URL: " & config.stationUrl, delayMs = 0, dontRing = true)
  warn("Edit station list in: " & fileHint & ".json", delayMs = 1350)

proc handlePlayerError(msg: string; config: MenuConfig; shouldReturn = false) =
  ## Handles player errors consistently and optionally destroys the player context.
  editBadFileHint(config, msg)
  if shouldReturn:
    return

func currentStatus(state: PlayerState): PlayerStatus =
  if not state.isPaused and not state.isMuted: StatusPlaying
  elif not state.isPaused and state.isMuted: StatusMuted
  elif state.isPaused and not state.isMuted: StatusPaused
  else:                                      StatusPausedMuted

func isValidPlaylistUrl(url: string): bool =
  ## Checks if the URL points to a valid playlist format (.pls or .m3u).
  result = url.endsWith(".pls") or url.endsWith(".m3u")

func milSecToSec(ms: int): float = ms / 1000

func getFileFormat(ctx: ptr Handle): string =
  # Query the `file-format` property
  var format: cstring = getPropertyString(ctx, "file-format")

  if format != nil:
    result = $format  # Convert cstring to Nim string
    free(format)  # Free the allocated cstring
  else:
    result = "unknown" # Fallback if the property is not available

proc playStation*(config: MenuConfig) =
  ## Plays a radio station and handles user input for playback control.
  #try:
  if config.stationUrl == "":
    editBadFileHint(config)
    return
  #defer: illwillDeinit()
  #illwillInit(false)

  # Validate the link
  try:
    initCheckingStationNotice()
    if not validateLink(config.stationUrl).isValid:
      editBadFileHint(config)
      return
    finishCheckingStationNotice()
  except Exception:
    editBadFileHint(config)
    return

  var state = PlayerState(isPaused: false, isMuted: false, volume: lastVolume) # Use lastVolume
  var isObserving = false
  var coreIdleCounter: uint8
  var playlistFirstPass = false
  var scrollOffset: int = 0
  var lastWidth: int = 0
  var fullTitle: string # Declare fullTitle here
  const mpvEventLoopTimeout = KeyTimeout.milSecToSec

  when not defined(simple):
    var metadata = initTable[string, string](8) # Declare metadata here
    var scrollCounter: int = 0
    var animationCounter: int = 0 # Counter for animation updates


  allocateJobMpv(config.stationUrl)
  var event = mpvCtx.waitEvent()


  # Draw the initial player UI
  drawPlayerUI(config.stationName, "Loading...", currentStatusEmoji(currentStatus(state)), state.volume)
  showFooter(isPlayerUI = true)
  when defined(simple):
    fullTitle = fullTitle.truncateMe()

  while true:
    if not state.isPaused:
      event = mpvCtx.waitEvent(mpvEventLoopTimeout)

    # Handle playback events
    if event.eventID in {IDPlaybackRestart} and not isObserving:
      when not defined(simple): mpvCtx.observeMetadata()
      else: mpvCtx.observeMediaTitle()

      isObserving = true

    if event.eventID in {IDEventPropertyChange}:
      state.currentSong = mpvCtx.getCurrentMediaTitle()
      fullTitle = state.currentSong # Assign to fullTitle
      config.appendToHistory()
      updateCurrentSongPlayerUI(state.currentSong)
      setCursorXPos 0
      when not defined(simple):
        globalMetadata = updateMetadataUI(config, mpvCtx, state)


    when not defined(simple):
      # Increment the animation counter every 25ms (getKeyWithTimeout interval)
      animationCounter += 1

      # Check if it's time to update the animation (1350ms / 50ms = 54 iterations)
      if animationCounter == 27:
        updateAnimationOnly(currentStatusEmoji(currentStatus(state)), state.currentSong, animationCounter)
        animationCounter = 0 # Reset the counter


        # Scrolling Logic
      if scrollCounter == 11:
        if state.currentSong.checkIfTooLongForUI():
          scrollTextOnce(fullTitle, scrollOffset, termWidth, startingX) # Corrected call
          if fullTitle.len > termWidth - startingX:
            scrollOffset += 1
          scrollCounter = 0
      else:
        scrollCounter += 1

    # Periodic checks
    if coreIdleCounter >= CheckIdleInterval:
      if mpvCtx.isIdle():
        handlePlayerError("Player core idle", config)
        break

      if event.eventID in {IDEndFile, IDShutdown}:
        if config.stationUrl.isValidPlaylistUrl():
          if playlistFirstPass:
            handlePlayerError("End of playlist reached", config)
            break
          playlistFirstPass = true
        else:
          handlePlayerError("Stream ended", config)
          break
      coreIdleCounter = 0
    inc coreIdleCounter

    # Handle user input
    case getKeyWithTimeout(KeyTimeout):
      of Key.P:
        state.isPaused = not state.isPaused
        mpvCtx.pause(state.isPaused)
        updatePlayMutedStatePlayerUI(currentStatusEmoji(currentStatus(state)))

      of Key.M:
        state.isMuted = not state.isMuted
        mpvCtx.mute(state.isMuted)
        updatePlayMutedStatePlayerUI(currentStatusEmoji(currentStatus(state)))

      of Key.Slash, Key.Plus:
        volume(inc = true)
        cE mpvCtx.setProperty("volume", fmtInt64, addr state.volume)
        updateVolumePlayerUI(state.volume)

      of Key.Asterisk, Key.Minus:
        volume(inc = false)
        cE mpvCtx.setProperty("volume", fmtInt64, addr state.volume)
        updateVolumePlayerUI(state.volume)

      of Key.R, Key.BackSpace:
        if not state.isPaused:
          cleanupPlayer(mpvCtx)
        stopCurrentJob()
        break

      of Key.Q, Key.Escape:
        cleanupPlayer(mpvCtx)
        exit(mpvCtx, state.isPaused)

      of Key.L: # New key binding for "Like" action
        if state.currentSong != "":
          appendToLikedSongs(config)
        else:
          warn("song field is currently empty")

      of Key.None:
        continue

      else:
        showInvalidChoice()

#except Exception:
  #  let fileHint = if config.currentSubsection != "": config.currentSubsection else: config.currentSection
  #  warn("An error occurred during playback. Edit the station list in: " & fileHint & ".json")
  #  cleanupPlayer(mpvCtx)
  #  return
