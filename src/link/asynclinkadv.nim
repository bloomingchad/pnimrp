#asynclinkadv.nim
import
  times, ../utils/utils, asyncdispatch,
  asyncnet, strutils, linkbase

import std/net, httpclient

var tempFileLogContent*: string

proc asyncLinkCheckTolerantWithContentType*(url: string; timeout = 10000): Future[LinkStatus] {.async.} =
  let url = normalizeUrl(url)
  let sslCtxWithNoVerify = newContext(verifyMode = CVerifyNone)

  try:
  #block:
    var client = newAsyncHttpClient(
      #timeout = timeout,
      sslContext = sslCtxWithNoVerify,
      userAgent = "pnimrp/0.1",
      maxRedirects = 2
      )
    await sleepAsync 5
    let clientResponse = await client.head(url)

    await sleepAsync 5
    let clientResponseContentType = clientResponse.contentType()
    await sleepAsync 5
    let clientResponseStatusCodeString = $clientResponse.code()
    await sleepAsync 5
    client.close()
    var status: bool

    if clientResponseContentType != "":
      status = clientResponseContentType.isValidAudioOrPlaylistStreamContentType()
      if status: return lsValid
    tempFileLogContent = tempFileLogContent & "url: " & url & " | " & clientResponseStatusCodeString & "\n"


    if clientResponseStatusCodeString[0] == '4': 
      
      #echo clientResponseStatusCodeString; result = lsInvalid
      case clientResponseStatusCodeString:
      of "401", "403", "404", "408", "410": return lsInvalid
      of "405", "400":
          tryHttpGetWhenMediaServerDoesNotSupportHead(url)
          return lsChecking
      else: discard

      if clientResponseStatusCodeString[0] in ['1', '2', '3']: result = lsValid


    elif clientResponseStatusCodeString[0] == '5': return lsChecking

    #result = LinkValidationResult(
    #  isValid: status
    #)
  except Exception as e:
    #Handle exceptions using the reusable error-handling function
    if e of SslError or e of ProtocolError: return lsChecking
    elif e of OSError: return lsInvalid
    #elif e of ProtocolError: result = lsInvalid
    else:
      raise e
    #result = lsInvalid #handleLinkCheckError(e, timeout)
    #echo ""
