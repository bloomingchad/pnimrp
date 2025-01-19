import std/[strutils, net, uri]

type
  LinkCheckError* = object of CatchableError
  LinkValidationResult* = object
    isValid*: bool
    error*: string
    protocol*: string
    domain*: string
    port*: Port

proc parseLink*(link: string): tuple[protocol, domain: string, port: Port] =
  ## Parses a URL into its components.
  ##
  ## Args:
  ##   link: The URL to parse
  ##
  ## Returns:
  ##   A tuple containing the protocol, domain, and port
  ##
  ## Raises:
  ##   LinkCheckError: If the URL is invalid or the domain is missing
  try:
    let uri = parseUri(link)
    let protocol = if uri.scheme == "": "http" else: uri.scheme
    let domain = uri.hostname
    let port = if uri.port == "":
                 if protocol == "https": Port(443) else: Port(80)
               else:
                 Port(parseInt(uri.port))

    if domain == "":
      raise newException(LinkCheckError, "Invalid domain")

    return (protocol, domain, port)
  except ValueError:
    raise newException(LinkCheckError, "Invalid URL format")

proc validateLink*(link: string, timeout: int = 2000): LinkValidationResult =
  ## Validates if a link is reachable.
  ##
  ## Args:
  ##   link: The URL to validate
  ##   timeout: Connection timeout in milliseconds (default: 2000)
  ##
  ## Returns:
  ##   LinkValidationResult object containing validation details
  ##
  ## Raises:
  ##   LinkCheckError: If the URL is invalid or the domain is missing
  try:
    let (protocol, domain, port) = parseLink(link)
    var socket = newSocket()

    # Attempt connection
    socket.connect(domain, port, timeout = timeout)
    socket.close()

    result = LinkValidationResult(
      isValid: true,
      error: "",
      protocol: protocol,
      domain: domain,
      port: port
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
    test "parseLink":
      let (protocol, domain, port) = parseLink("https://example.com:8080")
      check protocol == "https"
      check domain == "example.com"
      check port == Port(8080)

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