# asynclink.nim

import
  times, ../utils/utils, asyncdispatch,
  asyncnet, strutils, linkbase

from net import TimeoutError

const
  ResolveTimeout = 5000  # Timeout in milliseconds (5 seconds)

proc connectSocket(domain: string, port: Port): Future[bool] {.async.} =
  var socket = newAsyncSocket()
  let connectFuture = socket.connect(domain, port)
  let completed = await connectFuture.withTimeout(ResolveTimeout)
  socket.close()
  return completed

proc tryConnect(domain: string, port: Port): Future[LinkStatus] {.async.} =
  try:
    let connected = await connectSocket(domain, port)
    if not connected:
      return lsInvalid
    return lsValid
  except Exception as e:
    let result = handleLinkCheckError(e, ResolveTimeout)
    if result.isValid:
      return lsValid
    else:
      return lsInvalid

proc resolveLink*(url: string): Future[LinkStatus] {.async.} =
  try:
    let normalizedUrl = normalizeUrl(url)
    let (protocol, domain, port) = parseUrlComponents(normalizedUrl)
    result = await tryConnect(domain, port)
  except Exception as e:
    let result = handleLinkCheckError(e, ResolveTimeout)
    if result.isValid:
      return lsValid
    else:
      return lsInvalid
