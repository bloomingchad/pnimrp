import os, client, tables, strutils

type
  MpvError* = object of CatchableError
  ## Custom error type for MPV-related errors

  NodeListIterator* = object
    list: ptr client.NodeList
    index: int

proc initNodeListIterator(list: ptr client.NodeList): NodeListIterator =
  result = NodeListIterator(list: list, index: 0)

# Enhanced validation for small arrays
proc validateNodeList(list: ptr client.NodeList): bool =
  result = (list != nil) and (list.values != nil) and (list.keys != nil) and
           (list.num >= 0) and (list.num < 100) # Smaller upper bound for small arrays

iterator items(iter: var NodeListIterator): tuple[key: string,
    value: client.Node] =
  if not validateNodeList(iter.list):
    echo "Error: Invalid NodeList encountered in items iterator"
    iter.index = -1
  else:
    # Use seq instead of array
    var values = newSeq[client.Node](iter.list.num) # Pre-allocate for efficiency
    var keys = newSeq[cstring](iter.list.num) # Pre-allocate

    # Copy data into seqs
    for i in 0 ..< iter.list.num:
      let valuePtr =
        cast[ptr client.Node](
          cast[uint](iter.list.values) +
          (
            cast[uint](i) * cast[uint](sizeof(client.Node))
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

proc collectMetadata(iter: var NodeListIterator): Table[string, string] =
  var metadataTable = initTable[string, string]()
  for key, value in items(iter):
    if value.format == client.fmtString and value.u.str != nil:
      metadataTable[key] = $value.u.str
  return metadataTable

proc metadata*(ctx: ptr client.Handle): Table[string, string] =
  var result: client.Node
  ce(client.getProperty(ctx, "metadata", client.fmtNode, addr result))

  var metadataTable = initTable[string, string]()
  if validateNodeList(result.u.list):
    var iter = initNodeListIterator(result.u.list)
    metadataTable = collectMetadata(iter)
  else:
    echo "Warning: Invalid metadata list received"

  client.freeNodeContents(addr result)
  return metadataTable