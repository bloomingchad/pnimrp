# link.nim

import std/net, linkbase

when not defined(simple):
  import linkadvanced

proc validateLinkSimpleSocket(link: string, timeout: int = 2000): LinkValidationResult =
  ## Validates if a link is reachable and parses its components.
  ## If the link does not have a protocol prefix (e.g., "http://"), it defaults to "http://".
  ##
  ## Args:
  ##   link: The URL to validate.
  ##   timeout: Connection timeout in milliseconds (default: 2000).
  ##
  ## Returns:
  ##   LinkValidationResult object containing validation details.
  let finalLink = normalizeUrl(link)

  try:
    # Parse the URL components using linkbase.nim
    let (protocol, domain, port) = parseUrlComponents(finalLink)

    # Attempt connection
    var socket = newSocket()
    socket.connect(domain, port, timeout = timeout)
    socket.close()

    # Return validation result
    result = LinkValidationResult(
      isValid: true,
      error: "",
      protocol: protocol,
      domain: domain,
      port: port
    )
  except Exception as e:
    # Handle exceptions using the reusable error-handling function
    result = handleLinkCheckError(e, timeout)

template validateLink*(url: string; timeout = 2000): LinkValidationResult =
  #when defined(simple):
    validateLinkSimpleSocket(url, timeout)
  #else:
  #  validateLinkWithContentTypeCheck(url, timeout)
