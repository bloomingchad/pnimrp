# linkresolver.nim

import
  times, utils, os, asyncdispatch,
  asyncnet, strutils, uri, utils, link

from net import TimeoutError

const
  ResolveTimeout = 5000  # Timeout in milliseconds (5 seconds)

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

    # Attempt asynchronous connection with timeout
    var socket = newAsyncSocket()
    let connectFuture = socket.connect(domain, port)
    let completed = await connectFuture.withTimeout(ResolveTimeout)

    if not completed:
      result = lsInvalid
      #error("TimeoutError: Connection timed out for URL: " & url)
      return

    socket.close()

    # Return validation result
    result = lsValid

  except IOError as e:
    result = lsInvalid
    #error("IOError: " & e.msg)
  except:
    result = lsInvalid
    #error("Unexpected error: " & getCurrentExceptionMsg())
