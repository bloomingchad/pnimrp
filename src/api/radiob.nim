import std/cmdline

import net, httpclient, json, strutils

let baseUrl = "https://de2.api.radio-browser.info/"

let client = newHttpClient(sslContext=newContext(verifyMode=CVerifyNone))

#let fileName = "house.json"
let fileName = commandLineParams()[0] #"house.json"

proc sanitizeStr(str: string): string =
  var tempStr = str
  tempStr.removePrefix("\"")
  tempStr.removeSuffix("\"")
  return tempStr

proc getStyleToProcessFromFileName(fileName: string): string =
  var styleFromFilename = fileName
  styleFromFileName.removeSuffix(".json")
  result = styleFromFilename


let styleToProcess = getStyleToProcessFromFileName(fileName)


template skipThisLoopIfTooLong =
  if ($name in nameItems) or (name.getStr.len > 40):
    #echo "[SKIPPED] name: ", name
    #echo "[SKIPPED] len: ", name.getStr.len
    #echo "------------------"

    continue

  if (url.getStr.len > 70):
    continue

#echo baseUrl & "json/stations/bytag/" & styleToProcess & "/?hidebroken=true&limit=50"
#quit()

let e = client.getContent(baseUrl & "json/stations/bytag/" & styleToProcess #& "/?hidebroken=true&limit=50"
)

let c = e.parseJson()

var nameItems: seq[string]
var urlItems:  seq[string]

var
  name: JsonNode
  url:  JsonNode

for station in 0 .. (c.len - 1):
  if nameItems.len == 20: break
  name = c[station]["name"]
  url = c[station]["url"]

  skipThisLoopIfTooLong()
  #echo "name: ", name #, ": "
  #echo "len: ", name.getStr.len

    
  nameItems.add $name

  #echo "url: ", url
  urlItems.add $url
  #echo "------------------"
#echo c.pretty()

proc constructAndWriteExpectedJsonFromNamesAndUrlItem(nameItems, urlItems: seq[string]): string =
  var jsonObject = %* {"stations": {}}
  var stationList = newJObject()

  #var jsonStationsObject = jsonObject["stations"]
  for key in 0 .. nameItems.len - 1:
    #stationList.add(nameItems[key], %*urlItems[key])
    var cleanedStationName = nameItems[key].sanitizeStr()
    var cleanedStationUrl  =  urlItems[key].sanitizeStr()
    stationList[cleanedStationName] = %* cleanedStationUrl

  jsonObject["stations"] = stationList

    #.add(urlItems[key])
  return jsonObject.pretty

echo constructAndWriteExpectedJsonFromNamesAndUrlItem(nameItems, urlItems)
