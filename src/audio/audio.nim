const isVlc =
  static:
    defined(vlc)

import vlc/helper
import mpv/player

type
  audioHandle* = object
    mpvHandle: ptr Handle
    vlcHandle: ref libvlcHandle
    event:    ptr Event

using audioHandle: ref audioHandle

proc initAudio*(audioHandle) =
  when isVlc: discard
  else:
    audioHandle.mpvHandle = initGlobalMpv()

proc deinitAudio*(audioHandle) =
  when isVlc: audioHandle.vlcHandle.deinitPlayer()
  else:       audioHandle.mpvHandle.deinitPlayer()

proc setAllyOptions*(audioHandle) =
  when isVlc: audioHandle.vlcHandle.setAllyOptions()
  else:       audioHandle.mpvHandle.setAllyOptionsToMpv()

proc allocateJob*(audioHandle; url: string) =
  when isVlc: audioHandle.vlcHandle.allocateJob(url)
  else:       url.allocateJobMpv(audioHandle.mpvHandle)

proc waitEvent*(audioHandle) =
  when isVlc:
    discard
  else:
    audioHandle.event = audioHandle.mpvHandle.waitEvent()

template resourceIsOver*(audioHandle): bool =
  when isVlc:
    discard
  else:
    audioHandle.event.eventID in {IDEndFile}

proc setVolumeOfBellRelativeToMainCtx*(audioHandle) =
  when isVlc: audioHandle.vlcHandle.setVolumeOfBellRelativeToMainCtx()
  else:       audioHandle.mpvHandle.setVolumeOfBellRelativeToMainCtx()
