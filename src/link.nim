import std/[strutils, net, uri]

type
  LinkCheckError* = object of CatchableError
  LinkValidationResult* = object
    isValid*: bool
    error*: string
    protocol*: string
    domain*: string
    port*: Port

proc validateLink*(link: string, timeout: int = 2000): LinkValidationResult =
  ## Validates if a link is reachable and parses its components.
  ##
  ## Args:
  ##   link: The URL to validate.
  ##   timeout: Connection timeout in milliseconds (default: 2000).
  ##
  ## Returns:
  ##   LinkValidationResult object containing validation details.
  try:
    # Parse the URL
    let uri = parseUri(link)
    let protocol = if uri.scheme == "": "http" else: uri.scheme
    let domain = uri.hostname
    let port = if uri.port == "":
                 if protocol == "https": Port(443) else: Port(80)
               else:
                 Port(parseInt(uri.port))

    if domain == "":
      raise newException(LinkCheckError, "Invalid domain")

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
  except ValueError:
    result = LinkValidationResult(
      isValid: false,
      error: "Invalid URL format"
    )
  except LinkCheckError as e:
    result = LinkValidationResult(
      isValid: false,
      error: "Invalid URL: " & e.msg
    )
  except TimeoutError:
    result = LinkValidationResult(
      isValid: false,
      error: "Connection timed out after " & $timeout & "ms"
    )
  except OSError as e:
    result = LinkValidationResult(
      isValid: false,
      error: "Connection error: " & e.msg
    )
  except Exception as e:
    result = LinkValidationResult(
      isValid: false,
      error: "Unexpected error: " & e.msg
    )

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