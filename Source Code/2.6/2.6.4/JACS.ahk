#Requires AutoHotkey >=2.0.19 64-bit
#SingleInstance Force

global initializing := true
global version := "2.6.4"

CoordMode("Mouse", "Screen")
CoordMode("Menu", "Screen")
SetTitleMatchMode 2
DetectHiddenWindows(true)
A_HotkeyInterval := 0
A_MaxHotkeysPerInterval := 1000
global A_LocalAppData := EnvGet("LOCALAPPDATA")
global localScriptDir := A_LocalAppData "\JACS\"
global ProfilesDir := localScriptDir "Profiles.ini"

global IconsFolder := localScriptDir "images\icons\"
global ActiveIcon := localScriptDir "images\icons\Active.ico"
global InactiveIcon := localScriptDir "images\icons\Inactive.ico"
global SearchingIcon := localScriptDir "images\icons\Searching.ico"
global initializingIcon := localScriptDir "images\icons\Initializing.ico"

global doDebug := true
global debugKey := "^F12"

if doDebug {
	Hotkey(debugKey, ReloadScript, "On")
}

sidebarData := [
	{
		Icon: "🪟",
		Tooltip: "Window Settings",
		Function: CreateWindowSettingsGUI.Bind()
	},
	{
		Icon: "🖱",
		Tooltip: "Clicker Settings",
		Function: CreateClickerSettingsGUI.Bind()
	},
	{
		Icon: "📜",
		Tooltip: "Script Settings",
		Function: CreateScriptSettingsGUI.Bind()
	},
	{
		Icon: "✚",
		Tooltip: "Extras",
		Function: CreateExtrasGUI.Bind()
	}
]

icons := [
	{
		Icon: InactiveIcon,
		URL: "https://raw.githubusercontent.com/WoahItsJeebus/JACS/refs/heads/main/icons/Inactive.ico"
	},
	{
		Icon: SearchingIcon,
		URL: "https://raw.githubusercontent.com/WoahItsJeebus/JACS/refs/heads/main/icons/Searching.ico"
	},
	{
		Icon: ActiveIcon,
		URL: "https://raw.githubusercontent.com/WoahItsJeebus/JACS/refs/heads/main/icons/Active.ico"
	},
	{
		Icon: initializingIcon,
		URL: "https://raw.githubusercontent.com/WoahItsJeebus/JACS/refs/heads/main/icons/Initializing.ico"
	}
]

;"HideGUIHotkey"

global ICON_SPACING  := 20
global ICON_WIDTH    := 40
global BUTTON_HEIGHT := 40
global HeaderHeight := 30

global SelectedProcessExe := GetSelectedProcessName()
global URL_SCRIPT := "https://github.com/WoahItsJeebus/JACS/releases/latest/download/JACS.ahk"
global currentIcon := icons[4].Icon
setTrayIcon(currentIcon)
createDefaultSettingsData()
createDefaultDirectories()

global SettingsExists := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SettingsExists", false, "bool")
global MinutesToWait := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MinutesToWait", 15, "int")
global SecondsToWait := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SecondsToWait", MinutesToWait * 60, "int")
global minCooldown := 0
global lastUpdateTime := A_TickCount
global CurrentElapsedTime := 0
global playSounds := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SoundMode", 1, "int")
global isInStartFolder := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "IsInStartFolder", false, "bool")

global isActive := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "isActive", 1, "int") ; 1 = Disabled, 2 = Waiting, 3 = Enabled
global autoUpdateDontAsk := false
global FirstRun := True
global hwnd := ""
; global currentHotkey := ReadHotkeyFromRegistry()
; RegisterHotkey(currentHotkey)

; MainUI Data
global MainUI := ""
global ExtrasUI := ""

global monitorNum := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MonitorNum", 1, "int")

; Check if the monitor exists
monitorCount := MonitorGetCount()
if (monitorNum > monitorCount) {
    posX := A_ScreenWidth / 2
    posY := A_ScreenHeight / 2
}

global MainUI_PosX := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosX", A_ScreenWidth / 2)
global MainUI_PosY := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosY", A_ScreenHeight / 2)
global MainUI_Monitor := monitorNum

global isUIHidden := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "isUIHidden", false, "bool")
global MainUI_Disabled := false

global UI_Width := "400"
global UI_Height := "300"

global tips := []  ; Will be populated from tips.ahk or defaults if it fails

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
global AlwaysOnTopActive := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "AlwaysOnTop", false, "bool")

; Extra Menus
global PatchUI := ""
global WindowSettingsUI := ""
global ScriptSettingsUI := ""
global SettingsUI := ""
global MouseSpeed := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MouseSpeed", 1, "int")
global MouseClickRateOffset := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MouseClickRateOffset", 0, "int")
global MouseClickRadius := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MouseClickRadius", 0, "int")
global doMouseLock := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "doMouseLock", false, "bool")
global MouseClicks := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MouseClicks", 5, "int")

; Extras Menu
global ShowingExtrasUI := false 
global warningRequested := false

; Light/Dark mode colors
global updateTheme := true

; global blnLightMode := RegRead("HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize", "AppsUseLightTheme")
global intWindowColor := "404040"
global intControlColor := "606060"
global intProgressBarColor := "757575"
global ControlTextColor := "FFFFFF"
global linkColor := "99c3ff"
global currentTheme := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SelectedTheme", "Dark Mode")
global lastTheme := currentTheme

global wasActiveWindow := false

global ControlResize := (Target, position, size) => ResizeMethod(Target, position, size)
global MoveControl := (Target, position, size) => MoveMethod(Target, position, size)
global AcceptedWarning := readIniProfileSetting(ProfilesDir, "General", "AcceptedWarning", false, "bool") and CreateGui() or createWarningUI()
global tempUpdateFile := ""

; ================= Screen Info =================== ;
global refreshRate := GetRefreshRate_Alt() or 60

global Credits_CurrentColor := GetRandomColor(200, 255)
global Credits_TargetColor := GetRandomColor(200, 255)
global Credits_ColorChangeRate := 5 ; (higher = faster)

; Keys
global KeyToSend := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "KeyToSend", "~LButton")

OnExit(EndScriptProcess)

OnMessage(0x0112, WM_SYSCOMMAND_Handler)
DeleteTrayTabs()

A_TrayMenu.Insert("&Reload Script", "Fix GUI", MenuHandler)  ; Creates a new menu item.
Persistent

GetUpdate()

MenuHandler(ItemName, ItemPos, MyMenu) {
	global MainUI_PosX
	global MainUI_PosY
	global isUIHidden
	global SelectedProcessExe

	local VDisplay_Width := SysGet(78) ; SM_CXVIRTUALSCREEN
	local VDisplay_Height := SysGet(79) ; SM_CYVIRTUALSCREEN

	updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosX", MainUI_PosX)
	updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosY", MainUI_PosY)

	MainUI_PosX := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosX", VDisplay_Width / 2, "int")
	MainUI_PosY := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosY", VDisplay_Height / 2, "int")

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
    }
	else if IsVersionNewer(version, latestVersion) == "Updated" {
		autoUpdateDontAsk := false
		SetTimer(AutoUpdate, 0)
	}

	RollThankYou()
}

UpdateScript(targetFile := tempUpdateFile) {
	try FileMove(targetFile, A_ScriptFullPath, 1) ; Overwrite current script
	catch
		try FileMove(targetFile, A_ScriptFullPath)
	
	Reload
}

; ================================================= ;

createWarningUI(requested := false) {
	global ExtrasUI
	global ProfilesDir
	if ExtrasUI {
		ExtrasUI.Destroy()
		ExtrasUI := ""
	}

	local accepted := readIniProfileSetting(ProfilesDir, "General", "AcceptedWarning", false, "bool")
	if accepted and not requested {
		if MainUI_Warning
			MainUI_Warning.Destroy()
			MainUI_Warning := ""
		if not MainUI
			return CreateGui()
		return
	}

	; Global Variables
	global AlwaysOnTopActive
	local AOTStatus := AlwaysOnTopActive == true and "+AlwaysOnTop" or "-AlwaysOnTop"
	local AOT_Text := (AlwaysOnTopActive == true and "On") or "Off"

	global ExtrasUI
	global MainUI_Warning := Gui(AOTStatus)
	UpdateGuiIcon(icons[4].Icon)
	MainUI_Warning.BackColor := intWindowColor

	; Local Variables
	local UI_Width_Warning := "1200"
	local UI_Height_Warning := "100"

	; Colors
	global intWindowColor
	global intControlColor
	global intProgressBarColor
	global ControlTextColor
	global linkColor

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
			updateIniProfileSetting(ProfilesDir, "General", "AcceptedWarning", true)
			accepted := readIniProfileSetting(ProfilesDir, "General", "AcceptedWarning", false, "bool")
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
	global UI_Width
	global UI_Height
	
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
	; global OpenExtrasLabel

	global MoveControl
	global ControlResize

	global initializing
	global refreshRate

	; Colors
	global intWindowColor
	global intControlColor
	global intProgressBarColor
	global ControlTextColor
	global linkColor

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
	global hwnd := MainUI.Hwnd
	MainUI.BackColor := intWindowColor
	MainUI.OnEvent("Close", CloseApp)
	MainUI.Title := "Jeebus' Auto-Clicker"
	MainUI.SetFont("s14 w500", "Courier New")

	local UI_Margin_Width := UI_Width-MainUI.MarginX
	local UI_Margin_Height := UI_Height-MainUI.MarginY
	
	global TipsDisplayed := []     ; Recently used indexes
	global TipTimer := ""          ; Controls when a new tip is picked
	global ScrollTimer := ""       ; Controls horizontal scroll updates
	global TipScrollData := Map()  ; Keeps track of label & offset per GUI
	global tipHeight := 20         ; Height of the tip box
	global tips
	
	local dummy := MainUI.Add("Text", "Section w" UI_Margin_Width " h" tipHeight " 0x200 BackgroundTrans")  ; dummy container
	
	AddTipBox() {
		tipBox := MainUI.Add("Text", "w" UI_Margin_Width " h" tipHeight " BackgroundTrans vTipBox", "")
		tipBox.SetFont("s" tipHeight/2 " w550 Italic", "Consolas")
	
		TipScrollData[MainUI] := Map(
			"Ctrl", tipBox,
			"Offset", 10,
			"CurrentText", "",
			"TipList", tips,  ; ← Uses dynamic global list
			"LastIndexes", []
		)
	
		LoadNewTip()
	}

	LoadTipsFromAHKFile() {
		global tips := []
	
		local file := A_LocalAppData "\JACS\tips.ahk"
		if !FileExist(file)
			return
	
		local text := FileRead(file)
		local m := "", tipMatch := ""
	
		; Try to find the tips := [ ... ] block
		if RegExMatch(text, "s)tips\s*:=\s*\[\s*(.*?)\s*\]", &m) {
			rawList := m[1]  ; capture group 1 — the content inside [ ... ]
			lines := StrSplit(rawList, "`n", "`r")
			for line in lines {
				line := Trim(line)
				; Match quoted string tips like "Tip here",
				if RegExMatch(line, 's)^`"(.*?)`"', &tipMatch)
					tips.Push(tipMatch[1])
			}
		}
	}	
	
	UpdateTipsFile(*) {
		url := "https://raw.githubusercontent.com/WoahItsJeebus/JACS/main/Utilities/InfoBarMap.ahk"
		localPath := A_LocalAppData "\JACS\tips.ahk"
		try {
			DownloadURL(url, localPath)
			LoadTipsFromAHKFile()
			UpdateAllTipBoxes()
		} catch as e {
			LoadTipsFromAHKFile()
			UpdateAllTipBoxes()
		}
	}
	
	UpdateAllTipBoxes() {
		global TipScrollData, tips
	
		for hwnd, data in TipScrollData {
			data["TipList"] := tips
			data["LastIndexes"] := []
		}
	}
	
	LoadNewTip() {
		global initializing
		if initializing
			return
		UpdateTipsFile()
		global tips, tipHeight
		data := TipScrollData[MainUI]
		
		tips := data["TipList"]
		lastIndexes := data["LastIndexes"]
		
		if tips.Length = 0 {
			data["Ctrl"].Text := "No tips available."
			data["CurrentText"] := "No tips available."
			data["Offset"] := UI_Width + 100
			
			width := MeasureTextWidth(data["Ctrl"], "No tips available.")
			data["Ctrl"].Move(UI_Width + 100,10, width, tipHeight)
			return
		}

		maxHistory := Max(1, Round(tips.Length * 0.33))
		candidates := []
	
		for index, tip in tips {
			if !ArrayHasValue(lastIndexes, tip)
				candidates.Push({index: index, tip: tip})
		}
		
		if candidates.Length = 0 {
			lastIndexes := []
			for index, tip in tips
				candidates.Push({index: index, tip: tip})
		}
		
		; Pick a random tip from candidates that wasn't used recently
		pickRandomCandidate() {
			; 
		}
		choice := candidates[Random(1, candidates.Length)]
		text := choice.tip
		
		data["Ctrl"].Text := text
		data["CurrentText"] := text
		data["Offset"] := UI_Width + 100
		
		width := MeasureTextWidth(data["Ctrl"], text)
		data["Ctrl"].Move(UI_Width + 100,10, width, tipHeight)

		lastIndexes.Push(choice.tip)
		if lastIndexes.Length > maxHistory
			lastIndexes.RemoveAt(1)
		data["LastIndexes"] := lastIndexes
	}
	
	ScrollTip() {
		global initializing
		if initializing
			return

		data := TipScrollData[MainUI]
		ctrl := data["Ctrl"]
		text := data["CurrentText"]
		offset := data["Offset"]

		; Move leftward
		offset -= 1
		ctrl.Move(offset, , ,)

		; When it fully scrolls off screen, reset position

		if offset < -(UI_Width) - 100 {
			Sleep(Random(30000, 90000))
			return LoadNewTip()
		}
		else
			data["Offset"] := offset
	}
	
	createMainButtons()
	createSideBar()

	; LinkUseDefaultColor(VersionHyperlink)
	
	; Update ElapsedTimeLabel with the formatted time and total wait time in minutes
    UpdateTimerLabel()

	; ###################################################################### ;
	; #################### UI Formatting and Visibility #################### ;
	; ###################################################################### ;
	
	; ToggleHideUI(false)
	refreshRate := GetRefreshRate_Alt() or 60
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
			"Interval", 100,
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
		),
		"ScrollTip", Map(
			"Function", ScrollTip.Bind(),
			"Interval", refreshRate * 0.215,
			"Disabled", false
		),
	)
	
	
	; ApplyThemeToGui(MainUI, DarkTheme)
	setTrayIcon(icons[isActive].Icon)

	CheckDeviceTheme()
	AddTipBox()

	; Run loop functions
	for FuncName, Data in loopFunctions
		if not Data["Disabled"] {
			if FuncName == "ScrollTip"
				Sleep(100)
			SetTimer(Data["Function"], Data["Interval"])
		}
	
	; debugNotif(refreshRate = 0 ? "Failed to retrieve refresh rate" : "Refresh Rate: " refreshRate " Hz",,,5)
	
	initializing := false
}

; Create the main buttons and controls
createMainButtons(*) {
	global MainUI, intWindowColor, intControlColor, ControlTextColor, linkColor, ProfilesDir
	global UI_Width, UI_Height, ICON_WIDTH, ICON_SPACING, BUTTON_HEIGHT, HeaderHeight
	local UI_Margin_Width := UI_Width-MainUI.MarginX
	local UI_Margin_Height := UI_Height-MainUI.MarginY

	local Header := MainUI.Add("Text","x" ICON_WIDTH " y+" UI_Height*0.001 " Section Center vMainHeader cff4840 h" HeaderHeight " w" UI_Width,"Jeebus' Auto-Clicker — V" version)
	Header.SetFont("s18 w600", "Ink Free")

	; ########################
	; 		  Buttons
	; ########################
	; local activeText_Core := isActive and "Enabled" or "Disabled"
	global activeText_Core := (isActive == 3 and "Enabled") or (isActive == 2 and "Waiting...") or "Disabled"
	global CoreToggleButton := MainUI.Add("Button", "xs+" ICON_WIDTH + UI_Width/6 " h30 w" (UI_Margin_Width*0.75)-ICON_WIDTH, "Auto-Clicker: " activeText_Core)
	CoreToggleButton.OnEvent("Click", ToggleCore)
	CoreToggleButton.Opt("Background" intWindowColor)
	; CoreToggleButton.Move(UI_Width-((UI_Margin_Width * 0.6) + ICON_WIDTH))
	CoreToggleButton.SetFont("s12 w500", "Consolas")

	; ##############################
	
	; Calculate initial control width based on GUI width and margins
	InitialWidth := UI_Width - (2 * UI_Margin_Width)
	;X := 0, Y := 0, UI_Width := 0, UI_Height := 0
	
	; Get the client area dimensions
	NewButtonWidth := (UI_Width - (2 * UI_Margin_Width)) / 3
	
	local pixelSpacing := 5

	; ###############################
	
	; Reset Cooldown
	global ResetCooldownButton := MainUI.Add("Button", "x" (ICON_WIDTH*2) + UI_Margin_Width*0.375 " h30 w" UI_Margin_Width/4, "Reset")
	ResetCooldownButton.OnEvent("Click", ResetCooldown)
	ResetCooldownButton.SetFont("s12 w500", "Consolas")
	ResetCooldownButton.Opt("Background" intWindowColor)

	SeparationLine := MainUI.Add("Text", "x" ICON_WIDTH*2 " 0x7 h1 w" UI_Margin_Width) ; Separation Space
	SeparationLine.BackColor := "0x8"
	
	; Progress Bar
	global WaitTimerLabel := MainUI.Add("Text", "x" ICON_WIDTH*2 " Center 0x300 0xC00 h20 w" UI_Margin_Width, "0%")
	global WaitProgress := MainUI.Add("Progress", "x" ICON_WIDTH*2 " Center h40 w" UI_Margin_Width)
	global ElapsedTimeLabel := MainUI.Add("Text", "x" ICON_WIDTH*2 " Center 0x300 0xC00 h20 w" UI_Margin_Width, "00:00 / 0 min")
	ElapsedTimeLabel.SetFont("s18 w500", "Consolas")
	WaitTimerLabel.SetFont("s18 w500", "Consolas")
	
	WaitTimerLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	ElapsedTimeLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	WaitProgress.Opt("Background" intProgressBarColor)

	; Credits
	global CreditsLink := MainUI.Add("Link","c" linkColor . " Left h20 w" UI_Margin_Width, 'Created by <a href="https://www.roblox.com/users/3817884/profile">@WoahItsJeebus</a>')
	CreditsLink.SetFont("s12 w700", "Ink Free")
	CreditsLink.Opt("c" linkColor)
	; Move credits link to bottom of UI_Height
	CreditsLink.Move(ICON_WIDTH*2, UI_Height + (MainUI.MarginY - 20))
	LinkUseDefaultColor(CreditsLink)

	; Version
	; OpenExtrasLabel := MainUI.Add("Button", "x+120 Section Center 0x300 0xC00 h30 w" UI_Margin_Width/4, "Extras")
	; OpenExtrasLabel.SetFont("s12 w500", "Consolas")
	; OpenExtrasLabel.Opt("Background" intWindowColor)
	; OpenExtrasLabel.OnEvent("Click", CreateExtrasGUI)
}

createSideBar(*) {
	global MainUI, intWindowColor, UI_Height, ProfilesDir

	global ICON_SPACING, ICON_WIDTH, BUTTON_HEIGHT, HeaderHeight, tipHeight

	if not MainUI
		return

	; Sidebar background
	local sidebarBackground := MainUI.Add("Text","Section vSideBarBackground w" ICON_WIDTH " h" UI_Height-HeaderHeight-tipHeight " Background" intWindowColor)
	
	; Store buttons and tooltip data for hover tracking
	global iconButtons := []

	for idx, icon in sidebarData {
		y := ((idx - 1) * (BUTTON_HEIGHT + ICON_SPACING)) + ICON_SPACING + HeaderHeight + tipHeight + 10
		btn := MainUI.Add("Button", "xs-" ICON_WIDTH*1.5 " y" y " vIconButton" . idx . " w" ICON_WIDTH " h" BUTTON_HEIGHT " Background" intWindowColor, icon.Icon)
		
		btn.OnEvent("Click", icon.Function)  ; Assign specific function
		iconButtons.Push({control: btn, tooltip: icon.Tooltip})
	}

	sidebarBackground.Visible := false

	; Tooltip hover tracker
	global currentTooltipIndex := 0
	SetTimer(CheckSidebarHover, 100)
}

CheckSidebarHover() {
	global iconButtons, currentTooltipIndex, ProfilesDir

	MouseGetPos &mx, &my, &winHwnd, &ctrlHwnd, 2

	for idx, btnData in iconButtons {
		if ctrlHwnd = btnData.control.Hwnd {
			if currentTooltipIndex != idx {
				ToolTip(btnData.tooltip)
				currentTooltipIndex := idx
			}
			return
		}
	}

	if currentTooltipIndex != 0 {
		ToolTip()
		currentTooltipIndex := 0
	}
}

ClampMainUIPos(*) {
	global MainUI
	global isUIHidden
	global MainUI_PosX
	global MainUI_PosY
	global ProfilesDir

	local VDisplay_Width := SysGet(78) ; SM_CXVIRTUALSCREEN
	local VDisplay_Height := SysGet(79) ; SM_CYVIRTUALSCREEN
	
	WinGetPos(,, &W, &H, MainUI.Title)
	local X := MainUI_PosX + (W / 2)
	local Y := MainUI_PosY + (H / 2)
	local winState := MainUI != "" and WinGetMinMax(MainUI.Title) or "" ; -1 = Minimized | 0 = "Neither" (I assume floating) | 1 = Maximized
	if winState == -1 or winState == ""
		return

	if X > VDisplay_Width or X < -VDisplay_Width {
		updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosX", VDisplay_Width / 2)
		MainUI_PosX := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosX", VDisplay_Width / 2, "int")
		
		if MainUI and not isUIHidden and winState != -1
			MainUI.Show("X" . MainUI_PosX . " Y" . MainUI_PosY . " AutoSize")
	}

	if Y > VDisplay_Height or Y < (-VDisplay_Height*2) {
		updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosY", VDisplay_Height / 2)
		MainUI_PosY := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosY", VDisplay_Height / 2, "int")

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
	
	local buttonHeight := 23
	local buttonFontSize := 10
	local buttonFontWeight := 500
	local buttonFont := "Consolas"

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
	global currentHotkey
	global ProfilesDir
	; local HotkeyLabel := ""
	; local HotkeyButton := ""

	; Local Controls
	local AOTStatus := AlwaysOnTopActive == true and "+AlwaysOnTop" or "-AlwaysOnTop"
	local AOT_Text := (AlwaysOnTopActive == true and "On") or "Off"
	local ProcessDropdown := ""
	local themeDropdown := ""
	local themeLabel := ""
	local editTheme := ""

	; Colors
	global currentTheme := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SelectedTheme", "Default", "str")
	global intWindowColor
	global intControlColor
	global ControlTextColor

	CloseSettingsUI(*)
	{
		if WindowSettingsUI {
			WindowSettingsUI.Destroy()
			WindowSettingsUI := ""
		}

		SetTimer(mouseHoverDescription,0)
		WinActivate(MainUI.Title)
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

	local activeText_Sound := (playSounds == 1 and "All") or (playSounds == 2 and "Less") or (playSounds == 3 and "None")
	local themeNames := GetThemeListFromINI(localScriptDir "\themes.ini")

	if AlwaysOnTopButton
		AlwaysOnTopButton := ""
	
	if SoundToggleButton
		SoundToggleButton := ""

	; HotkeyLabel := WindowSettingsUI.Add("Text", "xm Center vHotkeyLabel h20 w" Popout_Width/1.05, "Hide Menu: " . (currentHotkey ? currentHotkey : "Alt+Backspace"))
	; HotkeyButton := WindowSettingsUI.Add("Button", "xm Center vHotkeyButton h30 w" Popout_Width/1.05, "Set Toggle Key")
	; HotkeyButton.Opt("Background" intWindowColor . " c" ControlTextColor)
	; HotkeyLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	; HotkeyLabel.SetFont("s12 w500", "Consolas")
	; HotkeyButton.SetFont("s12 w500", "Consolas")
	; HotkeyButton.OnEvent("Click", (*) => (
	; 	HotkeyLabel.Text := WaitForKeyPress(WindowSettingsUI)
	; ))
	local Popout_Margin_Width := Popout_Width-WindowSettingsUI.MarginX
	AlwaysOnTopButton := WindowSettingsUI.Add("Button", "Section Center vAlwaysOnTopButton h" buttonHeight " w" Popout_Margin_Width, "Always-On-Top: " AOT_Text)
	SoundToggleButton := WindowSettingsUI.Add("Button", "xm Section Center vSoundToggleButton h" buttonHeight " w" Popout_Margin_Width, "Sounds: " activeText_Sound)
	themeLabel := WindowSettingsUI.Add("Text", "xm Left vThemeLabel h" buttonHeight " w" Popout_Margin_Width, "Theme: " . currentTheme)
	themeDropdown := WindowSettingsUI.Add("DropDownList", "Section xm y+-5 R10 vThemeChoice h" buttonHeight " w" Popout_Margin_Width*0.75, themeNames)
	editTheme := WindowSettingsUI.Add("Button","x+1 y+-22 Center vEditThemeButton h" buttonHeight+2 " w" Popout_Margin_Width*0.25, "Edit Theme")
	
	; Get index of the current theme name
	for index, name in themeNames {
		if (name = currentTheme) {
			themeDropdown.Choose(index)
			break
		}
	}

	AlwaysOnTopButton.OnEvent("Click", ToggleAOT)
	AlwaysOnTopButton.Opt("Background" intWindowColor)
	AlwaysOnTopButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)

	SoundToggleButton.OnEvent("Click", ToggleSound)
	SoundToggleButton.Opt("Background" intWindowColor)
	SoundToggleButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)

	themeLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	themeLabel.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)

	editTheme.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	editTheme.Opt("Background" intWindowColor . " c" ControlTextColor)
	editTheme.OnEvent("Click", processThemeEdit)

	themeDropdown.OnEvent("Change", OnThemeDropdownChange)
	themeDropdown.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)

	processThemeEdit(*) {
		if FileExist(localScriptDir "\themes.ini")
			Run(localScriptDir "\themes.ini")
		else {
			ToolTip("themes.ini not found!")
			Sleep(2000)
			ToolTip()
		}
	}

	OnThemeDropdownChange(*) {
		global ProfilesDir
		selectedTheme := themeDropdown.Text
		updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "SelectedTheme", selectedTheme)
		currentTheme := selectedTheme
		themeLabel.Text := "Theme: " . selectedTheme

		updateGlobalThemeVariables(selectedTheme)
		updateGUITheme(WindowSettingsUI)
		updateGUITheme(MainUI)
	}
	
	OnProcessDropdownChange(*) {
		local selectedExe := ProcessDropdown.Text  ; get the selected process name
		ProcessLabel.Text := "Searching for: " . selectedExe
		
		SetSelectedProcessName(selectedExe)
		loadProfileSettings(selectedExe)
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
	
	; Add a label to display the currently selected process
    local ProcessLabel := WindowSettingsUI.Add("Text", "xm Left h" buttonHeight " vProcessLabel w" Popout_Margin_Width, "Searching for: " SelectedProcessExe)
    ProcessLabel.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ProcessLabel.Opt("Background" intWindowColor . " c" ControlTextColor)

    ; Add a dropdown list (ComboBox) for selecting a process
    ProcessDropdown := WindowSettingsUI.Add("DropDownList", "xm y+-5 R10 Center vProcessDropdown h" buttonHeight " w" Popout_Margin_Width, [SelectedProcessExe])
    ProcessDropdown.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ProcessDropdown.Choose(1)
	ProcessDropdown.OnEvent("Change", OnProcessDropdownChange)

	PopulateProcessDropdown(ProcessDropdown)

	; ################################# ;
	; Slider Description Box
	local testBoxColor := "666666"
	DescriptionBox := WindowSettingsUI.Add("Text", "xm y+15 Section Left vDescriptionBox h" . Popout_Height/2 . " w" Popout_Margin_Width)
	DescriptionBox.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	DescriptionBox.Opt("+Border Background" (testBoxColor or intWindowColor) . " c" ControlTextColor)
	
	; Hover Descriptions
	local Descriptions := Map(
		; Sliders
		"AlwaysOnTopButton", "This button controls whether the script's UI stays as the top-most window on the screen.",
		"SoundToggleButton", "This button controls the sounds that play when the auto-clicker sequence triggers, when no target window is found, etc.`n`nAll: All sounds play. This includes a 3 second countdown via audible beeps, a higher pitched trigger tone indicating the sequence has begun after the aforementioned countdown, and an audible indication the script launched.`n`nLess: Only the single higher pitched indicator and indicator on script launch are played.`n`nNone: No indication sounds are played.",
		"ProcessDropdown", "Pick a process from this dropdown list and the script will look for the first active process matching the name of the one selected.",
		"ThemeLabel", "This dropdown allows you to select a theme from the list of themes available in the themes.ini file. The selected theme will be applied to all user interfaces.",
		"ThemeChoice", "This dropdown allows you to select a theme from the list of themes available in the themes.ini file. The selected theme will be applied to all user interfaces.",
		"EditThemeButton", "This button opens the themes.ini file in your default text editor. You can edit, add, or remove any theme settings here.",
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

	updateGUITheme(WindowSettingsUI)
	WindowSettingsUI.Show("AutoSize X" . CenterX . " Y" . CenterY . " w" . Popout_Width . "h" . Popout_Height)

	SetTimer(mouseHoverDescription,50)
}

CreateClickerSettingsGUI(*) {
	; UI Settings
	local PixelOffset := 10
	local Popout_Width := 400
	local Popout_Height := 600
	local labelOffset := 50
	local sliderOffset := 0
	local toggleStatus := doMouseLock and "Enabled" or "Disabled"
	
	local buttonHeight := 23
	local buttonFontSize := 10
	local buttonFontWeight := 550
	local buttonFont := "Consolas"

	; Labels, Sliders, Buttons
	local MouseSpeedLabel := ""
	local MouseSpeedSlider := ""

	local ClickRateOffsetLabel := ""
	local ClickRateSlider := ""

	local ClickRadiusLabel := ""
	local ClickRadiusSlider := ""
	
	local SendKeyButton := ""
	local MouseClicksLabel := ""
	local MouseClicksSlider := ""
	local CooldownLabel := ""
	local CooldownSlider := ""
	local ToggleMouseLock := ""
	
	; Global Save Data
	global EditCooldownButton
	global KeyToSend
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
	
	; Colors
	global ProfilesDir
	global intWindowColor
	global intControlColor
	global ControlTextColor

	; If settingsUI is open, close it
	if SettingsUI
		return CloseSettingsUI()

	local AOTStatus := AlwaysOnTopActive == true and "+AlwaysOnTop" or "-AlwaysOnTop"
	local AOT_Text := (AlwaysOnTopActive == true and "On") or "Off"

	; Create GUI Window
	SettingsUI := Gui(AOTStatus)
	SettingsUI.Opt("+Owner" . MainUI.Hwnd)
	SettingsUI.BackColor := intWindowColor
	SettingsUI.OnEvent("Close", CloseSettingsUI)
	SettingsUI.Title := "Clicker Settings"
	
	local buddyWidth := 40
	local Popout_Margin_Width := Popout_Width - SettingsUI.MarginX
	local sliderWidth := (Popout_Margin_Width - ((buddyWidth+SettingsUI.MarginX)*2))

	MouseSpeedLabel := SettingsUI.Add("Text", "Section Center vMouseSpeedLabel h" buttonHeight " w" Popout_Margin_Width, "Mouse Speed: " . math.clamp(MouseSpeed,0,maxSpeed) . " ms")
	MouseSpeedSlider := SettingsUI.Add("Slider", "x" buddyWidth+(SettingsUI.MarginX*2) " 0x300 0xC00 AltSubmit vMouseSpeed w" sliderWidth)

	ClickRateOffsetLabel := SettingsUI.Add("Text", "xm" " Section Center vClickRateOffsetLabel h" buttonHeight " w" Popout_Margin_Width, "Click Rate Offset: " . math.clamp(MouseClickRateOffset,0,maxSpeed) . " ms")
	ClickRateSlider := SettingsUI.Add("Slider", "x" buddyWidth+(SettingsUI.MarginX*2) " y+-" . sliderOffset . " 0x300 0xC00 AltSubmit vClickRateOffset w" sliderWidth)

	ClickRadiusLabel := SettingsUI.Add("Text", "xm" " Section Center vClickRadiusLabel h" buttonHeight " w" Popout_Margin_Width, "Click Radius: " . math.clamp(MouseClickRadius,0,maxSpeed) . " pixels")
	ClickRadiusSlider := SettingsUI.Add("Slider", "x" buddyWidth+(SettingsUI.MarginX*2) " y+-" . sliderOffset . " 0x300 0xC00 AltSubmit vClickRadius w" sliderWidth)
	
	MouseClicksLabel := SettingsUI.Add("Text", "xm" " Section Center vMouseClicksLabel h" buttonHeight " w" Popout_Margin_Width, "Click Amount: " . math.clamp(MouseClicks,1,maxClicks) . " clicks")
	MouseClicksSlider := SettingsUI.Add("Slider", "x" buddyWidth+(SettingsUI.MarginX*2) " y+-" . sliderOffset . " 0x300 0xC00 AltSubmit vMouseClicks w" sliderWidth)
	
	CooldownLabel := SettingsUI.Add("Text", "xm" " Section Center vCooldownLabel h" buttonHeight " w" Popout_Margin_Width, "Cooldown: " SecondsToWait " seconds")
	EditCooldownButton := SettingsUI.Add("Button", "x+-" Popout_Margin_Width/3.5 " vCooldownEditor h" buttonHeight " w" Popout_Margin_Width/7, "Custom")
	CooldownSlider := SettingsUI.Add("Slider", "x" buddyWidth+(SettingsUI.MarginX*2) " y+-" sliderOffset . " 0x300 0xC00 AltSubmit vCooldownSlider w" sliderWidth)

	ToggleMouseLock := SettingsUI.Add("Button", "xm" " Section Center vToggleMouseLock h" buttonHeight " w" Popout_Margin_Width/2, "Block Inputs: " . (toggleStatus == "Enabled" ? "On" : "Off"))
	SendKeyButton := SettingsUI.Add("Button", "x+1 Section Center vSendKey h" buttonHeight " w" Popout_Margin_Width/2, "Send Key: " . (keytoSend == "LButton" ? "Left Click" : "Right Click"))
	
	; Slider Description Box
	DescriptionBox := SettingsUI.Add("Text", "xm Section Left vDescriptionBox h" . Popout_Height/3.25 . " w" Popout_Margin_Width)
	
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

	MS_Buddy1 :=			SettingsUI.Add("Text", "Center vMS_Buddy1 h" buttonHeight " w" buddyWidth, "Fast")
	MS_Buddy2 :=			SettingsUI.Add("Text", "Center vMS_Buddy2 h" buttonHeight " w" buddyWidth, "Slow")
	Rate_Buddy1 := 			SettingsUI.Add("Text", "Center vRate_Buddy1 h" buttonHeight " w" buddyWidth, "Less")
	Rate_Buddy2 := 			SettingsUI.Add("Text", "Center vRate_Buddy2 h" buttonHeight " w" buddyWidth, "More")
	ClickRadiusBuddy1 := 	SettingsUI.Add("Text", "Center vClickRadiusBuddy1 h" buttonHeight " w" buddyWidth, "Small")
	ClickRadiusBuddy2 :=	SettingsUI.Add("Text", "Center vClickRadiusBuddy2 h" buttonHeight " w" buddyWidth, "Big")
	MouseClicksBuddy1 := 	SettingsUI.Add("Text", "Center vMouseClicksBuddy1 h" buttonHeight " w" buddyWidth, "Less")
	MouseClicksBuddy2 := 	SettingsUI.Add("Text", "Center vMouseClicksBuddy2 h" buttonHeight " w" buddyWidth, "More")
	Cooldown_Buddy1 := 		SettingsUI.Add("Text", "Center vCooldown_Buddy1 h" buttonHeight " w" buddyWidth, "Fast")
	Cooldown_Buddy2 := 		SettingsUI.Add("Text", "Center vCooldown_Buddy2 h" buttonHeight " w" buddyWidth, "Slow")
	
	MS_Buddy1.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	MS_Buddy2.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	Rate_Buddy1.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	Rate_Buddy2.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ClickRadiusBuddy1.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ClickRadiusBuddy2.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	MouseClicksBuddy1.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	MouseClicksBuddy2.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	Cooldown_Buddy1.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	Cooldown_Buddy2.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)

	MouseSpeedLabel.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ClickRateOffsetLabel.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ClickRadiusLabel.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	MouseClicksLabel.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	CooldownLabel.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	EditCooldownButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ToggleMouseLock.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	SendKeyButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	DescriptionBox.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)

	MS_Buddy1.Opt("Background" intWindowColor " c" ControlTextColor)
	MS_Buddy2.Opt("Background" intWindowColor " c" ControlTextColor)
	Rate_Buddy1.Opt("Background" intWindowColor " c" ControlTextColor)
	Rate_Buddy2.Opt("Background" intWindowColor " c" ControlTextColor)
	ClickRadiusBuddy1.Opt("Background" intWindowColor " c" ControlTextColor)
	ClickRadiusBuddy2.Opt("Background" intWindowColor " c" ControlTextColor)
	MouseClicksBuddy1.Opt("Background" intWindowColor " c" ControlTextColor)
	MouseClicksBuddy2.Opt("Background" intWindowColor " c" ControlTextColor)
	Cooldown_Buddy1.Opt("Background" intWindowColor " c" ControlTextColor)
	Cooldown_Buddy2.Opt("Background" intWindowColor " c" ControlTextColor)

	MouseSpeedLabel.Opt("Background" intWindowColor " c" ControlTextColor)
	ClickRateOffsetLabel.Opt("Background" intWindowColor " c" ControlTextColor)
	ClickRadiusLabel.Opt("Background" intWindowColor " c" ControlTextColor)
	MouseClicksLabel.Opt("Background" intWindowColor " c" ControlTextColor)
	CooldownLabel.Opt("Background" intWindowColor " c" ControlTextColor)
	EditCooldownButton.Opt("Background" intWindowColor "")
	ToggleMouseLock.Opt("Background" intWindowColor " c" ControlTextColor)
	SendKeyButton.Opt("Background" intWindowColor " c" ControlTextColor)

	MouseSpeedSlider.Opt("Buddy1MS_Buddy1 Buddy2MS_Buddy2 Range0-" maxSpeed)
	ClickRateSlider.Opt("Buddy1Rate_Buddy1 Buddy2Rate_Buddy2 Range0-" maxRate)
	ClickRadiusSlider.Opt("Buddy1ClickRadiusBuddy1 Buddy2ClickRadiusBuddy2 Range0-" maxRadius)
	MouseClicksSlider.Opt("Buddy1MouseClicksBuddy1 Buddy2MouseClicksBuddy2 Range1-" maxClicks)
	CooldownSlider.Opt("Buddy1Cooldown_Buddy1 Buddy2Cooldown_Buddy2 Range10-" maxCooldown)
	
	DescriptionBox.Opt("+Border Background" intWindowColor . " c" ControlTextColor)

	MouseSpeedSlider.Value := math.clamp(MouseSpeed,0,maxSpeed) or 0
	ClickRateSlider.Value := math.clamp(MouseClickRateOffset,0,maxSpeed) or 0
	ClickRadiusSlider.Value := math.clamp(MouseClickRadius,0,maxSpeed) or 0
	MouseClicksSlider.Value := math.clamp(MouseClicks,1,maxClicks) or 1
	CooldownSlider.Value := math.clamp(SecondsToWait,0,maxCooldown) or 0

	MouseSpeedSlider.OnEvent("Change", updateSliderValues)
	ClickRateSlider.OnEvent("Change", updateSliderValues)
	ClickRadiusSlider.OnEvent("Change", updateSliderValues)
	MouseClicksSlider.OnEvent("Change", updateSliderValues)
	EditCooldownButton.OnEvent("Click", EditCooldown)
	CooldownSlider.OnEvent("Change", updateSliderValues)
	ToggleMouseLock.OnEvent("Click", updateToggle)
	SendKeyButton.OnEvent("Click", updateToggle)
	updateSliderValues(CooldownSlider,"")
	
	; Functions
	CloseSettingsUI(*)
	{
		if SettingsUI
		{
			SettingsUI.Destroy()
			SettingsUI := ""
		}

		SetTimer(mouseHoverDescription,0)
		WinActivate(MainUI.Title)
	}
	; Slider update function
	updateSliderValues(ctrlObj, info) {
		; MsgBox(ctrlObj.Name . ": " . info)
		if ctrlObj.Name == "MouseSpeed" {
			updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MouseSpeed", ctrlObj.Value)
			MouseSpeed := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MouseSpeed", 0, "int")
			
			if MouseSpeedLabel
				MouseSpeedLabel.Text := "Mouse Speed: " . (ctrlObj.Value >= 1000 ? Format("{:.2f} s", ctrlObj.Value / 1000) : ctrlObj.Value . " ms")
		}

		if ctrlObj.Name == "ClickRateOffset" {
			updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "ClickRateOffset", ctrlObj.Value)
			MouseClickRateOffset := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "ClickRateOffset", 0, "int")
			
			if ClickRateOffsetLabel
				ClickRateOffsetLabel.Text := "Click Rate Offset: " . (ctrlObj.Value >= 1000 ? Format("{:.2f} s", ctrlObj.Value / 1000) : ctrlObj.Value . " ms")
		}

		if ctrlObj.Name == "ClickRadius" {
			updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "ClickRadius", ctrlObj.Value)
			MouseClickRateOffset := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "ClickRadius", 0, "int")
			
			if ClickRadiusLabel
				ClickRadiusLabel.Text := "Click Radius: " . ctrlObj.Value . " pixels"
		}

		if ctrlObj.Name == "MouseClicks" {
			updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MouseClicks", ctrlObj.Value)
			MouseClicks := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MouseClicks", 0, "int")
			
			if MouseClicksLabel
				MouseClicksLabel.Text := "Click Amount: " . ctrlObj.Value . " clicks"
		}

		if ctrlObj.Name == "CooldownSlider" {
			; local targetSeconds := (SecondsToWait > 0) and Round(Mod(SecondsToWait, 60),0) or 0
			; local targetFormattedTime := Format("{:02}:{:02}", MinutesToWait, targetSeconds)
			; local mins_suffix := SecondsToWait > 60 and " minutes" or SecondsToWait == 60 and " minute" or SecondsToWait < 60 and " seconds"
			
			val := ctrlObj.Value ; Slider's raw value in seconds
			remainder := Mod(val, 60)
			if (remainder <= 3 || remainder >= 57) {
				val := Round(val / 60) * 60
				ctrlObj.Value := val ; snap to the nearest minute
			}

			updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "SecondsToWait", math.clamp(val,(minCooldown > 0 and minCooldown/60) or 0,900))
			updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MinutesToWait", Round(math.clamp(val / 60,(0 and minCooldown) or 0,15),2))
			SecondsToWait := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SecondsToWait", 0, "int")
			MinutesToWait := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MinutesToWait", 0, "int")
			local targetSeconds := (SecondsToWait > 0) and Round(Mod(SecondsToWait, 60),0) or 0
			local targetFormattedTime := Format("{:02}:{:02}", MinutesToWait, targetSeconds)
			local mins_suffix := SecondsToWait > 60 and " minutes" or SecondsToWait == 60 and " minute" or SecondsToWait < 60 and " seconds"
			
			if CooldownLabel
				CooldownLabel.Text := "Cooldown: " targetFormattedTime . mins_suffix
			UpdateTimerLabel()
		}
	}

	; Toggle Function
	updateToggle(ctrlObj, info) {
		if ctrlObj.Name == "ToggleMouseLock" {
			updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "doMouseLock", !doMouseLock)
			doMouseLock := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "doMouseLock", 0, "int")

			local toggleStatus := doMouseLock and "Enabled" or "Disabled"
			ctrlObj.Text := "Block Inputs: " . (toggleStatus == "Enabled" ? "On" : "Off")
		}

		if ctrlObj.Name == "SendKey" {
			local newValue := KeyToSend == "~LButton" ? "~RButton" : "~LButton"
			updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "KeyToSend", newValue)
			KeyToSend := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "KeyToSend", "~LButton")
			
			if SendKeyButton
				SendKeyButton.Text := "Send Key: " . (KeyToSend == "~LButton" ? "Left Click" : "Right Click")
		}
	}

	EditCooldown(*) {
		local newTime := CooldownEditPopup()
		CooldownSlider.Value := math.clamp(newTime,0,maxCooldown) or 0

		local targetSeconds := (SecondsToWait > 0) and Round(Mod(SecondsToWait, 60),0) or 0
		local targetFormattedTime := Format("{:02}:{:02}", MinutesToWait, targetSeconds)
		local mins_suffix := SecondsToWait > 60 and " minutes" or SecondsToWait == 60 and " minute" or SecondsToWait < 60 and " seconds"

		if CooldownLabel
			CooldownLabel.Text := "Cooldown: " targetFormattedTime . mins_suffix
	}

	updateDescriptionBoxValues(*) {
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
	}
	
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
	
	updateDescriptionBoxValues()

	SettingsUI.OnEvent("Close", CloseSettingsUI)

	; Calculate center position
	WinGetClientPos(&MainX, &MainY, &MainW, &MainH, MainUI.Title)
	CenterX := MainX + (MainW / 2) - (Popout_Width / 2)
	CenterY := MainY + (MainH / 2) - (Popout_Height / 2)

	updateGUITheme(SettingsUI)
	SettingsUI.Show("AutoSize X" . CenterX . " Y" . CenterY . " w" . Popout_Width . "h" . Popout_Height)

	SetTimer(mouseHoverDescription,50)
}

CreateScriptSettingsGUI(*) {
	global ProfilesDir

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
	global intWindowColor
	global intControlColor
	global ControlTextColor

	; Button Settings
	local buttonHeight := 23
	local buttonFontSize := 10
	local buttonFontWeight := 500
	local buttonFont := "Consolas"
	local Popout_Margin_Width := ""

	local addToStartUp_Text := isInStartFolder and "Remove from Windows startup folder" or "Add to Windows startup folder"
	local functions := Map(
		"EditButton", Map(
			"Function", (*) => (
				EditApp()
				CloseSettingsUI()
			),
		),
		"ExitButton", Map(
			"Function", (*) => (
				CloseApp()
				CloseSettingsUI()
			),
		),
		"EditorSelector", Map(
			"Function", (*) => (
				SelectEditor()
				CloseSettingsUI()
			),
		),
		"ScriptDir", Map(
			"Function", (*) => (
				OpenScriptDir()
				CloseSettingsUI()
			),
		),
	)

	if ScriptSettingsUI
		return CloseSettingsUI()

	ScriptSettingsUI := Gui(AOTStatus)
	ScriptSettingsUI.Title := "Script Settings"
	ScriptSettingsUI.BackColor := intWindowColor
	Popout_Margin_Width := Popout_Width-ScriptSettingsUI.MarginX

	EditButton := 				 ScriptSettingsUI.Add("Button","h" buttonHeight " w" Popout_Margin_Width/1.5 " vEditButton Section Center", "View Script")
	ReloadButton := 			ScriptSettingsUI.Add("Button", "h" buttonHeight " w" Popout_Margin_Width/1.5 " vReloadButton xs", "Relaunch Script")
	ExitButton := 				ScriptSettingsUI.Add("Button", "h" buttonHeight " w" Popout_Margin_Width/1.5 " vExitButton xs", "Close Script")
	EditorButton := 			ScriptSettingsUI.Add("Button", "h" buttonHeight " w" Popout_Margin_Width/1.5 " vEditorSelector xs", "Select Script Editor")
	ScriptDirButton := 			ScriptSettingsUI.Add("Button", "h" buttonHeight " w" Popout_Margin_Width/1.5 " vScriptDir xs", "Open File Location")
	AddToBootupFolderButton :=  ScriptSettingsUI.Add("Button", "h" buttonHeight " w" Popout_Margin_Width/1.5 " vStartupToggle xs", addToStartUp_Text)
	DescriptionBox := 	   ScriptSettingsUI.Add("Text", "h" . Popout_Height/4 . " w" Popout_Margin_Width/1.5 " xm Section Left vDescriptionBox")
	
	ScriptSettingsUI.OnEvent("Close", CloseSettingsUI)
	EditButton.OnEvent("Click", functions["EditButton"]["Function"])
	ReloadButton.OnEvent("Click", ReloadScript)
	ExitButton.OnEvent("Click", functions["ExitButton"]["Function"])
	EditorButton.OnEvent("Click", functions["EditorSelector"]["Function"])
	ScriptDirButton.OnEvent("Click", functions["ScriptDir"]["Function"])
	AddToBootupFolderButton.OnEvent("Click", ToggleStartup)

	EditButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ReloadButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ExitButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	EditorButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ScriptDirButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	AddToBootupFolderButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	DescriptionBox.SetFont("s10 w700", "Consolas")

	EditButton.Opt("Background" intWindowColor)
	ReloadButton.Opt("Background" intWindowColor)
	ExitButton.Opt("Background" intWindowColor)
	EditorButton.Opt("Background" intWindowColor)
	ScriptDirButton.Opt("Background" intWindowColor)
	AddToBootupFolderButton.Opt("Background" intWindowColor)
	DescriptionBox.Opt("+Border Background" intWindowColor " c" ControlTextColor)
	ScriptSettingsUI.Opt("+Owner" . MainUI.Hwnd)
	
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

	CloseSettingsUI(*)
	{
		if ScriptSettingsUI {
			ScriptSettingsUI.Destroy()
			ScriptSettingsUI := ""
		}
		SetTimer(mouseHoverDescription,0)
		WinActivate(MainUI.Title)
	}

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

	updateGUITheme(ScriptSettingsUI)
	ScriptSettingsUI.Show("AutoSize X" . CenterX . " Y" . CenterY . " w" . Popout_Width . "h" . Popout_Height)

	SetTimer(mouseHoverDescription,50)
}

CreateExtrasGUI(*) {
	global ProfilesDir

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

	ExtrasUI := Gui(AlwaysOnTopActive " +Owner" . MainUI.Hwnd)
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
		WinActivate(MainUI.Title)
	}
}

ToggleHideUI(newstate) {
	global MainUI
	global isUIHidden
	global ProfilesDir
	global SelectedProcessExe

	if not MainUI
		return CreateGui()

	updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "isUIHidden", newstate)
	isUIHidden := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "isUIHidden", false, "bool")
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
		MainUI.Show((MainUI_PosX = 0 and MainUI_PosY = 0 and "Center" or "X" . MainUI_PosX . " Y" . MainUI_PosY) " Restore AutoSize")
}

ToggleStartup(*) {
	global AddToBootupFolderButton
	global isInStartFolder
	global ProfilesDir
	global SelectedProcessExe

    StartupPath := A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup"
	TargetFile := StartupPath "\" A_ScriptName
	
	local newMode

    if (FileExist(TargetFile)) {
        FileDelete(TargetFile)

		newMode := false
		updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "isInStartFolder", newMode)
		isInStartFolder := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "isInStartFolder", false, "bool")

        MsgBox "Script removed from Startup."
    } else {
        FileCopy(A_ScriptFullPath, TargetFile)

		newMode := true
		updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "isInStartFolder", newMode)
		isInStartFolder := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "isInStartFolder", false, "bool")

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
	global ProfilesDir
	global SelectedProcessExe

	updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "AlwaysOnTop", !AlwaysOnTopActive)
	AlwaysOnTopActive := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "AlwaysOnTop", false, "bool")

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
	global currentTheme
	global MainUI
	global SettingsUI
	global WindowSettingsUI
	global ExtrasUI
	global ScriptSettingsUI
	
	; Check if themes.ini exists
	if !FileExist(localScriptDir "\themes.ini")
		return updateGlobalThemeVariables(currentTheme)
	
	if MainUI
		try updateGUITheme(MainUI)
	if SettingsUI
		try updateGUITheme(SettingsUI)
	if WindowSettingsUI
		try updateGUITheme(WindowSettingsUI)
	if ExtrasUI
		try updateGUITheme(ExtrasUI)
	if ScriptSettingsUI
		try updateGUITheme(ScriptSettingsUI)
}

CooldownEditPopup(*) {
	
    global MinutesToWait
    global SecondsToWait
    global MainUI
    global minCooldown
	global ProfilesDir
	global SelectedProcessExe
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
    updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "SecondsToWait", parsed.seconds)
    updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MinutesToWait", parsed.minutes)
    MinutesToWait := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MinutesToWait", 15, "int")
    SecondsToWait := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SecondsToWait", MinutesToWait * 60, "int")
    
    ; Optionally update the UI timer, etc.
    UpdateTimerLabel()
    
    return SecondsToWait
}

SaveMainUIPosition(*) {
    global MainUI_PosX
    global MainUI_PosY
    global MainUI
	global monitorNum
	global ProfilesDir
	global SelectedProcessExe

	if not MainUI
		return

	local winState := WinGetMinMax(MainUI.Title) ; -1 = Minimized | 0 = "Neither" (I assume floating) | 1 = Maximized
	if winState == -1
		return

	global MainUI
    WinGetPos(&x, &y,,,"ahk_id" MainUI.Hwnd)
    monitorNum := MonitorGetNumberFromPoint(x, y)

    updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosX", x)
	updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosY", y)
    updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "monitorNum", monitorNum)

	MainUI_PosX := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosX", A_ScreenWidth / 2, "int")
	MainUI_PosY := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosY", A_ScreenHeight / 2, "int")
}

UpdateTimerLabel(*) {
	global isActive
	global MinutesToWait
	global SecondsToWait
	global ElapsedTimeLabel
	global CurrentElapsedTime
	global lastUpdateTime := isActive > 1 and lastUpdateTime or A_TickCount
	global WaitProgress
	global WaitTimerLabel

	; Calculate and update progress bar
    secondsPassed := (A_TickCount - lastUpdateTime) / 1000  ; Convert ms to seconds
    finalProgress := Round((MinutesToWait == 0 and SecondsToWait == 0) and 100 or (secondsPassed / SecondsToWait) * 100, 0)
	
	; Calculate and format CurrentElapsedTime as MM:SS
    currentMinutes := Floor(secondsPassed / 60)
    currentSeconds := Round(Mod(secondsPassed, 60),0)
	
	targetSeconds := (SecondsToWait > 0) and Round(Mod(SecondsToWait, 60),0) or 0
	
	CurrentElapsedTime := Format("{:02}:{:02}", currentMinutes, currentSeconds)
	targetFormattedTime := Format("{:02}:{:02}", MinutesToWait, targetSeconds)

	local mins_suffix := SecondsToWait > 60 and " minutes" or SecondsToWait == 60 and " minute" or SecondsToWait < 60 and " seconds"
	
	try if ElapsedTimeLabel.Text != CurrentElapsedTime " / " . targetFormattedTime . " " mins_suffix
			ElapsedTimeLabel.Text := CurrentElapsedTime " / " . targetFormattedTime . " " mins_suffix

	if WaitProgress and WaitProgress.Value != finalProgress
		WaitProgress.Value := finalProgress

    local finalText  := Round(WaitProgress.Value, 0) "%"
	if WaitTimerLabel and WaitTimerLabel.Text != finalText
		WaitTimerLabel.Text := finalText
}

OpenScriptDir(*) {
	; SetWorkingDir A_InitialWorkingDir
	Run("explorer.exe " . A_ScriptDir)
}

SelectEditor(*) {
	Editor := FileSelect(2,, "Select your editor", "Programs (*.exe)")
	if !Editor
		return
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
	global ProfilesDir
	global SelectedProcessExe

	local newMode := forceState or switchActiveState()
	
	updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "isActive", newMode)

	isActive := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "isActive", 0, "int")
	activeText_Core := (isActive == 3 and "Enabled") or (isActive == 2 and "Waiting...") or "Disabled"
	
	CoreToggleButton.Text := "Auto-Clicker: " activeText_Core
	CoreToggleButton.Redraw()

	setTrayIcon(icons[isActive].Icon)
	; CreateGui()

	; Reset cooldown
	ResetCooldown()
	
	UpdateTimerLabel()
	; Toggle Timer
	if isActive > 1 {
		FirstRun := True
		return SetTimer(RunCore, 100)
	}
	else if isActive == 1 {
		return SetTimer(RunCore, 0)
	}

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
		
		if IsAltTabOpen() or (SecondsToWait < 10 and WinActive("A") != FindTargetHWND())
			return
		
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

		if (MinutesToWait > 0 or SecondsToWait > 0)
			WaitProgress.Value := 0

		lastUpdateTime := A_TickCount
	}
	
	; Unblock Inputs
	BlockInput("Off")
	BlockInput("Default")
	BlockInput("MouseMoveOff")

	; Calculate and progress visuals
    ; secondsPassed := (A_TickCount - lastUpdateTime) / 1000  ; Convert ms to seconds
    ; finalProgress := (MinutesToWait == 0 and SecondsToWait == 0) and 100 or (secondsPassed / SecondsToWait) * 100
	UpdateTimerLabel()
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
	updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "SoundMode", newMode)
	playSounds := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SoundMode", 1, "int")

	local activeText_Sound := (playSounds == 1 and "All") or (playSounds == 2 and "Less") or (playSounds == 3 and "None")
	
	; Setup Sound Toggle Button
	if SoundToggleButton
		SoundToggleButton.Text := "Sounds: " activeText_Sound
	
	return
}

; ################################ ;
; ######## .ini Functions ######## ;

IniSectionExists(fileOrLines, sectionName) {
    if Type(fileOrLines) = "String" {
        if !FileExist(fileOrLines)
            return false
        lines := StrSplit(FileRead(fileOrLines), "`n")
    } else if Type(fileOrLines) = "Array" {
        lines := fileOrLines
    } else {
        throw ValueError("Invalid type for IniSectionExists(): must be a file path or array of lines.")
    }

    sectionHeader := "[" sectionName "]"
    for line in lines {
        if Trim(line) = sectionHeader
            return true
    }
    return false
}

; ################################ ;
; ####### Window Functions ####### ;
; ################################ ;
; Gets the monitor index number based on a screen coordinate
MonitorGetNumberFromPoint(x, y) {
    ; MONITOR_DEFAULTTONEAREST = 2
    hMonitor := DllCall("User32\MonitorFromPoint", "int64", (y << 32) | (x & 0xFFFFFFFF), "uint", 2, "ptr")
    return MonitorGetIndexFromHandle(hMonitor)
}

MonitorGetIndexFromHandle(hMonitor) {
    SysGetMonitorCount := SysGet(80)
    Loop SysGetMonitorCount {
        SysGetMonitorHandle := SysGet(MonitorHandle := 66 + A_Index - 1)
        if (SysGetMonitorHandle = hMonitor)
            return A_Index
    }
    return 1 ; fallback to primary monitor
}

GetThemeListFromINI(filePath) {
    themeList := []
    Loop Read, filePath {
        if RegExMatch(A_LoopReadLine, "^\[(.+?)\]$", &match) {
			themeList.Push(match[1])
		}
    }
    return themeList
}

updateGlobalThemeVariables(themeName := "") {
	global localScriptDir
	global ProfilesDir
	global SelectedProcessExe
	
	; Create ini file if it doesn't exist for dark, light, and custom themes
	dataSets := Map(
		"Dark Mode", Map(
			"TextLabelBackgroundColor", "none",
			"TextColor", "dddddd",
			"ButtonTextColor", "000000",
			"LinkColor", "99c3ff",
			"Background", "303030",
			"ProgressBarColor", "5c5cd8",
			"ProgressBarBackground", "404040",
			"DescriptionBoxColor", "404040",
			"DescriptionBoxTextColor", "FFFFFF",
			"HeaderColor", "ff4840",
		),
	
		"Light Mode", Map(
			"TextLabelBackgroundColor", "none",
			"TextColor", "000000",
			"ButtonTextColor", "000000",
			"LinkColor", "4787e7",
			"Background", "EEEEEE",
			"ProgressBarColor", "54cc54",
			"ProgressBarBackground", "FFFFFF",
			"DescriptionBoxColor", "CCCCCC",
			"DescriptionBoxTextColor", "000000",
			"HeaderColor", "ff4840",
		),
	
		"Custom", Map(
			"TextLabelBackgroundColor", "none",
			"TextColor", "000000",
			"ButtonTextColor", "000000",
			"LinkColor", "7d4dc2",
			"Background", "FFFFFF",
			"ProgressBarColor", "a24454",
			"ProgressBarBackground", "FFFFFF",
			"DescriptionBoxColor", "AAAAAA",
			"DescriptionBoxTextColor", "000000",
			"HeaderColor", "ff4840",
		)
	)

	if !FileExist(localScriptDir "\themes.ini") {
		themeFile := localScriptDir "\themes.ini"
		SaveThemeToINI(dataSets["Dark Mode"], "Dark Mode")
		SaveThemeToINI(dataSets["Light Mode"], "Light Mode")
		SaveThemeToINI(dataSets["Custom"], "Custom")
	} else
		themeFile := localScriptDir "\themes.ini"

	for themeName, themeData in dataSets {
		local cachedTheme := LoadThemeFromINI(themeName)
		if !cachedTheme {
			SaveThemeToINI(themeData, themeName, themeFile)
			cachedTheme := LoadThemeFromINI(themeName)
		}
		
		for dataName, dataValue in themeData {
			existingValue := IniRead(themeFile, themeName, dataName, "__MISSING__")
			
			if existingValue == "__MISSING__" {
				IniWrite(dataValue, themeFile, themeName, dataName)
			}
		}
	}

	; Get theme from ini file
	global currentTheme := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SelectedTheme", "Dark Mode")
	local themeData := LoadThemeFromINI(currentTheme)

	global intWindowColor := themeData["Background"]
	global intControlColor := themeData["Background"]
	global intProgressBarColor := themeData["ProgressBarBackground"]
	global ControlTextColor := themeData["ButtonTextColor"]
	global linkColor := themeData["LinkColor"]	
}

updateGUITheme(GUIObject) {
	if not GUIObject
		return

    global currentTheme
    theme := LoadThemeFromINI(currentTheme)
    try ApplyThemeToGui(GUIObject, theme)
}

LoadThemeFromINI(themeName, filePath := localScriptDir "\themes.ini") {
    local keys := [
		"Background",
		"TextLabelBackgroundColor",
		"TextColor",
		"ButtonTextColor",
		"FontFace",
		"FontSize",
		"ProgressBarBackground",
		"ProgressBarColor",
		"LinkColor",
		"DescriptionBoxColor",
		"DescriptionBoxTextColor",
		"HeaderColor",
	]

    theme := Map()
    for _, key in keys
        theme[key] := IniRead(filePath, themeName, key, "")
    return theme
}

ApplyThemeToGui(guiObj, themeMap) {
    if !guiObj
        return

	local transparentBGs := [
		"0",
		"none",
		"n/a",
		"transparent",
		"zero",
		"clear",
	]

	if themeMap && themeMap.Has("Background") and (themeMap["Background"] == "000000" or themeMap["Background"] == "0x000000")
		themeMap["Background"] := "010101"

    for _, ctrl in guiObj {
        ; Skip the main header except for background update
        if ctrl.Name = "MainHeader" {
			try ctrl.Opt("Background" themeMap["Background"] " c" themeMap["HeaderColor"])
		}
		else
			try {
				; Determine foreground and background colors
				fg := "", bg := "", opt := ""
				switch ctrl.Type {
					case "Button":
						; If "IconButton" is not in the ctrl.Name, continue
						if InStr(ctrl.Name, "IconButton") = 0 {
							fg := themeMap["ButtonTextColor"]
						} 
						if ArrayHasValue(transparentBGs, StrLower(themeMap["Background"]))
							bg := "Trans"
						else bg := themeMap["Background"]
						opt := "Background" bg (fg ? " c" fg : "")
					case "Edit", "Text":
						if InStr(ctrl.Name, "DescriptionBox") = 0 {
							if ArrayHasValue(transparentBGs, StrLower(themeMap["TextLabelBackgroundColor"]))
								bg := "Trans"
							else bg := themeMap["TextLabelBackgroundColor"]
							fg := themeMap["TextColor"]
						} else {
							if ArrayHasValue(transparentBGs, StrLower(themeMap["Background"]))
								bg := "Trans"
							else bg := themeMap["DescriptionBoxColor"]
							fg := themeMap["DescriptionBoxTextColor"]
						}
						opt := "Background" bg " c" fg
					case "Progress":
						fg := themeMap["ProgressBarColor"]
						bg := themeMap["ProgressBarBackground"]
						opt := "Background" bg " Smooth c" fg
					case "Link":
						fg := themeMap["LinkColor"]
						opt := "c" fg
				}
	
				; Compare to cached values
				needsUpdate := false
				if ctrl.Type = "Progress" || ctrl.Type = "Link" {
					; Progress and Link don't use BG in same way
					if !ctrl.HasOwnProp("_lastFG") || ctrl._lastFG != fg
						needsUpdate := true
				} else {
					if !ctrl.HasOwnProp("_lastFG") || !ctrl.HasOwnProp("_lastBG")
						|| ctrl._lastFG != fg || ctrl._lastBG != bg
						needsUpdate := true
				}
	
				; Apply if needed
				if needsUpdate {
					ctrl.Opt(opt)
					ctrl._lastFG := fg
					ctrl._lastBG := bg
					ctrl.Redraw()
				}
			}
    }

	if guiObj.BackColor != themeMap["Background"]
        guiObj.BackColor := themeMap["Background"]
}

SaveThemeToINI(themeMap, section, filePath := localScriptDir "\themes.ini") {
	if !themeMap || !section || !filePath
		return
    for key, value in themeMap
        IniWrite(value, filePath, section, key)
}

WinSetRedraw(hWnd) {
	; Redraw the window to apply the new theme
	; This is a workaround for the issue where the theme doesn't apply immediately
    DllCall("RedrawWindow", "ptr", hWnd, "ptr", 0, "ptr", 0, "uint", 0x85)
}

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
			global KeyToSend
			
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
				Click(KeyToSend == "RButton" and "Right" or "Left")

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

moveCenterOfControl(ctrl, targetX, targetY) {
	local center := ctrl.GetPos(&startX, &startY, &width, &height)
	local centerX := startX + (width / 2)
	local centerY := startY + (height / 2)
	local offsetX := targetX - centerX
	local offsetY := targetY - centerY
	
	ctrl.Move(offsetX, offsetY, width, height)
	ctrl.Redraw()
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

MeasureTextWidth(ctrl, text) {
	static SIZE := Buffer(8, 0)  ; holds width (int32) and height (int32)
	local L_hwnd := ctrl.Hwnd
	hdc := DllCall("GetDC", "ptr", L_hwnd, "ptr")
	
	hFont := SendMessage(0x31, 0, 0, ctrl) ; WM_GETFONT
	if hFont
		DllCall("SelectObject", "ptr", hdc, "ptr", hFont)

	DllCall("GetTextExtentPoint32", "ptr", hdc, "str", text, "int", StrLen(text), "ptr", SIZE)
	DllCall("ReleaseDC", "ptr", L_hwnd, "ptr", hdc)

	width := NumGet(SIZE, 0, "int")
	return width
}

DownloadURL(url, filename := "") {
    local req, oStream, path, dir

    ; derive filename if none provided
    path := filename ? filename : RegExReplace(url, ".*/")
    if !path
        throw Error("Cannot derive filename from URL: " url)

    ; ensure output directory exists
    dir := RegExReplace(path, "\\[^\\]+$")
    if (dir && !FileExist(dir))
        DirCreate(dir)

    ; synchronous HTTP GET
    req := ComObject("Msxml2.XMLHTTP.6.0")
    req.open("GET", url, false)
    req.send()
    if (req.status != 200)
        throw Error("Download failed, status " req.status " for " url)

    ; write binary to disk
    oStream := ComObject("ADODB.Stream")
    oStream.Type := 1       ; adTypeBinary
    oStream.Open()
    oStream.Write(req.responseBody)
    oStream.SaveToFile(path, 2)  ; adSaveCreateOverWrite
    oStream.Close()

    return path
}

loadProfileSettings(processName) {
	global localScriptDir
    global playSounds, isActive, isInStartFolder, isUIHidden
    global MinutesToWait, SecondsToWait, MainUI_PosX, MainUI_PosY
    global KeyToSend, currentTheme, AcceptedWarning, SettingsExists, ProfilesDir
    if !IniSectionExists(ProfilesDir, processName) {
        createDefaultProfileSettings(processName)
    }

	SettingsExists := readIniProfileSetting(ProfilesDir, processName, "Exists", "false")
	AcceptedWarning := readIniProfileSetting(ProfilesDir, "General", "AcceptedWarning", "false")
	playSounds := readIniProfileSetting(ProfilesDir, processName, "SoundMode", 1, "int")
	isActive := readIniProfileSetting(ProfilesDir, processName, "isActive", 1, "int")
	isInStartFolder := readIniProfileSetting(ProfilesDir, processName, "isInStartFolder", "false")
	isUIHidden := readIniProfileSetting(ProfilesDir, processName, "isUIHidden", "false")
	MinutesToWait := readIniProfileSetting(ProfilesDir, processName, "MinutesToWait", 15, "int")
	SecondsToWait := readIniProfileSetting(ProfilesDir, processName, "SecondsToWait", MinutesToWait * 60, "int")
	MainUI_PosX := readIniProfileSetting(ProfilesDir, processName, "MainUI_PosX", A_ScreenWidth / 2, "int")
	MainUI_PosY := readIniProfileSetting(ProfilesDir, processName, "MainUI_PosY", A_ScreenHeight / 2, "int")
	KeyToSend := readIniProfileSetting(ProfilesDir, processName, "KeyToSend", "~LButton")
	currentTheme := readIniProfileSetting(ProfilesDir, processName, "SelectedTheme", "Dark Mode")

    updateGlobalThemeVariables(currentTheme)
}

saveProfileSettings(processName) {
	global localScriptDir
    global playSounds, isActive, isInStartFolder, isUIHidden
    global MinutesToWait, SecondsToWait, MainUI_PosX, MainUI_PosY
    global KeyToSend, currentTheme, AcceptedWarning, ProfilesDir, doMouseLock
    IniWrite("true", ProfilesDir, processName, "Exists")
    IniWrite(AcceptedWarning, ProfilesDir, "General", "AcceptedWarning")
    IniWrite(playSounds, ProfilesDir, processName, "SoundMode")
    IniWrite(isActive, ProfilesDir, processName, "isActive")
    IniWrite(isInStartFolder, ProfilesDir, processName, "isInStartFolder")
    IniWrite(isUIHidden, ProfilesDir, processName, "isUIHidden")
    IniWrite(MinutesToWait, ProfilesDir, processName, "MinutesToWait")
    IniWrite(SecondsToWait, ProfilesDir, processName, "SecondsToWait")
    IniWrite(MainUI_PosX, ProfilesDir, processName, "MainUI_PosX")
    IniWrite(MainUI_PosY, ProfilesDir, processName, "MainUI_PosY")
    IniWrite(KeyToSend, ProfilesDir, processName, "KeyToSend")
    IniWrite(currentTheme, ProfilesDir, processName, "SelectedTheme")
	IniWrite(doMouseLock, ProfilesDir, processName, "doMouseLock")
}

createDefaultProfileSettings(processName) {
	global ProfilesDir

	if !IniKeyExists(ProfilesDir, processName, "Exists")
		IniWrite("true", ProfilesDir, processName, "Exists")
	if !IniKeyExists(ProfilesDir, processName, "SoundMode")
		IniWrite(1, ProfilesDir, processName, "SoundMode")
	if !IniKeyExists(ProfilesDir, processName, "isActive")
		IniWrite(1, ProfilesDir, processName, "isActive")
	if !IniKeyExists(ProfilesDir, processName, "isInStartFolder")
		IniWrite("false", ProfilesDir, processName, "isInStartFolder")
	if !IniKeyExists(ProfilesDir, processName, "isUIHidden")
		IniWrite("false", ProfilesDir, processName, "isUIHidden")
	if !IniKeyExists(ProfilesDir, processName, "MinutesToWait")
		IniWrite(15, ProfilesDir, processName, "MinutesToWait")
	if !IniKeyExists(ProfilesDir, processName, "SecondsToWait")
		IniWrite(15 * 60, ProfilesDir, processName, "SecondsToWait")
	if !IniKeyExists(ProfilesDir, processName, "MainUI_PosX")
		IniWrite(0, ProfilesDir, processName, "MainUI_PosX")
	if !IniKeyExists(ProfilesDir, processName, "MainUI_PosY")
		IniWrite(0, ProfilesDir, processName, "MainUI_PosY")
	if !IniKeyExists(ProfilesDir, processName, "KeyToSend")
		IniWrite("~LButton", ProfilesDir, processName, "KeyToSend")
	if !IniKeyExists(ProfilesDir, processName, "SelectedTheme")
		IniWrite("Dark Mode", ProfilesDir, processName, "SelectedTheme")
	if !IniKeyExists(ProfilesDir, processName, "doMouseLock")
		IniWrite("false", ProfilesDir, processName, "doMouseLock")
	if !IniKeyExists(ProfilesDir, processName, "MouseSpeed")
		IniWrite(0, ProfilesDir, processName, "MouseSpeed")
	if !IniKeyExists(ProfilesDir, processName, "MouseClickRateOffset")
		IniWrite(0, ProfilesDir, processName, "MouseClickRateOffset")
	if !IniKeyExists(ProfilesDir, processName, "MouseClickRadius")
		IniWrite(0, ProfilesDir, processName, "MouseClickRadius")
}

SetSelectedProcessName(name) {
	global ProfilesDir, SelectedProcessExe
    updateIniProfileSetting(ProfilesDir, "SelectedProcessExe", "Process", name)
}

GetSelectedProcessName() {
	global ProfilesDir
	if !IniSectionExists(ProfilesDir, "SelectedProcessExe")
		updateIniProfileSetting(ProfilesDir, "SelectedProcessExe", "Process", "RobloxPlayerBeta.exe")
    return readIniProfileSetting(ProfilesDir, "SelectedProcessExe", "Process", "RobloxPlayerBeta.exe")
}

IniKeyExists(filePath, section, key) {
    return IniRead(filePath, section, key, "__MISSING__") != "__MISSING__"
}

createDefaultSettingsData(*) {
    global selectedProcessExe, ProfilesDir

	if !IniKeyExists(ProfilesDir, "General", "AcceptedWarning")
		IniWrite("false", ProfilesDir, "General", "AcceptedWarning")
	
    selectedExe := GetSelectedProcessName()
	loadProfileSettings(selectedExe)
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

setTrayIcon(icon := "") {
	global currentIcon
	createDefaultDirectories()
	if FileExist(icon) and icon != currentIcon {
		TraySetIcon(icon)
		currentIcon := icon
		; tell Windows to swap in the new .ico
		global MainUI
		global MainUI_Warning
		if MainUI or MainUI_Warning
			UpdateGuiIcon(icon)
	}
}

UpdateGuiIcon(newIconPath) {
	global MainUI
	global MainUI_Warning
	local MainUI_ID := MainUI and MainUI.Hwnd or ""
	local MainUI_Warning_ID := MainUI_Warning and MainUI_Warning.Hwnd or ""
    if !MainUI_ID && !MainUI_Warning_ID
        throw Error("No user interface found to update icon.")
	
    if !FileExist(newIconPath)
        throw Error("Icon file not found: " newIconPath)

    hIcon := DllCall(
        "LoadImageW"
      , "Ptr", 0                     ; hinst
      , "WStr", newIconPath          ; file
      , "UInt", 1                    ; IMAGE_ICON
      , "Int", 0                     ; cx (default)
      , "Int", 0                     ; cy (default)
      , "UInt", 0x10                 ; LR_LOADFROMFILE
      , "Ptr"
    )
    if !hIcon
        throw Error("Failed to load icon: " newIconPath)

    ; call SendMessageW directly:
	if MainUI_ID
		for wParam in [0, 1]  ; ICON_SMALL, ICON_BIG
			DllCall("SendMessageW"
			, "Ptr", MainUI_ID
			, "UInt", 0x80      ; WM_SETICON
			, "Ptr", wParam
			, "Ptr", hIcon
			)
	if MainUI_Warning_ID
		for wParam in [0, 1]  ; ICON_SMALL, ICON_BIG
		DllCall("SendMessageW"
			, "Ptr", MainUI_Warning_ID
			, "UInt", 0x80      ; WM_SETICON
			, "Ptr", wParam
			, "Ptr", hIcon
		)
	
    ; same SetWindowPos to repaint
	if MainUI_ID
		DllCall("SetWindowPos"
		, "Ptr", MainUI_ID
		, "Ptr", 0
		, "Int", 0, "Int", 0, "Int", 0, "Int", 0
		, "UInt", 0x27
		)
	if MainUI_Warning_ID
		DllCall("SetWindowPos"
		, "Ptr", MainUI_Warning_ID
		, "Ptr", 0
		, "Int", 0, "Int", 0, "Int", 0, "Int", 0
		, "UInt", 0x27
		)

    return true
}

createDefaultDirectories(*) {
	if !FileExist(localScriptDir)
		DirCreate(localScriptDir)

	if !FileExist(localScriptDir "\images")
		DirCreate(localScriptDir "\images")

	if !FileExist(localScriptDir "\images\icons")
		DirCreate(localScriptDir "\images\icons")

	for i,IconData in icons {
		if !FileExist(IconData.Icon)
			DownloadURL(IconData.URL, IconData.Icon)
	}
}

IsAltTabOpen() {
    return (
        WinExist("ahk_class MultitaskingViewFrame")
        || WinExist("ahk_class TaskSwitcherWnd")
        || WinExist("ahk_class #32771")
    ) != 0
}

readIniProfileSetting(filePath, section, key, default := "", type := "") {
    if !FileExist(filePath)
        return default

    value := IniRead(filePath, section, key, default)
	
    switch type {
        case "bool":
            return (value = "true" or value = 1 or value = "1")
        case "int":
            return Integer(value)
        case "float":
            return Number(value)
        default:
            return value
    }

	return value
}

EnsureDirectoryExists(filePath) {
    SplitPath(filePath,, &dir)
    if !DirExist(dir)
        DirCreate(dir)
}

updateIniProfileSetting(filePath, section, key, value) {
    EnsureDirectoryExists(filePath)

    existing := IniRead(filePath, section, key, "")
    if (existing != value)
        IniWrite(value, filePath, section, key)
}

updateIniProfileSection(filePath, section, settingsMap) {
    for key, val in settingsMap
        updateIniProfileSetting(filePath, section, key, val)
}

WM_SYSCOMMAND_Handler(wParam, lParam, msgNum, hwnd) {
    global MainUI, MainUI_PosX, MainUI_PosY
	global SelectedProcessExe, ProfilesDir, localScriptDir
    ; 0xF020 (SC_MINIMIZE) indicates the user is minimizing the window.
    if (wParam = 0xF020) {
        ; Save the current (restored) position before the minimize animation starts.
        pos := WinGetMinMax(MainUI.Title) != -1 and WinGetPos(&X := MainUI_PosX,&Y := MainUI_PosY,,,MainUI.Title)
		pos := {X: X, Y: Y}

		MainUI_PosX := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosX", A_ScreenWidth / 2, "int")
		MainUI_PosY := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosY", A_ScreenHeight / 2, "int")
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
					try FileDelete(tempUpdateFile)
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

ArrayHasValue(arr, val) {
	for each, v in arr {
		if (v == val)
			return true
	}
	return false
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
	
	SelectNewOption()

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

EndScriptProcess(*) {
	; Stop the timer tracking the GUI's position to prevent updating the registry during the window's closing animation
	SetTimer(SaveMainUIPosition, 0)
	ExitApp
}

; ############################## ;
; ########## Hotkeys ########### ;
; ############################## ;

RegisterHotkey(hotkeyStr := "Alt+Backspace") {
    global currentHotkey
    try {
        if currentHotkey
            Hotkey(currentHotkey, "Off")
        Hotkey(hotkeyStr, ToggleHide_Hotkey)
        currentHotkey := hotkeyStr
    } catch {
        SetTimer(() => ToolTip(), -2000)
    }
}

WaitForKeyPress(optionalGUI := "") {
    ; Ensure InputHook can see physical keystrokes
    SendMode("Event")

    ToolTip("Press a key combo to use as your toggle key...")

    ; — Create an InputHook capturing Modifiers (M) with no timeout (T0)
    ih := InputHook("M T0")
    ; Allow all visible keys through (text & non-text)
    ih.VisibleText    := true
    ih.VisibleNonText := true
    ; Disable suppression on *all* keys so nothing is eaten
    ih.KeyOpt("{All}", "-S")
    ; Exclude only mouse buttons (so they don’t end the hook)
    for btn in ["LButton","RButton","MButton","XButton1","XButton2"]
        ih.KeyOpt("{" btn "}", "E")
    ih.Start()

    ; — Canonicalize all modifier variants to a single name
    modKeys := Map(
        "LControl","Ctrl", "RControl","Ctrl", "Control","Ctrl"
      , "LShift","Shift",   "RShift","Shift",   "Shift","Shift"
      , "LAlt","Alt",       "RAlt","Alt",       "Alt","Alt"
      , "LWin","Win",       "RWin","Win",       "Win","Win"
    )
    ; The order we’ll display them in
    orderedMods := ["Ctrl","Alt","Shift","Win"]

    detectedMods := Map()  ; to record which modifiers were pressed
    lastKey := ""
	local_hotkey := ""
	
    ; — Loop until the user presses a non-modifier key
    while true {
        evt := ih.Wait()
        key := evt.Key
        if modKeys.HasKey(key) {
            detectedMods[ modKeys[key] ] := true
        } else {
            lastKey := key
            break
        }
    }
    ih.Stop()

    ; — If they never hit a real key, abort
    if !lastKey {
        ToolTip("Invalid combo. Press a non-modifier key.")
        SetTimer(() => ToolTip(), -1500)
        return "Set Toggle Key"
    }

    ; — Build the combo in proper order
    comboArr := []
    for _, modName in orderedMods {
        if detectedMods.HasKey(modName)
            comboArr.Push(modName)
    }

    if comboArr.Length() {
        prefix := JoinArray(comboArr, "+")   ; uses your helper: e.g. "Ctrl+Shift"
        local_hotkey := prefix . "+" . lastKey     ; e.g. "Ctrl+Shift+H"
    } else {
        local_hotkey := lastKey                    ; e.g. "H"
    }

    ; — Try to register & save it
    try {
        RegisterHotkey(local_hotkey)
        ; WriteHotkeyToRegistry(local_hotkey)
        ToolTip("Bound to: " local_hotkey)
    } catch {
        ToolTip("Invalid hotkey: " local_hotkey)
        local_hotkey := "Set Toggle Key"
    }
    SetTimer(() => ToolTip(), -1500)

	if optionalGUI {
		HotkeyLabel := optionalGUI["HotkeyLabel"]
		HotkeyLabel.Text := local_hotkey
		HotkeyLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	}

    return local_hotkey
}

old_WaitForKeyPress(optionalGUI := "") {
    ToolTip("Press a key combo to use as your toggle key...")

    ; — Create an InputHook capturing Modifiers (M), Visible keys (V), no timeout (T0)
    ih := InputHook("M V T0")
    ; Exclude only the five mouse buttons so we still see Ctrl/Shift/Alt/Win
    for btn in ["LButton","RButton","MButton","XButton1","XButton2"]
        ih.KeyOpt("{" btn "}", "E")
    ih.Start()

    ; — Canonicalize variants of modifier names to a single label
    modKeys := Map(
        "LControl","Ctrl", "RControl","Ctrl", "Control","Ctrl"
      , "LShift","Shift",   "RShift","Shift",   "Shift","Shift"
      , "LAlt","Alt",       "RAlt","Alt",       "Alt","Alt"
      , "LWin","Win",       "RWin","Win",       "Win","Win"
    )

    ; — Define the order in which modifiers should appear
    orderedMods := ["Ctrl","Alt","Shift","Win"]

    detectedMods := Map()  ; e.g. detectedMods["Ctrl"] := true
    lastKey := ""
	local_hotkey := ""

    ; — Loop until a non-modifier key is pressed
    while true {
        evt := ih.Wait()
        key := evt.Key
        if modKeys.HasKey(key) {
            detectedMods[ modKeys[key] ] := true
        } else {
            lastKey := key
            break
        }
    }
    ih.Stop()

    ; — If no real key was pressed, bail out
    if !lastKey {
        ToolTip("Invalid combo. Press a non-modifier key.")
        SetTimer(() => ToolTip(), -1500)
        return "Set Toggle Key"
    }

    ; — Build the modifier array in the correct display order
    comboArr := []
    for _, modName in orderedMods
        if detectedMods.HasKey(modName)
            comboArr.Push(modName)

    ; — Join with your helper and append the final key
    if (comboArr.Length()) {
        prefix := JoinArray(comboArr, "+")   ; e.g. "Ctrl+Shift"
        local_hotkey := prefix . "+" . lastKey     ; e.g. "Ctrl+Shift+H"
    } else {
        local_hotkey := lastKey                    ; e.g. "H"
    }

    ; — Attempt to register & persist the hotkey
    try {
        RegisterHotkey(local_hotkey)
        ; WriteHotkeyToRegistry(local_hotkey)
        ToolTip("Bound to: " local_hotkey)
    } catch {
        ToolTip("Invalid hotkey: " local_hotkey)
        local_hotkey := "Set Toggle Key"
    }
    SetTimer(() => ToolTip(), -1500)

	if optionalGUI {
		HotkeyLabel := optionalGUI["HotkeyLabel"]
		HotkeyLabel.Text := local_hotkey
		HotkeyLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	}
    return local_hotkey
}

JoinArray(arr, delim := "") {
    out := ""
    for i, val in arr {
        if i > 1
            out .= delim
        out .= val
    }
    return out
}

; ###################### ;
; ###### Registry ###### ;
; ###################### ;

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