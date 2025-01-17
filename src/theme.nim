# theme.nim
import
  json, strutils, os,
  terminal, tables

type
  Theme* = object
    header*: ForegroundColor
    separator*: ForegroundColor
    menu*: ForegroundColor
    footer*: ForegroundColor
    error*: ForegroundColor
    warning*: ForegroundColor
    success*: ForegroundColor
    nowPlaying*: ForegroundColor
    volumeLow*: ForegroundColor
    volumeMedium*: ForegroundColor
    volumeHigh*: ForegroundColor

  ThemeConfig* = object
    themes*: Table[string, Theme]
    currentTheme*: string

proc loadThemeConfig*(configPath: string): ThemeConfig =
  ## Loads the theme configuration from the specified JSON file.
  try:
    let jsonData = parseFile(configPath)
    result.themes = initTable[string, Theme]()

    for themeName, themeData in jsonData["themes"]:
      var theme: Theme
      theme.header = parseEnum[ForegroundColor](themeData["header"].getStr())
      theme.separator = parseEnum[ForegroundColor](themeData["separator"].getStr())
      theme.menu = parseEnum[ForegroundColor](themeData["menu"].getStr())
      theme.footer = parseEnum[ForegroundColor](themeData["footer"].getStr())
      theme.error = parseEnum[ForegroundColor](themeData["error"].getStr())
      theme.warning = parseEnum[ForegroundColor](themeData["warning"].getStr())
      theme.success = parseEnum[ForegroundColor](themeData["success"].getStr())
      theme.nowPlaying = parseEnum[ForegroundColor](themeData["nowPlaying"].getStr())
      theme.volumeLow = parseEnum[ForegroundColor](themeData["volumeLow"].getStr())
      theme.volumeMedium = parseEnum[ForegroundColor](themeData["volumeMedium"].getStr())
      theme.volumeHigh = parseEnum[ForegroundColor](themeData["volumeHigh"].getStr())

      result.themes[themeName] = theme

    result.currentTheme = jsonData["currentTheme"].getStr()
  except IOError:
    raise newException(ValueError, "Failed to load theme config: File not found")
  except JsonParsingError:
    raise newException(ValueError, "Failed to parse theme config: Invalid JSON format")

proc getCurrentTheme*(config: ThemeConfig): Theme =
  ## Returns the currently active theme.
  if config.currentTheme in config.themes:
    return config.themes[config.currentTheme]
  else:
    raise newException(ValueError, "Current theme not found in config")

proc setCurrentTheme*(config: var ThemeConfig, themeName: string) =
  ## Sets the current theme to the specified theme name.
  if themeName in config.themes:
    config.currentTheme = themeName
  else:
    raise newException(ValueError, "Theme not found: " & themeName)
