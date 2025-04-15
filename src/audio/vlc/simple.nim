import helper, os

proc example =
  #let url = "https://nl.ah.fm/mobile"
  let url1 = "https://listen.181fm.com/181-jammin_128k.mp3"

  var handle = initNewCtx()
  defer: handle.deinitPlayer()

  handle.setAllyOptionsVlc()
  handle.allocateJobVlc(url1)
  handle.playPlayer()

  while true:
    sleep(5)
    if handle.mediaPlayerIsPlaying(): break
    else: continue

  while handle.mediaPlayerIsPlaying():
    sleep 50
    continue
    ##  poll loop
    ## printf("nowplaying: %s\n", getCurrentMediaTitleVlc(libvlc_handle));
    ## fflush(stdout);
    ## ^^^^ only written to stdout when flushed

when isMainModule:
  example()
