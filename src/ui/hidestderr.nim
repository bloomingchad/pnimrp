const win32 =
  static:
    defined(windows)

when win32:
  const
    NULL_DEVICE* = "NUL"
    TERMINAL_DEVICE* = "CON"
else:
  const
    NULL_DEVICE* = "/dev/null"
    TERMINAL_DEVICE* = "/dev/tty"

type StderrState* {.bycopy.} = object
  originalStderrFd*: cint

template c_perror(str: cstring) = stderr.writeLine str

when win32:
  {.push header: "<io.h>".}
  proc c_dup*(fd: cint): cint {.importc: "_dup".}
  proc c_dup2*(oldfd, newfd: cint): cint {.importc: "_dup2".}
  proc c_fileno*(stream: File): cint {.importc: "_fileno".}
  proc c_close*(fd: cint): cint {.importc: "_close".}
  {.pop.}
else:
  {.push header: "<unistd.h>".}
  proc c_dup*(fd: cint): cint {.importc: "dup".}
  proc c_dup2*(oldfd, newfd: cint): cint {.importc: "dup2".}
  proc c_fileno*(stream: File): cint {.importc: "fileno".}
  proc c_close*(fd: cint): cint {.importc: "close".}
  {.pop.}

{.push header: "<stdio.h>".}
proc c_freopen*(filename: cstring, mode: cstring, stream: File): File {.importc: "freopen".}
{.pop.}

template checkError(status: cint) =
  if status == -1:
    c_perror "error!"
    quit(QuitFailure)

template cE(status: cint) =
  checkError(status)

proc initSuppressStderr*(state: ptr StderrState) =
  when win32: state.originalStderrFd = c_dup(c_fileno(stderr))
  else:       state.originalStderrFd = c_dup(c_fileno(stderr))

  if state.originalStderrFd == -1:
    c_perror("failed to save original stderr")
    quit(QuitFailure)

  if c_freopen(NULL_DEVICE, "w", stderr) == nil:
    c_perror("failed to suppress stderr")
    quit(QuitFailure)

proc restoreStderr*(state: ptr StderrState) =
  flushFile(stderr)

  when win32:
    if c_dup2(state.originalStderrFd, c_fileno(stderr)) == -1:
      c_perror("failed to restore stderr")
      quit(QuitFailure)
  else:
    if c_dup2(state.originalStderrFd, c_fileno(stderr)) == -1:
      c_perror("failed to restore stderr")
      quit(QuitFailure)

  when win32: cE c_close(state.originalStderrFd)
  else:       cE c_close(state.originalStderrFd)

  if c_freopen(TERMINAL_DEVICE, "w", stderr) == nil:
    c_perror("failed to reopen stderr")
    stdout.write "using stdout as fallback for stderr"

    when win32: cE c_dup2(c_fileno(stdout), c_fileno(stderr))
    else:       cE c_dup2(c_fileno(stdout), c_fileno(stderr))

when isMainModule:
  var state: StderrState
  echo("this goes to stdout")

  initSuppressStderr(addr(state))
  stderr.writeLine "this would go to stderr, but its suppressed"
  restoreStderr(addr(state))

  stderr.writeLine "this goes to stderr after restoration"
