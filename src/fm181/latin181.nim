from os import sleep
from terminal import getch
import ../base/[termbase,playerbase,initbase],json
from strformat import fmt


proc latin181* =
 const sub = "181FM"
 var sect = "Latin"
 let node = parseJ "181FM/latin181.json"
 let Name01 = getStr node{"Name01"}
 let Name02 = getStr node{"Name02"}
 let Name03 = getStr node{"Name03"}
 let link01 = getStr node{"link01"}
 let link02 = getStr node{"link02"}
 let link03 = getStr node{"link03"}
 while true:
  var j = false
  drawMenuSect sub,sect,fmt"""1 {Name01}
2 {Name02}
3 {Name03}
R Return
Q Exit"""
  while true:
   sleep 70
   case getch():
    of '1': call sub,sect,Name01,link01 ; break
    of '2': call sub,sect,Name02,link02 ; break
    of '3': call sub,sect,Name03,link03 ; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break
