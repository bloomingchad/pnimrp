# cache.nim

import std/[json, times, os, strutils, tables],
  ../utils/utils,
  ../link/link,
  ../link/asynclink

const
  CacheDir* = getAppDir() / "assets" / ".stationstatuscache"
  CacheTTL* = 86400  # 24 hours in seconds

type
  Cache* = object
   lastCheck*: string # Using string for ISO 8601 representation
   stations*: Table[string, string]  # URL -> "valid" / "invalid"
