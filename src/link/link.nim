# link.nim

import std/net, linkbase

proc handleLinkCheckError*(e: ref Exception, timeout: int): LinkValidationResult =
  ## Handles exceptions during link validation and returns a `LinkValidationResult`.
  ## This function is reusable and handles specific exceptions like `OSError`, `IOError`, etc.
  ##
  ## Args:
  ##   e: The exception to handle.
  ##   timeout: The timeout value used during the connection attempt.
  ##
  ## Returns:
  ##   LinkValidationResult object containing error details.
  if e of OSError or e of IOError:
    result = LinkValidationResult(
      isValid: false,
      error: "Connection error: " & e.msg
    )
  elif e of TimeoutError:
    result = LinkValidationResult(
      isValid: false,
      error: "Connection timed out after " & $timeout & "ms"
    )
  elif e of LinkCheckError:
    result = LinkValidationResult(
      isValid: false,
      error: "Invalid URL: " & e.msg
    )
  elif e of ValueError:
    result = LinkValidationResult(
      isValid: false,
      error: "Invalid URL format"
    )
  else:
    result = LinkValidationResult(
      isValid: false,
      error: "Unexpected error: " & e.msg
    )

proc validateLink*(link: string, timeout: int = 2000): LinkValidationResult =
  ## Validates if a link is reachable and parses its components.
  ## If the link does not have a protocol prefix (e.g., "http://"), it defaults to "http://".
  ##
  ## Args:
  ##   link: The URL to validate.
  ##   timeout: Connection timeout in milliseconds (default: 2000).
  ##
  ## Returns:
  ##   LinkValidationResult object containing validation details.
  var finalLink = normalizeUrl(link)

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

# Unit tests for link.nim
when isMainModule:
  import unittest

  suite "Link Tests":
    test "validateLink":
      let result = validateLink("https://example.com")
      check result.isValid == true
      check result.protocol == "https"
      check result.domain == "example.com"
      check result.port == Port(443)

    test "invalidLink":
      let result = validateLink("invalid-url")
      check result.isValid == false
      check "Invalid URL" in result.error
