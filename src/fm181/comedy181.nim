from os import sleep
from terminal import getch
import ../base,json

proc comedy181* =
 const sub = "181FM"
 const sect = "Comedy"
 let node = parseJ "181FM/comedy181.json"
 let Name01 = getStr node{"Name01"}
 let Name02 = getStr node{"Name02"}
 let Name03 = getStr node{"Name03"}
 let link01 = getStr node{"link01"}
 let link02 = getStr node{"link02"}
 let link03 = getStr node{"link03"}

 while true:
  var j = false
  drawMenuSect sub,sect,"1 " & Name01
  sayC "2 " & Name02
  sayC "3 " & Name03
  sayIter """R Return
Q Exit"""
  while true:
   sleep 100
   case getch():
    of '1': call sub,sect,Name01,link01 ; break
    of '2': call sub,sect,Name02,link02 ; break
    of '3': call sub,sect,Name03,link03 ; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j == true: break
