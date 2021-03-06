;
; File encoding:  UTF-8
; Platform:  Windows XP/Vista/7
; Author:    A.N.Other <myemail@nowhere.com>
;
; Script description:
;	Template script
;

#NoEnv
#NoTrayIcon
#SingleInstance Ignore
SetWorkingDir, %A_ScriptDir%
FileEncoding, UTF-8
Menu, Tray, NoStandard

title = SciTE4AutoHotkey installation
downloadurl = http://www.autohotkey.net/~fincs/SciTE4AutoHotkey_3/s4ahk-instdata.bin
version = 3.0.00

if A_IsCompiled
{
	if GetWinVer() < 5.1
	{
		MsgBox, 16, %title%, Windows XP or newer is required.
		ExitApp
	}

	if GetWinVer() >= 6 && !A_IsAdmin
	{
		MsgBox, 16, %title%, Admin rights required.
		ExitApp
	}
}

dlgoptions := "DlgTopmost=1, DlgStyle=Border, HtmFocus=1, Buttons=&Install/&Close, HtmW=480, HtmH=360, BEsc=2"

if HtmDlg("res://" A_ScriptFullPath "/10/dialog.html#" GetSysColor(15), "", dlgoptions) - 1
	ExitApp

FileInstall, 7z.exe, %A_Temp%\7z.exe, 1
ChkFileInstall("7z.exe")

tmpdir := A_Temp "\tmp-s4ahk-v" version A_TickCount
ahkdir := GetAutoHotkeyDir()
if !ahkdir
{
	MsgBox, 16, %title%, Failed to find AutoHotkey folder!
	ExitApp
}

IfNotExist, s4ahk-instdata.bin
{
	Menu, Tray, Icon
	TrayTip, SciTE4AutoHotkey Installer, Download in progress..., 5, 1
	r := NiceDownloader(downloadurl, A_ScriptDir "\s4ahk-instdata.bin", "Downloading SciTE4AutoHotkey...")
	Menu, Tray, NoIcon
	if !r
	{
		MsgBox, 16, %title%, Attempt to download SciTE4AutoHotkey failed!
		ExitApp
	}
}

RunWait, %A_Temp%\7z.exe x "%A_ScriptDir%\s4ahk-instdata.bin" "-o%tmpdir%" -aoa
FileRead, ver, %tmpdir%\$MAIN\$VER
if (ver != version)
{
	MsgBox, 16, Title, Version mismatch, you are using an outdated installer.
	ExitApp
}

UninstallOldBetas(0)
; The following was decided against, as the toolbar already does this
;~ profile = %A_MyDocuments%\AutoHotkey\SciTE
;~ IfExist, %profile%
;~ {
	;~ FileRead, ver, %profile%\$VER
	;~ if (ver != "3 beta4") && (ver != "3 beta5")
		;~ ; Delete the profile
		;~ WipeProfile(profile)
;~ }

instdir = %ahkdir%\SciTE
IfExist, %instdir%
	FileRemoveDir, %instdir%, 1

FileCreateDir, %instdir%

Progress, b m2 zh0, Copying files...
FileCopyDir, % tmpdir "\$" (A_Is64bitOS ? "X64" : "X86"), %instdir%, 1
ChkCopy()
FileCopyDir, %tmpdir%\$MAIN, %instdir%, 1
ChkCopy()
Progress, Off

FileInstall, uninst.exe, %instdir%\uninst.exe, 1
key = Software\Microsoft\Windows\CurrentVersion\Uninstall\SciTE4AutoHotkey
RegWrite, REG_SZ, HKLM, %key%, DisplayName, SciTE4AutoHotkey v%version%
RegWrite, REG_SZ, HKLM, %key%, DisplayVersion, v%version%
RegWrite, REG_SZ, HKLM, %key%, Publisher, fincs
RegWrite, REG_SZ, HKLM, %key%, DisplayIcon, %instdir%\SciTE.exe
RegWrite, REG_SZ, HKLM, %key%, URLInfoAbout, http://www.autohotkey.net/~fincs/SciTE4AutoHotkey_3/web/
RegWrite, REG_SZ, HKLM, %key%, UninstallString, %instdir%\uninst.exe

; COM registering
RegWrite, REG_SZ, HKLM, Software\Classes\SciTE4AHK.Application,, SciTE4AHK.Application
RegWrite, REG_SZ, HKLM, Software\Classes\SciTE4AHK.Application\CLSID,, {D7334085-22FB-416E-B398-B5038A5A0784}
RegWrite, REG_SZ, HKLM, Software\Classes\CLSID\{D7334085-22FB-416E-B398-B5038A5A0784},, SciTE4AHK.Application

MsgBox, 36, %title%, Do you want to set SciTE4AutoHotkey as the default .ahk editor?
IfMsgBox, Yes
	RegWrite, REG_SZ, HKCR, AutoHotkeyScript\Shell\Edit\command,, "%instdir%\SciTE.exe" "`%1"

MsgBox, 36, %title%, Do you want to create a desktop shortcut?
IfMsgBox, Yes
	Shortcut(A_DesktopCommon "\SciTE4AutoHotkey.lnk", instdir "\SciTE.exe", "AutoHotkey Script Editor")

MsgBox, 36, %title%, Do you want to create a Start Menu folder?
IfMsgBox, Yes
{
	FileCreateDir, %A_ProgramsCommon%\SciTE4AutoHotkey
	Shortcut(A_ProgramsCommon "\SciTE4AutoHotkey\SciTE4AutoHotkey.lnk", instdir "\SciTE.exe", "AutoHotkey Script Editor")
	Shortcut(A_ProgramsCommon "\SciTE4AutoHotkey\Uninstall.lnk", instdir "\uninst.exe", "Uninstall SciTE4AutoHotkey...")
}

FileRemoveDir, %tmpdir%, 1

MsgBox, 64, %title%, Done! Thank you for choosing SciTE4AutoHotkey.

ExitApp

Shortcut(Shrt, Path, Descr)
{
	SplitPath, Path,, Dir
	FileDelete, %Shrt%
	FileCreateShortcut, %Path%, %Shrt%, %Dir%,, %Descr%
}

; GetSysColor() function by SKAN
GetSysColor( DisplayElement=1 ) {
	VarSetCapacity( HexClr,14,0 ), SClr := DllCall( "GetSysColor", UInt,DisplayElement )
	RGB := ( ( ( SClr & 0xFF) << 16 ) | ( SClr & 0xFF00 ) | ( ( SClr & 0xFF0000 ) >> 16 ) )
	DllCall( "msvcrt\" (A_IsUnicode ? "swprintf" : "sprintf"), Str,HexClr, Str,"%06X", UInt,RGB )
	return HexClr
}

GetWinVer()
{
	pack := DllCall("GetVersion", "uint") & 0xFFFF
	return (pack & 0xFF) "." (pack >> 8)
}

ChkFileInstall(name)
{
	global title
	if ErrorLevel
	{
		MsgBox, 16, %title%, Can't extract %name%!
		ExitApp
	}
}

ChkCopy()
{
	global title
	if ErrorLevel
	{
		Progress, Off
		MsgBox, 16, %title%, Can't copy files!
		ExitApp
	}
}

OptCopy(src, dest, fname)
{
	IfExist, %dest%\%fname%
	{
		MsgBox, 36, Title, File %fname% already exists. Overwrite it?
		IfMsgBox, No
			return
	}
	FileCopy, %src%\%fname%, %dest%\%fname%, 1
}

__html_resources()
{
	FileInstall, dialog.html, _
	FileInstall, banner.png, _
}
