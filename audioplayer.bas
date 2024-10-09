' based on FreeBASIC-1.07.2-gcc-5.2\examples\sound\BASS\demo.bas
' compound time code https://rosettacode.org/wiki/Convert_seconds_to_compound_duration#FreeBASIC
' tweaked for fb and un4seen bass 2.4.16.7 sept 2021 by thrive4
' https://www.un4seen.com/

#Include once "bass.bi"
#include once "windows.bi"
#Include once "win/mmsystem.bi"
#include once "utilfile.bas"
#include once "shuffleplay.bas"
#cmdline "app.rc"

' setup playback
dim filename        as string = "test.mp3"
dim fileext         as string = ""
Dim secondsPosition As Double
dim chanlengthbytes as QWORD
dim tracklength     as double
Dim musicstate      As boolean
Dim currentvolume   as ulong
dim sourcevolume    as single = 0.33f
dim drcvolume       as single = 0.0f
dim drc             as string = "true"

' setup parsing pls and m3u
dim chkcontenttype  as boolean = false
dim itemnr          as integer = 1
dim listitem        as string
dim maxitems        as integer
dim listduration    as integer
dim lengthm3u       as integer
common shared currentitem as integer

' setup list of soundfiles
dim itemlist    as string = appname
dim imagefolder as string
dim filetypes   as string = ".mp3, .mp4, .ogg, .wav"
' options shuffle, linear
dim playtype    as string = "linear"

' init app with config file if present conf.ini
dim itm     as string
dim inikey  as string
dim inival  as string
dim inifile as string = exepath + "\conf\conf.ini"
dim f       as long
if FileExists(inifile) = false then
    logentry("error", inifile + " file does not excist")
else 
    f = readfromfile(inifile)
    Do Until EOF(f)
        Line Input #f, itm
        if instr(1, itm, "=") > 1 then
            inikey = trim(mid(itm, 1, instr(1, itm, "=") - 2))
            inival = trim(mid(itm, instr(1, itm, "=") + 2, len(itm)))
            if inival <> "" then
                select case inikey
                    case "defaultvolume"
                        sourcevolume = val(inival)
                    case "locale"
                        locale = inival
                    case "usecons"
                        usecons = inival
                    case "logtype"
                        logtype = inival
                    case "playtype"
                        playtype = inival
                    case "drc"
                        drc = inival
                end select
            end if
            'print inikey + " - " + inival
        end if    
    loop
    close(f)    
end if
drcvolume = sourcevolume

' parse commandline for options overides conf.ini settings
select case command(1)
    case "/?", "-man", ""
        displayhelp(locale)
        ' cleanup listplay files
        delfile(exepath + "\" + "music" + ".tmp")
        delfile(exepath + "\" + "music" + ".lst")
        delfile(exepath + "\" + "music" + ".swp")
        logentry("terminate", "normal termination " + appname)
end select

' get media
imagefolder = command(1)
if imagefolder = "" then
    imagefolder = exepath
end if
if instr(command(1), ".") <> 0 then
    fileext = lcase(mid(command(1), instrrev(command(1), ".")))
    if instr(1, filetypes, fileext) = 0 and instr(1, ".m3u, .pls", fileext) = 0 then
        logentry("fatal", command(1) + " file type not supported")
    end if
    if FileExists(exepath + "\" + command(1)) = false then
        if FileExists(imagefolder) then
            'nop
        else
            logentry("fatal", imagefolder + " does not excist or is incorrect")
        end if
    else
        imagefolder = exepath + "\" + command(1)
    end if
else
    if checkpath(imagefolder) = false then
        logentry("fatal", imagefolder + " does not excist or is incorrect")
    end if
end if
if instr(command(1), ".m3u") = 0 and instr(command(1), ".pls") = 0 and len(command(2)) = 0 then
    maxitems = createlist(imagefolder, filetypes, "music")
    filename = listplay(playtype, "music")
end if

if instr(command(1), ".") <> 0 and instr(command(1), ".m3u") = 0 and instr(command(1), ".pls") = 0 then
    filename = imagefolder
    imagefolder = left(command(1), instrrev(command(1), "\") - 1)
    maxitems = createlist(imagefolder, filetypes, "music")
    currentsong = setcurrentlistitem("music", command(1))
end if
    
' search with query and export .m3u 
if instr(command(1), ":") <> 0 and len(command(2)) <> 0 then
    select case command(2)
        case "artist"
        case "title"
        case "album"
        case "year"
        case "genre"
        case else
            logentry("fatal", "unknown tag '" & command(2) & "' valid tags artist, title, album, genre and year")
    end select
    ' scan and search nr results overwritten by getmp3playlist
    maxitems = exportm3u(command(1), "*.mp3", "m3u", "exif", command(2), command(3))
    maxitems = getmp3playlist(exepath + "\" + command(3) + ".m3u")
    filename = listplay(playtype, "music")
    currentsong = setcurrentlistitem("music", filename)
    if currentsong = 1 then
        logentry("fatal", "no matches found for " + command(3) + " in " + command(2))
    end if
end if

if instr(command(1), ".pls") <> 0 or instr(command(1), ".m3u") <> 0 then
    maxitems = getmp3playlist(command(1))
    filename = listplay(playtype, "music")
    logentry("notice", "parsing and playing plylist " + filename)
end if

' Find out which version of BASS is present.
If (HiWord(BASS_GetVersion()) <> BASSVERSION) Then
	logentry("fatal", "A wrong version of the BASS library has been found!")
End If

' Initialize BASS using the default device at 44.1 KHz.
If (BASS_Init(-1, 44100, 0, 0, 0) = FALSE) Then
	logentry("fatal", "Could not initialize audio! BASS returned error " & BASS_ErrorGetCode())
End If

' prime mp3
Dim As String fx1File = filename
Dim As HSTREAM fx1Handle = BASS_StreamCreateFile(0, StrPtr(fx1File), 0, 0, BASS_STREAM_PRESCAN or BASS_SAMPLE_FLOAT)

' compound seconds to hours, minutes, etc 
function compoundtime(m As Long) as string
    dim dummy as string
    Dim As Long c(1 To 5)={604800,86400,3600,60,1}
    Dim As String g(1 To 5)={" Wk "," d "," hr "," min "," sec"},comma
    Dim As Long b(1 To 5),flag,m2=m
    Redim As Long s(0)
    For n As Long=1 To 5
        If m>=c(n) Then
            Do
                Redim Preserve s(Ubound(s)+1)
                s(Ubound(s))=c(n)
                m=m-c(n)
            Loop Until m<c(n)
        End If
    Next n 
    For n As Long=1 To Ubound(s)
        For m As Long=1 To 5
            If s(n)=c(m) Then b(m)+=1
        Next m
    Next n
    'Print m2;" seconds = ";
    For n As Long=1 To 5
        If b(n) Then: comma=Iif(n<5 Andalso b(n+1),","," and"):flag+=1 
        If flag=1 Then comma=""
            'Print comma;b(n);g(n);
            dummy = dummy + str(b(n)) + str(g(n))
        End If
    Next
    return dummy
End function

' listduration for recursive scan dir
if maxitems > 1 then
    Dim scanhandle As HSTREAM
    dim tmp        as long
    dim cnt        as integer = 1
    itemlist = exepath + "\music.tmp"
    tmp = readfromfile(itemlist)
    cls
    ' count items in list and tally duration songs
    Do Until EOF(tmp)
        Locate 1, 1   
        print "scanning folder for audiofiles and creating playlist..."
        Line Input #tmp, listitem
        scanhandle = BASS_StreamCreateFile(0, StrPtr(listitem), 0, 0, BASS_STREAM_DECODE)
        ' length in bytes
        chanlengthbytes = BASS_ChannelGetLength(scanhandle, BASS_POS_BYTE)
        ' convert bytes to seconds
        tracklength = BASS_ChannelBytes2Seconds(scanhandle, chanlengthbytes)
        listduration = listduration + tracklength
        print cnt
        cnt += 1
        BASS_StreamFree(scanhandle)    
    Loop
    close(tmp)
end if

' set os fader volume app channel
function setvolumeosmixer(volume as ulong) as boolean

    Dim hMixer      As HMIXER
    Dim mxlc        As MIXERLINECONTROLS
    Dim mxcd        As MIXERCONTROLDETAILS
    Dim mxcd_vol    As MIXERCONTROLDETAILS_UNSIGNED
    Dim mxl         As MIXERLINE
    Dim mxlc_vol    As MIXERCONTROL

    ' Open the mixer
    mixerOpen(@hMixer, 0, 0, 0, 0)

    '  get volume control for app channel
    mxlc.cbStruct       = SizeOf(MIXERLINECONTROLS)
    mxlc.dwControlType  = MIXERCONTROL_CONTROLTYPE_VOLUME
    mxlc.cControls      = 1
    mxlc.cbmxctrl       = SizeOf(MIXERCONTROL)
    mxlc.pamxctrl       = @mxlc_vol
    mixerGetLineControls(hMixer, @mxlc, MIXER_GETLINECONTROLSF_ONEBYTYPE)

    ' get fader volume app channel
    mxcd.cbStruct = SizeOf(MIXERCONTROLDETAILS)
    mxcd.dwControlID    = mxlc_vol.dwControlID
    mxcd.cChannels      = 1
    mxcd.cMultipleItems = 0
    mxcd.cbDetails      = SizeOf(MIXERCONTROLDETAILS_UNSIGNED)
    mxcd.paDetails      = @mxcd_vol
    mixerGetControlDetails(hMixer, @mxcd, MIXER_GETCONTROLDETAILSF_VALUE)

    ' set fader volume app channel
    mxcd_vol.dwValue = volume
    mxcd.hwndOwner = 0
    mixerSetControlDetails(hMixer, @mxcd, MIXER_SETCONTROLDETAILSF_VALUE)

    ' close the mixer
    mixerClose(hMixer)
    return true

end function

' get os fader volume app channel
function getvolumeosmixer() as ulong

    Dim hMixer      As HMIXER
    Dim mxlc        As MIXERLINECONTROLS
    Dim mxcd        As MIXERCONTROLDETAILS
    Dim mxcd_vol    As MIXERCONTROLDETAILS_UNSIGNED
    Dim mxl         As MIXERLINE
    Dim mxlc_vol    As MIXERCONTROL

    ' Open the mixer
    mixerOpen(@hMixer, 0, 0, 0, 0)

    '  get volume control for app channel
    mxlc.cbStruct       = SizeOf(MIXERLINECONTROLS)
    mxlc.dwControlType  = MIXERCONTROL_CONTROLTYPE_VOLUME
    mxlc.cControls      = 1
    mxlc.cbmxctrl       = SizeOf(MIXERCONTROL)
    mxlc.pamxctrl       = @mxlc_vol
    mixerGetLineControls(hMixer, @mxlc, MIXER_GETLINECONTROLSF_ONEBYTYPE)

    ' get fader volume app channel
    mxcd.cbStruct       = SizeOf(MIXERCONTROLDETAILS)
    mxcd.dwControlID    = mxlc_vol.dwControlID
    mxcd.cChannels      = 1
    mxcd.cMultipleItems = 0
    mxcd.cbDetails      = SizeOf(MIXERCONTROLDETAILS_UNSIGNED)
    mxcd.paDetails      = @mxcd_vol
    mixerGetControlDetails(hMixer, @mxcd, MIXER_GETCONTROLDETAILSF_VALUE)

    ' close the mixer
    mixerClose(hMixer)
    
    ' return volume app channel
    return mxcd_vol.dwValue

end function

' convert os fader volume app channel
' scale from 0 ~ 65535 to 0 ~ 100 (windows mixer)
function displayvolumeosmixer(volume as ulong) as integer
    volume = volume / (65535 * 0.01)
    return int(volume)
end function

' init playback
dim refreshinfo     as boolean = true
'dim taginfo(1 to 5) as string
dim firstmp3        as integer = 1
dim musiclevel      as single
dim maxlevel        as single
dim sleeplength     as integer = 1000
readuilabel(exepath + "\conf\" + locale + "\menu.ini")
getmp3cover(filename)
BASS_ChannelSetAttribute(fx1Handle, BASS_ATTRIB_VOL, sourcevolume)
currentvolume = getvolumeosmixer() 
cls

Do
	Dim As String key = UCase(Inkey)
    sleeplength = 25

    ' ghetto attempt of dynamic range compression audio
    if drc = "true" and BASS_ChannelIsActive(fx1Handle) = 1 then
        musiclevel = BASS_ChannelGetLevel(fx1Handle)
        'maxlevel = max(loWORD(musiclevel), HIWORD(musiclevel)) / 32768.0f
        'drcvolume = (1.5f + (1.5f - maxlevel)) - maxlevel
        maxlevel = min(loWORD(musiclevel), HIWORD(musiclevel)) / 32768.0f
        drcvolume = ((1.0f + (4.75f - maxlevel)) - maxlevel) * sourcevolume
        'drcvolume = 2.0f - max(loWORD(musiclevel), HIWORD(musiclevel)) / 32768
        BASS_ChannelSetAttribute(fx1Handle, BASS_ATTRIB_VOL, drcvolume)
    else
        BASS_ChannelSetAttribute(fx1Handle, BASS_ATTRIB_VOL, sourcevolume) 
    end if

	Select Case key
        Case Chr$(32)
            ' toggle mp3 mute status
            If musicstate Then
                BASS_ChannelPause(fx1Handle)
                musicstate = false
            Else
                BASS_ChannelPlay(fx1Handle, 0)
                musicstate = true
            End If
        Case "."
            ' play next mp3
            BASS_ChannelStop(fx1Handle)    
            BASS_StreamFree(fx1Handle)    
            filename = listplay(playtype, "music")
            getmp3cover(filename)
            fx1Handle = BASS_StreamCreateFile(0, StrPtr(filename), 0, 0, BASS_STREAM_PRESCAN)
            BASS_ChannelPlay(fx1Handle, 0)
            erase taginfo 
            refreshinfo = true
            cls
        Case ","
            ' play previous mp3
            BASS_ChannelStop(fx1Handle)    
            BASS_StreamFree(fx1Handle)    
            filename = listplay("linearmin", "music")
            getmp3cover(filename)
            fx1Handle = BASS_StreamCreateFile(0, StrPtr(filename), 0, 0, BASS_STREAM_PRESCAN)
            BASS_ChannelPlay(fx1Handle, 0)
            erase taginfo 
            refreshinfo = true
            cls
        Case "]"
            ' fast foward 10 sec
            if secondsPosition < tracklength then
                secondsPosition = secondsPosition + 10
                BASS_ChannelSetPosition(fx1Handle, BASS_ChannelSeconds2Bytes(fx1Handle, + secondsPosition), BASS_POS_BYTE)
            end if
            cls
        Case "["
            ' rewind 10 sec
            if secondsPosition > 20 then
                secondsPosition = secondsPosition - 10
                BASS_ChannelSetPosition(fx1Handle, BASS_ChannelSeconds2Bytes(fx1Handle, + secondsPosition), BASS_POS_BYTE)
            end if
            cls
        Case "R"
            ' restart mp3
            BASS_ChannelPlay(fx1Handle, 1)
        Case "L"
            ' change list playtype
            select case playtype
                case "linear"
                    playtype = "shuffle"
                case "shuffle"
                    playtype = "linear"
            end select
        Case "D"
            ' toggle drc
            select case drc
                case "true"
                    drc = "false"
                    drcvolume = sourcevolume
                case "false"
                    drc = "true"
            end select
        Case "-"
            ' decrease fader mixer os volume (in range 0 - 65535)
            currentvolume = currentvolume - 1000
            if currentvolume < 1001 then currentvolume = 0 end if
            setvolumeosmixer(currentvolume)
        Case "+"
            ' increase fader mixer os volume (in range 0 - 65535)
            currentvolume = currentvolume + 1000
            if currentvolume > 65535 then currentvolume = 65535 end if
            setvolumeosmixer(currentvolume)
        Case Chr(27)
            Exit Do
        case else
            ' detect volume change via os mixer
            currentvolume = getvolumeosmixer()
            sleeplength = 1000
	End Select

    ' auto play next mp3 from list if applicable
	if BASS_ChannelIsActive(fx1Handle) = 0 and maxitems > 1 and firstmp3 = 0 then
            ' play next mp3
            BASS_ChannelStop(fx1Handle)    
            BASS_StreamFree(fx1Handle)    
            filename = listplay(playtype, "music")
            getmp3cover(filename)
            fx1Handle = BASS_StreamCreateFile(0, StrPtr(filename), 0, 0, BASS_STREAM_PRESCAN)
            BASS_ChannelPlay(fx1Handle, 0)
            refreshinfo = true
            cls
    end if

    ' play with first song
    if firstmp3 = 1 then
        BASS_ChannelPlay(fx1Handle, 0)
        firstmp3 = 0
        musicstate = true
    end if

    ' mp3 play time elapsed
    secondsPosition = BASS_ChannelBytes2Seconds(fx1Handle, BASS_ChannelGetPosition(fx1Handle, BASS_POS_BYTE))
    ' length in bytes
    chanlengthbytes = BASS_ChannelGetLength(fx1Handle, BASS_POS_BYTE)
    ' convert bytes to seconds
    tracklength = BASS_ChannelBytes2Seconds(fx1Handle, chanlengthbytes)

    ' ascii interface
    Locate 1, 1
    ' basic interaction
    Print "| BASS library demonstration v" + exeversion
    PRINT
    getuilabelvalue("next")
    getuilabelvalue("previous")
    getuilabelvalue("forward")
    getuilabelvalue("back")
    getuilabelvalue("pause")
    getuilabelvalue("restart")
    getuilabelvalue("togglelist")
    getuilabelvalue("drc")
    getuilabelvalue("volumedown")
    getuilabelvalue("volumeup")
    getuilabelvalue("quit")
    Print
    ' tag info
    if refreshinfo = true and instr(filename, ".mp3") <> 0 then
        getmp3baseinfo(filename)
        refreshinfo = false
    end if    
    getuilabelvalue("artist", taginfo(1))
    getuilabelvalue("title" , taginfo(2))
    getuilabelvalue("album" , taginfo(3))
    getuilabelvalue("year"  , taginfo(4))
    getuilabelvalue("genre" , taginfo(5))
    Print
    if taginfo(1) <> "----" and taginfo(2) <> "----" then
        getuilabelvalue("current", currentsong & ". " & taginfo(1) + " - " + taginfo(2))
    else    
        getuilabelvalue("current", currentsong & ". " & mid(left(filename, len(filename) - instr(filename, "\") -1), InStrRev(filename, "\") + 1, len(filename)))
    end if
    getuilabelvalue("duration", compoundtime(tracklength) & " / " & compoundtime(CInt(secondsPosition)) & "           ")
    ' song list info
    getuilabelvalue("list", maxitems & " / " & compoundtime(listduration) & " " & playtype + "  ")
    getuilabelvalue("file", filename)
    if musicstate = false then
        getuilabelvalue("volume",  "mute  ")
    else
        getuilabelvalue("volume", format(displayvolumeosmixer(currentvolume), "###-       "))
    end if
    print using "drc:      #.###"; drcvolume;
    print "  " & drc & "       "

    Sleep(sleeplength)

Loop

cleanup:
' cleanup listplay files
delfile(exepath + "\" + "music" + ".tmp")
delfile(exepath + "\" + "music" + ".lst")
delfile(exepath + "\" + "music" + ".swp")
delfile(exepath + "\thumb.jpg")
delfile(exepath + "\thumb.png")

' Free all resources allocated by BASS
BASS_Free()
close
logentry("terminate", "normal termination " + appname)
