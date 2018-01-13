#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icon.ico
#AutoIt3Wrapper_Outfile=..\ddolauncher.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=Original: Copyright 2012 by Florian Stinglmayr (Website: http://github/n0la/ddolauncher)
#AutoIt3Wrapper_Res_Description=An alternate DDO launcher
#AutoIt3Wrapper_Res_Fileversion=1.0.4.0
#AutoIt3Wrapper_Res_LegalCopyright=AutoIt port from Python by: MIvanIsten (https://github.com/MIvanIsten)
#AutoIt3Wrapper_Res_Field=ProductName|DDO-ML
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/rsln /mo
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs
	[FileVersion]
#ce
#include <File.au3>

$oErrObj = ObjEvent("AutoIt.Error","_MyErrFunc")
$debug = 0
$server = ""
$language = "English"
$subscription = ""
$user = ""
$pass = ""
$listservers = 0
$patch = 0
$ddogamedir = ""
$exe = ""
$outport = 0

If $CmdLine[0] > 0 Then
	For $i = 1 To $CmdLine[0]
		Select
			Case $CmdLine[$i] == "-g" Or $CmdLine[$i] == "--game-path"
				$i = $i + 1
				$ddogamedir = $CmdLine[$i]
			Case $CmdLine[$i] == "-u" Or $CmdLine[$i] == "--user"
				$i = $i + 1
				$user = $CmdLine[$i]
			Case $CmdLine[$i] == "-a" Or $CmdLine[$i] == "--pass"
				$i = $i + 1
				$pass = $CmdLine[$i]
			Case $CmdLine[$i] == "-h" Or $CmdLine[$i] == "--help"
				Usage()
				Exit 0
			Case $CmdLine[$i] == "-l" Or $CmdLine[$i] == "--list-servers"
				$listservers = 1
			Case $CmdLine[$i] == "-p" Or $CmdLine[$i] == "--patch"
				$patch = 1
			Case $CmdLine[$i] == "-s" Or $CmdLine[$i] == "--server"
				$i = $i + 1
				$server = $CmdLine[$i]
			Case $CmdLine[$i] == "-z" Or $CmdLine[$i] == "--subscription"
				$i = $i + 1
				$subscription = $CmdLine[$i]
			Case $CmdLine[$i] == "-d"
				$i = $i + 1
				$debug = $CmdLine[$i]
				If $debug <> 1 And $debug <> 2 Then $debug = 0
			Case $CmdLine[$i] == "-v" Or $CmdLine[$i] == "--version"
				Version()
				Exit 0
			Case $CmdLine[$i] == "-o" Or $CmdLine[$i] == "--out-port"
				$i = $i + 1
				$outport = $CmdLine[$i]
		EndSelect
	Next
EndIf

If $ddogamedir == "" Then
	Usage()
	Exit 1
EndIf

$exe = $ddogamedir & "\\dndclient.exe"
If Not FileExists($exe) Then
	ConsoleWriteError('Your DDO game directory "' & $ddogamedir & '" does not appear to be right.' & @CRLF)
	ConsoleWriteError("Try specifying your full absolute path to DDO through the -g option." & @CRLF)
	Exit 1
EndIf

$config = get_config_data($ddogamedir)
If IsArray($config) Then
	$datacenter = $config[0]
	$gamename = $config[1]
EndIf
If $datacenter == "" Or $gamename == "" Then
	ConsoleWriteError("Failed to get data center!" & @CRLF)
	Exit 1
EndIf

$config = query_worlds($datacenter, $gamename)
If IsArray($config) Then
	$authserver = $config[0]
	$patchserver = $config[1]
	$configserver = $config[2]
	$worlds = $config[3]
EndIf

$LoginQueueURL = query_queue_url($configserver)

If $debug > 0 Then 
	_FileWriteLog("ddolauncher.txt", "ddogamedir: " & $ddogamedir & @CRLF)
	_FileWriteLog("ddolauncher.txt", "exe: " & $exe & @CRLF)
	_FileWriteLog("ddolauncher.txt", "user: " & $user & @CRLF)
	_FileWriteLog("ddolauncher.txt", "pass: " & $pass & @CRLF)
	_FileWriteLog("ddolauncher.txt", "listservers: " & $listservers & @CRLF)
	_FileWriteLog("ddolauncher.txt", "patch: " & $patch & @CRLF)
	_FileWriteLog("ddolauncher.txt", "server: " & $server & @CRLF)
	_FileWriteLog("ddolauncher.txt", "subscription: " & $subscription & @CRLF)
	_FileWriteLog("ddolauncher.txt", "outport: " & $outport & @CRLF)
	_FileWriteLog("ddolauncher.txt", "datacenter: " & $datacenter & @CRLF)
	_FileWriteLog("ddolauncher.txt", "gamename: " & $gamename & @CRLF)
	_FileWriteLog("ddolauncher.txt", "$authserver: " & $authserver & @CRLF)
	_FileWriteLog("ddolauncher.txt", "$patchserver: " & $patchserver & @CRLF)
	_FileWriteLog("ddolauncher.txt", "$configserver: " & $configserver & @CRLF)
	_FileWriteLog("ddolauncher.txt", "$LoginQueueURL: " & $LoginQueueURL & @CRLF)
EndIf

If $patch == 1 Then
	ConsoleWrite("Checking for updates..." & @CRLF)
	patch_game($ddogamedir, $patchserver, $language, $gamename)
	Exit 0
EndIf

If $listservers == 1 Then
	ConsoleWrite('Authentication server:' & $authserver & @CRLF)
	ConsoleWrite('Patch server:' & $patchserver & @CRLF)
	ConsoleWrite('Config server:' & $configserver & @CRLF)
	ConsoleWrite('LoginQueue.URL:' & $LoginQueueURL & @CRLF)
	For $gw In $worlds
		ConsoleWrite('Server "' & $gw[0] & '"' & @CRLF)
		ConsoleWrite(" Login server:" & $gw[1] & @CRLF)
		ConsoleWrite(" Chat server:" & $gw[2] & @CRLF)
		ConsoleWrite(" Language:" & $gw[3] & @CRLF)
		ConsoleWrite(" Status:" & $gw[4] & @CRLF)
		ConsoleWrite(" LoginQueue:" & $gw[5] & @CRLF)
	Next
	Exit 0
EndIf

Local $selectedworlds[0]
Local $w[1]
For $gw In $worlds
	If StringLower($server) == StringLower($gw[0]) Then
		$w[0] = $gw
		_ArrayAdd($selectedworlds, $w)
	EndIf
Next

If UBound($selectedworlds) == 0 Then
	ConsoleWriteError('Your selected world does not exist.' & @CRLF)
	Exit 4
EndIf

If UBound($selectedworlds) > 1 Then
	ConsoleWriteError('Your server selection is not unique.' & @CRLF)
	Exit 5
EndIf

$world = query_host($selectedworlds[0])

$login_result = login($authserver, $world, $user, $pass, $subscription, $gamename, $LoginQueueURL)
If UBound($selectedworlds) == 0 Then
	ConsoleWriteError("Login of " & $user & " failed. Wrong password?")
Else
	run_ddo($ddogamedir, $login_result[0], $login_result[1], $language, $world, $gamename, $authserver, $outport)
EndIf

;===============================================================================
;===============================================================================
;===============================================================================

Func _GetVersion()
	If @Compiled Then
		Return FileGetVersion(@AutoItExe)
	Else
		Return IniRead(@ScriptFullPath, "FileVersion", "#AutoIt3Wrapper_Res_Fileversion", "0.0.0.0")
	EndIf
EndFunc   ;==>_GetVersion

Func run_ddo($gamedir, $username, $ticket, $language, $world, $gamename, $authserver, $outport)
	Local $params[0]

	_ArrayAdd($params, "dndclient.exe")
	_ArrayAdd($params, "-h")
	_ArrayAdd($params, $world[1])
	_ArrayAdd($params, "-a")
	_ArrayAdd($params, $username)
	_ArrayAdd($params, "--glsticketdirect")
	_ArrayAdd($params, $ticket)
	_ArrayAdd($params, "--chatserver")
	_ArrayAdd($params, '"' & $world[2] & '"')
	_ArrayAdd($params, "--language")
	_ArrayAdd($params, $language)
	_ArrayAdd($params, "--rodat")
	_ArrayAdd($params, "on")
	_ArrayAdd($params, "--gametype")
	_ArrayAdd($params, $gamename)
	_ArrayAdd($params, "--supporturl")
	_ArrayAdd($params, '"https://tss.turbine.com/TSSTrowser/trowser.aspx"')
	_ArrayAdd($params, "--supportserviceurl")
	_ArrayAdd($params, '"https://tss.turbine.com/TSSTrowser/SubmitTicket.asmx"')
	_ArrayAdd($params, "--authserverurl")
	_ArrayAdd($params, '"' & $authserver & '"')
	_ArrayAdd($params, "--glsticketlifetime")
	_ArrayAdd($params, "21600")

	If $outport Then
		_ArrayAdd($params, "--outport")
		_ArrayAdd($params, $outport)
	EndIf

	ConsoleWrite(_ArrayToString($params, ' ') & @CRLF)
EndFunc   ;==>run_ddo

Func join_queue($name, $ticket, $world, $LoginQueueURL)
	$params = "command=TakeANumber&subscription=" & $name & "&ticket=" & _UnicodeURLEncode($ticket) & "&ticket_type=GLS&queue_url=" & _UnicodeURLEncode($world[5])
	$oXML = _CreateMSXMLObj(1)
	If Not IsObj($oXML) Then
		ConsoleWriteError("_CreateMSXMLObj(1) ERROR!: Unable to create MSXML Object!!" & @CRLF)
		Exit 2
	EndIf

	While True
		$oXML.setOption(2, 13056)
		$oXML.Open("POST", $LoginQueueURL, False)
		$oXML.SetRequestHeader("Content-Type", "text/xml; charset=utf-8")
		$oXML.SetRequestHeader("Content-Length", StringLen($params))
		$oXML.Send($params)

		If @error Then Exit 2

		$oStatusCode = $oXML.status
		If $oStatusCode <> 200 Then
			ConsoleWriteError("Failed to join the queue." & @CRLF)
			If StringLen($oXML.statusText) > 0 Then
				ConsoleWriteError("Error " & $oXML.status & ": " & $oXML.statusText & @CRLF)
			EndIf
			Exit 3
		EndIf

		If $debug > 1 Then 
			_FileWriteLog("ddolauncher.txt", "join_queue: " & $oXML.responseXML.xml & @CRLF)
		EndIf

		$hresult = Dec(StringReplace($oXML.responseXML.selectSingleNode("//HResult").text, "0x", ""), 2)
		If $hresult > 0 Then
			ConsoleWriteError("World queue returned an error." & @CRLF)
			Exit 3
		Else
			$number = Dec(StringReplace($oXML.responseXML.selectSingleNode("//QueueNumber").text, "0x", ""), 2)
			$nowserving = Dec(StringReplace($oXML.responseXML.selectSingleNode("//NowServingNumber").text, "0x", ""), 2)
		EndIf

		If $number > $nowserving Then
			Sleep(2000)
		Else
			ExitLoop
		EndIf
	WEnd
EndFunc   ;==>join_queue

Func login($authserver, $world, $username, $password, $subscription, $gamename, $LoginQueueURL)
	Local $login_result[0]
	Local $found_ddo = False

	$xml = '<?xml version="1.0" encoding="utf-8"?>' & _
			'<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' & _
			'<soap:Body>' & _
			'<LoginAccount xmlns="http://www.turbine.com/SE/GLS">' & _
			'<username>' & $username & '</username>' & _
			'<password>' & $password & '</password>' & _
			'<additionalInfo></additionalInfo>' & _
			'</LoginAccount>' & _
			'</soap:Body>' & _
			'</soap:Envelope>'

	$oXML = _CreateMSXMLObj(1)
	If Not IsObj($oXML) Then
		ConsoleWriteError("_CreateMSXMLObj(1) ERROR!: Unable to create MSXML Object!!" & @CRLF)
		Exit 2
	EndIf
	
	$oXML.setOption(2, 13056)
	$oXML.Open("POST", $authserver, False)
	$oXML.SetRequestHeader("Content-Type", "text/xml; charset=utf-8")
	$oXML.SetRequestHeader("SOAPAction", "http://www.turbine.com/SE/GLS/LoginAccount")
	$oXML.SetRequestHeader("Content-Length", StringLen($xml))
	$oXML.Send($xml)

	If @error Then Exit 2

	$oStatusCode = $oXML.status
	If $oStatusCode <> 200 Then
		ConsoleWriteError("HTTP post failed." & @CRLF)
		If StringLen($oXML.statusText) > 0 Then
			ConsoleWriteError("Error " & $oXML.status & ": " & $oXML.statusText & @CRLF)
		EndIf
		Exit 2
	EndIf

	If $debug > 1 Then 
		_FileWriteLog("ddolauncher.txt", "login: " & $oXML.responseXML.xml & @CRLF)
	EndIf

	$oReceived = $oXML.responseXML
	$ticket = $oReceived.selectSingleNode('//Ticket').text

	For $game_sub In $oReceived.selectNodes('//Subscriptions/GameSubscription')
		If $subscription == "" Then
			$sub_info = $game_sub.selectSingleNode('Game')
			If StringLower($sub_info.text) == StringLower($gamename) Then
				$found_ddo = True
			EndIf
		Else
			$sub_info = $game_sub.selectSingleNode('Description')
			If StringLower($sub_info.text) == StringLower($subscription) Then
				$found_ddo = True
			EndIf
		EndIf
		If $found_ddo == True Then
			$account = $game_sub.selectSingleNode('Name').text
			ExitLoop
		EndIf
	Next

	If $found_ddo == False Then
		ConsoleWriteError("Unable to find a subscription on your account for DDO. Your LotrO account?" & @CRLF)
		Exit 2
	EndIf

	_ArrayAdd($login_result, $account)
	_ArrayAdd($login_result, $ticket)

	join_queue($account, $ticket, $world, $LoginQueueURL)

	Return $login_result
EndFunc   ;==>login

Func query_queue_url($configserver)
	Local $url = ""

	$oXML = _CreateMSXMLObj(1)
	If Not IsObj($oXML) Then
		ConsoleWriteError("_CreateMSXMLObj(1) ERROR!: Unable to create MSXML Object!!" & @CRLF)
		Exit 2
	EndIf

	$oXML.open("GET", $configserver, False)
	$oXML.send()

	If @error Then Exit 2

	$oStatusCode = $oXML.status
	If $oStatusCode <> 200 Then
		ConsoleWriteError("HTTP post failed." & @CRLF)
		If StringLen($oXML.statusText) > 0 Then
			ConsoleWriteError("Error " & $oXML.status & ": " & $oXML.statusText & @CRLF)
		EndIf
		Exit 2
	EndIf

	If $debug > 1 Then 
		_FileWriteLog("ddolauncher.txt", "query_queue_url: " & $oXML.responseXML.xml & @CRLF)
	EndIf

	$url = $oXML.responseXML.selectSingleNode('//appSettings/add[@key = "WorldQueue.LoginQueue.URL"]').getAttribute("value")

	Return $url
EndFunc   ;==>query_queue_url

Func get_config_data($basepath)
	Local $config[2] = ["", ""]

	$filename = "TurbineLauncher.exe.config"
	$path = $basepath & "\" & $filename

	$oXML = _CreateMSXMLObj(0)
	If Not IsObj($oXML) Then
		ConsoleWriteError("_CreateMSXMLObj(0) ERROR!: Unable to create MSXML Object!!" & @CRLF)
		Exit 1
	EndIf

	$oXML.async = False
	$error = $oXML.Load($path)
	If Not $error Then
		ConsoleWriteError("Load XML An error occurred loading " & $path & @CRLF)
		Exit 1
	EndIf

	$root = $oXML.documentElement
	$config[0] = $root.selectSingleNode('appSettings/add[@key = "Launcher.DataCenterService.GLS"]').getAttribute("value")
	$config[1] = $root.selectSingleNode('appSettings/add[@key = "DataCenter.GameName"]').getAttribute("value")
	Return $config
EndFunc   ;==>get_config_data

Func query_host($world)
	Local $url = ""

	$oXML = _CreateMSXMLObj(1)
	If Not IsObj($oXML) Then
		ConsoleWriteError("_CreateMSXMLObj(1) ERROR!: Unable to create MSXML Object!!" & @CRLF)
		Exit 2
	EndIf
	
	$oXML.open("GET", $world[4], False)
	$oXML.send()

	If @error Then Exit 2

	$oStatusCode = $oXML.status
	If $oStatusCode <> 200 Then
		ConsoleWriteError("The given server appears to be down.")
		If StringLen($oXML.statusText) > 0 Then
			ConsoleWriteError("Error " & $oXML.status & ": " & $oXML.statusText & @CRLF)
		EndIf
		Exit 2
	EndIf

	If $debug > 1 Then 
		_FileWriteLog("ddolauncher.txt", "query_host: " & $oXML.responseXML.xml & @CRLF)
	EndIf

	$hosts = StringSplit($oXML.responseXML.selectSingleNode("//loginservers").text, ";")
	$world[1] = $hosts[1]
	$queueurls = StringSplit($oXML.responseXML.selectSingleNode("//queueurls").text, ";")
	$world[5] = $queueurls[1]

	Return $world
EndFunc   ;==>query_host

Func query_worlds($url, $gamename)
	Local $config[4] = ["", "", ""]
	Local $w[6] = ["", "", "", "", "", ""]
	Local $game_world[1]
	Local $game_servers[0]

	$oXML = _CreateMSXMLObj(1)
	If Not IsObj($oXML) Then
		ConsoleWriteError("_CreateMSXMLObj(1) ERROR!: Unable to create MSXML Object!!" & @CRLF)
		Exit 2
	EndIf
	
	$sPD = '<?xml version="1.0" encoding="utf-8"?>' & _
			'<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' & _
			'<soap:Body>' & _
			'<GetDatacenters xmlns="http://www.turbine.com/SE/GLS">' & _
			'<game>' & $gamename & '</game>' & _
			'</GetDatacenters>' & _
			'</soap:Body>' & _
			'</soap:Envelope>'
	$oXML.Open("POST", $url, False)
	$oXML.SetRequestHeader("Content-Type", "text/xml; charset=utf-8")
	$oXML.SetRequestHeader("SOAPAction", "http://www.turbine.com/SE/GLS/GetDatacenters")
	$oXML.SetRequestHeader("Content-Length", StringLen($sPD))
	$oXML.Send($sPD)

	If @error Then Exit 2

	$oStatusCode = $oXML.status
	If $oStatusCode <> 200 Then
		ConsoleWriteError("No response from datacenter. Servers down?")
		If StringLen($oXML.statusText) > 0 Then
			ConsoleWriteError("Error " & $oXML.status & ": " & $oXML.statusText & @CRLF)
		EndIf
		Exit 2
	EndIf

	If $debug > 1 Then 
		_FileWriteLog("ddolauncher.txt", "query_worlds: " & $oXML.responseXML.xml & @CRLF)
	EndIf

	$oReceived = $oXML.responseXML
	$datacenters = $oReceived.selectNodes("//GetDatacentersResult/*")
	For $dc In $datacenters
		If $gamename == $dc.selectSingleNode("Name").text Then
			$config[0] = $dc.selectSingleNode('AuthServer').text
			$config[1] = $dc.selectSingleNode('PatchServer').text
			$config[2] = $dc.selectSingleNode('LauncherConfigurationServer').text
			$worlds = $dc.selectNodes("Worlds/*")
			For $world In $worlds
				$w[0] = $world.selectSingleNode('Name').text
				$w[1] = $world.selectSingleNode('LoginServerUrl').text
				$w[2] = $world.selectSingleNode('ChatServerUrl').text
				$w[3] = $world.selectSingleNode('Language').text
				$w[4] = $world.selectSingleNode('StatusServerUrl').text
				$game_world[0] = query_host($w)
				_ArrayAdd($game_servers, $game_world)
			Next
			$config[3] = $game_servers
		EndIf
	Next

	Return $config
EndFunc   ;==>query_worlds

Func patch_game($gamedir, $patchserver, $language, $game)
	$handle = Run(@ComSpec & ' /c ' & "rundll32.exe PatchClient.dll,Patch " & $patchserver & " --highres --filesonly --language " & $language & " --productcode " & $game, $gamedir, @SW_HIDE, 0x6)
	While 1
		$patch_text = StdoutRead($handle)
		If @error Then ExitLoop
		Sleep(1000)
		ConsoleWrite($patch_text)
	WEnd
	$handle = Run(@ComSpec & ' /c ' & "rundll32.exe PatchClient.dll,Patch " & $patchserver & " --highres --dataonly --language " & $language & " --productcode " & $game, $gamedir, @SW_HIDE, 0x6)
	While 1
		$patch_text = StdoutRead($handle)
		If @error Then ExitLoop
		Sleep(1000)
		ConsoleWrite($patch_text)
	WEnd
EndFunc   ;==>patch_game

Func _CreateMSXMLObj($mode) ; Creates a MSXML instance depending on the version installed on the system
	Switch $mode
		Case 0 ; for local file
			$xmlObj = ObjCreate("Msxml2.DOMdocument.6.0") ; Latest available, default in Vista
			If Not IsObj($xmlObj) Then
				$xmlObj = ObjCreate("Msxml2.DOMdocument.5.0") ; Office 2003
				If Not IsObj($xmlObj) Then
					$xmlObj = ObjCreate("Msxml2.DOMdocument.4.0")
					If Not IsObj($xmlObj) Then
						$xmlObj = ObjCreate("Msxml2.DOMdocument.3.0") ; XP and w2k3 server
						If Not IsObj($xmlObj) Then
							$xmlObj = ObjCreate("Msxml2.DOMdocument.2.6") ; Win98 ME...
							If Not IsObj($xmlObj) Then
								Return Null
							EndIf
						EndIf
					EndIf
				EndIf
			EndIf
		Case 1 ; for remote file
			$xmlObj = ObjCreate("Msxml2.ServerXMLHTTP")
			If Not IsObj($xmlObj) Then
				Return Null
			EndIf
	EndSwitch
	Return $xmlObj
EndFunc   ;==>_CreateMSXMLObj

Func _MyErrFunc()
;~ 					"description: "    & $oErrObj.description
;~ 					"windescription: " & $oErrObj.windescription
;~ 					"lastdllerror: "   & $oErrObj.lastdllerror
;~ 					"scriptline: "     & $oErrObj.scriptline
;~ 					"number: "         & Hex($oErrObj.number,8)
;~ 					"source: "         & $oErrObj.source
;~ 					"helpfile: "       & $oErrObj.helpfile
;~ 					"helpcontext: "    & $oErrObj.helpcontext
	If $debug>0 Then
		$msg = "ddolauncher "
		If $oErrObj.scriptline > -1 Then $msg &= "Line: " & $oErrObj.scriptline & ", "
		$msg &= "ERROR " & Hex($oErrObj.number,8)  & ": " & $oErrObj.description
		ConsoleWriteError($msg)
		_FileWriteLog("ddolauncher.txt", $msg)
	EndIf
	Seterror(1)
EndFunc   ;==>_MyErrFunc

Func Usage()
	ConsoleWrite("ddolauncher.exe -g gamedir [options]" & @CRLF)
	ConsoleWrite("" & @CRLF)
	ConsoleWrite("Options:" & @CRLF)
	ConsoleWrite(" -g --game-path Full absolute path to were DDO is." & @CRLF)
	ConsoleWrite(" -u --user account" & @CRLF)
	ConsoleWrite(" -a --pass password" & @CRLF)
	ConsoleWrite(" -h --help (This)" & @CRLF)
	ConsoleWrite(" -l --list-servers List all servers and exit." & @CRLF)
	ConsoleWrite(" -p --patch Run DDO patcher." & @CRLF)
	ConsoleWrite(" -s --server Specify server to login to, default Ghallanda." & @CRLF)
	ConsoleWrite(" -z --subscription Specify subscription name, default to the first one" & @CRLF)
	ConsoleWrite(" -d Specify debug level (1|2)" & @CRLF)
	ConsoleWrite(" -v --version Print version and author information." & @CRLF)
	ConsoleWrite(" -o --out-port Output for DDO to use. DDO binds to this address so using the same port again will cause DDO to fail." & @CRLF)
EndFunc   ;==>Usage

Func Version()
	ConsoleWrite("ddolauncher - An alternate DDO launcher v" & _GetVersion() & @CRLF)
	ConsoleWrite("Original: Copyright 2012 by Florian Stinglmayr" & @CRLF)
	ConsoleWrite("Website: http://github/n0la/ddolauncher" & @CRLF)
	ConsoleWrite("Modified by AtomicMew: accept command line password, multiple subscriptions and always output to stdout" & @CRLF)
	ConsoleWrite("AutoIt port from Python by: MIvanIsten (https://github.com/MIvanIsten)" & @CRLF)
EndFunc   ;==>Version

;===============================================================================
; _UnicodeURLEncode()
; Description: : Encodes an unicode string to be URL-friendly
; Parameter(s): : $UnicodeURL - The Unicode String to Encode
; Return Value(s): : The URL encoded string
; Author(s): : Dhilip89
; Note(s): : -
;
;===============================================================================

Func _UnicodeURLEncode($UnicodeURL)
	$UnicodeBinary = StringToBinary($UnicodeURL, 4)
	$UnicodeBinary2 = StringReplace($UnicodeBinary, '0x', '', 1)
	$UnicodeBinaryLength = StringLen($UnicodeBinary2)
	Local $EncodedString
	For $i = 1 To $UnicodeBinaryLength Step 2
		$UnicodeBinaryChar = StringMid($UnicodeBinary2, $i, 2)
;~ 		If StringInStr("$-_.+!*'(),;/?:@=&abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", BinaryToString ('0x' & $UnicodeBinaryChar, 4)) Then
		If StringInStr("-_.abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", BinaryToString('0x' & $UnicodeBinaryChar, 4)) Then
			$EncodedString &= BinaryToString('0x' & $UnicodeBinaryChar)
		Else
			$EncodedString &= '%' & $UnicodeBinaryChar
		EndIf
	Next
	Return $EncodedString
EndFunc   ;==>_UnicodeURLEncode

;===============================================================================
; _UnicodeURLDecode()
; Description: : Tranlates a URL-friendly string to a normal string
; Parameter(s): : $toDecode - The URL-friendly string to decode
; Return Value(s): : The URL decoded string
; Author(s): : nfwu, Dhilip89
; Note(s): : Modified from _URLDecode() that's only support non-unicode.
;
;===============================================================================
Func _UnicodeURLDecode($toDecode)
	Local $strChar = "", $iOne, $iTwo
	Local $aryHex = StringSplit($toDecode, "")
	For $i = 1 To $aryHex[0]
		If $aryHex[$i] = "%" Then
			$i = $i + 1
			$iOne = $aryHex[$i]
			$i = $i + 1
			$iTwo = $aryHex[$i]
			$strChar = $strChar & Chr(Dec($iOne & $iTwo))
		Else
			$strChar = $strChar & $aryHex[$i]
		EndIf
	Next
	$Process = StringToBinary(StringReplace($strChar, "+", " "))
	$DecodedString = BinaryToString($Process, 4)
	Return $DecodedString
EndFunc   ;==>_UnicodeURLDecode
