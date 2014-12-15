#AutoIt3Wrapper_UseX64=N
#include <File.au3>
traysetstate(2)


$ini_file = "ddo-ml.ini"
$debug = IniRead($ini_file, "startup", "debug", "0")
;~ msgbox(0,"",$cmdline[0])
;~ msgbox(0,"",$cmdline[1])
;~ msgbox(0,"",$cmdline[2])
;~ msgbox(0,"",$cmdline[3])
;~ msgbox(0,"",$cmdline[4])

$pid = $cmdline[1]
$rename = $cmdline[2]
;msgbox(0,"",$py_out)

		if $debug == 1 Then
			_FileWriteLog ( "debug.txt", $pid )
	    EndIf

		$rArr = _ProcessGetHWnd($pid, 2, "[Title:Dungeons and Dragons Online; CLASS:Turbine Device Class]", 8000)
		;update 19 - DDO creates "ghost" first window before creating real window
		If Not @error Then
			$handle = $rArr[1][1]
			$timer = timerInit()
			If $rename <> "" Then
				WinSetTitle($handle, "", $rename)
			EndIf
			while(WinExists($handle))
				if TimerDiff($timer) > 7000 Then exit 1
				Sleep(Opt("WinWaitDelay"))
			WEnd
		EndIf
		$rArr = _ProcessGetHWnd($pid, 2, "[Title:Dungeons and Dragons Online; CLASS:Turbine Device Class]", 8000)
		If Not @error Then
			If $rename == "" Then
				exit 0
			EndIf
			$handle = $rArr[1][1]
			WinSetTitle($handle, "", $rename)
			exit 0
		Else
			exit 1
		EndIf

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
