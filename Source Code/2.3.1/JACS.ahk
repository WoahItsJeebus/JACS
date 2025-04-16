#Requires AutoHotkey >=2.0.19 64-bit
#SingleInstance Force

CoordMode("Mouse", "Screen")
CoordMode("Menu", "Screen")
SetTitleMatchMode 2
DetectHiddenWindows(true)
A_HotkeyInterval := 0
A_MaxHotkeysPerInterval := 1000
A_LocalAppData := EnvGet("LOCALAPPDATA")
localScriptDir := A_LocalAppData "\JACS\"
downloadedIcon := localScriptDir "images\Icon.ico"

global initializing := true
global version := "2.3.1"

global SettingsExists := RegRead("HKCU\Software\JACS", "Exists", false)
global oldSettingsRemoved := RegRead("HKCU\Software\JACS", "OldSettingsRemoved", false)

checkForOldData()
setTrayIcon()
createDefaultSettingsData()

global URL_SCRIPT := "https://github.com/WoahItsJeebus/JACS/releases/latest/download/JACS.ahk"
global MinutesToWait := RegRead("HKCU\Software\JACS", "Cooldown", 15)
global SecondsToWait := SecondsToWait := RegRead("HKCU\Software\JACS", "SecondsToWait", MinutesToWait*60)
global minCooldown := 0
global lastUpdateTime := A_TickCount
global CurrentElapsedTime := 0
global playSounds := RegRead("HKCU\Software\JACS", "SoundMode", 1)
global isInStartFolder := RegRead("HKCU\Software\JACS", "isInStartFolder", false)

global isActive := RegRead("HKCU\Software\JACS", "isActive", 1)
global autoUpdateDontAsk := false
global FirstRun := True

; MainUI Data
global MainUI := ""
global ExtrasUI := ""
global MainUI_PosX := RegReadSigned("HKCU\Software\JACS", "MainUI_PosX", A_ScreenWidth / 2)
global MainUI_PosY := RegReadSigned("HKCU\Software\JACS", "MainUI_PosY", A_ScreenHeight / 2)
global isUIHidden := RegRead("HKCU\Software\JACS", "isUIHidden", false)
global MainUI_Disabled := false

global UI_Width := "500"
global UI_Height := "300"
global Min_UI_Width := "500"
global Min_UI_Height := "300"

; Core UI Buttons
global EditButton := ""
global ExitButton := ""
global OpenMouseSettingsButton := ""
global WindowSettingsButton := ""
global ScriptSettingsButton := ""
global CoreToggleButton := ""
global SoundToggleButton := ""
global ReloadButton := ""
global Core_Status_Bar := ""
global Sound_Status_Bar := ""
global WaitProgress := ""
global WaitTimerLabel := ""
global NextCheckTime := ""
global ElapsedTimeLabel := ""
global GitHubLink := ""
global CreditsLink := ""
global EditCooldownButton := ""
global ResetCooldownButton := ""
global MainUI_Warning := ""
global EditorButton := ""
global ScriptDirButton := ""
global AddToBootupFolderButton := ""
global AlwaysOnTopButton := ""
global AlwaysOnTopActive := RegRead("HKCU\Software\JACS", "AlwaysOnTop", false)

; Extra Menus
global PatchUI := ""
global WindowSettingsUI := ""
global ScriptSettingsUI := ""
global SettingsUI := ""
global MouseSpeed := RegRead("HKCU\Software\JACS", "MouseSpeed", 0)
global MouseClickRateOffset := RegRead("HKCU\Software\JACS", "ClickRateOffset", 0)
global MouseClickRadius := RegRead("HKCU\Software\JACS", "ClickRadius", 0)
global doMouseLock := RegRead("HKCU\Software\JACS", "doMouseLock", false)
global MouseClicks := RegRead("HKCU\Software\JACS", "MouseClicks", 5)
global SelectedProcessExe := RegRead("HKCU\Software\JACS", "SelectedProcessExe", "RobloxPlayerBeta.exe")

; Extras Menu
global ShowingExtrasUI := false 
global warningRequested := false

; Light/Dark mode colors
global updateTheme := true

global blnLightMode := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
global intWindowColor := (!blnLightMode and updateTheme) and "404040" or "EEEEEE"
global intControlColor := (!blnLightMode and updateTheme) and "606060" or "FFFFFF"
global intProgressBarColor := (!blnLightMode and updateTheme) and "757575" or "dddddd"
global ControlTextColor := (!blnLightMode and updateTheme) and "FFFFFF" or "000000"
global linkColor := (!blnLightMode and updateTheme) and "99c3ff" or "4787e7"
global currentTheme := blnLightMode
global lastTheme := currentTheme

global wasActiveWindow := false

global ControlResize := (Target, position, size) => ResizeMethod(Target, position, size)
global MoveControl := (Target, position, size) => MoveMethod(Target, position, size)
global AcceptedWarning := RegRead("HKCU\Software\JACS", "AcceptedWarning", false) and CreateGui() or createWarningUI()
global tempUpdateFile := ""

; ================= Screen Info =================== ;
global refreshRate := GetRefreshRate_Alt() or 60

global Credits_CurrentColor := GetRandomColor(200, 255)
global Credits_TargetColor := GetRandomColor(200, 255)
global Credits_ColorChangeRate := 5 ; (higher = faster)

OnExit(ClampMainUIPos)

OnMessage(0x0112, WM_SYSCOMMAND_Handler)
DeleteTrayTabs()

A_TrayMenu.Insert("&Reload Script", "Fix GUI", MenuHandler)  ; Creates a new menu item.
Persistent

GetUpdate()

MenuHandler(ItemName, ItemPos, MyMenu) {
	global MainUI_PosX
	global MainUI_PosY
	global isUIHidden

	local VDisplay_Width := SysGet(78) ; SM_CXVIRTUALSCREEN
	local VDisplay_Height := SysGet(79) ; SM_CYVIRTUALSCREEN

	RegWrite(VDisplay_Width / 2, "REG_DWORD", "HKCU\Software\JACS", "MainUI_PosX")
	RegWrite(VDisplay_Height / 2, "REG_DWORD", "HKCU\Software\JACS", "MainUI_PosY")

	MainUI_PosX := RegReadSigned("HKCU\Software\JACS", "MainUI_PosX", VDisplay_Width / 2)
	MainUI_PosY := RegReadSigned("HKCU\Software\JACS", "MainUI_PosY", VDisplay_Height / 2)

	if isUIHidden
		ToggleHideUI(!isUIHidden)
	
    CreateGui()
}

IsVersionNewer(localVersion, onlineVersion) {
	localParts := StrSplit(localVersion, ".")
	onlineParts := StrSplit(onlineVersion, ".")
	
	; Compare each version segment numerically
	Loop localParts.Length {
		localPart := localParts[A_Index]
		onlinePart := onlineParts[A_Index]
		
		; Treat missing parts as 0 (e.g., "1.2" vs "1.2.1")
		localPart := localPart != "" ? localPart : 0
		onlinePart := onlinePart != "" ? onlinePart : 0

		if (onlinePart > localPart)
			return "Outdated"
		else if (onlinePart < localPart)
			return "Other"
	}
	return "Updated" ; Versions are equal
}

GetLatestReleaseVersion() {
    local URL_API := "https://api.github.com/repos/WoahItsJeebus/JACS/releases/latest"
    local tempJSONFile := A_Temp "\latest_release.json"
    
    try {
        DownloadURL(URL_API, tempJSONFile)  ; Download the JSON response
    } catch {
        return ""
    }
    
    local jsonText := FileRead(tempJSONFile)
    FileDelete(tempJSONFile)  ; Clean up the temporary file
    
    local releaseInfo := JSON_parse(jsonText)
    
    if (!releaseInfo or !IsObject(releaseInfo)) {
        return ""
    }
    
    ; Use a try/catch to safely attempt to access tag_name
    try {
        local latestTag := releaseInfo.tag_name
    } catch {
        latestTag := ""
    }
    
    if (latestTag = "" or !latestTag) {
        return ""
    }
    
    return latestTag
}

GetUpdate(*) {
    global autoUpdateDontAsk
    global version
    
    local latestVersion := GetLatestReleaseVersion()
    if (latestVersion = "")
        return ""
    
    if IsVersionNewer(version, latestVersion) == "Outdated" {
        if !autoUpdateDontAsk {
            autoUpdateDontAsk := true
            SetTimer(AutoUpdate, 0)
            SendNotification("Click here to install", "JACS Update Available")
        }
    } else {
        ; Optionally notify that the script is up-to-date
        ; SendNotification("Script is up-to-date!", "Update Check")
    }

	RollThankYou()
}

UpdateScript(targetFile := tempUpdateFile) {
	FileMove(targetFile, A_ScriptFullPath, 1) ; Overwrite current script
	Reload
}

; ================================================= ;

createWarningUI(requested := false) {
	global ExtrasUI
	if ExtrasUI {
		ExtrasUI.Destroy()
		ExtrasUI := ""
	}

	local accepted := RegRead("HKCU\Software\JACS", "AcceptedWarning", false)
	if accepted and not requested {
		if MainUI_Warning
			MainUI_Warning.Destroy()
			MainUI_Warning := ""
		if not MainUI
			return CreateGui()
		return
	}

	; Global Variables
	global blnLightMode := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")

	global AlwaysOnTopActive
	local AOTStatus := AlwaysOnTopActive == true and "+AlwaysOnTop" or "-AlwaysOnTop"
	local AOT_Text := (AlwaysOnTopActive == true and "On") or "Off"

	global ExtrasUI
	global MainUI_Warning := Gui(AOTStatus)

	MainUI_Warning.BackColor := intWindowColor

	; Local Variables
	local UI_Width_Warning := "1200"
	local UI_Height_Warning := "100"

	; Colors
	global blnLightMode := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
	global intWindowColor := (!blnLightMode and updateTheme) and "404040" or "EEEEEE"
	global intControlColor := (!blnLightMode and updateTheme) and "606060" or "FFFFFF"
	global intProgressBarColor := (!blnLightMode and updateTheme) and "757575" or "dddddd"
	global ControlTextColor := (!blnLightMode and updateTheme) and "FFFFFF" or "000000"
	global linkColor := (!blnLightMode and updateTheme) and "99c3ff" or "4787e7"

	; Controls
	local warning_Text_Header := MainUI_Warning.Add("Text","h30 w" UI_Width_Warning/2-MainUI_Warning.MarginX*2, "WARNING")
	warning_Text_Header.SetFont("s24 w1000", "Consolas")
	warning_Text_Header.Opt("Center cff4840")
	
    ; ##############################################
    ; Body 1
	local warning_Text_Body1 := MainUI_Warning.Add("Link", "h80 w315", 'This script is provided by')
	warning_Text_Body1.SetFont("s12 w300", "Arial")
	warning_Text_Body1.Opt("c" ControlTextColor)
	
	local JEEBUS_LINK1 := MainUI_Warning.Add("Link", "x+-140 h20 w125 c" linkColor, '<a href="https://www.roblox.com/users/3817884/profile">@WoahItsJeebus</a>')
	JEEBUS_LINK1.SetFont("s12 w300", "Arial")
	LinkUseDefaultColor(JEEBUS_LINK1)

	local warning_Text_Body1_5 := MainUI_Warning.Add("Link", "x+0 h20 w300", 'and is intended solely for the purpose of')
	warning_Text_Body1_5.SetFont("s12 w300", "Arial")
	warning_Text_Body1_5.Opt("c" ControlTextColor)

    ; ###############################################
    ; Body 2
	local warning_Text_Body2 := MainUI_Warning.Add("Link", "y+0 x" MainUI_Warning.MarginX . " h80 w" UI_Width_Warning/2-MainUI_Warning.MarginX*2, 'maintaining an active gaming session while the user can do other tasks simultaneously. This is achieved by periodically activating the first found process matching a specific name and clicking the center of the window.')
	warning_Text_Body2.SetFont("s12 w300", "Arial")
	warning_Text_Body2.Opt("c" ControlTextColor)

	local warning_Text_Body3 := MainUI_Warning.Add("Text", "h60 w" UI_Width_Warning/2-MainUI_Warning.MarginX*2, 'While some games do not typically take action on the use of autoclickers, the rules of some games may prohibit the use of such tools. Use of this script is at your own risk.')
	warning_Text_Body3.SetFont("s12 w500", "Arial")
	warning_Text_Body3.Opt("c" ControlTextColor)

	local SeparationLine := MainUI_Warning.Add("Text", "0x7 h1 w" UI_Width_Warning/2) ; Separation Space
	SeparationLine.BackColor := "0x8"
	
	local important_Text_Body_Part1 := MainUI_Warning.Add("Text", "h20 w" UI_Width_Warning/2-MainUI_Warning.MarginX*2, '- [Roblox Users] Modifying this script in such a way that does not abide by the Roblox')
	important_Text_Body_Part1.SetFont("s12 w600", "Arial")
	important_Text_Body_Part1.Opt("c" ControlTextColor)

	local TOS_Link := MainUI_Warning.Add("Link", "y+-1 h20 w295 c" linkColor, '<a href="https://en.help.roblox.com/hc/en-us/articles/115004647846-Roblox-Terms-of-Use">Terms of Service</a>')
	TOS_Link.SetFont("s12 w600", "Arial")
	LinkUseDefaultColor(TOS_Link)

	local important_Text_Body_Part2 := MainUI_Warning.Add("Text", "x+-160 h20 w" UI_Width_Warning/2.75-MainUI_Warning.MarginX, 'can lead to actions taken by the Roblox Corporation')
	important_Text_Body_Part2.SetFont("s12 w600", "Arial")
	important_Text_Body_Part2.Opt("c" ControlTextColor)
	
	local important_Text_Body_Part2_5 := MainUI_Warning.Add("Text", "y+-1 x" MainUI_Warning.MarginX . " h20 w" UI_Width_Warning/2-MainUI_Warning.MarginX, 'including but not limited to account suspension or banning.')
	important_Text_Body_Part2_5.SetFont("s12 w600", "Arial")
	important_Text_Body_Part2_5.Opt("c" ControlTextColor)
	
	local JEEBUS_LINK2 := MainUI_Warning.Add("Link", "h20 w295 c" linkColor, '<a href="https://www.roblox.com/users/3817884/profile">@WoahItsJeebus</a>')
	JEEBUS_LINK2.SetFont("s12 w600", "Arial")
	LinkUseDefaultColor(JEEBUS_LINK2)
	
	local important_Text_Body_Part3 := MainUI_Warning.Add("Text", "x+-155 h20 w" UI_Width_Warning/2.75-MainUI_Warning.MarginX, "is not responsible for any misuse of this script or any")
	important_Text_Body_Part3.SetFont("s12 w600", "Arial")
	important_Text_Body_Part3.Opt("c" ControlTextColor)

	local important_Text_Body_Part3_5 := MainUI_Warning.Add("Text", "y+-1 x" MainUI_Warning.MarginX . " h20 w" UI_Width_Warning/2-MainUI_Warning.MarginX, 'consequences arising from such misuse.')
	important_Text_Body_Part3_5.SetFont("s12 w600", "Arial")
	important_Text_Body_Part3_5.Opt("c" ControlTextColor)

	local important_Text_Body2 := MainUI_Warning.Add("Text", "h40 w" UI_Width_Warning/2-MainUI_Warning.MarginX*2, '`nBy proceeding, you acknowledge and agree to the above.')
	important_Text_Body2.SetFont("s12 w600", "Arial")
	important_Text_Body2.Opt("Center c" ControlTextColor)
	
	local ok_Button_Warning := MainUI_Warning.Add("Button", "h40 w" UI_Width_Warning/8-MainUI_Warning.MarginX, "I AGREE")
	ok_Button_Warning.Move(UI_Width_Warning/8)
	ok_Button_Warning.SetFont("s14 w600", "Consolas")
	ok_Button_Warning.Opt("c" ControlTextColor . " Background" intWindowColor)
	
	local no_Button_Warning := MainUI_Warning.Add("Button", "x+m h40 w" UI_Width_Warning/8-MainUI_Warning.MarginX, "DECLINE")
	no_Button_Warning.Move(UI_Width_Warning/4)
	no_Button_Warning.SetFont("s14 w600", "Consolas")
	no_Button_Warning.Opt("c" ControlTextColor . " Background" intWindowColor)
	
	ok_Button_Warning.OnEvent("Click", clickOK)
	no_Button_Warning.OnEvent("Click", clickNo)
	
	MainUI_Warning.OnEvent("Close", (*) => (
		MainUI_Warning := ""
	))

	MainUI_Warning.Title := "Jeebus' Auto-Clicker - Warning"
	
	CloseWarning(clickedYes){
		try MainUI_Warning.Destroy()
		MainUI_Warning := ""

		if ExtrasUI
			ExtrasUI.Opt("-Disabled")

		if not accepted and clickedYes {
			RegWrite(true, "REG_DWORD", "HKCU\Software\JACS", "AcceptedWarning")
			accepted := RegRead("HKCU\Software\JACS", "AcceptedWarning", false)
		}
		
		if not MainUI and accepted and clickedYes {
			return CreateGui()
		}
		else if !clickedYes
			return CloseApp()
	}
	
	clickOK(uiObj*){
		CloseWarning(true)
	}

	clickNO(uiObj*){
		CloseWarning(false)
	}

	; Show UI
	MainUI_Warning.Show("AutoSize Center h500")
}

CreateGui(*) {
	global version
	global UI_Width := "500"
	global UI_Height := "300"
	global Min_UI_Width := "500"
	global Min_UI_Height := "300"
	
	global MainUI_PosX
	global MainUI_PosY

	global playSounds
	global isActive
	global isUIHidden

	global MainUI
	global MainUI_Warning
	global CoreToggleButton
	global SoundToggleButton
	global EditCooldownButton
	global AlwaysOnTopButton
	global AlwaysOnTopActive
	global AddToBootupFolderButton
	global ScriptSettingsButton
	global WindowSettingsButton
	global OpenMouseSettingsButton

	global MainUI_PosX
	global MainUI_PosY

	global WaitProgress
	global WaitTimerLabel
	global ElapsedTimeLabel
	global MinutesToWait
	global ResetCooldownButton

	global CreditsLink
	global OpenExtrasLabel

	global MoveControl
	global ControlResize

	global initializing
	global refreshRate

	; Colors
	global blnLightMode := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
	global intWindowColor := (!blnLightMode and updateTheme) and "404040" or "EEEEEE"
	global intControlColor := (!blnLightMode and updateTheme) and "606060" or "FFFFFF"
	global intProgressBarColor := (!blnLightMode and updateTheme) and "757575" or "dddddd"
	global ControlTextColor := (!blnLightMode and updateTheme) and "FFFFFF" or "000000"
	global linkColor := (!blnLightMode and updateTheme) and "99c3ff" or "4787e7"

	global IntValue := Integer(0)
	
	local AOTStatus := AlwaysOnTopActive == true and "+AlwaysOnTop" or "-AlwaysOnTop"
	local AOT_Text := (AlwaysOnTopActive == true and "On") or "Off"

	; Destroy old UI object
	if MainUI {
		MainUI.Destroy()
		MainUI := ""
	}
	
	if MainUI_Warning
		MainUI_Warning.Destroy()

	; Create new UI
	global MainUI := Gui(AOTStatus . " +OwnDialogs") ; Create UI window
	MainUI.BackColor := intWindowColor
	MainUI.OnEvent("Close", CloseApp)
	MainUI.Title := "Jeebus' Auto-Clicker"
	MainUI.SetFont("s14 w500", "Courier New")
	
	local UI_Margin_Width := UI_Width-MainUI.MarginX
	local UI_Margin_Height := UI_Height-MainUI.MarginY
	
	local Header := MainUI.Add("Text", "Section Center cff4840 h100 w" UI_Margin_Width,"`nJeebus' Auto-Clicker — V" version)
	Header.SetFont("s22 w600", "Ink Free")
	
	; ########################
	; 		  Buttons
	; ########################
	; local activeText_Core := isActive and "Enabled" or "Disabled"
	global activeText_Core := (isActive == 3 and "Enabled") or (isActive == 2 and "Waiting...") or "Disabled"
	CoreToggleButton := MainUI.Add("Button", "xs h40 w" UI_Margin_Width/2, "Auto-Clicker: " activeText_Core)
	CoreToggleButton.OnEvent("Click", ToggleCore)
	CoreToggleButton.Opt("Background" intWindowColor)
	CoreToggleButton.Move((UI_Width-(UI_Margin_Width / 1.333)))
	CoreToggleButton.SetFont("s12 w500", "Consolas")

	; ##############################
	
	; Calculate initial control width based on GUI width and margins
	InitialWidth := UI_Width - (2 * UI_Margin_Width)
	;X := 0, Y := 0, UI_Width := 0, UI_Height := 0
	
	; Get the client area dimensions
	NewButtonWidth := (UI_Width - (2 * UI_Margin_Width)) / 3
	
	local pixelSpacing := 5

	; ###############################
	
	SeparationLine := MainUI.Add("Text", "xs 0x7 h1 w" UI_Margin_Width) ; Separation Space
	SeparationLine.BackColor := "0x8"
	
	; Progress Bar
	WaitTimerLabel := MainUI.Add("Text", "xs Section Center 0x300 0xC00 h28 w" UI_Margin_Width, "0%")
	WaitProgress := MainUI.Add("Progress", "xs Section Center h50 w" UI_Margin_Width)
	ElapsedTimeLabel := MainUI.Add("Text", "xs Section Center 0x300 0xC00 h28 w" UI_Margin_Width, "00:00 / 0 min")
	ElapsedTimeLabel.SetFont("s18 w500", "Consolas")
	WaitTimerLabel.SetFont("s18 w500", "Consolas")
	
	WaitTimerLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	ElapsedTimeLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	WaitProgress.Opt("Background" intProgressBarColor)

	; Reset Cooldown
	ResetCooldownButton := MainUI.Add("Button", "xm+182 h30 w" UI_Margin_Width/4, "Reset")
	ResetCooldownButton.OnEvent("Click", ResetCooldown)
	ResetCooldownButton.SetFont("s12 w500", "Consolas")
	ResetCooldownButton.Opt("Background" intWindowColor)

	; Window Settings
	WindowSettingsButton := MainUI.Add("Button", "xs h30 w" UI_Margin_Width/3, "Window Settings")
	WindowSettingsButton.OnEvent("Click", CreateWindowSettingsGUI)
	WindowSettingsButton.SetFont("s12 w500", "Consolas")
	WindowSettingsButton.Opt("Background" intWindowColor)
	
	; Mouse Settings
	OpenMouseSettingsButton := MainUI.Add("Button", "x+1 h30 w" UI_Margin_Width/3, "Clicker Settings")
	OpenMouseSettingsButton.OnEvent("Click", CreateClickerSettingsGUI)
	OpenMouseSettingsButton.SetFont("s12 w500", "Consolas")
	OpenMouseSettingsButton.Opt("Background" intWindowColor)
	
	; Script Settings
	ScriptSettingsButton := MainUI.Add("Button", "x+1 h30 w" UI_Margin_Width/3, "Script Settings")
	ScriptSettingsButton.OnEvent("Click", CreateScriptSettingsGUI)
	ScriptSettingsButton.SetFont("s12 w500", "Consolas")
	ScriptSettingsButton.Opt("Background" intWindowColor)
	
	; Credits
	CreditsLink := MainUI.Add("Link", "xm c" linkColor . " Section Left h20 w" UI_Margin_Width/2, 'Created by <a href="https://www.roblox.com/users/3817884/profile">@WoahItsJeebus</a>')
	CreditsLink.SetFont("s12 w700", "Ink Free")
	CreditsLink.Opt("c" linkColor)
	LinkUseDefaultColor(CreditsLink)

	; Version
	OpenExtrasLabel := MainUI.Add("Button", "x+120 Section Center 0x300 0xC00 h30 w" UI_Margin_Width/4, "Extras")
	OpenExtrasLabel.SetFont("s12 w500", "Consolas")
	OpenExtrasLabel.Opt("Background" intWindowColor)
	OpenExtrasLabel.OnEvent("Click", CreateExtrasGUI)

	; LinkUseDefaultColor(VersionHyperlink)
	
	; Update ElapsedTimeLabel with the formatted time and total wait time in minutes
    UpdateTimerLabel()

	; ###################################################################### ;
	; #################### UI Formatting and Visibility #################### ;
	; ###################################################################### ;
	
	; ToggleHideUI(false)
	updateUIVisibility()
	ClampMainUIPos()
	SaveMainUIPosition()

	; ####################################
	
	; CreateExtrasGUI()

	; Indicate UI was fully created
	if playSounds == 1
		Loop 2
			SoundBeep(300, 200)
	
	if isActive > 1
		ToggleCore(,isActive)

	local loopFunctions := Map(
		"CheckDeviceTheme", Map(
			"Function", CheckDeviceTheme.Bind(),
			"Interval", 50,
			"Disabled", false
		),
		"SaveMainUIPosition", Map(
			"Function", SaveMainUIPosition.Bind(),
			"Interval", 1000,
			"Disabled", false
		),
		"CheckOpenMenus", Map(
			"Function", CheckOpenMenus.Bind(),
			"Interval", 50,
			"Disabled", false
		),
		"ClampMainUIPosition", Map(
			"Function", ClampMainUIPos.Bind(),
			"Interval", 50,
			"Disabled", true
		),
		"ColorizeCredits", Map(
			"Function", ColorizeCredits.Bind(CreditsLink),
			"Interval", 50,
			"Disabled", true
		)
	)
	Sleep(500)

	; Run loop functions
	for FuncName, Data in loopFunctions
		if not Data["Disabled"]
        	SetTimer(Data["Function"], Data["Interval"])

	refreshRate := GetRefreshRate_Alt()
	; debugNotif(refreshRate = 0 ? "Failed to retrieve refresh rate" : "Refresh Rate: " refreshRate " Hz",,,5)

	initializing := false
}

ClampMainUIPos(*) {
	global MainUI
	global isUIHidden
	global MainUI_PosX
	global MainUI_PosY
	
	local VDisplay_Width := SysGet(78) ; SM_CXVIRTUALSCREEN
	local VDisplay_Height := SysGet(79) ; SM_CYVIRTUALSCREEN
	
	WinGetPos(,, &W, &H, MainUI.Title)
	local X := MainUI_PosX + (W / 2)
	local Y := MainUI_PosY + (H / 2)
	local winState := WinGetMinMax(MainUI.Title) ; -1 = Minimized | 0 = "Neither" (I assume floating) | 1 = Maximized
	if winState == -1
		return

	if X > VDisplay_Width or X < -VDisplay_Width {
		RegWrite(VDisplay_Width / 2, "REG_DWORD", "HKCU\Software\JACS", "MainUI_PosX")
		MainUI_PosX := RegReadSigned("HKCU\Software\JACS", "MainUI_PosX", VDisplay_Width / 2)
		
		if MainUI and not isUIHidden and winState != -1
			MainUI.Show("X" . MainUI_PosX . " Y" . MainUI_PosY . " AutoSize")
	}

	if Y > VDisplay_Height or Y < (-VDisplay_Height*2) {
		RegWrite(VDisplay_Height / 2, "REG_DWORD", "HKCU\Software\JACS", "MainUI_PosY")
		MainUI_PosY := RegReadSigned("HKCU\Software\JACS", "MainUI_PosY", VDisplay_Height / 2)

		if MainUI and winState != -1
			MainUI.Show("X" . MainUI_PosX . " Y" . MainUI_PosY . " AutoSize")
	}
}

CheckOpenMenus(*) {
	global MainUI
	global ExtrasUI
	global SettingsUI
	global ScriptSettingsUI
	global WindowSettingsUI
	global MainUI_Disabled
	global MainUI_Warning
	
	if (MainUI and not ExtrasUI and not SettingsUI and not ScriptSettingsUI and not WindowSettingsUI and not MainUI_Warning) {
		if MainUI_Disabled {
			try MainUI.Opt("-Disabled")
			MainUI_Disabled := false
		}
		
		return
	}
	else if not MainUI_Disabled {
		MainUI.Opt("+Disabled")
		MainUI_Disabled := true
	}
}

CreateWindowSettingsGUI(*) {
	; UI Settings
	local PixelOffset := 10
	local Popout_Width := 400
	local Popout_Height := 600
	local labelOffset := 50
	local sliderOffset := 2.5

	; Global Save Data
	global WindowSettingsUI
	global playSounds
	global AlwaysOnTopActive
	global SelectedProcessExe

	; Global Controls
	global SoundToggleButton
	global AlwaysOnTopButton
	global MainUI
	global MainUI_PosX
	global MainUI_PosY

	; Local Controls
	local AOTStatus := AlwaysOnTopActive == true and "+AlwaysOnTop" or "-AlwaysOnTop"
	local AOT_Text := (AlwaysOnTopActive == true and "On") or "Off"
	local ProcessDropdown := ""

	; Colors
	global blnLightMode := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
	global intWindowColor := (!blnLightMode and updateTheme) and "404040" or "EEEEEE"
	global intControlColor := (!blnLightMode and updateTheme) and "606060" or "FFFFFF"
	global ControlTextColor := (!blnLightMode and updateTheme) and "FFFFFF" or "000000"

	CloseSettingsUI(*)
	{
		if WindowSettingsUI {
			WindowSettingsUI.Destroy()
			WindowSettingsUI := ""
		}

		SetTimer(mouseHoverDescription,0)
	}

	; If settingsUI is open, close it
	if WindowSettingsUI
		return CloseSettingsUI()

	; Create GUI Window
	WindowSettingsUI := Gui(AOTStatus)
	WindowSettingsUI.Opt("+Owner" . MainUI.Hwnd)
	WindowSettingsUI.BackColor := intWindowColor
	WindowSettingsUI.OnEvent("Close", CloseSettingsUI)
	WindowSettingsUI.Title := "Window Settings"
	
	if AlwaysOnTopButton
		AlwaysOnTopButton := ""

	AlwaysOnTopButton := WindowSettingsUI.Add("Button", "Section Center vAlwaysOnTopButton h30 w" Popout_Width/1.05, "Always-On-Top: " AOT_Text)
	AlwaysOnTopButton.OnEvent("Click", ToggleAOT)
	AlwaysOnTopButton.Opt("Background" intWindowColor)
	AlwaysOnTopButton.SetFont("s12 w500", "Consolas")

	local activeText_Sound := (playSounds == 1 and "All") or (playSounds == 2 and "Less") or (playSounds == 3 and "None")
	
	if SoundToggleButton
		SoundToggleButton := ""

	SoundToggleButton := WindowSettingsUI.Add("Button", "xm Section Center vSoundToggleButton h30 w" Popout_Width/1.05, "Sounds: " activeText_Sound)
	SoundToggleButton.OnEvent("Click", ToggleSound)
	SoundToggleButton.Opt("Background" intWindowColor)
	SoundToggleButton.SetFont("s12 w500", "Consolas")

	OnProcessDropdownChange(*) {
		local selectedExe := ProcessDropdown.Text  ; get the selected process name
		ProcessLabel.Text := "Searching for: " . selectedExe
		
		RegWrite(selectedExe, "REG_SZ", "HKCU\Software\JACS", "SelectedProcessExe")
		SelectedProcessExe := RegRead("HKCU\Software\JACS", "SelectedProcessExe", "RobloxPlayerBeta.exe")
	}

	PopulateProcessDropdown(*) {
		local winIDs := WinGetList()  ; Returns an array of window handles.
		local processList := []       ; Array for unique process names.
		local Items := ControlGetItems(ProcessDropdown.Hwnd) 
		
		for index, winID in winIDs {
			local title := WinGetTitle("ahk_id " winID)
			if (title = "")
				continue  ; Skip windows without a title.
			
			local procName := ""
			try {
				procName := WinGetProcessName("ahk_id " winID)
			} catch {
				continue  ; Skip windows that trigger an error (like access denied).
			}
			
			for i, name in Items {
				if Items[i] != procName and IsWindowVisibleToUser(winID)
					ProcessDropdown.Add([procName])
			}
		}
	}
	
	IsWindowVisibleToUser(hWnd) {
		; Ensure it's a number and not null
		if !IsInteger(hWnd) || hWnd = 0
			return false
	
		; Ensure the HWND exists and is a real window
		if !DllCall("IsWindow", "ptr", hWnd)
			return false
	
		; Check visibility
		return DllCall("IsWindowVisible", "ptr", hWnd, "int")
	}
	
	; Add a label to display the currently selected process
    local ProcessLabel := WindowSettingsUI.Add("Text", "xs y+30 Center h40 vProcessLabel w" Popout_Width/1.05, "Searching for: " SelectedProcessExe)
    ProcessLabel.SetFont("s12", "Consolas")
	ProcessLabel.Opt("Background" intWindowColor . " c" ControlTextColor)

    ; Add a dropdown list (ComboBox) for selecting a process
    ProcessDropdown := WindowSettingsUI.Add("DropDownList", "xm y+-20 R10 Center vProcessDropdown w" Popout_Width/1.05, [SelectedProcessExe])
    ProcessDropdown.SetFont("s12", "Consolas")
	ProcessDropdown.Choose(1)
	ProcessDropdown.OnEvent("Change", OnProcessDropdownChange)

	PopulateProcessDropdown(ProcessDropdown)

	; ################################# ;
	; Slider Description Box
	local testBoxColor := "666666"
	DescriptionBox := WindowSettingsUI.Add("Text", "xm y+15 Section Left vDescriptionBox h" . Popout_Height/2 . " w" Popout_Width/1.05)
	DescriptionBox.SetFont("s10 w700", "Consolas")
	DescriptionBox.Opt("+Border Background" (testBoxColor or intWindowColor) . " c" ControlTextColor)
	
	; Hover Descriptions
	local Descriptions := Map(
		; Sliders
		"AlwaysOnTopButton", "This button controls whether the script's UI stays as the top-most window on the screen.",
		"SoundToggleButton", "This button controls the sounds that play when the auto-clicker sequence triggers, when no target window is found, etc.`n`nAll: All sounds play. This includes a 3 second countdown via audible beeps, a higher pitched trigger tone indicating the sequence has begun after the aforementioned countdown, and an audible indication the script launched.`n`nLess: Only the single higher pitched indicator and indicator on script launch are played.`n`nNone: No indication sounds are played.",
		"ProcessDropdown", "Pick a process from this dropdown list and the script will look for the first active process matching the name of the one selected.",
	)
	Descriptions["ProcessLabel"] := Descriptions["ProcessDropdown"]
	
	updateDescriptionBox(newText := "") {
		DescriptionBox.Text := newText
	}

	mouseHoverDescription(*)
	{
		if not WindowSettingsUI or not DescriptionBox
			return SetTimer(mouseHoverDescription,0)

		MouseGetPos(&MouseX,&MouseY,&HoverWindow,&HoverControl)
		local targetControl := ""

		if HoverControl
		{
			try targetControl := WindowSettingsUI.__Item[HoverControl]
			if WindowSettingsUI and DescriptionBox and HoverControl and targetControl and Descriptions.Has(targetControl.Name) and DescriptionBox.Text != Descriptions[targetControl.Name] {
				try updateDescriptionBox(Descriptions[targetControl.Name])
			}
			else if WindowSettingsUI and DescriptionBox and not HoverControl or not targetControl or not Descriptions.Has(targetControl.Name) {
				try updateDescriptionBox()
			}
		}
	}

	; Calculate center position
	WinGetClientPos(&MainX, &MainY, &MainW, &MainH, MainUI.Title)
	CenterX := MainX + (MainW / 2) - (Popout_Width / 2)
	CenterY := MainY + (MainH / 2) - (Popout_Height / 2)

	WindowSettingsUI.Show("AutoSize X" . CenterX . " Y" . CenterY . " w" . Popout_Width . "h" . Popout_Height)

	SetTimer(mouseHoverDescription,50)
}

CreateClickerSettingsGUI(*) {
	

	; UI Settings
	local PixelOffset := 10
	local Popout_Width := 400
	local Popout_Height := 600
	local labelOffset := 50
	local sliderOffset := 2.5

	; Labels, Sliders, Buttons
	local MouseSpeedLabel := ""
	local MouseSpeedSlider := ""

	local ClickRateOffsetLabel := ""
	local ClickRateSlider := ""

	local ClickRadiusLabel := ""
	local ClickRadiusSlider := ""
	
	local MouseClicksLabel := ""
	local MouseClicksSlider := ""
	local CooldownLabel := ""
	local CooldownSlider := ""
	global EditCooldownButton
	local ToggleMouseLock := ""

	; Global Save Data
	global SettingsUI
	global MouseSpeed
	global MouseClickRateOffset
	global MouseClickRadius
	global doMouseLock
	global MouseClicks
	global MainUI
	global MainUI_PosX
	global MainUI_PosY
	global MinutesToWait
	global SecondsToWait
	global minCooldown

	; Clamps
	local maxRadius := 200
	local maxRate := 1000
	local maxSpeed := 1000
	local maxClicks := 10
	local maxCooldown := 15*60
	local buddyWidth := 50

	; Colors
	global blnLightMode := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
	global intWindowColor := (!blnLightMode and updateTheme) and "404040" or "EEEEEE"
	global intControlColor := (!blnLightMode and updateTheme) and "606060" or "FFFFFF"
	global ControlTextColor := (!blnLightMode and updateTheme) and "FFFFFF" or "000000"

	CloseSettingsUI(*)
	{
		if SettingsUI
		{
			SettingsUI.Destroy()
			SettingsUI := ""
		}

		SetTimer(mouseHoverDescription,0)
	}

	; If settingsUI is open, close it
	if SettingsUI
		return CloseSettingsUI()
	
	; Slider update function
	updateSliderValues(ctrlObj, info) {
		; MsgBox(ctrlObj.Name . ": " . info)
		if ctrlObj.Name == "MouseSpeed" {
			RegWrite(ctrlObj.Value, "REG_DWORD", "HKCU\Software\JACS", "MouseSpeed")
			MouseSpeed := RegRead("HKCU\Software\JACS", "MouseSpeed", 0)
			
			if MouseSpeedLabel
				MouseSpeedLabel.Text := "Mouse Speed: " . (ctrlObj.Value >= 1000 ? Format("{:.2f} s", ctrlObj.Value / 1000) : ctrlObj.Value . " ms")
		}

		if ctrlObj.Name == "ClickRateOffset" {
			RegWrite(ctrlObj.Value, "REG_DWORD", "HKCU\Software\JACS", "ClickRateOffset")
			MouseClickRateOffset := RegRead("HKCU\Software\JACS", "ClickRateOffset", 0)
			
			if ClickRateOffsetLabel
				ClickRateOffsetLabel.Text := "Click Rate Offset: " . (ctrlObj.Value >= 1000 ? Format("{:.2f} s", ctrlObj.Value / 1000) : ctrlObj.Value . " ms")
		}

		if ctrlObj.Name == "ClickRadius" {
			RegWrite(ctrlObj.Value, "REG_DWORD", "HKCU\Software\JACS", "ClickRadius")
			MouseClickRateOffset := RegRead("HKCU\Software\JACS", "ClickRadius", 0)
			
			if ClickRadiusLabel
				ClickRadiusLabel.Text := "Click Radius: " . ctrlObj.Value . " pixels"
		}

		if ctrlObj.Name == "MouseClicks" {
			RegWrite(ctrlObj.Value, "REG_DWORD", "HKCU\Software\JACS", "MouseClicks")
			MouseClicks := RegRead("HKCU\Software\JACS", "MouseClicks", 5)
			
			if MouseClicksLabel
				MouseClicksLabel.Text := "Click Amount: " . ctrlObj.Value . " clicks"
		}

		if ctrlObj.Name == "CooldownSlider" {
			local targetSeconds := (SecondsToWait > 0) and Round(Mod(SecondsToWait, 60),0) or 0
			local targetFormattedTime := Format("{:02}:{:02}", MinutesToWait, targetSeconds)
			local mins_suffix := SecondsToWait > 60 and " minutes" or SecondsToWait == 60 and " minute" or SecondsToWait < 60 and " seconds"
	
			RegWrite(ctrlObj.Value/60, "REG_DWORD", "HKCU\Software\JACS", "Cooldown")
			RegWrite(math.clamp(Round(ctrlObj.Value,2),(minCooldown > 0 and minCooldown/60) or 0,900),"REG_DWORD", "HKCU\Software\JACS", "SecondsToWait")
			MinutesToWait := RegRead("HKCU\Software\JACS", "Cooldown", 15)
			SecondsToWait := RegRead("HKCU\Software\JACS", "SecondsToWait",math.clamp(Round(ctrlObj.Value * 60,2),(minCooldown > 0 and minCooldown/60) or 0,900))
			
			if CooldownLabel
				CooldownLabel.Text := "Cooldown: " targetFormattedTime . mins_suffix
		}
	}

	; Toggle Function
	updateToggle(ctrlObj, info) {
		if ctrlObj.Name == "ToggleMouseLock" {
			RegWrite(not doMouseLock, "REG_DWORD", "HKCU\Software\JACS", "doMouseLock")
			doMouseLock := RegRead("HKCU\Software\JACS", "doMouseLock", false)

			local toggleStatus := doMouseLock and "Enabled" or "Disabled"
			ctrlObj.Text := "Block Inputs: " . toggleStatus
		}
	}

	local AOTStatus := AlwaysOnTopActive == true and "+AlwaysOnTop" or "-AlwaysOnTop"
	local AOT_Text := (AlwaysOnTopActive == true and "On") or "Off"

	; Create GUI Window
	SettingsUI := Gui(AOTStatus)
	SettingsUI.Opt("+Owner" . MainUI.Hwnd)
	SettingsUI.BackColor := intWindowColor
	SettingsUI.OnEvent("Close", CloseSettingsUI)
	SettingsUI.Title := "Clicker Settings"

	; Mouse Speed
	MouseSpeedLabel := SettingsUI.Add("Text", "Section Center vMouseSpeedLabel h20 w" Popout_Width/1.05, "Mouse Speed: " . math.clamp(MouseSpeed,0,maxSpeed) . " ms")
	MouseSpeedLabel.SetFont("s14 w600", "Consolas")
	MouseSpeedLabel.Opt("Background" intWindowColor . " c" ControlTextColor)

	MouseSpeedSlider := SettingsUI.Add("Slider", "xm+" . Popout_Width/6.5 . " 0x300 0xC00 AltSubmit vMouseSpeed w" Popout_Width/1.5 - (SettingsUI.MarginX))
	MouseSpeedSlider.OnEvent("Change", updateSliderValues)
	
	MS_Buddy1 := SettingsUI.Add("Text", "Center vMS_Buddy1 h20 w" buddyWidth, "Fast")
	MS_Buddy1.SetFont("s12 w600", "Consolas")
	MS_Buddy1.Opt("Background" intWindowColor . " c" ControlTextColor)
	MS_Buddy2 := SettingsUI.Add("Text", "Center vMS_Buddy2 h20 w" buddyWidth, "Slow")
	MS_Buddy2.SetFont("s12 w600", "Consolas")
	MS_Buddy2.Opt("Background" intWindowColor . " c" ControlTextColor)

	MouseSpeedSlider.Opt("Buddy1MS_Buddy1 Buddy2MS_Buddy2 Range0-" maxSpeed)
	MouseSpeedSlider.Value := math.clamp(MouseSpeed,0,maxSpeed) or 0

	; Mouse Click Rate Offset
	ClickRateOffsetLabel := SettingsUI.Add("Text", "xm y+-" . labelOffset . " Section Center vClickRateOffsetLabel h20 w" Popout_Width/1.05, "Click Rate Offset: " . math.clamp(MouseClickRateOffset,0,maxSpeed) . " ms")
	ClickRateOffsetLabel.SetFont("s14 w600", "Consolas")
	ClickRateOffsetLabel.Opt("Background" intWindowColor . " c" ControlTextColor)

	ClickRateSlider := SettingsUI.Add("Slider", "xm+" . Popout_Width/6.5 . " y+-" . sliderOffset . " 0x300 0xC00 AltSubmit vClickRateOffset w" Popout_Width/1.5 - (SettingsUI.MarginX))
	ClickRateSlider.OnEvent("Change", updateSliderValues)
	
	Rate_Buddy1 := SettingsUI.Add("Text", "Center vRate_Buddy1 h20 w" buddyWidth, "Less")
	Rate_Buddy1.SetFont("s12 w600", "Consolas")
	Rate_Buddy1.Opt("Background" intWindowColor . " c" ControlTextColor)
	Rate_Buddy2 := SettingsUI.Add("Text", "Center vRate_Buddy2 h20 w" buddyWidth, "More")
	Rate_Buddy2.SetFont("s12 w600", "Consolas")
	Rate_Buddy2.Opt("Background" intWindowColor . " c" ControlTextColor)

	ClickRateSlider.Opt("Buddy1Rate_Buddy1 Buddy2Rate_Buddy2 Range0-" maxRate)
	ClickRateSlider.Value := math.clamp(MouseClickRateOffset,0,maxSpeed) or 0

	; Mouse Click Radius
	ClickRadiusLabel := SettingsUI.Add("Text", "xm y+-" . labelOffset . " Section Center vClickRadiusLabel h20 w" Popout_Width/1.05, "Click Radius: " . math.clamp(MouseClickRadius,0,maxSpeed) . " pixels")
	ClickRadiusLabel.SetFont("s14 w600", "Consolas")
	ClickRadiusLabel.Opt("Background" intWindowColor . " c" ControlTextColor)

	ClickRadiusSlider := SettingsUI.Add("Slider", "xm+" . Popout_Width/6.5 . " y+-" . sliderOffset . " 0x300 0xC00 AltSubmit vClickRadius w" Popout_Width/1.5 - (SettingsUI.MarginX))
	ClickRadiusSlider.OnEvent("Change", updateSliderValues)
	
	ClickRadiusBuddy1 := SettingsUI.Add("Text", "Center vClickRadiusBuddy1 h20 w" buddyWidth, "Small")
	ClickRadiusBuddy1.SetFont("s12 w600", "Consolas")
	ClickRadiusBuddy1.Opt("Background" intWindowColor . " c" ControlTextColor)
	ClickRadiusBuddy2 := SettingsUI.Add("Text", "Center vClickRadiusBuddy2 h20 w" buddyWidth, "Big")
	ClickRadiusBuddy2.SetFont("s12 w600", "Consolas")
	ClickRadiusBuddy2.Opt("Background" intWindowColor . " c" ControlTextColor)

	ClickRadiusSlider.Opt("Buddy1ClickRadiusBuddy1 Buddy2ClickRadiusBuddy2 Range0-" maxRadius)
	ClickRadiusSlider.Value := math.clamp(MouseClickRadius,0,maxSpeed) or 0
	
	; Mouse Clicks
	MouseClicksLabel := SettingsUI.Add("Text", "xm y+-" . labelOffset . " Section Center vMouseClicksLabel h20 w" Popout_Width/1.05, "Click Amount: " . math.clamp(MouseClicks,1,maxClicks) . " clicks")
	MouseClicksLabel.SetFont("s14 w600", "Consolas")
	MouseClicksLabel.Opt("Background" intWindowColor . " c" ControlTextColor)

	MouseClicksSlider := SettingsUI.Add("Slider", "xm+" . Popout_Width/6.5 . " y+-" . sliderOffset . " 0x300 0xC00 AltSubmit vMouseClicks w" Popout_Width/1.5 - (SettingsUI.MarginX))
	MouseClicksSlider.OnEvent("Change", updateSliderValues)
	
	MouseClicksBuddy1 := SettingsUI.Add("Text", "Center vMouseClicksBuddy1 h20 w" buddyWidth, "Less")
	MouseClicksBuddy1.SetFont("s12 w600", "Consolas")
	MouseClicksBuddy1.Opt("Background" intWindowColor . " c" ControlTextColor)
	MouseClicksBuddy2 := SettingsUI.Add("Text", "Center vMouseClicksBuddy2 h20 w" buddyWidth, "More")
	MouseClicksBuddy2.SetFont("s12 w600", "Consolas")
	MouseClicksBuddy2.Opt("Background" intWindowColor . " c" ControlTextColor)

	MouseClicksSlider.Opt("Buddy1MouseClicksBuddy1 Buddy2MouseClicksBuddy2 Range1-" maxClicks)
	MouseClicksSlider.Value := math.clamp(MouseClicks,1,maxClicks) or 1
	
	; Mouse Click Rate Offset
	CooldownLabel := SettingsUI.Add("Text", "xm y+-" . labelOffset . " Section Center vCooldownLabel h20 w" Popout_Width/1.05, "Cooldown: " SecondsToWait " seconds")
	CooldownLabel.SetFont("s14 w600", "Consolas")
	CooldownLabel.Opt("Background" intWindowColor . " c" ControlTextColor)

	CooldownSlider := SettingsUI.Add("Slider", "xm+" . Popout_Width/6.5 . " y+-" . sliderOffset . " 0x300 0xC00 AltSubmit vCooldownSlider w" Popout_Width/1.5 - (SettingsUI.MarginX))
	CooldownSlider.OnEvent("Change", updateSliderValues)
	
	Cooldown_Buddy1 := SettingsUI.Add("Text", "Center vCooldown_Buddy1 h20 w" buddyWidth, "Fast")
	Cooldown_Buddy1.SetFont("s12 w600", "Consolas")
	Cooldown_Buddy1.Opt("Background" intWindowColor . " c" ControlTextColor)
	Cooldown_Buddy2 := SettingsUI.Add("Text", "Center vCooldown_Buddy2 h20 w" buddyWidth, "Slow")
	Cooldown_Buddy2.SetFont("s12 w600", "Consolas")
	Cooldown_Buddy2.Opt("Background" intWindowColor . " c" ControlTextColor)

	CooldownSlider.Opt("Buddy1Cooldown_Buddy1 Buddy2Cooldown_Buddy2 Range10-" maxCooldown)
	CooldownSlider.Value := math.clamp(SecondsToWait,0,maxCooldown) or 0

	updateSliderValues(CooldownSlider,"")

	EditCooldown(*) {
		local newTime := CooldownEditPopup()
		CooldownSlider.Value := math.clamp(newTime,0,maxCooldown) or 0

		local targetSeconds := (SecondsToWait > 0) and Round(Mod(SecondsToWait, 60),0) or 0
		local targetFormattedTime := Format("{:02}:{:02}", MinutesToWait, targetSeconds)
		local mins_suffix := SecondsToWait > 60 and " minutes" or SecondsToWait == 60 and " minute" or SecondsToWait < 60 and " seconds"

		if CooldownLabel
			CooldownLabel.Text := "Cooldown: " targetFormattedTime . mins_suffix
	}

	; Cooldown Editor
	EditCooldownButton := SettingsUI.Add("Button", "xm y+-" . labelOffset . " vCooldownEditor h40 w" Popout_Width/1.05, "Custom Cooldown")
	EditCooldownButton.OnEvent("Click", EditCooldown)
	EditCooldownButton.SetFont("s14 w500", "Consolas")
	EditCooldownButton.Opt("Background" intWindowColor)
	
	; Mouse Lock
	local toggleStatus := doMouseLock and "Enabled" or "Disabled"
	ToggleMouseLock := SettingsUI.Add("Button", "xm y+" . labelOffset/6.5 . " Section Center vToggleMouseLock h40 w" Popout_Width/1.05, "Block Inputs: " . toggleStatus)
	ToggleMouseLock.SetFont("s14 w500", "Consolas")
	ToggleMouseLock.Opt("Background" intWindowColor . " c" ControlTextColor)
	ToggleMouseLock.OnEvent("Click", updateToggle)
	
	; Slider Description Box
	local testBoxColor := "666666"
	DescriptionBox := SettingsUI.Add("Text", "xm Section Left vDescriptionBox h" . Popout_Height/3.25 . " w" Popout_Width/1.05)
	DescriptionBox.SetFont("s10 w700", "Consolas")
	DescriptionBox.Opt("+Border Background" (testBoxColor or intWindowColor) . " c" ControlTextColor)
	
	; Hover Descriptions
	local Descriptions := Map(
		; Sliders
		"MouseSpeed", "Use this slider to control how fast the mouse moves to each location in the auto-clicker sequence.",
		"ClickRateOffset", 'Use this slider to control the time between clicks when the auto-clicker fires.',
		"ClickRadius", "Use this slider to add random variations to the click auto-clicker's click pattern.`n`n(Higher values = Larger area of randomized clicks)",
		"ToggleMouseLock", "This button controls if the script blocks user inputs or not during the short auto-click sequence.`n`nIt is recommended to enable this setting if you are actively using your mouse or keyboard when the script is running. This is to prevent accidental mishaps in your gameplay.`n`n(Note: This setting will not impede on your active gameplay session, as your manual inputs will reset the script's auto-click timer!)",
		"MouseClicks", "Use this slider to control how many clicks are sent when the bar fills to 100%.",
		"CooldownEditor", "This button controls the duration of the auto-clicker sequence timer.`n`nLength: 0-15 minutes`n`n(Note: Setting the auto-clicker to 0 will constantly click, like typical auto-clickers, however other windows not in the target scope will be ignored and not clicked.)",
		"CooldownSlider", "Use this slider to fine-tune the cooldown for the auto-clicker. Alternatively you can use the `"Custom Cooldown`" button to set a specific value."
	)
	
	Descriptions.Set("MouseSpeedLabel", Descriptions["MouseSpeed"])
	Descriptions.Set("MS_Buddy1", Descriptions["MouseSpeed"])
	Descriptions.Set("MS_Buddy2", Descriptions["MouseSpeed"])

	Descriptions.Set("ClickRateOffsetLabel", Descriptions["ClickRateOffset"])
	Descriptions.Set("Rate_Buddy1", Descriptions["ClickRateOffset"])
	Descriptions.Set("Rate_Buddy2", Descriptions["ClickRateOffset"])

	Descriptions.Set("ClickRadiusLabel", Descriptions["ClickRadius"])
	Descriptions.Set("ClickRadiusBuddy1", Descriptions["ClickRadius"])
	Descriptions.Set("ClickRadiusBuddy2", Descriptions["ClickRadius"])

	Descriptions.Set("MouseClicksLabel", Descriptions["MouseClicks"])
	Descriptions.Set("MouseClicksBuddy1", Descriptions["MouseClicks"])
	Descriptions.Set("MouseClicksBuddy2", Descriptions["MouseClicks"])
	
	Descriptions.Set("CooldownLabel", Descriptions["CooldownSlider"])
	Descriptions.Set("Cooldown_Buddy1", Descriptions["CooldownSlider"])
	Descriptions.Set("Cooldown_Buddy2", Descriptions["CooldownSlider"])


	updateDescriptionBox(newText := "") {
		DescriptionBox.Text := newText
	}

	mouseHoverDescription(*)
	{
		if not SettingsUI or not DescriptionBox
			return SetTimer(mouseHoverDescription,0)

		MouseGetPos(&MouseX,&MouseY,&HoverWindow,&HoverControl)
		local targetControl := ""

		if HoverControl
		{
			try targetControl := SettingsUI.__Item[HoverControl]
			if SettingsUI and DescriptionBox and HoverControl and targetControl and Descriptions.Has(targetControl.Name) and DescriptionBox.Text != Descriptions[targetControl.Name] {
				try updateDescriptionBox(Descriptions[targetControl.Name])
			}
			else if SettingsUI and DescriptionBox and not HoverControl or not targetControl or not Descriptions.Has(targetControl.Name) {
				try updateDescriptionBox()
			}
		}
	}
	SettingsUI.OnEvent("Close", CloseSettingsUI)

	; Calculate center position
	WinGetClientPos(&MainX, &MainY, &MainW, &MainH, MainUI.Title)
	CenterX := MainX + (MainW / 2) - (Popout_Width / 2)
	CenterY := MainY + (MainH / 2) - (Popout_Height / 2)

	SettingsUI.Show("AutoSize X" . CenterX . " Y" . CenterY . " w" . Popout_Width . "h" . Popout_Height)

	SetTimer(mouseHoverDescription,50)
}

CreateScriptSettingsGUI(*) {
	; UI Settings
	local PixelOffset := 10
	local Popout_Width := 400
	local Popout_Height := 600
	local labelOffset := 50
	local sliderOffset := 2.5

	; Labels, Sliders, Buttons
	global EditButton
	global ExitButton
	global OpenMouseSettingsButton
	global ReloadButton
	global EditorButton
	global ScriptDirButton
	global AddToBootupFolderButton

	; Global Save Data
	global ScriptSettingsUI
	global AlwaysOnTopActive
	
	; Global Controls
	global MainUI
	global MainUI_PosX
	global MainUI_PosY

	local AOTStatus := AlwaysOnTopActive == true and "+AlwaysOnTop" or "-AlwaysOnTop"
	local AOT_Text := (AlwaysOnTopActive == true and "On") or "Off"

	; Colors
	global blnLightMode := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
	global intWindowColor := (!blnLightMode and updateTheme) and "404040" or "EEEEEE"
	global intControlColor := (!blnLightMode and updateTheme) and "606060" or "FFFFFF"
	global ControlTextColor := (!blnLightMode and updateTheme) and "FFFFFF" or "000000"

	CloseSettingsUI(*)
	{
		if ScriptSettingsUI {
			ScriptSettingsUI.Destroy()
			ScriptSettingsUI := ""
		}
	}

	; If settingsUI is open, close it
	if ScriptSettingsUI
		return CloseSettingsUI()

	; ############################################ ;
	; ############################################ ;
	; ############################################ ;

	; Create GUI Window
	ScriptSettingsUI := Gui(AOTStatus)
	ScriptSettingsUI.Opt("+Owner" . MainUI.Hwnd)
	ScriptSettingsUI.BackColor := intWindowColor
	ScriptSettingsUI.OnEvent("Close", CloseSettingsUI)
	ScriptSettingsUI.Title := "Script Settings"

	; ############################################ ;
	; ############################################ ;
	; ############################################ ;
	
	; Edit
	EditButton := ScriptSettingsUI.Add("Button","vEditButton Section Center h40 w" Popout_Width/1.05, "View Script")
	EditButton.OnEvent("Click", EditApp)
	EditButton.SetFont("s12 w500", "Consolas")
	EditButton.Opt("Background" intWindowColor)
	
	; Reload
	ReloadButton := ScriptSettingsUI.Add("Button", "vReloadButton xs h40 w" (Popout_Width/1.05), "Relaunch Script")
	ReloadButton.OnEvent("Click", ReloadScript)
	ReloadButton.SetFont("s12 w500", "Consolas")
	ReloadButton.Opt("Background" intWindowColor)
	
	; Exit
	ExitButton := ScriptSettingsUI.Add("Button", "vExitButton xs h40 w" (Popout_Width/1.05), "Close Script")
	ExitButton.OnEvent("Click", CloseApp)
	ExitButton.SetFont("s12 w500", "Consolas")
	ExitButton.Opt("Background" intWindowColor)

	; ############################################ ;
	; ############################################ ;
	
	; Editor Selector
	EditorButton := ScriptSettingsUI.Add("Button", "vEditorSelector xs h40 w" Popout_Width/1.05, "Select Script Editor")
	EditorButton.OnEvent("Click", SelectEditor)
	EditorButton.SetFont("s12 w500", "Consolas")
	EditorButton.Opt("Background" intWindowColor)

	; Open Script Directory
	ScriptDirButton := ScriptSettingsUI.Add("Button", "vScriptDir xs h40 w" Popout_Width/1.05, "Open File Location")
	ScriptDirButton.OnEvent("Click", OpenScriptDir)
	ScriptDirButton.SetFont("s12 w500", "Consolas")
	ScriptDirButton.Opt("Background" intWindowColor)

	local addToStartUp_Text := isInStartFolder and "Remove from Windows startup folder" or "Add to Windows startup folder"
	AddToBootupFolderButton := ScriptSettingsUI.Add("Button", "vStartupToggle xs h40 w" Popout_Width/1.05, addToStartUp_Text)
	AddToBootupFolderButton.OnEvent("Click", ToggleStartup)
	AddToBootupFolderButton.Opt("Background" intWindowColor)
	AddToBootupFolderButton.SetFont("s12 w500", "Consolas")

	; ############################################ ;
	; ############################################ ;
	; ############################################ ;

	; Slider Description Box
	local testBoxColor := "666666"
	DescriptionBox := ScriptSettingsUI.Add("Text", "xm Section Left vDescriptionBox h" . Popout_Height/4 . " w" Popout_Width/1.05)
	DescriptionBox.SetFont("s10 w700", "Consolas")
	DescriptionBox.Opt("+Border Background" (testBoxColor or intWindowColor) . " c" ControlTextColor)
	
	; Hover Descriptions
	local Descriptions := Map(
		; Sliders
		; "Button", "Text",
		"StartupToggle", "If enabled, the script will launch automatically when Windows boots up. Recommended with hidden UI (Alt + Backspace)",
		"ScriptDir", "View where the script is location in Windows Explorer",
		"EditorSelector", "Select a script editor to edit the script with (notepad, notepad++, Visual Studio Code, etc.)",
		"EditButton", "View or edit the script using a script editor of your choice.",
		"ExitButton", "Terminate the script",
		"ReloadButton", "Reload the script",
	)
	
	updateDescriptionBox(newText := "") {
		DescriptionBox.Text := newText
	}

	mouseHoverDescription(*)
	{
		if not ScriptSettingsUI or not DescriptionBox
			return SetTimer(mouseHoverDescription,0)

		MouseGetPos(&MouseX,&MouseY,&HoverWindow,&HoverControl)
		local targetControl := ""

		if HoverControl
		{
			try targetControl := ScriptSettingsUI.__Item[HoverControl]
			if ScriptSettingsUI and DescriptionBox and HoverControl and targetControl and Descriptions.Has(targetControl.Name) and DescriptionBox.Text != Descriptions[targetControl.Name] {
				try updateDescriptionBox(Descriptions[targetControl.Name])
			}
			else if ScriptSettingsUI and DescriptionBox and not HoverControl or not targetControl or not Descriptions.Has(targetControl.Name) {
				try updateDescriptionBox()
			}
		}
	}

	; Calculate center position
	WinGetClientPos(&MainX, &MainY, &MainW, &MainH, MainUI.Title)
	CenterX := MainX + (MainW / 2) - (Popout_Width / 2)
	CenterY := MainY + (MainH / 2) - (Popout_Height / 2)

	ScriptSettingsUI.Show("AutoSize X" . CenterX . " Y" . CenterY . " w" . Popout_Width . "h" . Popout_Height)

	SetTimer(mouseHoverDescription,50)
}

CreateExtrasGUI(*) {
	global MoveControl
	global ControlResize
	global warningRequested
	global MainUI_PosX
	global MainUI_PosY

	local Popout_Width := 400
	local Popout_Height := 600
	local createNewWarningButton := ""
	local ExtrasUI_Width := 400
	local ExtrasUI_Height := 400
	
	; Create new UI
	global ExtrasUI

	if ExtrasUI
		ExtrasUI.Destroy()

	ExtrasUI := Gui(AlwaysOnTopActive)
	ExtrasUI.BackColor := intWindowColor
	ExtrasUI.Title := "Extras"
	ExtrasUI.OnEvent("Close", killGUI)
	ExtrasUI.SetFont("s14 w500", "Courier New")
	
	local UI_Margin_Width := ExtrasUI.MarginX*2
	local UI_Margin_Height := ExtrasUI.MarginY*1.25
	local buttonHeight := (ExtrasUI_Height/8) - UI_Margin_Height
	local buttonWidth := ExtrasUI_Width - UI_Margin_Width

	; Discord
	local DiscordLink := ExtrasUI.Add("Button", "vDiscordLink Center h" . buttonHeight . " w" . Popout_Width/1.05, 'Join the Discord!')
	DiscordLink.SetFont("s12 w500", "Consolas")
	DiscordLink.OnEvent("Click", DiscordLink_Click)
	DiscordLink.Opt("Background" intWindowColor)
	DiscordLink_Click(*) {
		Run("https://discord.gg/w8QdNsYmbr")
	}
	
	; GitHub
	local GitHubLink := ExtrasUI.Add("Button", "vGithubLink Center h" . buttonHeight . " w" . Popout_Width/1.05, "GitHub Repository")
	GitHubLink.SetFont("s12 w500", "Consolas")
	GitHubLink.OnEvent("Click", GitHubLink_Click)
	GitHubLink.Opt("Background" intWindowColor)
	GitHubLink_Click(*) {
		Run("https://github.com/WoahItsJeebus/JACS/")
	}

	; Warning UI
	local OpenWarningLabel := ExtrasUI.Add("Button", "vOpenWarning Center h" . buttonHeight . " w" . Popout_Width/1.05, "View Warning Agreement")
	OpenWarningLabel.SetFont("s12 w500", "Consolas")
	OpenWarningLabel.OnEvent("Click", (*) => createWarningUI(true))
	OpenWarningLabel.Opt("Background" intWindowColor)

	; Patchnotes UI
	local ViewPatchnotes := ExtrasUI.Add("Button", "vViewPatchnotes Center h" . buttonHeight . " w" . Popout_Width/1.05, "Patchnotes")
	ViewPatchnotes.SetFont("s12 w500", "Consolas")
	ViewPatchnotes.OnEvent("Click", ShowPatchnotes)
	ViewPatchnotes.Opt("Background" intWindowColor)

	ShowPatchnotes(*) {
		ShowPatchNotesGUI()
	}

	; ############################### ;
	; ############################### ;
	; Slider Description Box
	local testBoxColor := "666666"
	DescriptionBox := ExtrasUI.Add("Text", "xm Section Left vDescriptionBox h" . Popout_Height/4 . " w" Popout_Width/1.05)
	DescriptionBox.SetFont("s10 w700", "Consolas")
	DescriptionBox.Opt("+Border Background" (testBoxColor or intWindowColor) . " c" ControlTextColor)
	
	; Hover Descriptions
	local Descriptions := Map(
		; Sliders
		; "Button", "Text",
		"DiscordLink","Join the Discordeebus Discord server!",
		"GithubLink","View the Github repository and see changes from past versions!",
		"OpenWarning","View the warning popup seen when running the script for the first time (or if denying the agreement/closing without accepting)",
		"ViewPatchnotes","Fetch the patchnotes for the latest version of the script posted to Github!",
	)
	
	updateDescriptionBox(newText := "") {
		DescriptionBox.Text := newText
	}

	mouseHoverDescription(*)
	{
		if not ExtrasUI or not DescriptionBox
			return SetTimer(mouseHoverDescription,0)

		MouseGetPos(&MouseX,&MouseY,&HoverWindow,&HoverControl)
		local targetControl := ""

		if HoverControl
		{
			try targetControl := ExtrasUI.__Item[HoverControl]
			if ExtrasUI and DescriptionBox and HoverControl and targetControl and Descriptions.Has(targetControl.Name) and DescriptionBox.Text != Descriptions[targetControl.Name] {
				try updateDescriptionBox(Descriptions[targetControl.Name])
			}
			else if ExtrasUI and DescriptionBox and not HoverControl or not targetControl or not Descriptions.Has(targetControl.Name) {
				try updateDescriptionBox()
			}
		}
	}

	; Calculate center position
	WinGetClientPos(&MainX, &MainY, &MainW, &MainH, MainUI.Title)
	CenterX := MainX + (MainW / 2) - (Popout_Width / 2)
	CenterY := MainY + (MainH / 2) - (Popout_Height / 2)

	ExtrasUI.Show("AutoSize X" . CenterX . " Y" . CenterY . " w" . Popout_Width . "h" . Popout_Height)

	SetTimer(mouseHoverDescription,50)

	; Calculate center position
	WinGetClientPos(&MainX, &MainY, &MainW, &MainH, MainUI.Title)
	CenterX := MainX + (MainW / 2) - (ExtrasUI_Width / 2)
	CenterY := MainY + (MainH / 2) - (ExtrasUI_Height / 2)

	ExtrasUI.Show("AutoSize X" . CenterX . " Y" . CenterY . " w" . ExtrasUI_Width . " h" . ExtrasUI_Height)

	killGUI(*) {
		if ExtrasUI
			ExtrasUI := ""
	}
}

ToggleHideUI(newstate) {
	global MainUI
	global isUIHidden

	if not MainUI
		return CreateGui()

	RegWrite(newstate or not isUIHidden, "REG_DWORD", "HKCU\Software\JACS", "isUIHidden")
	isUIHidden := RegRead("HKCU\Software\JACS", "isUIHidden", false)
}

updateUIVisibility(*) {
	global MainUI
	global isUIHidden
	global MainUI_PosX
	global MainUI_PosY
	
	if not MainUI
		return

	local winState := WinGetMinMax(MainUI.Title) ; -1 = Minimized | 0 = "Neither" (I assume floating) | 1 = Maximized
	if isUIHidden
		MainUI.Hide()
	else if not isUIHidden and winState != -1
		MainUI.Show("X" . MainUI_PosX . " Y" . MainUI_PosY . " Restore AutoSize")
}

ToggleStartup(*) {
	global AddToBootupFolderButton
	global isInStartFolder

    StartupPath := A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup"
	TargetFile := StartupPath "\" A_ScriptName
	
	local newMode

    if (FileExist(TargetFile)) {
        FileDelete(TargetFile)

		newMode := false
		RegWrite(newMode, "REG_DWORD", "HKCU\Software\JACS", "isInStartFolder")
		isInStartFolder := RegRead("HKCU\Software\JACS", "isInStartFolder", false)

        MsgBox "Script removed from Startup."
    } else {
        FileCopy(A_ScriptFullPath, TargetFile)

		newMode := true
		RegWrite(newMode, "REG_DWORD", "HKCU\Software\JACS", "isInStartFolder")
		isInStartFolder := RegRead("HKCU\Software\JACS", "isInStartFolder", false)

        MsgBox "Script added to Startup."
    }

	local addToStartUp_Text := isInStartFolder and "Remove from startup folder" or "Add to startup folder"
	AddToBootupFolderButton.Text := addToStartUp_Text
}

ToggleAOT(*) {
	global MainUI
	global SettingsUI
	global WindowSettingsUI
	global AlwaysOnTopButton
	global AlwaysOnTopActive

	RegWrite(!AlwaysOnTopActive, "REG_DWORD", "HKCU\Software\JACS", "AlwaysOnTop")
	AlwaysOnTopActive := RegRead("HKCU\Software\JACS", "AlwaysOnTop", false)

	local AOTStatus := (AlwaysOnTopActive == true and "+AlwaysOnTop") or "-AlwaysOnTop"
	local AOT_Text := (AlwaysOnTopActive == true and "On") or "Off"

	if AlwaysOnTopButton
		AlwaysOnTopButton.Text := "Always-On-Top: " . AOT_Text

	if MainUI
		MainUI.Opt(AOTStatus)

	if SettingsUI
		SettingsUI.Opt(AOTStatus)

	if WindowSettingsUI
		WindowSettingsUI.Opt(AOTStatus)
}

CheckDeviceTheme(*) {
	global MainUI
	global EditButton
	global ExitButton
	global CoreToggleButton
	global SoundToggleButton
	global ReloadButton
	global EditCooldownButton
	global EditorButton
	global ScriptDirButton

	global WaitProgress
	global WaitTimerLabel
	global ElapsedTimeLabel
	global MinutesToWait
	global CreditsLink
	global ResetCooldownButton

	; Colors
	global blnLightMode := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
	global intWindowColor := (!blnLightMode and updateTheme) and "404040" or "EEEEEE"
	global intControlColor := (!blnLightMode and updateTheme) and "606060" or "FFFFFF"
	global intProgressBarColor := (!blnLightMode and updateTheme) and "757575" or "dddddd"
	global ControlTextColor := (!blnLightMode and updateTheme) and "FFFFFF" or "000000"
	global linkColor := (!blnLightMode and updateTheme) and "99c3ff" or "4787e7"
	
	global currentTheme := blnLightMode
	global lastTheme
	
	if lastTheme != currentTheme and MainUI
	{
		lastTheme := currentTheme
		MainUI.BackColor := intWindowColor
		
		EditButton.Opt("Background" intWindowColor)
		ExitButton.Opt("Background" intWindowColor)
		CoreToggleButton.Opt("Background" intWindowColor)
		SoundToggleButton.Opt("Background" intWindowColor)
		ReloadButton.Opt("Background" intWindowColor)
		ScriptDirButton.Opt("Background" intWindowColor)
		EditorButton.Opt("Background" intWindowColor)
		EditCooldownButton.Opt("Background" intWindowColor)
		WaitProgress.Opt("Background" intProgressBarColor)
		ResetCooldownButton.Opt("Background" intWindowColor)
		WaitTimerLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
		ElapsedTimeLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
		
		EditButton.Redraw()
		ExitButton.Redraw()
		CoreToggleButton.Redraw()
		SoundToggleButton.Redraw()
		ReloadButton.Redraw()
		ScriptDirButton.Redraw()
		EditorButton.Redraw()
		WaitProgress.Redraw()
		WaitTimerLabel.Redraw()
		ElapsedTimeLabel.Redraw()
		ResetCooldownButton.Redraw()
		CreditsLink.Opt("c" linkColor)
	}
}

CooldownEditPopup(*) {
	
    global MinutesToWait
    global SecondsToWait
    global MainUI
    global minCooldown

    local UI_Height := 120
	local UI_Width := 350
    local InpBox := InputBox(minCooldown . " - 15 minutes. You can also use formats like `"`1m 30s`"`, `"`10s`"`, or `"`1:30`"`.", "Edit Cooldown", "w" UI_Width " h" UI_Height)
    
    if (InpBox.Result = "Cancel")
        return SecondsToWait

    local inputText := Trim(InpBox.Value)
    local parsed := {}
    
    ; Determine which format the user provided
    if (InStr(inputText, ":")) {
        ; Colon-separated format e.g. "1:30"
        try {
            parsed := ParseColonFormat(inputText)
        } catch error as e {
            MsgBox("Invalid colon format. Please use something like '1:30'.", "Cooldown update error", "T5")
            return SecondsToWait
        }
    } else if (RegExMatch(inputText, "[ms]")) {
        ; Letter-based format e.g. "1m 30s" or "38s 10m"
        try {
            parsed := ParseLetterFormat(inputText)
        } catch error as e {
            MsgBox("Invalid time format. Please use a valid format like '1m 30s' or '10s'.", "Cooldown update error", "T5")
            return SecondsToWait
        }
    } else if (IsNumber(inputText)) {
        ; Pure number is interpreted as minutes
        parsed := { minutes: inputText+0, seconds: Round((inputText+0) * 60) }
    } else {
        MsgBox("Please enter a valid number or time format to update the cooldown!", "Cooldown update error", "T5")
        return SecondsToWait
    }
    
    ; Clamp the minutes value between minCooldown and 15 minutes
    parsed.minutes := math.clamp(parsed.minutes, minCooldown, 15)
    ; Update total seconds accordingly
    parsed.seconds := Round(parsed.minutes * 60)
    
    ; Write the new values to the registry
    RegWrite(parsed.seconds, "REG_DWORD", "HKCU\Software\JACS", "SecondsToWait")
    RegWrite(parsed.minutes, "REG_DWORD", "HKCU\Software\JACS", "Cooldown")
    MinutesToWait := RegRead("HKCU\Software\JACS", "Cooldown", 15)
    SecondsToWait := RegRead("HKCU\Software\JACS", "SecondsToWait", MinutesToWait * 60)
    
    ; Optionally update the UI timer, etc.
    UpdateTimerLabel()
    
    return SecondsToWait
}

SaveMainUIPosition(*) {
    global MainUI_PosX
    global MainUI_PosY
    global MainUI
	local winState := WinGetMinMax(MainUI.Title) ; -1 = Minimized | 0 = "Neither" (I assume floating) | 1 = Maximized

	if not WinActive(MainUI.Title)
		return

    if MainUI and WinExist(MainUI.Title) {
        WinGetClientPos(&X, &Y,&W,&H, MainUI.Title)

        ; Convert to unsigned if negative before saving
        X := (X < 0) ? (0xFFFFFFFF + X + 1) : X
        Y := (Y < 0) ? (0xFFFFFFFF + Y + 1) : Y

        if MainUI_PosX != X and (X < 32000 and X > -32000) and winState != -1 {
            RegWrite(X, "REG_DWORD", "HKCU\Software\JACS", "MainUI_PosX")
            MainUI_PosX := RegReadSigned("HKCU\Software\JACS", "MainUI_PosX", A_ScreenWidth / 2)
        }

        if MainUI_PosY != Y and (Y < 32000 and Y > -32000) and winState != -1 {
            RegWrite(Y, "REG_DWORD", "HKCU\Software\JACS", "MainUI_PosY")
            MainUI_PosY := RegReadSigned("HKCU\Software\JACS", "MainUI_PosY", A_ScreenHeight / 2)
        }
    }
}

UpdateTimerLabel(*) {
	global isActive
	global MinutesToWait
	global ElapsedTimeLabel
	global CurrentElapsedTime
	global lastUpdateTime := isActive > 1 and lastUpdateTime or A_TickCount
	global SecondsToWait
	
	; Calculate and update progress bar
    secondsPassed := (A_TickCount - lastUpdateTime) / 1000  ; Convert ms to seconds

    finalProgress := (MinutesToWait == 0 and SecondsToWait == 0) and 100 or (secondsPassed / SecondsToWait) * 100
	
	; Calculate and format CurrentElapsedTime as MM:SS
    currentMinutes := Floor(secondsPassed / 60)
    currentSeconds := Round(Mod(secondsPassed, 60),0)
	
	targetSeconds := (SecondsToWait > 0) and Round(Mod(SecondsToWait, 60),0) or 0
	
	CurrentElapsedTime := Format("{:02}:{:02}", currentMinutes, currentSeconds)
	targetFormattedTime := Format("{:02}:{:02}", MinutesToWait, targetSeconds)

	local mins_suffix := SecondsToWait > 60 and " minutes" or SecondsToWait == 60 and " minute" or SecondsToWait < 60 and " seconds"
	
	try if ElapsedTimeLabel.Text != CurrentElapsedTime " / " . targetFormattedTime . " " mins_suffix
			ElapsedTimeLabel.Text := CurrentElapsedTime " / " . targetFormattedTime . " " mins_suffix
}

OpenScriptDir(*) {
	; SetWorkingDir A_InitialWorkingDir
	Run("explorer.exe " . A_ScriptDir)
}

SelectEditor(*) {
	Editor := FileSelect(2,, "Select your editor", "Programs (*.exe)")
	RegWrite Format('"{1}" "%L"', Editor), "REG_SZ", "HKCR\AutoHotkeyScript\Shell\Edit\Command"
}

CloseApp(*) {
	; SetTimer(SaveMainUIPosition,0)
	SaveMainUIPosition()
	ExitApp
}

EditApp(*) {
	Edit
}

ResetCooldown(*) {
	global CoreToggleButton
	global ElapsedTimeLabel
	global WaitProgress
	global WaitTimerLabel
	global activeText_Core
	global lastUpdateTime := A_TickCount

	activeText_Core := (isActive == 3 and "Enabled") or (isActive == 2 and "Waiting...") or "Disabled"

	if CoreToggleButton.Text != "Auto-Clicker: " activeText_Core
		CoreToggleButton.Text := "Auto-Clicker: " activeText_Core
	; CoreToggleButton.Redraw()

	if isActive == 2 and FindTargetHWND()
		ToggleCore(,3)
	else if isActive == 3 and not FindTargetHWND()
		ToggleCore(,2)

	; Reset cooldown progress bar
	UpdateTimerLabel()
	
	if isActive <= 2 or (WaitProgress and WaitProgress.Value != 0 and (MinutesToWait > 0 or SecondsToWait > 0))
		WaitProgress.Value := 0
    
	local finalText  := Round(WaitProgress.Value, 0) "%"
	if WaitTimerLabel and WaitTimerLabel.Text != finalText
		WaitTimerLabel.Text := finalText
}

switchActiveState(*) {
	global isActive
	local newMode := isActive < 3 and isActive + 1 or 1
	if newMode == 3 and not FindTargetHWND()
		newMode := 1
	return newMode
}

ToggleCore(optionalControl?, forceState?, *) {
	; Variables
	global isActive
	global FirstRun
	global activeText_Core
	global CoreToggleButton

	local newMode := forceState or switchActiveState()
	
	RegWrite(newMode, "REG_DWORD", "HKCU\Software\JACS", "isActive")
	
	isActive := RegRead("HKCU\Software\JACS", "isActive", 1)
	activeText_Core := (isActive == 3 and "Enabled") or (isActive == 2 and "Waiting...") or "Disabled"
	
	CoreToggleButton.Text := "Auto-Clicker: " activeText_Core
	CoreToggleButton.Redraw()

	; Reset cooldown
	ResetCooldown()
	
	UpdateTimerLabel()
	; Toggle Timer
	if isActive > 1
	{
		FirstRun := True
		return SetTimer(RunCore, 100)
	}
	else if isActive == 1
		return SetTimer(RunCore, 0)

	; isActive := 1
	ResetCooldown()
	SetTimer(RunCore, 0)
	return
}

ReloadScript(*) {
	SaveMainUIPosition()
	Reload
}

FindTargetHWND(*) {
	global SelectedProcessExe
	local foundWindow := WinExist("ahk_exe " SelectedProcessExe) and WinExist("ahk_exe " SelectedProcessExe) or ""
	
	if !foundWindow
		return false
	
	return foundWindow
}

RunCore(*) {
	global FirstRun
	global MainUI
	global UI_Width
	global UI_Height
	global playSounds
	global isActive
	
	global EditButton
	global ExitButton

	global ReloadButton
	global CoreToggleButton
	
	global lastUpdateTime
	global MinutesToWait
	global SecondsToWait
	global WaitProgress
	global WaitTimerLabel
	global CurrentElapsedTime

	global wasActiveWindow

	global doMouseLock

	; Check for process
	if not FindTargetHWND()
		ResetCooldown()
	; 	ToggleCore(, 2)
	
	; Check if the toggle has been switched off
	if isActive == 1
		return
	
	if (FirstRun or WaitProgress.Value >= 100) and FindTargetHWND()
	{
		; Kill FirstRun for automation
		if FirstRun
			FirstRun := False
		
		ResetCooldown()
		
		if playSounds == 1
			RunWarningSound()
		
		if isActive == 1
			return
		
		; Indicate target found with audible beep
		if playSounds == 2
			SoundBeep(2000, 70)
		
		; Get old mouse pos
		MouseGetPos(&OldPosX, &OldPosY, &windowID)
		
		local wasMinimized := False
		
		; Block Inputs
		if doMouseLock and (MinutesToWait > 0 or SecondsToWait > 0) {
			BlockInput("On")
			BlockInput("SendAndMouse")
			BlockInput("MouseMove")
		}

		;---------------
		; Find and activate processe
		local targetProcess := FindTargetHWND()
		try ClickWindow(targetProcess)
		
		; Activate previous application window & reposition mouse
		local lastActiveWindowID := ""
		try lastActiveWindowID := WinExist(windowID)

		if not wasActiveWindow and lastActiveWindowID and (MinutesToWait > 0 or SecondsToWait > 0) {
			WinActivate lastActiveWindowID
			MouseMove OldPosX, OldPosY, 0
		}

		if doMouseLock
			Sleep(25)

		; Unblock Inputs
		BlockInput("Off")
		BlockInput("Default")
		BlockInput("MouseMoveOff")

		if (MinutesToWait > 0 or SecondsToWait > 0)
			WaitProgress.Value := 0

		lastUpdateTime := A_TickCount
	}
	
	; Calculate and progress visuals
    secondsPassed := (A_TickCount - lastUpdateTime) / 1000  ; Convert ms to seconds
    finalProgress := (MinutesToWait == 0 and SecondsToWait == 0) and 100 or (secondsPassed / SecondsToWait) * 100
	UpdateTimerLabel()

    ; Update UI elements for progress
    WaitProgress.Value := finalProgress

    local finalText  := Round(WaitProgress.Value, 0) "%"
	if WaitTimerLabel and WaitTimerLabel.Text != finalText
		WaitTimerLabel.Text := finalText
}

; ################################ ;
; ###### Button Formatting ####### ;
; ################################ ;

ResizeMethod(TargetButton, optionalX, objInGroup) {
	local parentUI := TargetButton.Gui
	
	; Calculate initial control width based on GUI width and margins
	local X := 0, Y := 0, UI_Width := 0, UI_Height := 0
	local UI_Margin_Width := UI_Width-parentUI.MarginX
	
	; Get the client area dimensions
	parentUI.GetPos(&X, &Y, &UI_Width, &UI_Height)
	NewButtonWidth := (UI_Width - (2 * UI_Margin_Width))
	
	; Prevent negative button widths
	if (NewButtonWidth < UI_Margin_Width/(objInGroup or 1)) {
		NewButtonWidth := UI_Margin_Width/(objInGroup or 1)  ; Set to 0 if the width is negative
	}
	
	OldButtonPosX := 0, OldY := 0, OldWidth := 0, OldHeight := 0
	TargetButton.GetPos(&OldButtonPosX, &OldY, &OldWidth, &OldHeight)
	
	; Move
	TargetButton.Move(optionalX > 0 and 0 + (UI_Width / optionalX) or 0 + parentUI.MarginX, , )
}

MoveMethod(Target, position, size) {
	local parentUI := Target.Gui
	
	local X := 0, Y := 0, UI_Width := 0, UI_Height := 0
	local UI_Margin_Width := UI_Width-parentUI.MarginX
	
	; Calculate initial control width based on GUI width and margins
	X := 0, Y := 0, UI_Width := 0, UI_Height := 0
	
	; Get the client area dimensions
	parentUI.GetPos(&X, &Y, &UI_Width, &UI_Height)
	NewButtonWidth := (UI_Width - (2 * UI_Margin_Width))
	
	; Prevent negative button widths
	if (NewButtonWidth < UI_Margin_Width/(size or 1)) {
		NewButtonWidth := UI_Margin_Width/(size or 1)  ; Set to 0 if the width is negative
	}
	
	OldButtonPosX := 0, OldY := 0, OldWidth := 0, OldHeight := 0
	Target.GetPos(&OldButtonPosX, &OldY, &OldWidth, &OldHeight)
	
	; Resize
	Target.Move(position > 0 and 0 + (UI_Width / position) or 0 + parentUI.MarginX, , position > 0 and 0 + (UI_Width / position) or 0 + parentUI.MarginX)
}

; ################################ ;
; ############ Sounds ############ ;
; ################################ ;

RunWarningSound(*) {

	Loop 3
		{
			if isActive == 1
			break

			if playSounds == 1
				SoundBeep(1000, 80)
			else
				break

			Sleep 1000
		}
}

ToggleSound(*) {
	global playSounds
	global SoundToggleButton
	local newMode := playSounds < 3 and playSounds + 1 or 1
	RegWrite(newMode, "REG_DWORD", "HKCU\Software\JACS", "SoundMode")
	playSounds := RegRead("HKCU\Software\JACS", "SoundMode", 1)

	local activeText_Sound := (playSounds == 1 and "All") or (playSounds == 2 and "Less") or (playSounds == 3 and "None")
	
	; Setup Sound Toggle Button
	if SoundToggleButton
		SoundToggleButton.Text := "Sounds: " activeText_Sound
	
	return
}

; ################################ ;
; ####### Window Functions ####### ;
; ################################ ;

isMouseClickingOnTargetWindow(key?, override*) {
	global initializing
	if initializing
		return

	local process := FindTargetHWND()
	if not process
		return
	
	checkWindow(*) {
		MouseGetPos(&mouseX, &mouseY, &hoverWindow)
		
		if hoverWindow == process
			return ResetCooldown()
	}
	
	if override[1]
		return checkWindow()
	
	while (GetKeyState(key) == 1)
		checkWindow()
}

ClickWindow(process) {
	global wasActiveWindow := false
	global MouseSpeed
	global MouseClickRateOffset
	global MouseClickRadius
	global MouseClicks

	try wasActiveWindow := WinActive(process) and true or false

	MouseGetPos(&mouseX, &mouseY, &hoverWindow)
	local activeTitle := ""

	; Check if a window is active before calling WinGetTitle("A")
	if WinExist("A")
		try activeTitle := WinGetTitle("A")  ; Only attempt if a window exists
	
	ActivateWindow() {
		try {
			if not WinActive(process) and (MinutesToWait > 0 or SecondsToWait > 0)
				WinActivate(process)
		}
	}

	doClick(loopAmount := 1) {
		loop loopAmount {
			if activeTitle and not WinExist(activeTitle)
				break
			
			local cachedWindowID := ""
			local cachedWindowPos := ""
			local WindowX := 0, WindowY := 0, Width := 0, Height := 0
			local hoverWindow := ""
			local hoverCtrl := ""
			local mouseX := 0, mouseY := 0

			try cachedWindowID := WinGetID(process)  ; Only attempt if a window exists
			try WinGetPos(&WindowX, &WindowY, &Width, &Height, cachedWindowID)
			try MouseGetPos(&mouseX, &mouseY, &hoverWindow, &hoverCtrl)

			; Determine exact center of the active window
			CenterX := WindowX + (Width / 2)
			CenterY := WindowY + (Height / 2)

			; Generate randomized offset
			OffsetX := Random(-MouseClickRadius, MouseClickRadius)
			OffsetY := Random(-MouseClickRadius, MouseClickRadius)

			; Move mouse to the new randomized position within the area
			if (hoverWindow and (hoverWindow != cachedWindowID)) and (MinutesToWait > 0 or SecondsToWait > 0)
				MouseMove(CenterX + OffsetX, CenterY + OffsetY, (MouseSpeed == 0 and 0 or Random(0, MouseSpeed)))

			if not hoverCtrl and (hoverWindow and cachedWindowID and hoverWindow == cachedWindowID)
				Send "{Click}"

			if loopAmount > 1
				Sleep(Random(10,(MouseClickRateOffset or 10)))
		}
	}

	; Use the local variable instead of calling WinGetTitle("A") again
	if (hoverWindow and (hoverWindow != process and hoverWindow != WinGetID(process))) and activeTitle
		ActivateWindow()

	doClick(MouseClicks or 5)
}

debugNotif(msg := "1", title := "", options := "16", duration := 2) {
	SendNotification(msg, title, options, duration)
}

; ################################ ;
; ######### Math Library ######### ;
; ################################ ;

class math {
    static clamp(number, minimum, maximum) {
        return Min(Max(number, minimum), maximum)
    }
}

; ################################ ;
; ####### Extra Functions ######## ;
; ################################ ;

DownloadURL(url, filename?) {
    local oStream, req := ComObject("Msxml2.XMLHTTP")
    req.open("GET", url, true)
    req.send()
    while req.readyState != 4
        Sleep 100

    if req.status == 200 {
        oStream := ComObject("ADODB.Stream")
        oStream.Open()
        oStream.Type := 1
        oStream.Write(req.responseBody)
        oStream.SaveToFile(filename ?? StrSplit(url, "/")[-1], 2)
        oStream.Close()
    } else
        return Error("Download failed",, url)
}

KeyExists(keyPath, data) {
    try {
		RegRead(keyPath, data)

        return true
    } catch {
        return false
    }
}

checkForOldData(*) {
	local oldKey := "HKCU\Software\AFKeebus"
	local dataSets := [
		"AlwaysOnTop",
		"ClickRadius",
		"ClickRateOffset",
		"Cooldown",
		"doMouseLock",
		"isActive",
		"MouseClicks",
		"MouseSpeed",
		"SecondsToWait",
		"SoundMode"
	]

	loop reg oldKey, 'R KV' {
		if !KeyExists("HKCU\Software\JACS", A_LoopRegName) and dataSets.Has(A_LoopRegName) {
			RegWrite(RegRead(oldKey,A_LoopRegName),A_LoopRegType,A_LoopRegName)
		}
	}

	try RegDeleteKey(oldKey)
}

createDefaultSettingsData(*) {
	global SettingsExists
    
	if not SettingsExists {
        RegWrite(true, "REG_DWORD", "HKCU\Software\JACS", "Exists")
		RegWrite(false, "REG_DWORD", "HKCU\Software\JACS", "AcceptedWarning")
		RegWrite(1, "REG_DWORD", "HKCU\Software\JACS", "SoundMode")
		RegWrite(1, "REG_DWORD", "HKCU\Software\JACS", "isActive")
		RegWrite(false, "REG_DWORD", "HKCU\Software\JACS", "isInStartFolder")
		RegWrite(false, "REG_DWORD", "HKCU\Software\JACS", "isUIHidden")
		RegWrite(15, "REG_DWORD", "HKCU\Software\JACS", "Cooldown")
	}
    
	SettingsExists := RegRead("HKCU\Software\JACS", "Exists", false)
}

AutoUpdate(*) {
	global autoUpdateDontAsk
	if autoUpdateDontAsk
		return toggleAutoUpdate(false)
	
	GetUpdate()
}

toggleAutoUpdate(doUpdate){
	if not doUpdate
		return SetTimer(AutoUpdate, 0)

	return SetTimer(AutoUpdate, 10000)
}

setTrayIcon(*) {
	createDefaultDirectories()
	checkDownload(*) {
		if !FileExist(downloadedIcon)
			DownloadURL("https://raw.githubusercontent.com/WoahItsJeebus/JACS/refs/heads/main/JACS_Tray.ico", downloadedIcon)
	}
	try
		checkDownload()
	catch Error as testE {
		SendNotification("Failed to set TrayIcon: " testE.Message " | " testE.What)
	}

	if FileExist(downloadedIcon)
		TraySetIcon(downloadedIcon)
}

DeleteTrayTabs(*) {
	TabNames := [
		"&Edit Script",
		"&Window Spy",
		"&Pause Script",
		"&Suspend Hotkeys",
		"&Help",
		"&Open"
	]

	if TabNames.Length > 0
		for _,tab in TabNames
			A_TrayMenu.Delete(tab)
}

createDefaultDirectories(*) {
	if !FileExist(localScriptDir)
		DirCreate(localScriptDir)

	if !FileExist(localScriptDir "\images")
		DirCreate(localScriptDir "\images")
}

WM_SYSCOMMAND_Handler(wParam, lParam, msgNum, hwnd) {
    global MainUI, MainUI_PosX, MainUI_PosY
    ; 0xF020 (SC_MINIMIZE) indicates the user is minimizing the window.
    if (wParam = 0xF020) {
        ; Save the current (restored) position before the minimize animation starts.
        pos := WinGetMinMax(MainUI.Title) != -1 and WinGetPos(&X := MainUI_PosX,&Y := MainUI_PosY,,,MainUI.Title)
		pos := {X: X, Y: Y}

		RegWrite(pos.X, "REG_DWORD", "HKCU\Software\JACS", "MainUI_PosX")
		RegWrite(pos.Y, "REG_DWORD", "HKCU\Software\JACS", "MainUI_PosY")
        MainUI_PosX := RegReadSigned("HKCU\Software\JACS", "MainUI_PosX", A_ScreenWidth / 2)
        MainUI_PosY := RegReadSigned("HKCU\Software\JACS", "MainUI_PosY", A_ScreenHeight / 2)
    }
}

GetRandomColor(minVal := 0, maxVal := 255) {
    minVal := Max(0, Min(255, minVal)) ; Ensure min is within range
    maxVal := Max(0, Min(255, maxVal)) ; Ensure max is within range

    if (minVal > maxVal) { ; Prevents invalid range (swaps values if needed)
        temp := minVal
        minVal := maxVal
        maxVal := temp
    }

    ; Generate a bright color within the given range
    r := Random(minVal, maxVal)
    g := Random(minVal, maxVal)
    b := Random(minVal, maxVal)

    ; Ensure at least one channel is strong (prevents dark colors)
    if (r + g + b < (minVal * 3 + 50)) { ; If too dark, boost a random channel
        RandomChannel := Random(1, 3)
        if (RandomChannel = 1) 
            r := maxVal
        else if (RandomChannel = 2) 
            g := maxVal
        else 
            b := maxVal
    }

    return {R: r, G: g, B: b}
}

Lerp(start, stop, step) {
    return start + (stop - start) * (step / 100)
}

RollThankYou(*)
{
	local randomNumber := Random(1,10000)
	local OSVer := GetWinOSVersion()
	
	if randomNumber != 1 or (OSVer != "11" and OSVer != "10")
		return
	
	SendNotification("Hey! I want to thank you for using my script! It's nice to see my work getting out there and being used!", "Jeebus' Auto-Clicker Script", "16", 0)
}

SendNotification(msg := "", title := "", options := "", optionalCooldown := 0) {
	local SleepAmount := 1000 * optionalCooldown

	if title == "JACS Update Available" {
		local event := OnMessage(0x404, AHK_NOTIFYICON)
		AHK_NOTIFYICON(wParam, lParam, msg, hwnd)
		{
			if (hwnd != A_ScriptHwnd) {
				return
			}
			if (lParam = 1029) { ; Left-Clicked
				event := ""
				
				try {
					global URL_SCRIPT := "https://github.com/WoahItsJeebus/JACS/releases/latest/download/JACS.ahk"
					global tempUpdateFile := A_Temp "\temp_script.ahk"

					DownloadURL(URL_SCRIPT, tempUpdateFile)
				} catch {
					FileDelete(tempUpdateFile)
					return SendNotification("JACS update failed to download... Continuing with onboard script", "JACS Update Failed")
				}
				if tempUpdateFile
					UpdateScript(tempUpdateFile)
			}
		}
	}

	TrayTip(msg, title, options)

	if optionalCooldown == 0
		return

	if GetWinOSVersion() == "10" {
		Sleep(SleepAmount)
		HideTrayTip()
	}
	else {
		Sleep(SleepAmount)
		TrayTip
	}
}

HideTrayTip() {
    TrayTip  ; Attempt to hide it the normal way.
    if SubStr(A_OSVersion,1,3) = "10." {
        A_IconHidden := true
        Sleep 200  ; It may be necessary to adjust this sleep.
        A_IconHidden := false
    }
}

GetWinOSVersion(WindowsVersion := "") {
	Ver := 0
	static Versions := [[">=10.0.20000", "11"], [">=10.0.10000", "10"], [">=6.3", "8.1"], [">=6.2", "8"], [">=6.1", "7"], [">=6.0", "Vista"], [">=5.2", "XP"], [">=5.1", "XP"]]
	if !(WindowsVersion)
		WindowsVersion := A_OSVersion
	if (WindowsVersion = "WIN_7")
		Ver := "7"
	else if (WindowsVersion = "WIN_8.1")
		Ver := "8.1"
	else if (WindowsVersion = "WIN_VISTA")
		Ver := "Vista"
	else if (WindowsVersion = "WIN_XP")
		Ver := "XP"
	else {
		static Versions := [[">=10.0.20000", "11"], [">=10.0.10000", "10"], [">=6.3", "8.1"], [">=6.2", "8"], [">=6.1", "7"], [">=6.0", "Vista"], [">=5.2", "XP"], [">=5.1", "XP"]]
		for i, VersionData in Versions {
			if !(VerCompare(WindowsVersion, VersionData[1]))
				continue
			Ver := VersionData[2]
			break
		}
	}
	return Ver
}

LinkUseDefaultColor(CtrlObj, Use := True)
{
	LITEM := Buffer(4278, 0)                  ; 16 + (MAX_LINKID_TEXT * 2) + (L_MAX_URL_LENGTH * 2)
	NumPut("UInt", 0x03, LITEM)               ; LIF_ITEMINDEX (0x01) | LIF_STATE (0x02)
	NumPut("UInt", Use ? 0x10 : 0, LITEM, 8)  ; ? LIS_DEFAULTCOLORS : 0
	NumPut("UInt", 0x10, LITEM, 12)           ; LIS_DEFAULTCOLORS
	While DllCall("SendMessage", "Ptr", CtrlObj.Hwnd, "UInt", 0x0702, "Ptr", 0, "Ptr", LITEM, "UInt") ; LM_SETITEM
	   NumPut("Int", A_Index, LITEM, 4)
	CtrlObj.Opt("+Redraw")
}

RegReadSigned(Key, ValueName, Default) {
    Value := RegRead(Key, ValueName, Default)  ; Read value from the registry

    if (Value > 0x7FFFFFFF) {  ; If it's an incorrectly stored unsigned 32-bit integer
        Value := -(0xFFFFFFFF - Value + 1)  ; Convert it to a signed 32-bit integer
    }

    return Value
}

RegWriteSigned(Key, ValueName, Value) {
    ; If the value is negative, convert it to its unsigned 32-bit equivalent
    if (Value < 0)
        Value := 0x100000000 + Value  ; 0x100000000 is 2^32

    ; Write the (now unsigned) value to the registry
    RegWrite(Key, ValueName, Value)
}

ToggleHide_Hotkey(*) {
	global isUIHidden
	if isUIHidden == ""
		return

	ToggleHideUI(not isUIHidden)
	updateUIVisibility()
}

GetRefreshRate_Alt() {
    hdc := DllCall("GetDC", "Ptr", 0, "Ptr") ; Get Device Context Handle
    RF := DllCall("GetDeviceCaps", "Ptr", hdc, "Int", 116) ; VREFRESH index = 116
    DllCall("ReleaseDC", "Ptr", 0, "Ptr", hdc) ; ReleaseDC for cleanup
    return RF
}

ColorizeCredits(creditsLinkCtrl) { 
    if not creditsLinkCtrl
        return

    global Credits_CurrentColor
    global Credits_TargetColor
    global Credits_ColorChangeRate

    ; Store old color before interpolation to prevent unnecessary updates
    local oldColor := Credits_CurrentColor.Clone()

    ; Interpolate each RGB channel
    Credits_CurrentColor.R := Lerp(Credits_CurrentColor.R, Credits_TargetColor.R, Credits_ColorChangeRate)
    Credits_CurrentColor.G := Lerp(Credits_CurrentColor.G, Credits_TargetColor.G, Credits_ColorChangeRate)
    Credits_CurrentColor.B := Lerp(Credits_CurrentColor.B, Credits_TargetColor.B, Credits_ColorChangeRate)

    ; Only update if color changed significantly
    if (Round(oldColor.R) != Round(Credits_CurrentColor.R) || Round(oldColor.G) != Round(Credits_CurrentColor.G) || Round(oldColor.B) != Round(Credits_CurrentColor.B)) {
        newColor := Format("c{:02}{:02}{:02}", Round(Credits_CurrentColor.R), Round(Credits_CurrentColor.G), Round(Credits_CurrentColor.B))
        creditsLinkCtrl.Opt(newColor) ; Correct AHK v2 way to update the control
    }

    ; Check if transition is complete, then set a new target color
    if (Round(Credits_CurrentColor.R) = Credits_TargetColor.R && Round(Credits_CurrentColor.G) = Credits_TargetColor.G && Round(Credits_CurrentColor.B) = Credits_TargetColor.B) {
        Credits_TargetColor := {R: Random(10, 99), G: Random(10, 99), B: Random(10, 99)}
    }
}

; Evaluate expressions in concatenated strings
Eval(expr) {
    return %expr%
}

ParseColonFormat(input) {
    local parts := StrSplit(Trim(input), ":")
    if (parts.Length < 2)
        return Error("Invalid colon format. Expected at least two parts separated by ':'.")
    
    local minutes := parts[1]   ; Convert the string to a number
    local seconds := parts[2]   ; Convert the string to a number
    local totalMinutes := minutes + seconds / 60
	
    return { minutes: totalMinutes, seconds: Round(totalMinutes * 60) }
}

ParseLetterFormat(input) {
    local pos := 1
    local minutes := 0.0
    local seconds := 0.0
    ; Use a case-insensitive pattern that matches a number (integer or float) followed by
    ; optional spaces and then either "m" or "s".
    local pattern := "i)(\d+(?:\.\d+)?)[ ]*([ms])"
    local m := {}  ; This will hold the match object
	
    while pos <= StrLen(input) {
        if !RegExMatch(input, pattern, &m, pos)
            break
        local num := m[1]
        local unit := m[2]
        if (unit = "m" or unit = "M")
            minutes += num
        else if (unit = "s" or unit = "S")
            seconds += num
        pos := m.Pos + StrLen(num)
    }
    local totalMinutes := minutes + seconds / 60
    return { minutes: totalMinutes, seconds: Round(totalMinutes * 60) }
}

; ################################# ;
; ########## Patchnotes ########### ;
; ################################# ;

GetGitHubReleaseInfo(owner, repo, release:="latest") {
    req := ComObject("Msxml2.XMLHTTP")
    req.open("GET", (release != "latest" and "https://api.github.com/repos/" owner "/" repo "/releases/tags/" release) or "https://api.github.com/repos/" owner "/" repo "/releases/latest", false)
    req.send()

    if req.status != 200
        Error(req.status " - " req.statusText, -1)

    res := JSON_parse(req.responseText)

    try {
        return Map( 
            "title", res.name,     ; The release title (name)
            "tag", res.tag_name,   ; The release version/tag
            "body", StripMarkdown(res.body)       ; The release body
        )
    }
    catch PropertyError {
        (Error(res.message, -1))
    }
}

GetGitHubReleaseTags(owner, repo) {
    ; repo should be something like "username/repo"
    url := "https://api.github.com/repos/" owner "/" repo "/releases"
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("GET", url, false)
    http.Send()
    jsonStr := http.ResponseText
    tags := []
    pos := 1
    ; Extract tag_name values directly from the JSON string.
    while RegExMatch(jsonStr, '"tag_name"\s*:\s*"([^"]+)"', &m, pos) {
        tag := m[1]
        if RegExMatch(tag, "^\d+(\.\d+)*$")  ; only accept version-like tags
            tags.Push(tag)
        pos := m.Pos + m.Len
    }
    return tags
}

ShowPatchNotesGUI(release := "latest") {
    owner := "WoahItsJeebus"
    repo := "JACS"
    versionTags := GetGitHubReleaseTags(owner, repo)

	global AlwaysOnTopActive
	global MainUI_PosX
	global MainUI_PosY
	global PatchUI
	global ExtrasUI

	local Popout_Width := "700"
	local Popout_Height := "400"
	local AOTStatus := AlwaysOnTopActive == true and "+AlwaysOnTop" or "-AlwaysOnTop"
	local AOT_Text := (AlwaysOnTopActive == true and "On") or "Off"
	githubResponse := GetGitHubReleaseInfo("WoahItsJeebus", repo, "latest")
	patchNotes := githubResponse
	try if patchNotes["title"] and patchNotes["body"]
		patchNotes := Map(
			"title", "Error",
			"body", "Error"
		)
	catch Error as e
		patchNotes := Map(
			"title", "Error",
			"body", "Error"
		)

    ; Create GUI Window
	if PatchUI
		PatchUI.Destroy()

	PatchUI := Gui(AOTStatus)
	if ExtrasUI
		PatchUI.Opt("+Owner" . ExtrasUI.Hwnd)

	PatchUI.BackColor := intWindowColor
	PatchUI.Title := "Patchnotes"
	
	local PatchnotesLabel := PatchUI.Add("Text", "Section Center vPatchnotesLabel h40 w" (Popout_Width-PatchUI.MarginX), "Patchnotes: " patchNotes["title"])
	PatchnotesLabel.SetFont("s20 w600", "Consolas")
	PatchnotesLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	PatchNotesLabel.GetPos(,,&LabelWidth,&LabelHeight)

	local VersionList := PatchUI.Add("DropDownList", "xm Section Center vVersionList R10 h60 w" (Popout_Width-PatchUI.MarginX)/2.5, ["latest"])
	VersionList.SetFont("s12", "Consolas")
	VersionList.Opt("Background" intWindowColor . " c" ControlTextColor)
	VersionList.Value := 1
	VersionList.Move((Popout_Width/3) - PatchUI.MarginX)
	VersionList.GetPos(,,&LabelWidth,&ListHeight)
	VersionList.OnEvent("Change", SelectNewOption)
	local addedHeight := LabelHeight + ListHeight

	SelectNewOption(*) {
		githubResponse := GetGitHubReleaseInfo("WoahItsJeebus", repo, VersionList.Text)
		patchNotes := githubResponse
		
		if BodyBox {
			BodyBox.Text := patchNotes["body"]
			PatchnotesLabel.Text := "Patchnotes: " patchNotes["title"]
		}
	}

	if versionTags.Length > 0
		for index, tag in versionTags {
			VersionList.Add([tag])
			; option.SetFont("s10 w300", "Consolas")
			; option.Opt("Background" intWindowColor . " c" ControlTextColor)
		}

	PatchUI.Show("Hide")

	local BodyBox := PatchUI.Add("Edit", "xs y+20 vPatchnotes VScroll Section ReadOnly h" (Popout_Height-PatchUI.MarginY) - addedHeight " w" Popout_Width-PatchUI.MarginX, patchNotes["body"])
	BodyBox.SetFont("s14 w600", "Consolas")
	BodyBox.Opt("Background555555" . " c" ControlTextColor)

	; Calculate center position
	PatchUI.Show("AutoSize")

	WinGetClientPos(&MainX, &MainY, &MainW, &MainH, MainUI.Title)
	WinGetPos(,,&patchUI_width,&patchUI_height, PatchUI.Title)

	CenterX := MainX + (MainW / 2) - (patchUI_width / 2)
	CenterY := MainY + (MainH / 2) - (patchUI_height / 2)
	PatchUI.Show("X" CenterX " Y" CenterY)
}

JSON_parse(str) {
	htmlfile := ComObject("htmlfile")
	htmlfile.write('<meta http-equiv="X-UA-Compatible" content="IE=edge">')
	return htmlfile.parentWindow.JSON.parse(str)
}

StripMarkdown(text) {
    ; Remove specific HTML tags like <ins>, <del>, <mark>
    text := RegExReplace(text, "(?i)<(ins|del|mark)>(.*?)<\/\1>", "$2")

    ; Convert Markdown-style hyperlinks [text](url) → text
    text := RegExReplace(text, "\[(.*?)\]\(.*?\)", "$1")

    ; Remove Markdown-style headings (e.g. # Heading)
    text := RegExReplace(text, "(?m)^#+\s*", "")

    ; Handle bold (**bold** or __bold__)
    text := RegExReplace(text, "(\*\*|__)(.*?)\1", "$2")

    ; Handle italics with asterisk or underscore, but avoid bold conflicts
    text := RegExReplace(text, "(?<!\*)\*(?!\*)(.*?)\*(?!\*)", "$1") ; *italic*
    text := RegExReplace(text, "(?<!_)_(?!_)(.*?)_(?!_)", "$1")      ; _italic_

	; Inline code using backticks → 'code'
	text := RegExReplace(text, "``+(.*?)``+", "'$1'")

    ; Strikethrough ~~text~~ → [text]
    text := RegExReplace(text, "~~(.*?)~~", "[$1]")

    ; Remove blockquote markers
    text := RegExReplace(text, "(?m)^\s*>\s?", "")

    ; Convert list markers (- item) to bullets
    text := RegExReplace(text, "(?m)^\s*-\s*", "• ")

    ; Remove any remaining raw URLs (after markdown links are handled)
    text := RegExReplace(text, "https?://[^\s\)]+", "")

    return text
}

CheckScriptExists(url) {
	try {
		; Create a COM object for an HTTP request.
		http := ComObject("MSXML2.XMLHTTP")
		; Use HEAD method to avoid downloading the full file.
		http.Open("HEAD", url, false)
		http.Send()
		status := http.Status
		; Return true if the status is 200 (OK), false otherwise.
		return (status = 200)
	} catch
		return false
}

; ############################## ;
; ########## Hotkeys ########### ;
; ############################## ;

global Keys := Map()

Keys["~W"] := Map()
Keys["~W"]["Function"] := isMouseClickingOnTargetWindow.Bind("W", false)

Keys["~W"] := Map()
Keys["~W"]["Function"] := isMouseClickingOnTargetWindow.Bind("W", false)

Keys["~A"] := Map()
Keys["~A"]["Function"] := isMouseClickingOnTargetWindow.Bind("A", false)

Keys["~S"] := Map()
Keys["~S"]["Function"] := isMouseClickingOnTargetWindow.Bind("S", false)

Keys["~D"] := Map()
Keys["~D"]["Function"] := isMouseClickingOnTargetWindow.Bind("D", false)

Keys["~Space"] := Map()
Keys["~Space"]["Function"] := isMouseClickingOnTargetWindow.Bind("Space", false)

Keys["~Left"] := Map()
Keys["~Left"]["Function"] := isMouseClickingOnTargetWindow.Bind("Left", false)

Keys["~Right"] := Map()
Keys["~Right"]["Function"] := isMouseClickingOnTargetWindow.Bind("Right", false)

Keys["~Up"] := Map()
Keys["~Up"]["Function"] := isMouseClickingOnTargetWindow.Bind("Up", false)

Keys["~Down"] := Map()
Keys["~Down"]["Function"] := isMouseClickingOnTargetWindow.Bind("Down", false)

Keys["~/"] := Map()
Keys["~/"]["Function"] := isMouseClickingOnTargetWindow.Bind("/", false)

Keys["~LButton"] := Map()
Keys["~LButton"]["Function"] := isMouseClickingOnTargetWindow.Bind("LButton", false)

Keys["~RButton"] := Map()
Keys["~RButton"]["Function"] := isMouseClickingOnTargetWindow.Bind("RButton", false)

Keys["~WheelUp"] := Map()
Keys["~WheelUp"]["Function"] := isMouseClickingOnTargetWindow.Bind("WheelUp", true)

Keys["~WheelDown"] := Map()
Keys["~WheelDown"]["Function"] := isMouseClickingOnTargetWindow.Bind("WheelDown", true)

Keys["~!BackSpace"] := Map()
Keys["~!BackSpace"]["Function"] := ToggleHide_Hotkey.Bind()

Keys["~!\"] := Map()
Keys["~!\"]["Function"] := cooldownFailsafe.Bind()

cooldownFailsafe(*) {
	ToggleCore(,1)
}

enableAllHotkeys(*) {
	for keyName, data in Keys
		enableHotkey(keyName, data["Function"])
}

disableAllHotkeys(*) {
	for keyName, data in Keys
		disableHotkey(keyName, data["Function"])
}

disableHotkey(keyName?, bind?) {
	try Hotkey(keyName,, "Off")
}

enableHotkey(keyName?, bind?) {
	Hotkey(keyName, bind, "On")
}

enableAllHotkeys()