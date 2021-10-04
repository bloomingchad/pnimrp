from os import sleep
from terminal import getch
import ../base/[termbase,playerbase,initbase],json
from strformat import fmt

proc easy181* =
 const sub = "181FM"
 const sect = "Easy Listening"
 let node = parseJ "181FM/easy181.json"
 let Name01 = getStr node{"Name01"}
 let Name02 = getStr node{"Name02"}
 let Name03 = getStr node{"Name03"}
 let Name04 = getStr node{"Name04"}
 let Name05 = getStr node{"Name05"}
 let Name06 = getStr node{"Name06"}
 let Name07 = getStr node{"Name07"}
 let Name08 = getStr node{"Name08"}
 let Name09 = getStr node{"Name09"}
 let Name10 = getStr node{"Name10"}
 let Name11 = getStr node{"Name11"}
 let Name12 = getStr node{"Name12"}
 let Name13 = getStr node{"Name13"}
 let Name14 = getStr node{"Name14"}
 let Name15 = getStr node{"Name15"}

 let link01 = getStr node{"link01"}
 let link02 = getStr node{"link02"}
 let link03 = getStr node{"link03"}
 let link04 = getStr node{"link04"}
 let link05 = getStr node{"link05"}
 let link06 = getStr node{"link06"}
 let link07 = getStr node{"link07"}
 let link08 = getStr node{"link08"}
 let link09 = getStr node{"link09"}
 let link10 = getStr node{"link10"}
 let link11 = getStr node{"link11"}
 let link12 = getStr node{"link12"}
 let link13 = getStr node{"link13"}
 let link14 = getStr node{"link14"}
 let link15 = getStr node{"link15"}

 while true:
  var j = false
  drawMenuSect sub,sect,fmt"""1 {Name01}
2 {Name02}
3 {Name03}
4 {Name04}
5 {Name05}
6 {Name06}
7 {Name07}
8 {Name08}
9 {Name09}
A {Name10}
B {Name11}
C {Name12}
D {Name13}
E {Name14}
F {Name15}
R Return
Q Exit"""
  while true:
   sleep 100
   case getch():
    of '1': call sub,sect,Name01,link01 ; break
    of '2': call sub,sect,Name02,link02 ; break
    of '3': call sub,sect,Name03,link03 ; break
    of '4': call sub,sect,Name04,link04 ; break
    of '5': call sub,sect,Name05,link05 ; break
    of '6': call sub,sect,Name06,link06 ; break
    of '7': call sub,sect,Name07,link07 ; break
    of '8': call sub,sect,Name08,link08 ; break
    of '9': call sub,sect,Name09,link09 ; break
    of 'A','a': call sub,sect,Name10,link10 ; break
    of 'B','b': call sub,sect,Name11,link11 ; break
    of 'C','c': call sub,sect,Name12,link12 ; break
    of 'D','d': call sub,sect,Name13,link13 ; break
    of 'E','e': call sub,sect,Name14,link14 ; break
    of 'F','f': call sub,sect,Name15,link15 ; break
    of 'R','r': j = true; break
    of 'Q','q': exitEcho()
    else: inv()
  if j: break
