import libvlc/libvlc, libvlc/base

type VlcError* = object of CatchableError

var playerCurrentSituation*: libvlc.state
var currentVol*: cint

type libvlcHandle* = object
  ctx*:            ptr instance
  mediaDscptr*:    ptr media
  mediaPlayerCtx*: ptr mediaPlayer

proc checkError*(status: cint, msg: cstring) =
  if status == -1:
    raise newException(VlcError, $msg)

template cE*(status: cint, msg: cstring) =
  checkError(status, msg)

using Handle: ref libvlcHandle

proc playPlayer*(Handle) =
  let msg: cstring = "play player"
  cE(libvlc.mediaPlayerPlay(Handle.mediaPlayerCtx), msg)

template resume*(Handle) =
  playPlayer(Handle)

proc pausePlayer*(Handle) =
  mediaPlayerPause(Handle.mediaPlayerCtx)

proc setVolume*(Handle; volume: int) =
  let msg: cstring = "set volume"
  cE(audioSetVolume(Handle.mediaPlayerCtx, cint(volume)), msg)

template volumeChange*(Handle; inc: bool) =
  when inc: currentVol += 5
  else:     currentVol -= 5

  Handle.setVolume(currentVol)

var volumeBeforeMuted*: int

proc muteVolume*(Handle) =
  volumeBeforeMuted = libvlc.audioGetVolume(Handle.mediaPlayerCtx)
  setVolume(Handle, 0)

proc unmuteVolume*(Handle) =
  setVolume(Handle, volumeBeforeMuted)
  volumeBeforeMuted = -1

template volumeUp*(Handle) =
  volumeChange(Handle, true)

template volumeDown*(Handle) =
  volumeChange(Handle, false)

proc setVolumeOfBellRelativeToMainCtx*(Handle) =
  var relativeVol = int(1.5 * float(currentVol))
  setVolume(Handle, relativeVol)

proc stopPlayer*(Handle) =
  libvlc.mediaPlayerStop(Handle.mediaPlayerCtx)

proc isIdle*(Handle): bool =
  playerCurrentSituation = libvlc.mediaPlayerGetState(Handle.mediaPlayerCtx)
  if playerCurrentSituation in
    [libvlc.Ended, libvlc.Error, libvlc.Stopped]:
      return true
  else:
    return false

## auto observeMediaTitle() {}

proc getCurrentMediaTitleVlc*(Handle): string =
  return $libvlc.mediaGetMeta(Handle.mediaDscptr, libvlc.metaNowPlaying)

proc initNewCtx*(Handle) =
  var ctx = libvlc.new(0, allocCStringArray [])
  if ctx.isNil:
    raise newException(VlcError, "Failed to create libvlc instance")

  Handle.ctx = ctx

proc deinitPlayer*(Handle) =
  libvlc.mediaPlayerRelease(Handle.mediaPlayerCtx)
  libvlc.mediaRelease(Handle.mediaDscptr)
  libvlc.release(Handle.ctx)

proc allocateJobVlc*(Handle; url: string) =
  Handle.mediaDscptr    = libvlc.mediaNewLocation(Handle.ctx, cstring(url))
  Handle.mediaPlayerCtx = libvlc.mediaPlayerNewFromMedia(Handle.mediaDscptr)

proc setAllyOptionsVlc*(Handle) =
  libvlc.setUserAgent(Handle.ctx, "pnimrp/0.1", "pnimrp/0.1")
  libvlc.setAppId(Handle.ctx, "pnimrp", "0.1", "")
