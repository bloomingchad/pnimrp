import std/net, httpclient, linkbase, strutils

template tryHttpGetWhenMediaServerDoesNotSupportHead(url: string) = #TODO
  discard

const validPlaylistTypesList = [
  "audio/x-scpls",
  "audio/x-mpegurl",
  "application/vnd.apple.mpegurl",
  "application/x-mpegurl",
  "application/pls+xml",
  "application/xspf+xml",
  "audio/x-ms-asx",
  "application/octet-stream"
]

proc isValidAudioOrPlaylistStreamContentType(contentType: string): bool =
  let normalizedContentType = contentType.toLowerAscii()
  if normalizedContentType.startsWith("audio/"): return true
  elif normalizedContentType in validPlaylistTypesList: return true
  return

proc validateLinkWithContentTypeCheck*(url: string; timeout = 2000): LinkValidationResult =
  let url = normalizeUrl(url)
  let sslCtxWithNoVerify = newContext(verifyMode = CVerifyNone)

  try:
    var client = newHttpClient(
      timeout = timeout,
      sslContext = sslCtxWithNoVerify
      )
    let clientResponse = client.head(url)

    let clientResponseContentType = clientResponse.contentType()
    let clientResponseStatusCodeString = $clientResponse.code()
    client.close()

    var status: bool

    if clientResponseContentType != "":
      status = clientResponseContentType.isValidAudioOrPlaylistStreamContentType()

    if clientResponseStatusCodeString == $405:
      tryHttpGetWhenMediaServerDoesNotSupportHead(url)
      result = LinkValidationResult(isValid: status)

    elif clientResponseStatusCodeString[0] in ['4', '5']:
      result = LinkValidationResult(isValid: false)

    result = LinkValidationResult(
      isValid: status
    )
  except Exception as e:
    #Handle exceptions using the reusable error-handling function
    result = handleLinkCheckError(e, timeout)
