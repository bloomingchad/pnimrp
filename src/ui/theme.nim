# theme.nim

import
  json, strutils,
  terminal, tables,

  ../utils/utils

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
      theme.header       =  parseEnum[ForegroundColor](themeData["header"]      .getStr())
      theme.separator    =  parseEnum[ForegroundColor](themeData["separator"]   .getStr())
      theme.menu         =  parseEnum[ForegroundColor](themeData["menu"]        .getStr())
      theme.footer       =  parseEnum[ForegroundColor](themeData["footer"]      .getStr())
      theme.error        =  parseEnum[ForegroundColor](themeData["error"]       .getStr())
      theme.warning      =  parseEnum[ForegroundColor](themeData["warning"]     .getStr())
      theme.success      =  parseEnum[ForegroundColor](themeData["success"]     .getStr())
      theme.nowPlaying   =  parseEnum[ForegroundColor](themeData["nowPlaying"]  .getStr())
      theme.volumeLow    =  parseEnum[ForegroundColor](themeData["volumeLow"]   .getStr())
      theme.volumeMedium =  parseEnum[ForegroundColor](themeData["volumeMedium"].getStr())
      theme.volumeHigh   =  parseEnum[ForegroundColor](themeData["volumeHigh"]  .getStr())

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
