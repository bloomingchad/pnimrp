from os import fileExists,findExe,dirExists
from strformat import fmt
from strutils import splitLines
import json

proc checkFileIter*(x:seq[string]):bool =
 var i:uint8 = 0
 for f in x:
  if fileExists(fmt"pnimrp.d/{x[i]}.csv"): inc i
  else: return false
 return true

proc init* =
 var amog = @["pnimrp","181FM/comedy181","181FM/easy181","181FM/latin181","181FM/oldies181",
 "181FM/rock181","181FM/country181","181FM/eight181","181FM/nine181","181FM/pop181","181FM/urban181"]

 if not ( dirExists "pnimrp.d" ) and checkFileIter amog: echo "data and config files dont exist" ; quit 1
 if findExe("curl") == "": echo "please get curl installed"; quit 1

proc parse*(x:string):seq[string] = splitLines readFile fmt"pnimrp.d/{x}"
proc parseJ*(x:string):JsonNode = parseJson readFile fmt"pnimrp.d/{x}"
