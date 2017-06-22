#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_Outfile=..\ddoclient_wrapper.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Description=An alternate DDO launcher
#AutoIt3Wrapper_Res_Fileversion=1.0.1.1
#AutoIt3Wrapper_Res_Field=ProductName|DDO-ML
#AutoIt3Wrapper_Add_Constants=n
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/rsln /mo
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs
	[FileVersion]
#ce

#include <File.au3>
TraySetState(2)

If $CmdLine[0] < 2 Then Exit 1

$ini_file = "ddo-ml.ini"
$debug = IniRead($ini_file, "startup", "debug", "0")

$pid = $cmdline[1]
$rename = $cmdline[2]

If $debug == 1 Then
	_FileWriteLog("debug.txt", $pid)
EndIf

$rArr = _ProcessGetHWnd($pid, 2, "[Title:Dungeons and Dragons Online; CLASS:Turbine Device Class]", 8000)
;update 19 - DDO creates "ghost" first window before creating real window
If Not @error Then
	$handle = $rArr[1][1]
	$timer = TimerInit()
	WinSetTitle($handle, "", $rename)
	While (WinExists($handle))
		If TimerDiff($timer) > 7000 Then Exit 1
		Sleep(Opt("WinWaitDelay"))
	WEnd
EndIf

$rArr = _ProcessGetHWnd($pid, 2, "[Title:Dungeons and Dragons Online; CLASS:Turbine Device Class]", 8000)
If Not @error Then
	$handle = $rArr[1][1]
	WinSetTitle($handle, "", $rename)
	Exit 0
Else
	Exit 1
EndIf

Func _GetVersion()
	If @Compiled Then
		Return FileGetVersion(@AutoItExe)
	Else
		Return IniRead(@ScriptFullPath, "FileVersion", "#AutoIt3Wrapper_Res_Fileversion", "0.0.0.0")
	EndIf
EndFunc   ;==>_GetVersion

Func _ProcessGetHWnd($iPid, $iOption = 1, $sTitle = "", $iTimeout = 2000)
	Local $aReturn[1][1] = [[0]], $aWin, $hTimer = TimerInit()

	While 1
		; Get list of windows
		$aWin = WinList($sTitle)

		; Searches thru all windows
		For $i = 1 To $aWin[0][0]

			; F*ound a window owned by the given PID
			If $iPid = WinGetProcess($aWin[$i][1]) Then

				; Option 0 or 1 used
				If $iOption = 1 Or ($iOption = 0 And $aWin[$i][0] <> "") Then
					Return $aWin[$i][1]

					; Option 2 is used
				ElseIf $iOption = 2 Then
					ReDim $aReturn[UBound($aReturn) + 1][2]
					$aReturn[0][0] += 1
					$aReturn[$aReturn[0][0]][0] = $aWin[$i][0]
					$aReturn[$aReturn[0][0]][1] = $aWin[$i][1]
				EndIf
			EndIf
		Next

		; If option 2 is used and there was matches then the list is returned
		If $iOption = 2 And $aReturn[0][0] > 0 Then Return $aReturn

		; If timed out then give up
		If TimerDiff($hTimer) > $iTimeout Then ExitLoop

		; Waits before new attempt
		Sleep(Opt("WinWaitDelay"))
	WEnd

	; No matches
	SetError(1)
	Return 0
EndFunc   ;==>_ProcessGetHWnd
