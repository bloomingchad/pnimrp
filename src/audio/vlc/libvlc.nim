type
  media*       = distinct pointer
  mediaPlayer* = distinct pointer
  instance*    = distinct pointer

type meta* = enum
  metaTitle
  meta_Artist
  metaGenre
  metaCopyright
  metaAlbum
  metaTrackNumber
  metaDescription
  metaRating
  metaDate
  metaSetting
  metaURL
  metaLanguage
  metaNowPlaying
  metaPublisher
  metaEncodedBy
  metaArtworkURL
  metaTrackID
  metaTrackTotal
  metaDirector
  metaSeason
  metaEpisode
  metaShowName
  metaActors
  metaAlbumArtist
  metaDiscNumber
  metaDiscTotal

proc mediaGetMeta*(p_md: ptr libvlc.media, e_meta: libvlc.meta): cstring
  {.importc: "libvlc_media_get_meta".}

## end libvlc_media.h*/
## start libvlc_media.h

type state* = enum
  NothingSpecial = 0
  Opening
  Buffering
  Playing
  Paused
  Stopped
  Ended
  Error

##  XXX: `libvlc_Buffering` Deprecated value. Check the
## libvlc_MediaPlayerBuffering event to know the
## buffering state of a libvlc_media_player

proc mediaGetState*(p_md: ptr media): libvlc.state
  {.importc: "libvlc_media_get_state".}

## end libvlc_media.hp## start libvlc_media_player.h

proc mediaPlayerPlay*(p_mi: ptr mediaPlayer): cint
    {.importc: "libvlc_media_player_play".}

proc mediaPlayerPause*(p_mi: ptr mediaPlayer)
    {.importc: "libvlc_media_player_pause".}

proc audioSetVolume*(p_mi: ptr mediaPlayer, i_volume: cint): cint
    {.importc: "libvlc_audio_set_volume".}

proc audioGetVolume*(p_mi: ptr mediaPlayer): cint
    {.importc: "libvlc_audio_get_volume".}

proc mediaPlayerStop*(p_mi: ptr mediaPlayer)
    {.importc: "libvlc_media_player_stop".}

proc mediaPlayerGetState*(p_mi: ptr mediaPlayer): libvlc.state
    {.importc: "libvlc_media_player_get_state".}

proc mediaPlayerIsPlaying*(p_mi: ptr mediaPlayer): cint
    {.importc: "libvlc_media_player_is_playing".}

proc mediaPlayerRelease*(p_mi: ptr mediaPlayer)
    {.importc: "libvlc_media_player_release".}

proc mediaPlayerNewFromMedia*(p_md: ptr media): ptr mediaPlayer
    {.importc: "libvlc_media_player_new_from_media".}

## end libvlc_media_player.h*/
## start libvlc.h

proc setUserAgent*(p_instance: ptr instance, name: cstring, http: cstring)
    {.importc: "libvlc_set_user_agent".}

proc new*(argc: cint, argv: cstringArray): ptr instance
    {.importc: "libvlc_new".}

proc setAppId*(p_instance: ptr instance, id: cstring, version: cstring, icon: cstring)
    {.importc: "libvlc_set_app_id".}

proc release*(p_instance: ptr instance)
    {.importc: "libvlc_release".}
## end libvlc.h
## start libvlc_media.h

proc mediaRelease*(p_md: ptr media)
    {.importc: "libvlc_media_release".}

proc mediaNewLocation*(p_instance: ptr instance, psz_mrl: cstring): ptr media
    {.importc: "libvlc_media_new_location".}

## end libvlc_media.h
