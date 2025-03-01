# asynclink.nim

import
  times, ../utils/utils, asyncdispatch,
  asyncnet, strutils, uri, link

from net import TimeoutError

const
  ResolveTimeout = 5000  # Timeout in milliseconds (5 seconds)

proc connectSocket(domain: string, port: Port): Future[bool] {.async.} =
  var socket = newAsyncSocket()
  let connectFuture = socket.connect(domain, port)
  let completed = await connectFuture.withTimeout(ResolveTimeout)
  socket.close()
  return completed

proc normalizeUrl(url: string): string =
  result = url
  if not result.startsWith("http://") and not result.startsWith("https://"):
    result = "http://" & result  # Default to HTTP if no protocol is specified

proc parseUrlComponents(url: string): tuple[protocol: string, domain: string, port: Port] =
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

proc tryConnect(domain: string, port: Port): Future[LinkStatus] {.async.} =
  try:
    let connected = await connectSocket(domain, port)
    if not connected:
      return lsInvalid
    return lsValid
  except IOError:
    return lsInvalid
  except:
    return lsInvalid

proc resolveLink*(url: string): Future[LinkStatus] {.async.} =
  try:
    let normalizedUrl = normalizeUrl(url)
    let (protocol, domain, port) = parseUrlComponents(normalizedUrl)
    result = await tryConnect(domain, port)
  except:
    result = lsInvalid
    #error("Unexpected error: " & getCurrentExceptionMsg())
