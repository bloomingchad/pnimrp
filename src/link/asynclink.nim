# asynclink.nim

import
  times, ../utils/utils, asyncdispatch,
  asyncnet, strutils, linkbase

from net import TimeoutError

when defined(asynclinkadv):
  import asynclinkadv

const
  ResolveTimeout = 5000 # Timeout in milliseconds (5 seconds)

proc connectSocket(domain: string, port: Port): Future[bool] {.async.} =
  var socket = newAsyncSocket()
  await sleepAsync(5)
  let connectFuture = socket.connect(domain, port)
  await sleepAsync(5)
  let completed = await connectFuture.withTimeout(ResolveTimeout)
  await sleepAsync(5)
  socket.close()
  await sleepAsync(5)
  return completed

proc tryConnect(domain: string, port: Port): Future[LinkStatus] {.async.} =
  try:
    let connected = await connectSocket(domain, port)
    if not connected:
      return lsInvalid
    return lsValid
  except Exception as e:
    await sleepAsync(5)
    let result = handleLinkCheckError(e, ResolveTimeout)
    if result.isValid:
      return lsValid
    else:
      return lsInvalid

proc resolveLink*(url: string): Future[LinkStatus] {.async.} =
 let normalizedUrl = normalizeUrl(url)

 when not defined(asynclinkadv):
  try:
    let (protocol, domain, port) = parseUrlComponents(normalizedUrl)
    result = await tryConnect(domain, port)
  except Exception as e:
    await sleepAsync(5)
    let result = handleLinkCheckError(e, ResolveTimeout)
    if result.isValid:
      return lsValid
    else:
      return lsInvalid
 else:
  #try:
    var fileInConsideration: File
    when not defined(release) or not defined(danger):
      let filePathNameExt = "debug.log"
      discard open(fileInConsideration, filePathNameExt, fmAppend)

    result = await  asyncLinkCheckTolerantWithContentType(normalizedUrl)
    fileInConsideration.writeLine tempFileLogContent
    fileInConsideration.close()
    tempFileLogContent = ""

  #except Exception as e:
    #await sleepAsync(5)
    #let result = handleLinkCheckError(e, ResolveTimeout)
    #if result.isValid:
    #  return lsValid
    #else:
    #  return lsInvalid
