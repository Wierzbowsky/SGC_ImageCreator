; SGC Image Creator Tool version 1.0
; Copyright (c) 2017 Alexey Podrezov (alexey.podrezov@gmail.com)
;

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=sgc.ico
#AutoIt3Wrapper_Res_Comment=SGC Image Creator
#AutoIt3Wrapper_Res_Description=Small Games Cartridge Image Creator
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=Copyright (c) 2017 Alexey Podrezov
#AutoIt3Wrapper_Res_Field=Created By|Alexey Podrezov
#AutoIt3Wrapper_Res_Icon_Add=sgc.ico
#AutoIt3Wrapper_Res_File_Add=board.bmp
#AutoIt3Wrapper_Res_File_Add=sjumper.bmp
#AutoIt3Wrapper_AU3Check_Stop_OnWarning=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; Options
#NoTrayIcon

Opt("WinTitleMatchMode", 3) ; Exact title string match
Opt("TrayMenuMode", 1) ; Default tray menu items (Script Paused/Exit) will not be shown.
Opt("TrayAutoPause", 0) ; Script will not be paused when clicking the tray icon
Opt("GUICloseOnESC", 0)	; ESC does not close GUI
Opt("GUIEventOptions", 1) ; Supress resize events
Opt("GUIResizeMode", 802) ; Supress resize/move
Opt("GUICoordMode", 1) ; Relative to the window top left corner

#include <SendMessage.au3>
#include <Constants.au3>
#include <WindowsConstants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <GDIPlus.au3>
#include <ProgressConstants.au3>
#include <file.au3>

Global Const $SC_DRAGMOVE = 0xF012
Global $guihandle, $counter, $counter1, $result, $mode
Global $inputfilename, $outputfilename, $inputfilehandle, $outfilehandle, $inputfilesize
Global $inputfiledata[65536 + 5]
Global $fadespeed = 5
Global $requiredfilecount = 3
Global $requiredfiles[$requiredfilecount] = ["board.bmp", "sjumper.bmp", "sgc.ico"]
Global $msgboxtimeout = 5


; Run main code
_Main()

Func _Main()
	; Check for previous version in memory
	$guihandle = WinGetHandle("SGC Image Creator")
	If Not @error Then
		MsgBox(4096 + 64, "Information", "The SGC Image Creator Tool is already active..." & @CRLF & "Click OK to close the program.", $msgboxtimeout)
		Exit
	EndIf

	; Drop necessary files
	$counter = 0
	$result = FileInstall("board.bmp", @TempDir & "\" & $requiredfiles[$counter], 1)
	If $result = 0 Then
		MsgBox(4096 + 16, "Error", "Failed to extract necessary resource files..." & @CRLF & "Click OK to close the program.")
		Exit
	EndIf
	$counter = $counter + 1
	$result = FileInstall("sjumper.bmp", @TempDir & "\" & $requiredfiles[$counter], 1)
	If $result = 0 Then
		MsgBox(4096 + 16, "Error", "Failed to extract necessary resource files..." & @CRLF & "Click OK to close the program.")
		Exit
	EndIf
	$counter = $counter + 1
	$result = FileInstall("sgc.ico", @TempDir & "\" & $requiredfiles[$counter], 1)
	If $result = 0 Then
		MsgBox(4096 + 16, "Error", "Failed to extract necessary resource files..." & @CRLF & "Click OK to close the program.")
		Exit
	EndIf

	; Display main dialog
	_GDIPlus_Startup()
	$guihandle = GUICreate("SGC Image Creator", 600, 375, (@DesktopWidth - 600) / 2, (@DesktopHeight - 375) / 2, $WS_POPUP + $WS_BORDER + $WS_THICKFRAME)
	$header = GUICtrlCreatePic(@TempDir & "\" & "board.bmp", 0,0, 600, 375)
	GUICtrlSetState($header ,$GUI_DISABLE)
	$sjumper = GUICtrlCreatePic(@TempDir & "\" & "sjumper.bmp", 515, 35, 25, 15)
	GUICtrlSetState($sjumper ,$GUI_DISABLE)
	GUISetIcon(@TempDir & "\" & "sgc.ico")
	WinSetTrans("SGC Image Creator", "", 0)
	Local $button1 = GUICtrlCreateButton("Change Mode", 71, 327, 150, 25)
	Local $button2 = GUICtrlCreateButton("Open and Convert", 226, 327, 150, 25, $BS_DEFPUSHBUTTON)
	Local $button3 = GUICtrlCreateButton("Exit", 381, 327, 150, 25)

	GUISetState(@SW_SHOWNORMAL, $guihandle)
	ControlFocus($guihandle, "", $button2)
	FadeIn($fadespeed)

	; Mode set
	$mode = 1
	SetMode($mode, $sjumper)

	; Message loop
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_PRIMARYDOWN
				_SendMessage($guihandle, $WM_SYSCOMMAND, $SC_DRAGMOVE, 0)

			Case $GUI_EVENT_CLOSE
				FadeOut($fadespeed)
				Cleanup()
				Exit

			Case $GUI_EVENT_RESTORE
				GUISetState(@SW_RESTORE, $guihandle)

			Case $button3	; Exit
				Local $answer = MsgBox(4096 + 4 + 32, "Exit Confirmation", "Are you sure you want to exit?")
				If $answer = 6 Then
					FadeOut($fadespeed)
					Cleanup()
					Exit
				Else
					ContinueLoop
				EndIf

			Case $button2	; Open and convert file
				$inputfilename = FileOpenDialog ( "Select a ROM file to convert", @ScriptDir & "\", "ROM (*.ROM)", 1 + 2)
				If @error Then
					MsgBox(4096 + 16, "Error", "Error selecting an input file..." & @CRLF & "Please try again.")
				Else
					OpenAndConvert($inputfilename)
				EndIf

			Case $button1	; Change mode
				Switch $mode
					Case 1
						$mode = 2
						SetMode($mode, $sjumper)

					Case 2
						$mode = 3
						SetMode($mode, $sjumper)

					Case 3
						$mode = 4
						SetMode($mode, $sjumper)

					Case 4
						$mode = 1
						SetMode($mode, $sjumper)
				EndSwitch
		EndSwitch

	WEnd

EndFunc

; Cleanup
Func Cleanup()
	; Clean up resources
	_GDIPlus_Shutdown()
	GUIDelete($guihandle)	; close
EndFunc

; Fade in
Func FadeIn($speed)
	If $speed > 5 Then
		$speed = 5
	EndIf
	$speed = $speed * 2 + 2

	; Fade in
	For $counter = 0 to 255 Step $speed
		WinSetTrans("SGC Image Creator", "", $counter)
		Sleep(1)
	Next
EndFunc

; Fade out
Func FadeOut($speed)
	If $speed > 5 Then
		$speed = 5
	EndIf
	$speed = $speed * 2 + 2

	; Fade out
	For $counter = 255 to 0 Step -$speed
		WinSetTrans("SGC Image Creator", "", $counter)
		Sleep(1)
	Next
EndFunc

; Set mode and show appropriate solder jumper
Func SetMode($setmode, $sjumper)

	Switch $setmode
		Case 1
			GUICtrlDelete($sjumper)
			$sjumper = GUICtrlCreatePic(@TempDir & "\" & "sjumper.bmp", 515,35, 25, 15)
			GUICtrlSetState($sjumper ,$GUI_DISABLE)

		Case 2
			GUICtrlDelete($sjumper)
			$sjumper = GUICtrlCreatePic(@TempDir & "\" & "sjumper.bmp", 515,80, 25, 15)
			GUICtrlSetState($sjumper ,$GUI_DISABLE)

		Case 3
			GUICtrlDelete($sjumper)
			$sjumper = GUICtrlCreatePic(@TempDir & "\" & "sjumper.bmp", 515,126, 25, 15)
			GUICtrlSetState($sjumper ,$GUI_DISABLE)

		Case 4
			GUICtrlDelete($sjumper)
			$sjumper = GUICtrlCreatePic(@TempDir & "\" & "sjumper.bmp", 515,172, 25, 15)
			GUICtrlSetState($sjumper ,$GUI_DISABLE)
		EndSwitch
	EndFunc

	; Open file and convert
Func OpenAndConvert($inputfilename)
	$inputfilesize = FileGetSize($inputfilename)
	If @error or $inputfilesize = 0 Then
		MsgBox(4096 + 16, "Error", "Error getting file size or an empty file selected..." & @CRLF & "Please select another file.")
		Return
	Else
		If $inputfilesize = 8192 or $inputfilesize = 16384 or $inputfilesize = 32768 or $inputfilesize = 49152 or $inputfilesize = 65536 Then

			; Check for incompatible mode
			If $mode > 1 and $inputfilesize > 32768 Then
				MsgBox(4096 + 16, "Error", "Files larger than 32768 bytes can be converted only in RD mode..." & @CRLF & "Please select another file or change mode to RD.")
				Return
			EndIf

			; Check for wrong mode/size match
			If $mode > 2 And $inputfilesize > 16384 Then
				MsgBox(4096 + 48, "Error", "Files larger than 16384 bytes can't be converted in CS1/CS2 modes..." & @CRLF & "Please select another file or change mode to RD or CS12.")
				Return
			EndIf

			; Clear buffer
			For $counter = 0 to 65536
				$inputfiledata[$counter] = 0
			Next

			; Open and read file
			$inputfilehandle = FileOpen($inputfilename, 16)
			If $inputfilehandle = -1 Then
				MsgBox(4096 + 16, "Error", "Can't open input file..." & @CRLF & "Please select another file.")
				Return
			EndIf
			For $counter = 0 to $inputfilesize - 1
				$inputfiledata[$counter] = FileRead($inputfilehandle, 1)
				If @error Or @extended <> 1 Then
					MsgBox(4096 + 16, "Error", "Can't read from input file..." & @CRLF & "Please select another file.")
					FileClose($inputfilehandle)
					Return
				EndIf
			Next
			If $counter <> $inputfilesize Then
				MsgBox(4096 + 16, "Error", "Can't read from input file..." & @CRLF & "Please select another file.")
				FileClose($inputfilehandle)
				Return
			EndIf
			FileClose($inputfilehandle)

			; Check for missing AB signature
			If $inputfilesize <= 32768 And (BinaryToString($inputfiledata[0]) <> "A" or BinaryToString($inputfiledata[1]) <> "B") Then
				MsgBox(4096 + 48, "Error", "This file can't be converted because it's missing AB signature..." & @CRLF & "Please select another file.")
				Return
			ElseIf $inputfilesize > 32768 And (BinaryToString($inputfiledata[0]) = "A" And BinaryToString($inputfiledata[1]) = "B") Then
				MsgBox(4096 + 48, "Error", "This file can't be converted because it requires a mapper..." & @CRLF & "Please select another file.")
				Return
			ElseIf $inputfilesize > 32768 And (BinaryToString($inputfiledata[16384]) <> "A" or BinaryToString($inputfiledata[16384 + 1]) <> "B") Then
				MsgBox(4096 + 48, "Error", "This file can't be converted because it is missing AB signature..." & @CRLF & "Please select another file.")
				Return
			EndIf

			; Check for wrong mode/size match
			If $mode = 3 And $inputfilesize <= 32768 And $inputfiledata[3] < 0x80 Then
				MsgBox(4096 + 48, "Error", "This file starts below 0x8000 and can't be used in CS2 mode..." & @CRLF & "Please select another file or change mode to RD or CS1.")
				Return
			ElseIf $mode = 4 And $inputfilesize <= 16384 And $inputfiledata[3] >= 0x80 Then
				MsgBox(4096 + 48, "Error", "This file starts above 0x8000 and can't be used in CS1 mode..." & @CRLF & "Please select another file or change mode to RD or CS2.")
				Return
			ElseIf $mode > 1 And $inputfilesize <= 32768 And $inputfiledata[3] < 0x40 Then
				MsgBox(4096 + 48, "Error", "This file starts below 0x4000 and can't be used in CS1/CS2/CS12 modes..." & @CRLF & "Please select another file or change mode to RD.")
				Return
			EndIf

			; Show info before conversion
			If $inputfilesize <= 32768 Then
				MsgBox(4096 + 64, "Information", "Ready to convert file: " & $inputfilename & @CRLF & @CRLF & "File type:" & @TAB & "ROM image" & @CRLF & "File size:" & @TAB & $inputfilesize & " bytes" & @CRLF & "Starts at: " & @TAB & $inputfiledata[3] & StringMid($inputfiledata[2], 3, 2))
			Else
				MsgBox(4096 + 64, "Information", "Ready to convert file: " & $inputfilename & @CRLF & @CRLF & "File type:" & @TAB & "ROM image" & @CRLF & "File size:" & @TAB & $inputfilesize & " bytes" & @CRLF & "Starts at: " & @TAB & $inputfiledata[16384 + 3] & StringMid($inputfiledata[16384 + 2], 3, 2))
			EndIf

		Else
			MsgBox(4096 + 16, "Error", "Only files with following sizes can be converted: 8192, 16384, 32768, 49152, 65536..." & @CRLF & "Please select another file.")
			Return
		EndIf
	EndIf

	$outputfilename = FileSaveDialog ( "Select or input a BIN file name for output", @ScriptDir & "\", "All (*.*)", 1 + 2)
		If @error or $inputfilename = $outputfilename Then
			MsgBox(4096 + 16, "Error", "Error selecting an output file..." & @CRLF & "Please try again.")
		Else
			If FileExists($outputfilename) Then
				Local $answer = MsgBox(4096 + 4 + 32, "File already exists", "File with this name already exists..." & @CRLF & "Are you sure you want to overwrite it?")
				If $answer = 6 Then
					ConvertROM($inputfilename, $outputfilename)
				EndIf
			Else
				ConvertROM($inputfilename, $outputfilename)
			EndIf
		EndIf
EndFunc

; ROM conversion depending on mode
Func ConvertROM($inputfilename, $outputfilename)

	; Open file for writing
	$outputfilehandle = FileOpen($outputfilename, 2 + 16)
	If $outputfilehandle = -1 Then
		MsgBox(4096 + 16, "Error", "Can't create output file..." & @CRLF & "Please try again.")
		Return
	EndIf

	; Write 8kb file 8 times
	If $inputfilesize = 8192 Then
		For $counter1 = 1 to 8
			For $counter = 0 to $inputfilesize - 1
				$result = FileWrite($outputfilehandle, $inputfiledata[$counter])
				If $result <> 1 Then
					MsgBox(4096 + 16, "Error", "Can't write to output file..." & @CRLF & "Please try again.")
					FileClose($outputfilehandle)
					Return
				EndIf
			Next
		Next

	; Write 16kb file 4 times
	ElseIf $inputfilesize = 16384 Then
		For $counter1 = 1 to 4
			For $counter = 0 to $inputfilesize - 1
				$result = FileWrite($outputfilehandle, $inputfiledata[$counter])
				If $result <> 1 Then
					MsgBox(4096 + 16, "Error", "Can't write to output file..." & @CRLF & "Please try again.")
					FileClose($outputfilehandle)
					Return
				EndIf
			Next
		Next

	; Swap 16kb parts of 32kb file and write 2 times
	ElseIf $inputfilesize = 32768 Then
		For $counter1 = 1 to 2
			For $counter = 0 to ($inputfilesize / 2) - 1
				$result = FileWrite($outputfilehandle, $inputfiledata[$counter + 16384])
				If $result <> 1 Then
					MsgBox(4096 + 16, "Error", "Can't write to output file..." & @CRLF & "Please try again.")
					FileClose($outputfilehandle)
					Return
				EndIf
			Next
			For $counter = 0 to ($inputfilesize / 2) - 1
				$result = FileWrite($outputfilehandle, $inputfiledata[$counter])
				If $result <> 1 Then
					MsgBox(4096 + 16, "Error", "Can't write to output file..." & @CRLF & "Please try again.")
					FileClose($outputfilehandle)
					Return
				EndIf
			Next
		Next

	; Write 49kb file and add 16kb to the end
	ElseIf $inputfilesize = 49152 Then
		For $counter = 0 to $inputfilesize + 4096 - 1
			$result = FileWrite($outputfilehandle, $inputfiledata[$counter])
			If $result <> 1 Then
				MsgBox(4096 + 16, "Error", "Can't write to output file..." & @CRLF & "Please try again.")
				FileClose($outputfilehandle)
				Return
			EndIf
		Next

	; Write 64kb fully
	Else
		For $counter = 0 to $inputfilesize - 1
			$result = FileWrite($outputfilehandle, $inputfiledata[$counter])
			If $result <> 1 Then
				MsgBox(4096 + 16, "Error", "Can't write to output file..." & @CRLF & "Please try again.")
				FileClose($outputfilehandle)
				Return
			EndIf
		Next
	EndIf

	FileClose($outputfilehandle)
	MsgBox(4096 + 64, "Success", "The conversion completed successfully!" & @CRLF & @CRLF & "Input file:" & @CRLF & $inputfilename & @CRLF & @CRLF & "Output file:" & @CRLF & $outputfilename & @CRLF & @CRLF & "Press OK to continue.")
EndFunc
