#tool to make parsing values from pmrp easier
from strutils import splitLines,removeSuffix,contains,join,strip,find,delete
from os import commandLineParams,copyFile,fileExists
from strformat import fmt

let lex = commandLineParams()
if lex == @[]: echo "give files" ; quit 1

for f in lex.low..lex.high:
 try:
  var file = lex[f]
  if fileExists fmt"{file}.bkp": echo fmt"info: {file} aldready processed" ; break
  else:
   file.copyFile fmt"{file}.bkp"
   var inSeq = splitLines readFile file

   for f in inSeq.low..inSeq.high:
    if ( inSeq[f].find """: """ ) == -1: echo fmt"info: {file} aldready processed" ; break
    elif inSeq[f] == "": echo fmt"info: {file} {f + 1}: line is nil"
    elif inSeq[f].contains "onomy":
     inSeq[f] = ""
     inSeq[int( inSeq.high / 2 ) - int( inSeq.high - f )] = ""
     echo fmt"info: {file} {f + 1}: line had radionomy link"
    else:
     inSeq[f] = strip inSeq[f]
     inSeq[f].removeSuffix "\""
     inSeq[f].delete(inSeq.low..(inSeq[f].find("=") + 1))

   file.writeFile strip inSeq.join "\n"
 except IOError,OSError: echo fmt"no such file"
 except: echo fmt"unexpected error"
