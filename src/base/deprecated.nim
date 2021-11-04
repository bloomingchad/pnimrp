#[proc menuIter(sect:string,endn:uint32,arr:seq[string]) =
 var a,b:uint8
 a = 1
 b = 0
 echo "PNimRP -> ",sect ; echo ""
 echo "Stations Playing ",sect," Music:"
 for f in 1..endn:
  echo a," ",arr[b]
  inc a
  inc b
 echo "R Return"
 echo "Q Quit"
 stdout.write "> "

proc read():char = stdin.readLine[0]

proc wait = sleep 3000

when defined windows:
  if findExe("nircmd").contains "nircmd":
   mnuSy 2, 6 , fgRed,"nircmd was not found in your windows system"
   sleep 1000
   downloadFile "https://www.nirsoft.net/utils/nircmd.zip","nircmd.zip"
   exec "7z.exe" ,["e","nircmd.zip"],0

proc clsIter(x:int) =
  if x == 0: tb.write 2,1," ".repeat(terminalWidth() - 4)
  var i:uint8 = 4
  for f in 1..20:
    tb.write 2,i," ".repeat(terminalWidth() - 4)
    inc i
  tb.display()

proc cls(x:int) =
  tb.write 2,x," ".repeat(terminalWidth() - 4)
  tb.display()

proc parse*(x:string):seq[string] = splitLines readFile fmt"pnimrp.d/{x}"

proc sayC*(txt:string) =
 setCursorXPos 5
 styledEcho fgBlue,txt

proc back*(x:uint32) =
 for a in 1..x:
  cursorUp()
  eraseLine()

]#
