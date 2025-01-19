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
  ##
  ## Args:
  ##   configPath: Path to the JSON configuration file
  ##
  ## Returns:
  ##   ThemeConfig object containing the loaded themes and current theme
  ##
  ## Raises:
  ##   ValueError: If the file is not found or the JSON format is invalid
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
  ##
  ## Args:
  ##   config: ThemeConfig object
  ##
  ## Returns:
  ##   The current theme
  ##
  ## Raises:
  ##   ValueError: If the current theme is not found in the config
  if config.currentTheme in config.themes:
    return config.themes[config.currentTheme]
  else:
    raise newException(ValueError, "Current theme not found in config")

proc setCurrentTheme*(config: var ThemeConfig, themeName: string) =
  ## Sets the current theme to the specified theme name.
  ##
  ## Args:
  ##   config: ThemeConfig object
  ##   themeName: Name of the theme to set as current
  ##
  ## Raises:
  ##   ValueError: If the theme is not found in the config
  if themeName in config.themes:
    config.currentTheme = themeName
  else:
    raise newException(ValueError, "Theme not found: " & themeName)

# Unit tests for theme.nim
when isMainModule:
  import unittest

  suite "Theme Tests":
    test "loadThemeConfig":
      let testJson = """
      {
        "themes": {
          "default": {
            "header": "fgBlue",
            "separator": "fgGreen",
            "menu": "fgYellow",
            "footer": "fgCyan",
            "error": "fgRed",
            "warning": "fgMagenta",
            "success": "fgGreen",
            "nowPlaying": "fgWhite",
            "volumeLow": "fgBlue",
            "volumeMedium": "fgYellow",
            "volumeHigh": "fgRed"
          }
        },
        "currentTheme": "default"
      }
      """
      writeFile("test_theme.json", testJson)
      let config = loadThemeConfig("test_theme.json")
      check config.currentTheme == "default"
      check config.themes["default"].header == fgBlue
      removeFile("test_theme.json")

    test "getCurrentTheme":
      let testJson = """
      {
        "themes": {
          "default": {
            "header": "fgBlue",
            "separator": "fgGreen",
            "menu": "fgYellow",
            "footer": "fgCyan",
            "error": "fgRed",
            "warning": "fgMagenta",
            "success": "fgGreen",
            "nowPlaying": "fgWhite",
            "volumeLow": "fgBlue",
            "volumeMedium": "fgYellow",
            "volumeHigh": "fgRed"
          }
        },
        "currentTheme": "default"
      }
      """
      writeFile("test_theme.json", testJson)
      let config = loadThemeConfig("test_theme.json")
      let theme = getCurrentTheme(config)
      check theme.header == fgBlue
      removeFile("test_theme.json")

    test "setCurrentTheme":
      let testJson = """
      {
        "themes": {
          "default": {
            "header": "fgBlue",
            "separator": "fgGreen",
            "menu": "fgYellow",
            "footer": "fgCyan",
            "error": "fgRed",
            "warning": "fgMagenta",
            "success": "fgGreen",
            "nowPlaying": "fgWhite",
            "volumeLow": "fgBlue",
            "volumeMedium": "fgYellow",
            "volumeHigh": "fgRed"
          },
          "dark": {
            "header": "fgBlack",
            "separator": "fgWhite",
            "menu": "fgGray",
            "footer": "fgBlack",
            "error": "fgRed",
            "warning": "fgYellow",
            "success": "fgGreen",
            "nowPlaying": "fgWhite",
            "volumeLow": "fgBlue",
            "volumeMedium": "fgYellow",
            "volumeHigh": "fgRed"
          }
        },
        "currentTheme": "default"
      }
      """
      writeFile("test_theme.json", testJson)
      var config = loadThemeConfig("test_theme.json")
      setCurrentTheme(config, "dark")
      check config.currentTheme == "dark"
      removeFile("test_theme.json")