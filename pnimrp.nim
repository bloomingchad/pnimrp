import
  os,
  src/[menu, ui, illwill],
  terminal, strformat,   std/exitprocs


type
  AppConfig = object
    assetsDir: string
    version: string

const
  AppName = "Poor Man's Radio Player"
  Version = "1.0.0"
  RequiredAssets = [
    "quote.json"  # Add other required asset files here
  ]

proc validateEnvironment() =
  ## Validates the application environment and requirements
  let assetsDir = getAppDir() / "assets"
  
  # Check assets directory
  if not dirExists(assetsDir):
    error "Assets directory not found: " & assetsDir
  
  # Verify required assets exist
  #for asset in RequiredAssets:
  #  let assetPath = assetsDir / asset
  #  if not fileExists(assetPath):
  #    error "Required asset not found: " & assetPath
  
  # Check for write permissions in necessary directories
  #try:
  #  let testFile = assetsDir / ".write_test"
  #  writeFile(testFile, "")
  #  removeFile(testFile)
  #except IOError:
  #  error "No write permission in assets directory"
  #except Exception as e:
  #  error "Failed to validate environment: " & e.msg

proc getAppConfig(): AppConfig =
  ## Initializes application configuration
  result = AppConfig(
    assetsDir: getAppDir() / "assets",
    version: Version
  )

proc showBanner() =
  ## Displays application banner
  styledEcho(fgCyan, fmt"""
{AppName} v{Version}
Copyright (c) 2021-2024
""")

proc cleanup()  =
  ## Performs cleanup on application exit
  showCursor()
  echo "\nThank you for using " & AppName

when defined(dragonfly):
  {.error: """
    PNimRP is not supported under DragonFlyBSD
    Please see user.rst for more information.
  """}

proc main() =
  ## Main application entry point
  try:
    # Set up cleanup handler
    addExitProc(cleanup)  # Updated: Replaced addQuitProc with addExitProc
    
    # Initialize
    validateEnvironment()
    let config = getAppConfig()
    
    # Display banner and start UI
    showBanner()
    hideCursor()
    
    # Start main menu
    drawMainMenu(config.assetsDir)
    
  except Exception as e:
    error "Fatal error: " & e.msg
  finally:
    cleanup()

when isMainModule:
  main()
