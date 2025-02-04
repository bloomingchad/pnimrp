
import os, strutils, net, httpclient, json, uri

type
  LinkCheckResult = object
    stationName, url: string
    valid: bool
    error: string

proc checkUrl(url: string): LinkCheckResult =
  result = LinkCheckResult(url: url)
  
  try:
    let client = newHttpClient()
    client.headers = newHttpHeaders({"User-Agent": "PNimRP Link Checker"})
    client.timeout = 5000
    
    let response = client.head(url)
    if response.code.int == 200:
      result.valid = true
    else:
      result.error = "HTTP " & $response.code.int
      
  except Exception as e:
    result.error = e.msg

proc processJsonFile(filePath: string) =
  let jsonData = parseFile(filePath)
  
  if not jsonData.hasKey("stations"):
    echo "⚠️ No stations found in ", filePath
    return
    
  for name, url in jsonData["stations"].pairs:
    var check = checkUrl(url.getStr())
    check.stationName = name
    
    if check.valid:
      echo "✅ ", name
    else:
      echo "❌ ", name, " - ", check.error

proc main() =
  echo "🔍 Checking stations..."
  for file in walkDirRec("assets"):
    if file.endsWith(".json"):
      processJsonFile(file)
  echo "✨ Done!"

when isMainModule:
  main()
