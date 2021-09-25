#tool to make parsing values from pmrp easier
from strutils import splitLines,contains,join,strip,find,replace
from os import commandLineParams
from sequtils import delete

let lex = commandLineParams()
if lex == @[]: echo "give files" ; quit 1

for f in lex.low..lex.high:
 try:
   var file = lex[f]
  #if file.contains "json": echo "info: ", file, " aldready processed" ; break
  #else:
   var inSeq = splitLines readFile file
   if inSeq[0].contains "{": break
   else:
    var lo = inSeq.low
    var hi = inSeq.high
    for f in lo..hi:
     if ( inSeq[f].find "=" ) == -1: echo "info: ", file, " ", f + 1, ": aldready processed or has space"
     elif inSeq[f] == "":
      inSeq.delete(f..f)
      var e = int( inSeq.high / 2 ) - int( inSeq.high - f )
      inSeq.delete(e..e)
      lo = inSeq.low
      hi = inSeq.high
      echo "info: ", file, " ", f + 1, ": line is nil"
     elif inSeq[f].contains "onomy":
      inSeq[f] = ""
      inSeq[int( inSeq.high / 2 ) - int( inSeq.high - f )] = ""
      echo "info: ", file, " ", f + 1, ": line had radionomy link"
     else:
      inSeq[f] = strip inSeq[f]
      inseq[f] = "  \"" & inSeq[f]
      inSeq[f] = inSeq[f].replace("=", "\": ")
      #if f == inSeq.high - 1: discard else: 
      inSeq[f] = inSeq[f] & ","

    inSeq = "{" & inSeq
    var e = strip inSeq.join "\x0D\x0A"
    e.add "\x0D\x0A}\x0D\x0A"
    file.writeFile e
 except IOError,OSError: echo "no such file"
 except: echo "unexpected error"
