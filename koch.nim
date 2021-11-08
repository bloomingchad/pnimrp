#installs, uninstalls and packages pnimrp for different platforms
when defined windows: {.error: "koch does not support Windows for now!".}
import osproc,os

template exec(x:string) = discard execCmd x

let
 param = commandLineParams()
 help = """Koch - Install, Uninstall, Package, Compile PNimRP.

help - print this help
compile - compile the application
package - conceive a package for your OS

see doc/installation.rst
"""

if param == @[]:
 echo "Error: give arguments!"
 echo help
 quit QuitFailure

if param[0] in @["help", "--help", "-h"]:
 echo help
 quit QuitFailure

case param[0]:
 of "compile": exec "nimble build"
 else:
  echo "Error: parameter @ index 0 is nil"
  quit QuitFailure

