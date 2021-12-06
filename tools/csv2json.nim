#tool to make parsing values from pmrp easier
from strutils import splitLines,contains,join,strip,find,replace
from os import commandLineParams
from sequtils import delete

let lex = commandLineParams()
if lex == @[]: echo "give files"; quit QuitFailure

for f in lex.low..lex.high:
 try:
   var file = lex[f]
  #if file.contains "json": echo "info: ", file, " aldready processed" ; break
  #else:
   var inSeq = splitLines readFile file
   if inSeq[0].contains "{": echo "info: ",file," processed?"
   else:
    var
     lo = inSeq.low
     hi = inSeq.high
     ind = inSeq[f]
    for f in lo..hi:
     if ( ind.find "=" ) == -1: echo "info: ", file, " ", f + 1, ": aldready processed or has space"
     elif ind == "":
      inSeq.delete(f,f)
      var e = int(hi / 2) - int(hi - f)
      inSeq.delete(e,e)
      echo "info: ", file, " ", f + 1, ": line is nil"
     elif ind.contains "onomy":
      ind = ""
      inSeq[int( inSeq.high / 2 ) - int( inSeq.high - f )] = ""
      echo "info: ", file, " ", f + 1, ": line had radionomy link"
     else:
      ind = strip ind
      if ind[4] == '0': strutils.delete ind, 4,4
      ind = "  \"" & ind
      ind = ind.replace("=", "\": ")
      #if f == inSeq.high - 1: discard else: 
      ind = ind & ","

    inSeq = "{" & inSeq
    var e = strip inSeq.join "\x0D\x0A"
    e.add "\x0D\x0A}\x0D\x0A"
    file.writeFile e
 except IOError,OSError: echo "no such file"
