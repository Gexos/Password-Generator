#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=PasswordGen.exe
#AutoIt3Wrapper_Outfile_x64=PasswordGen_X64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <AutoItConstants.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <EditConstants.au3>
#include <ButtonConstants.au3>
#include <StaticConstants.au3>
#include <Clipboard.au3>

Global $gEngine = @ScriptDir & "\PasswordEngine.exe"

Global $hGUI = GUICreate("Strong Password Generator (Portable)", 700, 460, -1, -1, $WS_CAPTION + $WS_SYSMENU)

; Mode
GUICtrlCreateGroup("Mode", 10, 10, 330, 70)
Global $rbPassword   = GUICtrlCreateRadio("Password (characters)", 20, 35, 160, 20)
Global $rbPassphrase = GUICtrlCreateRadio("Passphrase (words)",    190, 35, 140, 20)
GUICtrlSetState($rbPassword, $GUI_CHECKED)

; Password options
GUICtrlCreateGroup("Password options", 10, 90, 330, 250)
GUICtrlCreateLabel("Length:", 20, 115, 50, 18)
Global $inLen = GUICtrlCreateInput("24", 80, 112, 60, 22, $ES_NUMBER)

Global $cbLower   = GUICtrlCreateCheckbox("Lowercase", 20, 145, 100, 20)
Global $cbUpper   = GUICtrlCreateCheckbox("Uppercase", 130, 145, 100, 20)
Global $cbDigits  = GUICtrlCreateCheckbox("Digits",    240, 145, 70, 20)

Global $cbSymbols = GUICtrlCreateCheckbox("Symbols",   20, 170, 80, 20)
Global $cbEnforce = GUICtrlCreateCheckbox("Enforce 1 of each selected", 110, 170, 200, 20)

GUICtrlSetState($cbLower, $GUI_CHECKED)
GUICtrlSetState($cbUpper, $GUI_CHECKED)
GUICtrlSetState($cbDigits, $GUI_CHECKED)
GUICtrlSetState($cbSymbols, $GUI_CHECKED)
GUICtrlSetState($cbEnforce, $GUI_CHECKED)

GUICtrlCreateLabel("Symbols (custom):", 20, 200, 110, 18)
Global $inSymbols = GUICtrlCreateInput("\/!@#$%^&*()-_=+[]{};:,.?~", 20, 220, 300, 22)

Global $cbNoRepeats = GUICtrlCreateCheckbox("No repeats", 20, 250, 90, 20)
Global $cbWebSafe   = GUICtrlCreateCheckbox("Website-safe mode", 120, 250, 140, 20)

Global $cbAmb = GUICtrlCreateCheckbox("Exclude ambiguous (O/0, l/1, quotes, etc.)", 20, 275, 300, 20)
Global $cbSim = GUICtrlCreateCheckbox("Exclude similar symbols (\ / | ` ' "")", 20, 295, 300, 20)

; Passphrase options
GUICtrlCreateGroup("Passphrase options", 360, 10, 330, 330)
GUICtrlCreateLabel("Words:", 370, 35, 50, 18)
Global $inWords = GUICtrlCreateInput("5", 420, 32, 50, 22, $ES_NUMBER)

GUICtrlCreateLabel("Separator:", 480, 35, 70, 18)
Global $inSep = GUICtrlCreateInput("-", 550, 32, 90, 22)

Global $cbCap = GUICtrlCreateCheckbox("Random Capitalization", 370, 65, 200, 20)
Global $cbAppendSym = GUICtrlCreateCheckbox("Append 1 symbol", 370, 90, 140, 20)

Global $cbAppendDig = GUICtrlCreateCheckbox("Append digits:", 370, 115, 110, 20)
Global $inAppendDig = GUICtrlCreateInput("2", 480, 112, 40, 22, $ES_NUMBER)

GUICtrlCreateLabel("Wordlist file:", 370, 150, 120, 18)
Global $inWordlist = GUICtrlCreateInput(@ScriptDir & "\wordlist.txt", 370, 170, 310, 22)
GUICtrlCreateLabel("(Tip: big wordlist = stronger passphrases)", 370, 195, 300, 18)

; Output
GUICtrlCreateGroup("Output", 10, 350, 680, 100)
Global $outValue = GUICtrlCreateInput("", 20, 375, 520, 24, $ES_READONLY)
Global $lblInfo  = GUICtrlCreateLabel("Ready.", 20, 407, 520, 18)

Global $btnGen  = GUICtrlCreateButton("Generate", 555, 375, 120, 28)
Global $btnCopy = GUICtrlCreateButton("Copy",     555, 409, 120, 28)

GUISetState(@SW_SHOW, $hGUI)

While 1
    Switch GUIGetMsg()
        Case $GUI_EVENT_CLOSE
            Exit
        Case $btnGen
            _Generate()
        Case $btnCopy
            Local $v = GUICtrlRead($outValue)
            If $v <> "" Then
                _ClipBoard_SetData($v)
                GUICtrlSetData($lblInfo, "Copied to clipboard.")
            EndIf
    EndSwitch
WEnd

Func _Generate()
    If Not FileExists($gEngine) Then
        GUICtrlSetData($outValue, "")
        GUICtrlSetData($lblInfo, "ERROR: PasswordEngine.exe not found next to this app.")
        Return
    EndIf

    GUICtrlSetData($lblInfo, "Generating...")
    Sleep(10)

    Local $mode = "password"
    If BitAND(GUICtrlRead($rbPassphrase), $GUI_CHECKED) Then $mode = "passphrase"

    Local $symbols = GUICtrlRead($inSymbols)
    Local $outFile = @TempDir & "\pwgen_" & Hex(Random(0, 0x7FFFFFFF, 1), 8) & ".json"

    Local $cmd = '"' & $gEngine & '" --json --mode ' & $mode & ' --out-file "' & _EscapeArg($outFile) & '"'

    If $mode = "password" Then
        Local $len = Int(GUICtrlRead($inLen))
        If $len < 4 Then $len = 4
        If $len > 256 Then $len = 256
        $cmd &= " --length " & $len

        If BitAND(GUICtrlRead($cbLower), $GUI_CHECKED) Then $cmd &= " --lower"
        If BitAND(GUICtrlRead($cbUpper), $GUI_CHECKED) Then $cmd &= " --upper"
        If BitAND(GUICtrlRead($cbDigits), $GUI_CHECKED) Then $cmd &= " --digits"

        If BitAND(GUICtrlRead($cbSymbols), $GUI_CHECKED) Then
            $cmd &= " --allow-symbols"
            $cmd &= ' --symbols "' & _EscapeArg($symbols) & '"'
        EndIf

        If BitAND(GUICtrlRead($cbEnforce), $GUI_CHECKED) Then $cmd &= " --enforce-each"
        If BitAND(GUICtrlRead($cbNoRepeats), $GUI_CHECKED) Then $cmd &= " --no-repeats"
        If BitAND(GUICtrlRead($cbWebSafe), $GUI_CHECKED) Then $cmd &= " --website-safe"
        If BitAND(GUICtrlRead($cbAmb), $GUI_CHECKED) Then $cmd &= " --exclude-ambiguous"
        If BitAND(GUICtrlRead($cbSim), $GUI_CHECKED) Then $cmd &= " --exclude-similar-symbols"
    Else
        Local $words = Int(GUICtrlRead($inWords))
        If $words < 2 Then $words = 2
        If $words > 20 Then $words = 20

        Local $sep = GUICtrlRead($inSep)
        Local $wl = GUICtrlRead($inWordlist)

        $cmd &= " --words " & $words
        $cmd &= ' --separator "' & _EscapeArg($sep) & '"'
        $cmd &= ' --wordlist "' & _EscapeArg($wl) & '"'

        If BitAND(GUICtrlRead($cbCap), $GUI_CHECKED) Then $cmd &= " --capitalize"
        If BitAND(GUICtrlRead($cbAppendSym), $GUI_CHECKED) Then $cmd &= ' --symbols "' & _EscapeArg($symbols) & '" --append-symbol'
        If BitAND(GUICtrlRead($cbAppendDig), $GUI_CHECKED) Then
            Local $d = Int(GUICtrlRead($inAppendDig))
            If $d < 1 Then $d = 1
            If $d > 10 Then $d = 10
            $cmd &= " --append-digits " & $d
        EndIf

        If BitAND(GUICtrlRead($cbWebSafe), $GUI_CHECKED) Then $cmd &= " --website-safe"
        If BitAND(GUICtrlRead($cbAmb), $GUI_CHECKED) Then $cmd &= " --exclude-ambiguous"
        If BitAND(GUICtrlRead($cbSim), $GUI_CHECKED) Then $cmd &= " --exclude-similar-symbols"
    EndIf

    Local $exitCode = RunWait($cmd, @ScriptDir, @SW_HIDE)

    If Not FileExists($outFile) Then
        GUICtrlSetData($outValue, "")
        GUICtrlSetData($lblInfo, "ERROR: Engine produced no output (exit=" & $exitCode & ").")
        Return
    EndIf

    Local $json = FileRead($outFile)
    FileDelete($outFile)

    If $json = "" Then
        GUICtrlSetData($outValue, "")
        GUICtrlSetData($lblInfo, "ERROR: Output was empty.")
        Return
    EndIf

    Local $err = _JsonGet($json, "error")
    If $err <> "" Then
        GUICtrlSetData($outValue, "")
        GUICtrlSetData($lblInfo, "ERROR: " & $err)
        Return
    EndIf

    Local $val = _JsonGet($json, "value")
    Local $entropy = _JsonGet($json, "entropy_bits")

    ; minimal JSON unescape
    $val = StringReplace($val, "\\/", "/")
    $val = StringReplace($val, "\\\\", "\")

    GUICtrlSetData($outValue, $val)
    GUICtrlSetData($lblInfo, "Entropy (rough): " & $entropy & " bits")
EndFunc

Func _EscapeArg($s)
    Return StringReplace($s, '"', '\"')
EndFunc

Func _JsonGet($json, $key)
    Local $re1 = '"' & $key & '"\s*:\s*"([^"]*)"'
    Local $re2 = '"' & $key & '"\s*:\s*([0-9]+(\.[0-9]+)?)'
    Local $m = StringRegExp($json, $re1, 1)
    If IsArray($m) Then Return $m[0]
    $m = StringRegExp($json, $re2, 1)
    If IsArray($m) Then Return $m[0]
    Return ""
EndFunc
