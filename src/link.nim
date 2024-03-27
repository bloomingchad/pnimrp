import strutils, json, httpclient, net, ui

proc cleanLink(str: string): string =
  var link = str
  link.removePrefix "http://"
  link.removePrefix "https://"
  link.rsplit("/", maxSplit = 1)[0]
    #no use strutils.delete() for nimv1.2.14

#[proc checkHttpsOnly(linke: string): bool =
  var link = linke
  try:
    var client = newHttpClient()
    link = "http://" & cleanLink link
    discard client.getContent(link & "/currentsong")
  except ProtocolError:
    link.removePrefix "http://"
    link = "https://" & link
    return true
  except: return false
  return false]#

proc getCurrentSong*(linke: string): string =
#https and http can be connect checked w/o ssl
#use mpv stream_lavf.c to get icy-title from audio buffer
  let client = newHttpClient()
  var link = linke

  link = "http://" & cleanLink link
  try: #shoutcast
    #echo "getCurrentSong: ", link
    client.getContent(link & "/currentsong")
  except ProtocolError: #ICY404 Resource Not Found?
    "notimplemented"
  except HttpRequestError: #icecast
    try:
      to(
         parseJson(
           client.getContent(link & "/status-json.xsl")
        ){"icestats"}{"source"}[1]{"yp_currently_playing"},
        string
      )
    except HttpRequestError,
       JsonParsingError, #different technique than implemented
         ProtocolError, #connection refused?
           KeyError: "notimplemented"

proc splitLink(str: string): seq[string] = rsplit(str, ":", maxSplit = 1)

template isHttps(link: string): bool = link.startsWith "https://"

proc doesLinkWork*(link: string): bool =
  #echo "doeslinkworkInit: " & link
  let seq = splitLink cleanLink link
  #echo "doesLinkWorkSeq: ", seq
  #we cannot check w/o port
  try:
    newSocket().connect(
       seq[0],
       Port(
         if not isHttps link: uint16 parseInt seq[1]
           #for link with no port will except
         else: 443),
       timeout = 2000)
    echo "link dont cause except"
    return true
  except HttpRequestError: warn "HttpRequestError. bad link?"
  except IndexDefect: return true #lmpv will error IDEndFile if badLink
    #retuns false default in except
  except OSError: warn "OSError. No Internet? ConnectionRefused?"
  except TimeoutError: warn "timeout of 3s failed"
