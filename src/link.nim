import strutils, #[json,]# httpclient, net, ui

proc cleanLink(str: string): string =
  var link = str
  link.removePrefix "http://"
  link.removePrefix "https://"
  link.split("/", maxSplit = 1)[0]

proc splitLink(str: string): seq[string] = split(str, ":", maxSplit = 1)

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
         if link.isHttps: 443
           #for link with no port will except
         else: parseInt seq[1]),
       timeout = 2000)
    echo "link dont cause except"
    return true
  except HttpRequestError: warn "HttpRequestError. bad link?"
  except IndexDefect: return true #lmpv will error IDEndFile if badLink
    #retuns false default in except
  except OSError: warn "OSError. No Internet? ConnectionRefused?"
  except TimeoutError: warn "timeout of 3s failed"
