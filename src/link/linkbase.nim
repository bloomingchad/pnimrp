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
    result = "http://" & result # Default to HTTP if no protocol is specified

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
