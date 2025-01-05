import std/[strutils, net, uri, logging]

type
  LinkCheckError* = object of CatchableError
  LinkValidationResult* = object
    isValid*: bool
    error*: string
    protocol*: string
    domain*: string
    port*: Port

proc initLogger() =
  ## Initializes the logger for the module
  var consoleLogger = newConsoleLogger()
  addHandler(consoleLogger)
  setLogFilter(lvlInfo)

proc parseLink*(link: string): tuple[protocol, domain: string, port: Port] =
  ## Parses a URL into its components
  ## 
  ## Args:
  ##   link: The URL to parse
  ##
  ## Returns:
  ##   A tuple containing the protocol, domain, and port
  ##
  ## Example:
  ##   let parts = parseLink("https://example.com:8080")
  ##   echo parts.protocol  # "https"
  ##   echo parts.domain   # "example.com"
  ##   echo parts.port     # Port(8080)
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
  ## Validates if a link is reachable
  ## 
  ## Args:
  ##   link: The URL to validate
  ##   timeout: Connection timeout in milliseconds (default: 2000)
  ##
  ## Returns:
  ##   LinkValidationResult object containing validation details
  ##
  ## Example:
  ##   let result = validateLink("https://example.com")
  ##   if result.isValid:
  ##     echo "Link is valid!"
  ##   else:
  ##     echo "Link error: ", result.error
  
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

when isMainModule:
  # Initialize logger when module is run directly
  initLogger()
  
  # Example usage
  let testUrls = [
    "https://example.com",
    "http://localhost:8080",
    "invalid-url",
    "https://nonexistent.domain:443"
  ]
  
  for url in testUrls:
    let result = validateLink(url)
    if result.isValid:
      info("✓ Valid link: ", url)
      echo "  Protocol: ", result.protocol
      echo "  Domain: ", result.domain
      echo "  Port: ", result.port
    else:
      warn("✗ Invalid link: ", url)
      echo "  Error: ", result.error
