## audioplayer (bass) [![Github All Releases](https://img.shields.io/github/downloads/thrive4/app.fb.audioplayer-bass/total.svg)]()
basic audioplayer written in freebasic and bass
* supported audio types .mp3, .mp4, .ogg, .wav
* supported playlists .m3u, .pls
* supported streams icecast and shoutcast http, https
* ascii interface

if present coverart will be extracted and written to file as thumb.jpg
When a file or path is specified the current dir and sub dir(s)
will be scanned for audio file(s) which will generate an internal playlist

## usage
audioplayer.exe "path to file or folder"
if a file or path is specified the folder will be scanned for an audio file
if the folder has subfolder(s) these will be scanned for audio files as well.

generate .m3u: audioplayer "path to file or folder" "tag" "tagquery"
example: audioplayer.exe g:datamp3classic artist beethoven
generates the m3u file beethoven.m3u
which then can be played by audioplayer.exe beethoven.m3u
* simple search so 195 is equivelant of ?195? or *195*
* runtime in seconds is not calculated default is #EXTINF:134
* no explicit wildcard support, only searchs on one tag
* supported tags artist, title, album, genre and year

## install
open zip file and copy contents to preferd folder
this application is **portable**.

## configuration
basic config options in conf.ini
locale          = <en, es, de, fr, nl>
defaultvolume   = <0.0 .. 1.0>
playtype        = <shuffle, linear>
' dynamic range compression
drc             = <true, false>
' location media
mediafolder = g:datamp3classic
' location thumbnail media for station
' example: uk3 internet-radio.jpg put in ...
radiofolder = g:internetradio

## requirements
bass.dll (32bit)
https://www.un4seen.com/

## performance
windows 7 / windows 10(1903)
ram usage ~2.2MB / ~2.2MB
handles   ~120 / 200
threads   7 / 8
cpu       ~1% (low) / ~2%
tested on intel i5-6600T

## navigation
press .     to play next
press ,     to play previous
press ]     to skip forward   10 secs
press [     to skip backwards 10 secs
press space to pause / play or mute / unmute
press r     to restart
press l     for linear / shuffle list play
press d     for dynamic range compression
press -     to increase volume
press +     to decrease volume
press esc   to quit

# special thanks to
squall4226 for getmp3tag
see https://www.freebasic.net/forum/viewtopic.php?p=149207&hilit=user+need+TALB+for+album#p149207
rosetta code for compoundtime
https://rosettacode.org/wiki/Convert_seconds_to_compound_duration#FreeBASIC
