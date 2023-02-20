## audioplayer (bass)
basic audioplayer written in freebasic and bass\
supported audio types .mp3, .mp4, .ogg, .wav\
supported playlists .m3u, .pls\
\
basic config options in conf.ini\
locale          = <locale>\
defaultvolume   = <0.0 .. 1.0>\
playtype        = <shuffle, linear>\
\
basic help localization via:\
help-de.ini\
help-en.ini\
\
if present coverart will be extracted and written to file as thumb.jpg\
When a file or path is specified the current dir and sub dir(s)\
will be scanned for audio file(s) which will generate an internal playlist\
32bit version tested
## usage
audioplayer.exe "path to file or folder"\
if a file or path is specified the folder will be scanned for an audio file\
if the folder has subfolder(s) these will be scanned for audio files as well
## requirements
bass.dll (32bit)\
https://www.un4seen.com/
## performance
windows 7 / windows 10(1903)\
ram usage ~2.2MB / ~2.2MB\
handles   ~120 / 200\
threads   7 / 8\
cpu       ~1% (low) / ~2%\
tested on intel i5-6600T
## navigation
press p     to play
press .     to play next
press ,     to play previous
press ]     to skip forward   10 secs
press [     to skip backwards 10 secs
press space to pause / play or mute / unmute
press r     to restart
press -     to increase volume
press +     to decrease volume
press esc   to quit
