# linkbase.nim

import strutils, uri, net

type
  LinkCheckError* = object of CatchableError
  LinkValidationResult* = object
    isValid*: bool
    error*: string
    protocol*: string
    domain*: string
    port*: Port

proc normalizeUrl*(url: string): string =
  result = url
  if not result.startsWith("http://") and not result.startsWith("https://"):
    result = "http://" & result  # Default to HTTP if no protocol is specified

proc parseUrlComponents*(url: string): tuple[protocol: string, domain: string, port: Port] =
  let uri = parseUri(url)
  let protocol = if uri.scheme == "": "http" else: uri.scheme
  let domain = uri.hostname
  
  let portNum = if uri.port == "":
    if protocol == "https": 443 else: 80
  else: 
    parseInt(uri.port)
  
  let port = Port(portNum)
  
  if domain == "":
    raise newException(LinkCheckError, "Invalid domain")
    
  return (protocol, domain, port)
