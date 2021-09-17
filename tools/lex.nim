#tool to make parsing values from pmrp easier

from strutils import splitLines,removePrefix,removeSuffix,contains,join,strip,find,delete,replace
from os import commandLineParams,copyFile
from strformat import fmt

let lex = commandLineParams()
if lex == @[]: echo "give files" ; quit 1

proc isEven(x:int):bool = x mod 2 == 0

for f in lex.low..lex.high:
 var file = lex[f]
 copyFile(file,fmt"{file}.bkp")
 var inSeq = readFile(file).splitLines()

 for f in inSeq.low..inSeq.high:
  if inSeq[f] == "": echo fmt"info: {file} {f + 1}: line is nil"
  elif inSeq[f].contains "onomy":
   inSeq[f] = ""
   var e = ( inSeq.high / 2 ).int - ( inSeq.high - f ).int 
   inSeq[e] = ""
   echo fmt"info: {file} {f + 1}: line had radionomy link"
   
  elif inSeq[f].contains " ":
   echo fmt"info: {file} {f + 1}: line had space"
   inSeq[f] = inSeq[f].strip()
   try:
    if inSeq[f].find("=") == -1: echo fmt"info: {file} {f + 1}: processed"
    else:
     removeSuffix(inSeq[f],"\"")
     inSeq[f].delete(inSeq.low..(inSeq[f].find("=") + 1))
   except: discard

  else:
   if ( inSeq[f].find "=" ) == -1: echo fmt"info: {file} {f + 1}: processed"
   else:
    echo fmt"info: {file} {f + 1}: processed"
    inSeq[f] = inSeq[f].strip()
    removeSuffix(inSeq[f],"\"")
    inSeq[f].delete(inSeq.low..(inSeq[f].find("=") + 1))

 #echo inSeq.join("\n").strip()
 writeFile(file,inSeq.join("\n"))
