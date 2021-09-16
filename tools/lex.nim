#tool to make parsing values from pmrp easier

from strutils import splitLines,removePrefix,removeSuffix,delete,contains,join
from os import commandLineParams,copyFile
from strformat import fmt

let lex = commandLineParams()

if lex == @[]: echo "give files" ; quit 1

for f in lex.low..lex.high:
 var file = lex[f]
 copyFile(file,fmt"{file}.bkp")
 var inSeq = readFile(file).splitLines()
 for f in inSeq.low..inSeq.high:
  if inSeq[f] == "": echo fmt"warning: {file} {f + 1}: line is nil"
  elif inSeq[f].contains " ":
   #inSeq[f] = ""
   echo fmt"warning: {file} {f + 1}: line has space"
  else:
   removePrefix(inSeq[f],"\"")
   removeSuffix(inSeq[f],"\"")
   inSeq[f].delete(0..7)
 writeFile(file,inSeq.join("\n"))
