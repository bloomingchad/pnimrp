from osproc import startProcess,waitForExit,poUsePath,poParentStreams,kill,suspend,resume
from strutils import contains,repeat
from term import warn,say,sayPos,inv,clear,exitEcho
from terminal import terminalWidth,setCursorXPos,getch,cursorUp,cursorDown,eraseLine,showCursor,styledWriteLine,fgCyan
from strformat import fmt
import client

proc exec*(x:string,args:openArray[string]; stream = false) =
 if stream: discard waitForExit startProcess(x,args=args,options={poUsePath,poParentStreams})
 else: discard waitForExit startProcess(x,args=args,options={poUsePath})

proc exit(ctx:ptr handle, isPaused: bool ) =
 if not(isPaused):
  terminateDestroy ctx
 exitEcho()

template cE(s:cint) = checkError s

proc init(parm:string,ctx: ptr handle) =
 let file = allocCStringArray ["loadfile", parm] #couldbe file,link,playlistfile
 var val: cint = 1
 cE ctx.setOption("osc", formatFlag, addr val)
 cE initialize ctx
 cE ctx.cmd file

proc call*(sub:string; sect = ""; stat,link:string) =
 if link == "" or link.contains " ": warn "link dont exist or is invalid"
 else:
  clear()
  if sect == "": say fmt"PNimRP > {sub} > {stat}"
  else: say fmt"PNimRP > {sub} > {sect} > {stat}"
  sayPos 0,'-'.repeat(int terminalWidth() / 8) & '>'.repeat int terminalWidth() / 12

  let ctx = create()
  init link, ctx
  var
   echoPlay = true
   event = ctx.waitEvent 1000
   isPaused = false

  while true:
   if echoPlay:
    sayPos 4, "Playing"
    cursorUp()
    echoPlay = false

   #remove cursorUp?
   if not(isPaused):
    event = ctx.waitEvent 1000

   #remove casting?
   if cast[eventID](event) == eventIDShutdown: break
   if cast[eventID](event) == eventIDIdle: break

   case getch():
    of 'p','m','P','M':
     if isPaused:
      eraseLine()
      let ctx = create()
      init link, ctx
      echoPlay = true
      isPaused = false

     else:
      warn "Paused/Muted",4
      cursorUp()
      terminateDestroy ctx
      isPaused = true

    of '/':
     when defined linux: exec "amixer",["--quiet","set","PCM","5+"]
     #when defined windows: exec "nircmd",["changesysvolume","5000"]
     cursorDown()
     warn "Volume+", 4
     cursorUp()
     eraseLine()
     cursorUp()

    of 'r','R':
     if not(isPaused): terminateDestroy ctx
     break
    of 'q','Q': exit ctx, isPaused
    else: inv()
