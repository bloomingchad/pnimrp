import std/net, httpclient, linkbase

template tryGetWhenMediaServerDoesNotSupportHead(url: string) = #TODO
  discard

proc validateLinkWithContentTypeCheck*(url: string; timeout = 2000): LinkValidationResult =
  var url = normalizeUrl(url)
  var sslCtxWithNoVerify = newContext(verifyMode=CVerifyNone)

  try:
    var client = newHttpClient(
      timeout = timeout,
      sslContext=sslCtxWithNoVerify
     )
    var clientResponse = client.head(url)

    var clientResponseContentType = clientResponse.contentType()
    var clientResponseStatusCode = clientResponse.code()
    client.close()

    var status: bool

    if clientResponseContentType != "":
      status =  true#.startsWith("audio/")

    if $clientResponseStatusCode == $405:
      #tryGetWhenMediaServerDoesNotSupportHead(url)
      result = LinkValidationResult(isValid: status)

    result = LinkValidationResult(
      isValid: status
    )
  except Exception as e:
    #Handle exceptions using the reusable error-handling function
    result = handleLinkCheckError(e, timeout)
