# pnimrp.nim

import
  os,  terminal, strformat, std/exitprocs,
  src/[menu, utils, illwill, player, libmpv]

when not defined(simple):
  import src/theme

type
  AppConfig = object
    assetsDir: string # Directory where application assets are stored
    version: string   # Application version

const
  AppName = "Poor Man's Radio Player" # Name of the application
  Version = "0.1"                   # Current version of the application
  RequiredAssets = [
    "quote.json" # List of required asset files (can be expanded as needed)
  ]

proc validateEnvironment() =
  ## Validates the application environment, ensuring necessary assets and permissions are in place.
  let assetsDir = getAppDir() / "assets"

  # Ensure the assets directory exists
  if not dirExists(assetsDir):
    error "Assets directory not found: " & assetsDir

  # Future: Add checks for required assets and write permissions if needed

proc getAppConfig(): AppConfig =
  ## Initializes and returns the application configuration.
  result = AppConfig(
    assetsDir: getAppDir() / "assets", # Set the assets directory path
    version: Version # Set the application version
  )

proc showBanner() =
  ## Displays the application banner with version and copyright information.
  styledEcho(fgCyan, fmt"""
{AppName} v{Version}
Copyright (c) 2021-2024
""")

proc cleanup() =
  ## Performs cleanup tasks on application exit, such as restoring the cursor.
  showCursor()
  mpvCtx.destroy()
  echo ""
  echo "Thank you for using " & AppName

when defined(dragonfly):
  {.error: """
    PNimRP is not supported under DragonFlyBSD
    Please see user.rst for more information.
  """.}

proc main() =
  ## Main entry point for the application.
  try:
    # Register cleanup procedure to run on exit
    addExitProc(cleanup)

    when not defined(simple):
      # Load theme configuration
      let configPath = getAppDir() / "assets" / "config" / "themes.json"
      var themeConfig = loadThemeConfig(configPath)
      currentTheme = getCurrentTheme(themeConfig)

    else:
      currentTheme = Theme(
        header: fgYellow,
        separator: fgGreen,
        menu: fgBlue,
        footer: fgYellow,
        error: fgRed,
        warning: fgYellow,
        success: fgGreen,
        nowPlaying: fgCyan,
        volumeLow: fgBlue,
        volumeMedium: fgGreen,
        volumeHigh: fgRed
      )

    # Validate the environment and initialize configuration
    validateEnvironment()
    let config = getAppConfig()

    # Display the application banner and hide the cursor
    showBanner()
    hideCursor()

    #init global mpv context for reuse
    initGlobalMpv()
    
    # Start the main menu with the configured assets directory
    drawMainMenu(config.assetsDir)

  #except Exception as e:
    # Handle any fatal errors that occur during execution
  #  error "Fatal error: " & e.msg
  finally:
    # Ensure cleanup is always performed
    cleanup()

when isMainModule:
  main()
