# linkresolver.nim

import
  times, utils, os, asyncdispatch,
  asyncnet, strutils, uri, utils, link

from net import TimeoutError

proc resolveLink*(url: string): Future[LinkStatus] {.async.} =
  var finalUrl = url
  if not finalUrl.startsWith("http://") and not finalUrl.startsWith("https://"):
    finalUrl = "http://" & finalUrl  # Default to HTTP if no protocol is specified

  try:
    # Parse the URL
    let uri = parseUri(finalUrl)
    let protocol = if uri.scheme == "": "http" else: uri.scheme
    let domain = uri.hostname
    let port = Port(
      if uri.port == "":
        if protocol == "https": 443 else: 80
        else: parseInt(uri.port)
    )

    if domain == "":
      raise newException(LinkCheckError, "Invalid domain")

    # Attempt asynchronous connection
    var socket = newAsyncSocket()
    await socket.connect(domain, port)
    socket.close()

    # Return validation result
    result = lsValid

  except IOError as e:
    result = lsInvalid
    error("IOError: " & e.msg)
  except TimeoutError as e:
    result = lsInvalid
    error("TimeoutError: " & e.msg)
  except:
    result = lsInvalid
    error("Unexpected error: " & getCurrentExceptionMsg())
