# metadata.nim

import libmpv, tables, strutils, terminal, ../utils/utils

type
  MpvError* = object of CatchableError
  ## Custom error type for MPV-related errors

  NodeListIterator* = object
    list: ptr NodeList
    index: int

proc initNodeListIterator(list: ptr NodeList): NodeListIterator =
  result = NodeListIterator(list: list, index: 0)

# Enhanced validation for small arrays
proc validateNodeList(list: ptr NodeList): bool =
  result = (list != nil) and (list.values != nil) and (list.keys != nil) and
           (list.num >= 0) and (list.num < 100) # Smaller upper bound for small arrays

iterator items(iter: var NodeListIterator):
  tuple[
    key: string,
    value: Node
  ] =
  if not validateNodeList(iter.list):
    echo "Error: Invalid NodeList encountered in items iterator"
    iter.index = -1
  else:
    # Use seq instead of array
    var values = newSeq[Node](iter.list.num) # Pre-allocate for efficiency
    var keys = newSeq[cstring](iter.list.num) # Pre-allocate

    # Copy data into seqs
    for i in 0 ..< iter.list.num:
      let valuePtr =
        cast[ptr Node](
          cast[uint](iter.list.values) +
          (
            cast[uint](i) * cast[uint](sizeof(Node))
          )
        )
      values[i] = valuePtr[]
      keys[i] = iter.list.keys[i]

    # Iterate and yield
    var index = iter.index
    while index < iter.list.num:
      let key = keys[index]
      if key != nil:
        let value = values[index]
        yield (key: $key, value: value)
      inc(index)

proc handleIndividualTag(lowerKey: string, value: string,
                          tagMap: Table[string, string],
                          metadataTable: var Table[string, string]) =
  # Handle individual tags based on the tagMap
  let preferredKey = tagMap[lowerKey]
  if preferredKey notin metadataTable:
    var formattedValue = value

    # Add units for specific keys
    if preferredKey == "Bitrate":
      formattedValue = formattedValue & " kbps"
    elif preferredKey == "SampleRate":
      formattedValue = formattedValue & " Hz"

    metadataTable[preferredKey] = formattedValue

proc handleIcyAudioInfo(
    value: string,
    tagMap: Table[string, string],
    metadataTable: var Table[string, string]
  ) =
  # Handle icy-audio-info parsing
  let audioInfoParts = value.split(";")
  for part in audioInfoParts:
    let keyValue = part.split("=")
    if keyValue.len == 2:
      let audioInfoKey = keyValue[0].strip.toLowerAscii
      var audioInfoValue = keyValue[1].strip

      # Use preferred key if available, otherwise use the lowercase key
      let keyToAdd = if audioInfoKey in tagMap: tagMap[audioInfoKey] else: audioInfoKey
      if keyToAdd notin metadataTable:
        # Add units for specific keys
        if keyToAdd == "Bitrate":
          audioInfoValue = audioInfoValue & " kbps"
        elif keyToAdd == "SampleRate":
          audioInfoValue = audioInfoValue & " Hz"

        metadataTable[keyToAdd] = audioInfoValue

proc handleID3v2PrivTag(lowerKey: string, value: string,
                         metadataTable: var Table[string, string]) =
  # Handle ID3v2_priv tags
  let owner = lowerKey.split(".")[1 .. lowerKey.split(".").high].join(".") # Extract owner identifier
  metadataTable[owner] = value # Store raw data with owner as key

proc collectMetadata(iter: var NodeListIterator,
                     parseAudioInfo: bool = true): Table[string, string] =
  var metadataTable = initTable[string, string]()

  # Mapping of common tag names (case-insensitive) to preferred names
  const tagMap: Table[string, string] = {
    "artist": "Artist",
    "icy-artist": "Artist",
    "title": "Title",
    "icy-name": "Title",
    "icy-title": "Title",
    "genre": "Genre",
    "icy-genre": "Genre",
    "album": "Album",
    "icy-url": "URL",
    "url": "URL",
    "icy-br": "Bitrate",
    "icy-description": "Description",
    "icy-sr": "SampleRate",
    "description": "Description",
    "samplerate": "SampleRate",
    "bitrate": "Bitrate",
    "channels": "Channels",
    "variant_bitrate": "Variant Bitrate",
    "ice-samplerate": "SampleRate",
    "ice-channels": "Channels",
    "ice-bitrate": "Bitrate"
  }.toTable

  for key, nodeValue in items(iter):
      # Access the format field of the client.Node correctly
      if nodeValue.format == fmtString and nodeValue.u.str != nil:
          let lowerKey = key.toLowerAscii()
          let value = $nodeValue.u.str # Now a Nim string

          # Filter out icy-notice, icy-pub, icy-metadata, and icy-private
          if lowerKey.startsWith("icy-notice") or lowerKey == "icy-pub" or lowerKey == "icy-metadata" or lowerKey == "icy-private":
              continue

          # Handle individual tags
          if lowerKey in tagMap:
              handleIndividualTag(lowerKey, value, tagMap, metadataTable)

          # Handle icy-audio-info
          elif lowerKey == "icy-audio-info" and parseAudioInfo:
              handleIcyAudioInfo(value, tagMap, metadataTable)

          # Handle ID3v2_priv tags
          elif lowerKey.startsWith("id3v2_priv."):
              handleID3v2PrivTag(lowerKey, value, metadataTable)

          # Handle unknown tags
          elif lowerKey notin metadataTable:
              metadataTable[lowerKey] = value

  return metadataTable

proc metadata*(ctx: ptr Handle): Table[string, string] =
  try:
    var dataNode: Node
    cE getProperty(ctx, "metadata", fmtNode, addr dataNode)

    var metadataTable = initTable[string, string]()
    if validateNodeList(dataNode.u.list):
      var iter = initNodeListIterator(dataNode.u.list)
      metadataTable = collectMetadata(iter)
    else:
      echo "Warning: Invalid metadata list received"

    freeNodeContents(addr dataNode)
    return metadataTable
  except CatchableError:
    discard

proc updateMetadataUI*(config: MenuConfig, ctx: ptr Handle, state: PlayerState): Table[string, string] =
  ## Updates and returns the metadata for the current station.
  result = metadata(ctx)
  var goingDown: uint8
  if result.len > 0:
    cursorDown 6
    for key, value in result:
      if (value == "") or (key.contains("title")) : continue
      styledEcho fgCyan, "  " & key & ": '" & value.truncateMe() & "'"
      goingDown += 1
    cursorUp int(goingDown)
    cursorUp 6
