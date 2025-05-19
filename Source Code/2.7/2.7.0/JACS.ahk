#Requires AutoHotkey >=2.0.19 64-bit
#SingleInstance Force
Persistent

global initializing := true
global version := "2.7.0"

CoordMode("Mouse", "Screen")
CoordMode("Menu", "Screen")
SetTitleMatchMode 2
DetectHiddenWindows(true)
A_HotkeyInterval := 0
A_MaxHotkeysPerInterval := 1000

global GeneralData := Map(
	"author", "WoahItsJeebus",
	"repo", "JACS",
	"versionData", Map()
)

global A_LocalAppData := EnvGet("LOCALAPPDATA")
global localScriptDir := A_LocalAppData "\JACS\"
global Utilities := localScriptDir "Utilities"
global ProfilesDir := localScriptDir "Profiles.ini"

global IconsFolder := localScriptDir "images\icons\"
global ActiveIcon := localScriptDir "images\icons\Active.ico"
global InactiveIcon := localScriptDir "images\icons\Inactive.ico"
global SearchingIcon := localScriptDir "images\icons\Searching.ico"
global initializingIcon := localScriptDir "images\icons\Initializing.ico"

global doDebug := true

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
global HeaderHeight := 28
global tipHeight := 20
global buttonHeight := 23
global PixelOffset := 10

global SelectedProcessExe := GetSelectedProcessName()
global URL_SCRIPT := "https://github.com/WoahItsJeebus/JACS/releases/latest/download/JACS.ahk"
global currentIcon := icons[4].Icon

; Cooldown Debounces
global cooldownToggleDebounce := false

setTrayIcon(currentIcon)
createDefaultSettingsData()
createDefaultDirectories()

global SettingsExists := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SettingsExists", false, "bool")
global MinutesToWait := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MinutesToWait", 15, "int")
global SecondsToWait := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SecondsToWait", MinutesToWait * 60, "int")
global minCooldown := 0
global lastUpdateTime := A_TickCount
global lastUpdateTimes := Map()

global playSounds := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SoundMode", 1, "int")
global isInStartFolder := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "IsInStartFolder", false, "bool")

global isActive := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "isActive", 1, "int") ; 1 = Disabled, 2 = Waiting, 3 = Enabled
global autoUpdateDontAsk := false
global FirstRun := True

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
global UI_Height := "350"

; Caches
global tips := []  ; Will be populated from tips.ahk or defaults if it fails
global ProcessWindowCache := Map()

; Core UI
global MainUI_BG := ""
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
global ID_SelectorLabel := ""
global ID_Selector := ""
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
global KeyToSend := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "KeyToSend", "~LButton")
global Global_Keybinds := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "Global_Keybinds", false, "bool")

; Extras Menu
global ShowingExtrasUI := false
global warningRequested := false

global fadeLock := false
global updateTheme := true
global intWindowColor := "404040"
global intControlColor := "606060"
global intProgressBarColor := "757575"
global ControlTextColor := "FFFFFF"
global linkColor := "99c3ff"
global currentTheme := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SelectedTheme", "Dark Mode")
global lastTheme := currentTheme

global buttonFontSize := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "ButtonFontSize", "12", "int")
global buttonFontWeight := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "ButtonFontWeight", "550", "int")
global buttonFont := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "ButtonFontStyle", "Consolas")

global LastActiveWindow := false
global AcceptedWarning := readIniProfileSetting(ProfilesDir, "General", "AcceptedWarning", false, "bool") and CreateGui() or createWarningUI()
global tempUpdateFile := ""

; =============== Screen Info ================ ;
global refreshRate := GetRefreshRate_Alt() or 60

toggleAutoUpdate(true)
OnExit(EndScriptProcess)
OnMessage(0x0112, WM_SYSCOMMAND_Handler)
DeleteTrayTabs()

A_TrayMenu.Insert("&Reload Script", "Fix GUI", MenuHandler)  ; Creates a new menu item.
SetTimer(RollThankYou, 30000, 100)

; ============================================= ;
; ============= Primary Functions ============= ;
; ============================================= ;

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
	global MainUI
	global MainUI_Warning
	
	global isActive
	global MainUI_BG
	
	global initializing
	global refreshRate := GetRefreshRate_Alt() or 60

	local AOTStatus := AlwaysOnTopActive == true and "+AlwaysOnTop" or "-AlwaysOnTop"
	local AOT_Text := (AlwaysOnTopActive == true and "On") or "Off"

	local MarginX := 10
	local MarginY := 10

	; Destroy old UI object
	if MainUI {
		MainUI.Destroy()
		MainUI := ""
	}
	
	if MainUI_Warning {
		MainUI_Warning.Destroy()
		MainUI_Warning := ""
	}

	; Create new UI
	global MainUI := Gui(AOTStatus . " +OwnDialogs") ; Create UI window
	MainUI.BackColor := MainUI_BG
	MainUI.OnEvent("Close", CloseApp)
	MainUI.Title := "Jeebus' Auto-Clicker"
	MainUI.MarginX := MarginX
	MainUI.MarginY := MarginY
	
	createMainButtons()
	createSideBar()
    ; UpdateTimerLabel()
	addTipBox()
	
	updateUIVisibility()
	ClampMainUIPos()
	SaveMainUIPosition()
	setTrayIcon(icons[isActive].Icon)

	if playSounds == 1
		Loop 2
			SoundBeep(300, 200)
	
	runNecessaryTimers()
	
	CheckDeviceTheme()

	if isActive > 1
		ToggleCore(,isActive)


	initializing := false
}

runNecessaryTimers(*) {
	local loopFunctions := Map(
		"CheckDeviceTheme", Map(
			"Function", CheckDeviceTheme.Bind(),
			"Interval", 250,
			"Disabled", true
		),
		"SaveMainUIPosition", Map(
			"Function", SaveMainUIPosition.Bind(),
			"Interval", 100,
			"Disabled", true
		),
		"CheckOpenMenus", Map(
			"Function", CheckOpenMenus.Bind(),
			"Interval", 250,
			"Disabled", false
		),
		"ClampMainUIPosition", Map(
			"Function", ClampMainUIPos.Bind(),
			"Interval", 1000,
			"Disabled", true
		),
		"ScrollTip", Map(
			"Function", ScrollTip.Bind(),
			"Interval", refreshRate * 0.225,
			"Disabled", false
		),
	)

	; Run loop functions
	for FuncName, Data in loopFunctions
		if not Data["Disabled"] {
			if FuncName == "ScrollTip"
				Sleep(100)
			SetTimer(Data["Function"], Data["Interval"])
		}
}

addTipBox(*) {
	global MainUI, intWindowColor, intControlColor, ControlTextColor, linkColor, ProfilesDir
	global TipsDisplayed := []     ; Recently used indexes
	global TipTimer := ""          ; Controls when a new tip is picked
	global ScrollTimer := ""       ; Controls horizontal scroll updates
	global TipScrollData := Map()  ; Keeps track of label & offset per GUI
	global tipHeight := 20         ; Height of the tip box
	global tips
	
	global UI_Height, UI_Width, ICON_WIDTH, ICON_SPACING, BUTTON_HEIGHT, HeaderHeight
	local buttonHeight := 23
	local buttonFontSize := 10
	local buttonFontWeight := 500
	local buttonFont := "Consolas"

	local UI_Margin_Width := UI_Width-MainUI.MarginX
	local UI_Margin_Height := UI_Height-MainUI.MarginY

	local dummy := MainUI.Add("Text", "x0 y0 Section w" UI_Margin_Width " h" tipHeight " 0x200")  ; dummy container
	tipBox := MainUI.Add("Text", "x0 y0 w" UI_Margin_Width " h" tipHeight " BackgroundTrans vTipBox", "")
	tipBox.SetFont("s" tipHeight/2 " w" buttonFontWeight " Italic", buttonFont)
	tipBox.Opt("c" ControlTextColor . " BackgroundTrans")
	
	TipScrollData[MainUI] := Map(
		"Ctrl", tipBox,
		"Offset", 10,
		"CurrentText", "",
		"TipList", tips,  ; ← Uses dynamic global list
		"LastIndexes", []
	)

	LoadNewTip()
}

createMainButtons(*) {
	global MainUI, intWindowColor, intControlColor, ControlTextColor, linkColor, ProfilesDir
	global UI_Width, UI_Height, ICON_WIDTH, ICON_SPACING, BUTTON_HEIGHT, HeaderHeight, tipHeight
	global buttonFontSize, buttonFontWeight, buttonFont, buttonHeight
	global SelectedProcessExe, ProcessWindowCache
	
	local UI_Margin_Width := UI_Width-MainUI.MarginX
	local UI_Margin_Height := UI_Height-MainUI.MarginY

	local Header := MainUI.Add("Text","x" ICON_WIDTH " y+" tipHeight+MainUI.MarginY " Section Center vMainHeader cff4840 h" math.clamp(HeaderHeight, 30, math.huge()) " w" UI_Width,"Jeebus' Auto-Clicker — V" version)

	; ########################
	; 		  Buttons
	; ########################

	global activeText_Core := (isActive == 3 and "Enabled") or (isActive == 2 and "Waiting...") or "Disabled"
	global CoreToggleButton := MainUI.Add("Button", "xs+" ICON_WIDTH + UI_Width/6 " h30 w" (UI_Margin_Width*0.75)-ICON_WIDTH, "Auto-Clicker: " activeText_Core)
	CoreToggleButton.OnEvent("Click", ToggleCore)

	; Reset Cooldown
	global ResetCooldownButton := MainUI.Add("Button", "x" (ICON_WIDTH*2) + UI_Margin_Width*0.375 " h30 w" UI_Margin_Width/4, "Reset")
	ResetCooldownButton.OnEvent("Click", ResetCooldown)

	SeparationLine := MainUI.Add("Text", "Section x" ICON_WIDTH*2 " 0x7 h1 w" UI_Margin_Width) ; Separation Space
	SeparationLine.BackColor := "0x8"
	
	; Progress Bar
	; local allProcessKeys := ProcessWindowCache[SelectedProcessExe]
	global ID_SelectorLabel := MainUI.Add("Text", "x" ICON_WIDTH*2 " y+0 Center vID_SelectorLabel h" buttonHeight " w" UI_Margin_Width, SelectedProcessExe)
	; global ID_Selector := MainUI.Add("DropDownList", "x" ICON_WIDTH*2 " y+0 Center vID_Selector R10 h" buttonHeight " w" UI_Margin_Width " Choose1", allProcessKeys)
	global WaitTimerLabel := MainUI.Add("Text", "x" ICON_WIDTH*2 " vWaitTimerLabel Center 0x300 0xC00 h20 w" UI_Margin_Width, "0%")
	global WaitProgress := MainUI.Add("Progress", "x" ICON_WIDTH*2 " vWaitProgress Center h40 w" UI_Margin_Width)
	global ElapsedTimeLabel := MainUI.Add("Text", "x" ICON_WIDTH*2 " vElapsedTimeLabel Center 0x300 0xC00 h20 w" UI_Margin_Width, "00:00 / 0 min")
	
	; Credits
	global CreditsLink := MainUI.Add("Link","c" linkColor . " Left h" buttonHeight " w" UI_Margin_Width, 'Created by <a href="https://www.roblox.com/users/3817884/profile">@WoahItsJeebus</a>')
	; Move credits link to bottom of UI_Height
	local creditsY := UI_Height + (MainUI.MarginY - HeaderHeight - (tipHeight*1.5))
	CreditsLink.Move(ICON_WIDTH*2, UI_Margin_Height - buttonHeight - MainUI.MarginY)
	LinkUseDefaultColor(CreditsLink)

	CoreToggleButton.Opt("Background" intWindowColor)
	ResetCooldownButton.Opt("Background" intWindowColor)
	WaitTimerLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	ElapsedTimeLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	WaitProgress.Opt("Background" intProgressBarColor)
	CreditsLink.Opt("c" linkColor)
	; ID_Selector.Opt("Background" intWindowColor . " c" ControlTextColor)
	ID_SelectorLabel.Opt("Background" intWindowColor . " c" ControlTextColor)

	Header.SetFont("s18 w600", "Ink Free")
	CoreToggleButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ResetCooldownButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ElapsedTimeLabel.SetFont("s" buttonFontSize*1.15 " w" buttonFontWeight, buttonFont)
	WaitTimerLabel.SetFont("s" buttonFontSize*1.15 " w" buttonFontWeight, buttonFont)
	CreditsLink.SetFont("s" buttonFontSize*1.15 " w" buttonFontWeight, buttonFont)
	; ID_Selector.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ID_SelectorLabel.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)

	; ID_Selector.OnEvent("Change", (*) => UpdateTimerLabel)
}

createSideBar(*) {
	global MainUI, intWindowColor, UI_Height, ProfilesDir
	global ICON_SPACING, ICON_WIDTH, BUTTON_HEIGHT, HeaderHeight, tipHeight
	
	if not MainUI
		return

	; Sidebar background
	local sidebarBackground := MainUI.Add("Text","x" MainUI.MarginX " y0" " Section vSideBarBackground w" ICON_WIDTH " h" UI_Height-MainUI.MarginY-tipHeight " BackgroundFF0000")
	
	; Store buttons and tooltip data for hover tracking
	global iconButtons := []

	for idx, icon in sidebarData {
		y := ((idx - 1) * (BUTTON_HEIGHT + ICON_SPACING)) + ICON_SPACING + HeaderHeight + tipHeight
		btn := MainUI.Add("Button", "xs" " y" y " vIconButton" . idx . " w" ICON_WIDTH " h" BUTTON_HEIGHT " Background" intWindowColor, icon.Icon)
		btn.SetFont("s" BUTTON_HEIGHT/2 " w500")
		btn.OnEvent("Click", icon.Function)  ; Assign specific function
		iconButtons.Push({control: btn, tooltip: icon.Tooltip})
	}

	sidebarBackground.Visible := true

	; Tooltip hover tracker
	global currentTooltipIndex := 0
	SetTimer(CheckSidebarHover, 100)
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
	global buttonFontSize, buttonFontWeight, buttonFont, buttonHeight
	local PixelOffset := 10
	local Popout_Width := 320
	local Popout_Height := 400
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
	global currentHotkey
	global ProfilesDir
	global ID_SelectorLabel
	; local HotkeyLabel := ""
	; local HotkeyButton := ""

	; Local Controls
	local AOTStatus := AlwaysOnTopActive == true and "+AlwaysOnTop" or "-AlwaysOnTop"
	local AOT_Text := (AlwaysOnTopActive == true and "On") or "Off"
	local ProcessDropdown := ""
	local themeDropdown := ""
	local themeLabel := ""
	local editTheme := ""
	local ProcessLabel := ""
	local DescriptionBox := ""

	; Colors
	global currentTheme := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SelectedTheme", "Default", "str")
	global intWindowColor
	global intControlColor
	global ControlTextColor

	local Popout_MarginX := 10
	local Popout_MarginY := 10

	CloseSettingsUI(*) {
		SetTimer(mouseHoverDescription,0)
		
		if WindowSettingsUI {
			WindowSettingsUI.Destroy()
			WindowSettingsUI := ""
		}

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
	WindowSettingsUI.MarginX := Popout_MarginX
	local activeText_Sound := (playSounds == 1 and "All") or (playSounds == 2 and "Less") or (playSounds == 3 and "None")
	local themeNames := GetThemeListFromINI(localScriptDir "\themes.ini")

	if AlwaysOnTopButton
		AlwaysOnTopButton := ""
	
	if SoundToggleButton
		SoundToggleButton := ""

	local Popout_Margin_Width := Popout_Width-(WindowSettingsUI.MarginX*2)
	local Popout_Margin_Height := Popout_Height-(WindowSettingsUI.MarginY*2)

	AlwaysOnTopButton := WindowSettingsUI.Add("Button", "Section Center vAlwaysOnTopButton h" buttonHeight " w" Popout_Margin_Width, "Always-On-Top: " AOT_Text)
	SoundToggleButton := WindowSettingsUI.Add("Button", "xm Section Center vSoundToggleButton h" buttonHeight " w" Popout_Margin_Width, "Sounds: " activeText_Sound)
	themeLabel := WindowSettingsUI.Add("Text", "xm Left vThemeLabel h" buttonHeight*0.95 " w" Popout_Margin_Width, "Theme: " . currentTheme)
	themeDropdown := WindowSettingsUI.Add("DropDownList", "Section xm R10 vThemeChoice h" buttonHeight " w" (Popout_Margin_Width*0.75) - buttonHeight-6, themeNames)
	editTheme := WindowSettingsUI.Add("Button","x+1 y+-22 Center vEditThemeButton h" buttonHeight+6 " w" Popout_Margin_Width*0.25, "Edit Theme")
	refreshTheme := WindowSettingsUI.Add("Button", "x+1 Center vRefreshThemeButton h" buttonHeight+6 " w" buttonHeight+6, "🔄")
	ProcessLabel := WindowSettingsUI.Add("Text", "xm Left h" buttonHeight " vProcessLabel w" Popout_Margin_Width, "Searching for: " SelectedProcessExe)
	ProcessDropdown := WindowSettingsUI.Add("DropDownList", "xm y+0 R10 Center vProcessDropdown h" buttonHeight " w" Popout_Margin_Width, [SelectedProcessExe])

	local groupPadding := 20
	descriptionGroup := WindowSettingsUI.Add("GroupBox","xm Section vDescriptionGroupBox h" 0 " w" Popout_Margin_Width, "")
	DescriptionBoxBG := WindowSettingsUI.Add("Text", "xs+" groupPadding/2 " yp+" groupPadding " Left vDescriptionBoxBG h" . (0) . " w" Popout_Margin_Width - groupPadding)
	DescriptionBox := WindowSettingsUI.Add("Text", "xs+" groupPadding/2 " yp+" groupPadding " Section Left vInvis_BG_DescriptionBox h" . (0) . " w" Popout_Margin_Width - groupPadding)

	; Get index of the current theme name
	for index, name in themeNames {
		if (name = currentTheme) {
			themeDropdown.Choose(index)
			break
		}
	}
	
	; ################################# ;
	; Slider Description Box
	local ThemeMap := LoadThemeFromINI(currentTheme)
	
	descriptionGroup.Opt("Background" intWindowColor . " c" ControlTextColor)
	DescriptionBoxBG.Opt("Background" intWindowColor . " c" ControlTextColor)
	AlwaysOnTopButton.Opt("Background" intWindowColor)
	SoundToggleButton.Opt("Background" intWindowColor)
	themeLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	editTheme.Opt("Background" intWindowColor . " c" ControlTextColor)
	refreshTheme.Opt("Background" intWindowColor . " c" ControlTextColor)
	ProcessLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	DescriptionBox.Opt("BackgroundTrans" . " c" ControlTextColor)

	descriptionGroup.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	AlwaysOnTopButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	SoundToggleButton.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	themeLabel.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	editTheme.SetFont("s" buttonFontSize*0.7 " w" buttonFontWeight, buttonFont)
	refreshTheme.SetFont("s" 16 " w" 550, buttonFont)
	themeDropdown.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ProcessLabel.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	ProcessDropdown.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	DescriptionBox.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)

	AlwaysOnTopButton.OnEvent("Click", ToggleAOT)
	SoundToggleButton.OnEvent("Click", ToggleSound)
	editTheme.OnEvent("Click", processThemeEdit)
	refreshTheme.OnEvent("Click", CheckDeviceTheme)
	themeDropdown.OnEvent("Change", OnThemeDropdownChange)
	ProcessDropdown.OnEvent("Change", OnProcessDropdownChange)

	ProcessDropdown.Choose(1)
	PopulateProcessDropdown(ProcessDropdown)

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
	
	processThemeEdit(*) {
		if FileExist(localScriptDir "\themes.ini")
			Run(localScriptDir "\themes.ini")
		else
			SendNotification("themes.ini not found!", Map(
				"Title", "JACS - Error",
				"Timeout", 5000,
				"Type", "Info",
			),)
	}
	
	OnThemeDropdownChange(*) {
		global ProfilesDir
		selectedTheme := themeDropdown.Text
		updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "SelectedTheme", selectedTheme)
		currentTheme := selectedTheme
		themeLabel.Text := "Theme: " . selectedTheme
		
		updateGlobalThemeVariables(selectedTheme)
		CheckDeviceTheme()
		; updateGUITheme(WindowSettingsUI)
		; updateGUITheme(MainUI)
	}
	
	OnProcessDropdownChange(*) {
		local selectedExe := ProcessDropdown.Text  ; get the selected process name
		ProcessLabel.Text := "Searching for: " . selectedExe
		ID_SelectorLabel.Text := selectedExe
		
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

	updateDescriptionBox(newText := "") {
		if newText == DescriptionBox.Text
			return

		ControlGetPos(&groupX, &groupY, &groupW, &groupH, descriptionGroup)
		DescriptionBox.Text := newText

		local textWidth := MeasureTextWidth(DescriptionBox, newText)
		local textHeight := MeasureWrappedTextHeight(DescriptionBox, newText)

		descriptionGroup.Move(,,, textHeight+(groupPadding*2))
		DescriptionBoxBG.Move(,,, textHeight+(groupPadding/2))
		DescriptionBox.Move(, groupY + groupPadding,, textHeight)
		
		WindowSettingsUI.Show("AutoSize")
	}
	
	mouseHoverDescription(*)
	{
		if not WindowSettingsUI or not DescriptionBox
			return SetTimer(mouseHoverDescription,0)

		MouseGetPos(&MouseX,&MouseY,&HoverWindow,&HoverControl)
		local targetControl := ""

		if HoverControl && HoverWindow && HoverWindow {
			if HoverWindow != WindowSettingsUI.Hwnd
				return

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

	CheckDeviceTheme()
	updateDescriptionBox(" ")
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
	
	global buttonFontSize, buttonFontWeight, buttonFont
	local buttonHeight := 23

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
	
	
	local Popout_MarginX := 10
	local Popout_MarginY := 10
	local groupPadding := 20
	
	local Popout_Margin_Width := Popout_Width - (SettingsUI.MarginX*2)
	local Popout_Margin_Height := Popout_Height - (SettingsUI.MarginY*2)
	
	local buddyWidth := 40
	local sliderWidth := (Popout_Margin_Width - ((buddyWidth+SettingsUI.MarginX)*2))

	MouseSpeedLabel := SettingsUI.Add("Text", "Section Center vMouseSpeedLabel h" buttonHeight " w" Popout_Margin_Width, "Mouse Speed: " . math.clamp(MouseSpeed,0,maxSpeed) . " ms")
	MouseSpeedSlider := SettingsUI.Add("Slider", "x" buddyWidth+(SettingsUI.MarginX*2) " 0x300 0xC00 AltSubmit vMouseSpeed w" sliderWidth)

	ClickRateOffsetLabel := SettingsUI.Add("Text", "xm Section Center vClickRateOffsetLabel h" buttonHeight " w" Popout_Margin_Width, "Click Rate Offset: " . math.clamp(MouseClickRateOffset,0,maxSpeed) . " ms")
	ClickRateSlider := SettingsUI.Add("Slider", "x" buddyWidth+(SettingsUI.MarginX*2) " y+-" . sliderOffset . " 0x300 0xC00 AltSubmit vClickRateOffset w" sliderWidth)

	ClickRadiusLabel := SettingsUI.Add("Text", "xm Section Center vClickRadiusLabel h" buttonHeight " w" Popout_Margin_Width, "Click Radius: " . math.clamp(MouseClickRadius,0,maxSpeed) . " pixels")
	ClickRadiusSlider := SettingsUI.Add("Slider", "x" buddyWidth+(SettingsUI.MarginX*2) " y+-" . sliderOffset . " 0x300 0xC00 AltSubmit vClickRadius w" sliderWidth)
	
	MouseClicksLabel := SettingsUI.Add("Text", "xm Section Center vMouseClicksLabel h" buttonHeight " w" Popout_Margin_Width, "Click Amount: " . math.clamp(MouseClicks,1,maxClicks) . " clicks")
	MouseClicksSlider := SettingsUI.Add("Slider", "x" buddyWidth+(SettingsUI.MarginX*2) " y+-" . sliderOffset . " 0x300 0xC00 AltSubmit vMouseClicks w" sliderWidth)
	
	CooldownLabel := SettingsUI.Add("Text", "xm Section Center vCooldownLabel h" buttonHeight " w" Popout_Margin_Width, "Cooldown: " SecondsToWait " seconds")
	EditCooldownButton := SettingsUI.Add("Button", "x" Popout_MarginX " yp vCooldownEditor h" buttonHeight " w" Popout_Margin_Width/5, "Custom")
	CooldownSlider := SettingsUI.Add("Slider", "x" buddyWidth+(SettingsUI.MarginX*2) " y+-" sliderOffset . " 0x300 0xC00 AltSubmit vCooldownSlider w" sliderWidth)

	SendKeyLabel := SettingsUI.Add("Text", "xm+" Popout_MarginX/2 " Section Center vSendKeyLabel h" buttonHeight " w" Popout_Margin_Width/2-Popout_MarginX, "Send Key:")
	SendKeyButton := SettingsUI.Add("Button", "xm+" Popout_MarginX/2 " Section Center vSendKeyButton h" buttonHeight " w" Popout_Margin_Width/2-Popout_MarginX, keytoSend == "LButton" ? "Left Click" : "Right Click")
	
	ToggleMouseLock := SettingsUI.Add("Button", "x+m Center vToggleMouseLock h" buttonHeight " w" Popout_Margin_Width/2-Popout_MarginX, "Block Inputs: " . (toggleStatus == "Enabled" ? "On" : "Off"))
	
	; Slider Description Box
	descriptionGroup := SettingsUI.Add("GroupBox","xm Section vDescriptionGroupBox h" 0 " w" Popout_Margin_Width, "")
	DescriptionBoxBG := SettingsUI.Add("Text", "xs+" groupPadding/2 " yp+" groupPadding " Left vDescriptionBoxBG h" . (0) . " w" Popout_Margin_Width - groupPadding)
	DescriptionBox := SettingsUI.Add("Text", "xs+" groupPadding/2 " yp+" groupPadding " Section Left vInvis_BG_DescriptionBox h" . (0) . " w" Popout_Margin_Width - groupPadding)
	
	; Hover Descriptions
	local Descriptions := Map(
		; Sliders
		"MouseSpeed", "Use this slider to control how fast the mouse moves to each location in the auto-clicker sequence.",
		"ClickRateOffset", 'Use this slider to control the time between clicks when the auto-clicker fires.',
		"ClickRadius", "Use this slider to add random variations to the click auto-clicker's click pattern.`n`n(Higher values = Larger area of randomized clicks)",
		"ToggleMouseLock", "This button controls if the script blocks user inputs or not during the short auto-click sequence.`n`nIt is recommended to enable this setting if you are actively using your mouse or keyboard when the script is running. This is to prevent accidental mishaps in your gameplay.`n`n(Note: This setting will not impede on your active gameplay session, as your manual inputs will reset the script's auto-click timer!)",
		"MouseClicks", "Use this slider to control how many clicks are sent when the bar fills to 100%.",
		"CooldownEditor", "This button controls the duration of the auto-clicker sequence timer.`n`nLength: 0-15 minutes`n`n(Note: Setting the auto-clicker to 0 will constantly click, like typical auto-clickers, however other windows not in the target scope will be ignored and not clicked.)",
		"CooldownSlider", "Use this slider to fine-tune the cooldown for the auto-clicker. Alternatively you can use the `"Custom Cooldown`" button to set a specific value.",
		"SendKeyLabel", "This button controls whether the script sends a left or right click when the auto-clicker fires.`n`nLeft Click: Sends a left click to the target window.`n`nRight Click: Sends a right click to the target window.",
		"SendKeyButton", "This button controls whether the script sends a left or right click when the auto-clicker fires.`n`nLeft Click: Sends a left click to the target window.`n`nRight Click: Sends a right click to the target window.",
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
	SendKeyLabel.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	
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
	
	SendKeyLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	MouseSpeedLabel.Opt("Background" intWindowColor " c" ControlTextColor)
	ClickRateOffsetLabel.Opt("Background" intWindowColor " c" ControlTextColor)
	ClickRadiusLabel.Opt("Background" intWindowColor " c" ControlTextColor)
	MouseClicksLabel.Opt("Background" intWindowColor " c" ControlTextColor)
	CooldownLabel.Opt("Background" intWindowColor " c" ControlTextColor)
	EditCooldownButton.Opt("Background" intWindowColor "")
	ToggleMouseLock.Opt("Background" intWindowColor " c" ControlTextColor)
	SendKeyButton.Opt("Background" intWindowColor " c" ControlTextColor)
	descriptionGroup.Opt("Background" intWindowColor . " c" ControlTextColor)
	DescriptionBoxBG.Opt("Background" intWindowColor . " c" ControlTextColor)
	DescriptionBox.Opt("Background" intWindowColor . " c" ControlTextColor)

	MouseSpeedSlider.Opt("ToolTipBottom Buddy1MS_Buddy1 Buddy2MS_Buddy2 TickInterval" maxSpeed/10 " Range0-" maxSpeed)
	ClickRateSlider.Opt("ToolTipBottom Buddy1Rate_Buddy1 Buddy2Rate_Buddy2 TickInterval" maxRate/10 " Range0-" maxRate)
	ClickRadiusSlider.Opt("ToolTipBottom Buddy1ClickRadiusBuddy1 Buddy2ClickRadiusBuddy2 TickInterval" maxRadius/10 " Range0-" maxRadius)
	MouseClicksSlider.Opt("ToolTipBottom Buddy1MouseClicksBuddy1 Buddy2MouseClicksBuddy2 TickInterval" maxClicks/10 " Range1-" maxClicks)
	CooldownSlider.Opt("ToolTipBottom Buddy1Cooldown_Buddy1 Buddy2Cooldown_Buddy2 TickInterval" (maxCooldown-10)/15 " Range10-" maxCooldown)

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
	CloseSettingsUI(*) {
		SetTimer(mouseHoverDescription,0)

		if SettingsUI {
			SettingsUI.Destroy()
			SettingsUI := ""
		}

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
		if newText == DescriptionBox.Text
			return

		ControlGetPos(&groupX, &groupY, &groupW, &groupH, descriptionGroup)
		DescriptionBox.Text := newText

		local textWidth := MeasureTextWidth(DescriptionBox, newText)
		local textHeight := MeasureWrappedTextHeight(DescriptionBox, newText)

		descriptionGroup.Move(,,, textHeight+(groupPadding*2.05))
		DescriptionBoxBG.Move(,,, textHeight+(groupPadding/2.05))
		DescriptionBox.Move(, groupY + groupPadding,, textHeight)
		
		SettingsUI.Show("AutoSize")
	}

	mouseHoverDescription(*)
	{
		if not SettingsUI or not DescriptionBox
			return SetTimer(mouseHoverDescription,0)

		MouseGetPos(&MouseX,&MouseY,&HoverWindow,&HoverControl)
		local targetControl := ""

		if HoverControl && HoverWindow && HoverWindow {
			if HoverWindow != SettingsUI.Hwnd
				return
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
	
	updateDescriptionBox(" ")
	CheckDeviceTheme()
	SettingsUI.Show("AutoSize X" . CenterX . " Y" . CenterY . " w" . Popout_Width . "h" . Popout_Height)

	SetTimer(mouseHoverDescription,50)
}

CreateScriptSettingsGUI(*) {
	global ProfilesDir

	; UI Settings
	local PixelOffset := 10
	local Popout_Width := 300
	local Popout_Height := 350
	local labelOffset := 50
	local sliderOffset := 2.5

	; Button Settings
	global buttonFontSize, buttonFontWeight, buttonFont
	local buttonHeight := 23

	; Labels, Sliders, Buttons
	global EditButton
	global ExitButton
	global OpenMouseSettingsButton
	global ReloadButton
	global EditorButton
	global ScriptDirButton
	global AddToBootupFolderButton
	local DescriptionBox := ""
	local descriptionGroup := ""
	local DescriptionBoxBG := ""

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

	local Popout_Margin_Width := ""
	local Popout_Margin_Height := ""

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

	ScriptSettingsUI := Gui(AOTStatus " +Owner" . MainUI.Hwnd)
	ScriptSettingsUI.Title := "Script Settings"
	ScriptSettingsUI.BackColor := intWindowColor
	Popout_Margin_Width := Popout_Width-(ScriptSettingsUI.MarginX*2)
	Popout_Margin_Height := Popout_Height-(ScriptSettingsUI.MarginY*2)

	local Popout_MarginX := 10
	local Popout_MarginY := 10
	local groupPadding := 20
	
	local Popout_Margin_Width := Popout_Width - (ScriptSettingsUI.MarginX*2)
	local Popout_Margin_Height := Popout_Height - (ScriptSettingsUI.MarginY*2)

	EditButton := 				ScriptSettingsUI.Add("Button", "h" buttonHeight " w" Popout_Margin_Width " vEditButton Section Center", "View Script")
	ReloadButton := 			ScriptSettingsUI.Add("Button", "h" buttonHeight " w" Popout_Margin_Width " vReloadButton xs", "Relaunch Script")
	ExitButton := 				ScriptSettingsUI.Add("Button", "h" buttonHeight " w" Popout_Margin_Width " vExitButton xs", "Close Script")
	EditorButton := 			ScriptSettingsUI.Add("Button", "h" buttonHeight " w" Popout_Margin_Width " vEditorSelector xs", "Select Script Editor")
	ScriptDirButton := 			ScriptSettingsUI.Add("Button", "h" buttonHeight " w" Popout_Margin_Width " vScriptDir xs", "Open File Location")
	AddToBootupFolderButton :=  ScriptSettingsUI.Add("Button", "h" buttonHeight " w" Popout_Margin_Width " vStartupToggle xs", addToStartUp_Text)

	evenlySpaceControls() {
		local buttonCount := 0
		local remainingHeight := 0

		for i, control in ScriptSettingsUI {
			if control.Name != "Section" {
				buttonCount++
				local totalHeight := buttonHeight * buttonCount + (ScriptSettingsUI.MarginY * (buttonCount - 1)) + PixelOffset * 2
				remainingHeight := Popout_Margin_Height - totalHeight + (ScriptSettingsUI.MarginY * 2)

				control.Y := (remainingHeight / 2) + (buttonHeight * (i - 1)) + ScriptSettingsUI.MarginY * i + PixelOffset
			}
		}
		
		; Slider Description Box
		descriptionGroup := ScriptSettingsUI.Add("GroupBox","xm Section vDescriptionGroupBox h" 0 " w" Popout_Margin_Width, "")
		DescriptionBoxBG := ScriptSettingsUI.Add("Text", "xs+" groupPadding/2 " yp+" groupPadding " Left vDescriptionBoxBG h" . (0) . " w" Popout_Margin_Width - groupPadding)
		DescriptionBox := ScriptSettingsUI.Add("Text", "xs+" groupPadding/2 " yp+" groupPadding " Section Left vInvis_BG_DescriptionBox h" . (0) . " w" Popout_Margin_Width - groupPadding)
	}
	
	evenlySpaceControls()

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
	DescriptionBox.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)

	EditButton.Opt("Background" intWindowColor)
	ReloadButton.Opt("Background" intWindowColor)
	ExitButton.Opt("Background" intWindowColor)
	EditorButton.Opt("Background" intWindowColor)
	ScriptDirButton.Opt("Background" intWindowColor)
	AddToBootupFolderButton.Opt("Background" intWindowColor)
	descriptionGroup.Opt("Background" intWindowColor . " c" ControlTextColor)
	DescriptionBoxBG.Opt("Background" intWindowColor . " c" ControlTextColor)
	DescriptionBox.Opt("Background" intWindowColor . " c" ControlTextColor)

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

	CloseSettingsUI(*) {
		SetTimer(mouseHoverDescription,0)

		if ScriptSettingsUI {
			ScriptSettingsUI.Destroy()
			ScriptSettingsUI := ""
		}
		WinActivate(MainUI.Title)
	}

	updateDescriptionBox(newText := "") {
		if newText == DescriptionBox.Text
			return

		ControlGetPos(&groupX, &groupY, &groupW, &groupH, descriptionGroup)
		DescriptionBox.Text := newText

		local textWidth := MeasureTextWidth(DescriptionBox, newText)
		local textHeight := MeasureWrappedTextHeight(DescriptionBox, newText)

		descriptionGroup.Move(,,, textHeight+(groupPadding*2.1))
		DescriptionBoxBG.Move(,,, textHeight+(groupPadding/2.1))
		DescriptionBox.Move(, groupY + groupPadding,, textHeight)
		
		ScriptSettingsUI.Show("AutoSize")
	}

	mouseHoverDescription(*)
	{
		if not ScriptSettingsUI or not DescriptionBox
			return SetTimer(mouseHoverDescription,0)

		MouseGetPos(&MouseX,&MouseY,&HoverWindow,&HoverControl)
		local targetControl := ""

		if HoverControl && HoverWindow && HoverWindow {
			if HoverWindow != ScriptSettingsUI.Hwnd
				return
			try targetControl := ScriptSettingsUI.__Item[HoverControl]
			if ScriptSettingsUI and DescriptionBox and HoverControl and targetControl and Descriptions.Has(targetControl.Name) and DescriptionBox.Text != Descriptions[targetControl.Name] {
				try updateDescriptionBox(Descriptions[targetControl.Name])
			}
			else if ScriptSettingsUI and DescriptionBox and not HoverControl or not targetControl or not Descriptions.Has(targetControl.Name) {
				try updateDescriptionBox()
			}
		}
	}

	; Get full window position and size (including title bar)
	WinGetPos(&MainX, &MainY, &MainW, &MainH, MainUI.Hwnd)

	CenterX := MainX + (MainW // 2) - (Popout_Width // 2)
	CenterY := MainY + (MainH // 2) - (Popout_Height // 2)

	CheckDeviceTheme()
	updateDescriptionBox(" ")
	ScriptSettingsUI.Show("AutoSize X" . CenterX . " Y" . CenterY . " w" . Popout_Width . " h" . Popout_Height)
	SetTimer(mouseHoverDescription,50)
}

CreateExtrasGUI(*) {
	global ProfilesDir

	global ExtrasUI, PatchUI
	global warningRequested
	global MainUI_PosX
	global MainUI_PosY
	global AlwaysOnTopActive

	global buttonFontSize, buttonFontWeight, buttonFont, buttonHeight
	global PixelOffset

	; Colors
	global intWindowColor
	global intControlColor
	global ControlTextColor

	local AOTStatus := AlwaysOnTopActive == true and "+AlwaysOnTop" or "-AlwaysOnTop"
	local createNewWarningButton := ""
	local Popout_Width := 300
	local Popout_Height := 350
	local Popout_Margin_Height := 0
	local Popout_Margin_Width := 0

	local Popout_MarginX := 10
	local Popout_MarginY := 10
	local groupPadding := 20

	local descriptionGroup := ""
	local DescriptionBoxBG := ""
	local DescriptionBox := ""

	global buttonHeight
	
	; Create new UI

	if ExtrasUI
		ExtrasUI.Destroy()

	ExtrasUI := Gui(AOTStatus)
	ExtrasUI.Opt("+Owner" . MainUI.Hwnd)
	ExtrasUI.MarginX := Popout_MarginX
	ExtrasUI.MarginY := Popout_MarginY
	ExtrasUI.BackColor := intWindowColor
	ExtrasUI.Title := "Extras"
	ExtrasUI.OnEvent("Close", killGUI)
	ExtrasUI.SetFont("w" buttonFontWeight . " s" buttonFontSize, buttonFont)
	
	Popout_Margin_Width := Popout_Width-(ExtrasUI.MarginX*2)
	Popout_Margin_Height := Popout_Height-(ExtrasUI.MarginY*2)
	
	local DiscordLink := ExtrasUI.Add("Button", "vDiscordLink Center h" . buttonHeight . " w" . Popout_Margin_Width, 'Join the Discord!')
	local GitHubLink := ExtrasUI.Add("Button", "vGithubLink Center h" . buttonHeight . " w" . Popout_Margin_Width, "GitHub Repository")
	local OpenWarningLabel := ExtrasUI.Add("Button", "vOpenWarning Center h" . buttonHeight . " w" . Popout_Margin_Width, "View Warning Agreement")
	local ViewPatchnotes := ExtrasUI.Add("Button", "vViewPatchnotes Center h" . buttonHeight . " w" . Popout_Margin_Width, "Patchnotes")
	
	evenlySpaceControls()

	WinGetClientPos(&MainX, &MainY, &MainW, &MainH, MainUI.Title)
	CenterX := MainX + (MainW / 2) - (Popout_Width / 2)
	CenterY := MainY + (MainH / 2) - (Popout_Height / 2)	
	
	DiscordLink.Opt("Background" intWindowColor)
	GitHubLink.Opt("Background" intWindowColor)
	OpenWarningLabel.Opt("Background" intWindowColor)
	ViewPatchnotes.Opt("Background" intWindowColor)
	descriptionGroup.Opt("Background" intWindowColor . " c" ControlTextColor)
	DescriptionBoxBG.Opt("Background" intWindowColor . " c" ControlTextColor)
	DescriptionBox.Opt("Background" intWindowColor . " c" ControlTextColor)
	
	DescriptionBox.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	DiscordLink.SetFont("w" buttonFontWeight . " s" buttonFontSize, buttonFont)
	GitHubLink.SetFont("w" buttonFontWeight . " s" buttonFontSize, buttonFont)
	OpenWarningLabel.SetFont("w" buttonFontWeight . " s" buttonFontSize, buttonFont)
	ViewPatchnotes.SetFont("w" buttonFontWeight . " s" buttonFontSize, buttonFont)

	DiscordLink.OnEvent("Click", (*) => Run("https://discord.gg/w8QdNsYmbr"))
	GitHubLink.OnEvent("Click", (*) => Run("https://github.com/WoahItsJeebus/JACS/"))
	OpenWarningLabel.OnEvent("Click", (*) => createWarningUI(true))
	ViewPatchnotes.OnEvent("Click", (*) => ShowPatchNotesGUI())

	; Hover Descriptions
	local Descriptions := Map(
		"DiscordLink","Join the Discordeebus Discord server!",
		"GithubLink","View the Github repository and see changes from past versions!",
		"OpenWarning","View the warning popup seen when running the script for the first time (or if denying the agreement/closing without accepting)",
		"ViewPatchnotes","Fetch the patchnotes for the latest version of the script posted to Github!",
	)

	evenlySpaceControls() {
		local buttonCount := 0
		local remainingHeight := 0

		for i, control in ExtrasUI {
			if control.Name != "Section" {
				buttonCount++
				local totalHeight := buttonHeight * buttonCount + (ExtrasUI.MarginY * (buttonCount - 1)) + PixelOffset * 2
				remainingHeight := Popout_Margin_Height - totalHeight + (ExtrasUI.MarginY * 2)

				control.Y := (remainingHeight / 2) + (buttonHeight * (i - 1)) + ExtrasUI.MarginY * i + PixelOffset
			}
		}
		
		; Slider Description Box
		descriptionGroup := ExtrasUI.Add("GroupBox","xm Section vDescriptionGroupBox h" 0 " w" Popout_Margin_Width, "")
		DescriptionBoxBG := ExtrasUI.Add("Text", "xs+" groupPadding/2 " yp+" groupPadding " Left vDescriptionBoxBG h" . (0) . " w" Popout_Margin_Width - groupPadding)
		DescriptionBox := ExtrasUI.Add("Text", "xs+" groupPadding/2 " yp+" groupPadding " Section Left vInvis_BG_DescriptionBox h" . (0) . " w" Popout_Margin_Width - groupPadding)
	}
	
	updateDescriptionBox(newText := "") {
		if newText == DescriptionBox.Text
			return

		ControlGetPos(&groupX, &groupY, &groupW, &groupH, descriptionGroup)
		DescriptionBox.Text := newText

		local textWidth := MeasureTextWidth(DescriptionBox, newText)
		local textHeight := MeasureWrappedTextHeight(DescriptionBox, newText)

		descriptionGroup.Move(,,, textHeight+(groupPadding*2.1))
		DescriptionBoxBG.Move(,,, textHeight+(groupPadding/2.1))
		DescriptionBox.Move(, groupY + groupPadding,, textHeight)
		
		ExtrasUI.Show("AutoSize")
	}
	updateDescriptionBox(" ")
	mouseHoverDescription(*)
	{
		if not ExtrasUI or not DescriptionBox
			return SetTimer(mouseHoverDescription,0)

		global PatchUI
		if PatchUI
			return

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

	SetTimer(mouseHoverDescription,50)

	; Calculate center position
	WinGetClientPos(&MainX, &MainY, &MainW, &MainH, MainUI.Title)
	CenterX := MainX + (MainW / 2) - (Popout_Width / 2)
	CenterY := MainY + (MainH / 2) - (Popout_Height / 2)

	CheckDeviceTheme()
	ExtrasUI.Show("AutoSize X" . CenterX . " Y" . CenterY . " w" . Popout_Width . " h" . Popout_Height)

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

UpdateTimerLabel(*) {
	global isActive
	global MinutesToWait
	global SecondsToWait
	global lastUpdateTimes

	global ElapsedTimeLabel
	global WaitProgress
	global WaitTimerLabel
	global ID_Selector
<<<<<<< HEAD
	global SelectedProcessExe
	
	local ID := (ID_Selector and ID_Selector.Text) ? ID_Selector.Text : SelectedProcessExe
	if !lastUpdateTimes.Has(ID) or (lastUpdateTimes.Has(ID) and isActive == 1){
		lastUpdateTimes.Set(ID, tick())
		SendNotification("Updated lastUpdateTimes for ID: " ID " to " lastUpdateTimes.Get(ID))
	}
=======
	global SelectedProcessExe, ProcessWindowCache

	local IDs := ProcessWindowCache[SelectedProcessExe]
	local ID := (ID_Selector and ID_Selector.Text != "") ? Number(ID_Selector.Text) : IDs[1]
	if !lastUpdateTimes.Has(ID)
		lastUpdateTimes[ID] := A_TickCount
	else
		lastUpdateTimes[ID] := isActive > 1 and lastUpdateTimes[ID] or A_TickCount
>>>>>>> parent of 38be338 ([Broken Build])
	
	global ID_SelectorLabel
	if ID_SelectorLabel and ID_SelectorLabel.Text != SelectedProcessExe
		ID_SelectorLabel.Text := SelectedProcessExe

	; Calculate and update progress bar
<<<<<<< HEAD
    secondsPassed := (tick() - lastUpdateTimes[ID])  ; Convert ms to seconds
	
=======
    secondsPassed := (A_TickCount - lastUpdateTimes[ID]) / 1000  ; Convert ms to seconds
>>>>>>> parent of 38be338 ([Broken Build])
    finalProgress := Round((MinutesToWait == 0 and SecondsToWait == 0) and 100 or (secondsPassed / SecondsToWait) * 100, 0)
	
	; Calculate and format CurrentElapsedTime as MM:SS
    currentMinutes := Floor(secondsPassed / 60)
    currentSeconds := Round(Mod(secondsPassed, 60),0)
	
	targetSeconds := (SecondsToWait > 0) and Round(Mod(SecondsToWait, 60),0) or 0
	
	local CurrentElapsedTime := Format("{:02}:{:02}", currentMinutes, currentSeconds)
	local targetFormattedTime := Format("{:02}:{:02}", MinutesToWait, targetSeconds)

	local mins_suffix := SecondsToWait > 60 and " minutes" or SecondsToWait == 60 and " minute" or SecondsToWait < 60 and " seconds"
	
	try if ElapsedTimeLabel and ElapsedTimeLabel.Text != CurrentElapsedTime " / " . targetFormattedTime . " " mins_suffix
			ElapsedTimeLabel.Text := CurrentElapsedTime " / " . targetFormattedTime . " " mins_suffix

	if WaitProgress and WaitProgress.Value != finalProgress
		WaitProgress.Value := finalProgress

    local finalText  := Round((WaitProgress and WaitProgress.Value or 0), 0) "%"
	if WaitTimerLabel and WaitTimerLabel.Text != finalText
		WaitTimerLabel.Text := finalText
}

<<<<<<< HEAD
ResetCooldown(ID) {
	global CoreToggleButton, ElapsedTimeLabel, WaitProgress, WaitTimerLabel, activeText_Core, lastUpdateTimes, ID_Selector
	global SelectedProcessExe

=======
ResetCooldown(*) {
	global CoreToggleButton
	global ElapsedTimeLabel
	global WaitProgress
	global WaitTimerLabel
	global activeText_Core
	global lastUpdateTimes
	
>>>>>>> parent of 38be338 ([Broken Build])
	activeText_Core := (isActive == 3 and "Enabled") or (isActive == 2 and "Waiting...") or "Disabled"

	if CoreToggleButton and CoreToggleButton.Text != "Auto-Clicker: " activeText_Core
		CoreToggleButton.Text := "Auto-Clicker: " activeText_Core

	if isActive == 2 and FindTargetHWND()
		ToggleCore(,3)
	else if isActive == 3 and not FindTargetHWND()
		ToggleCore(,2)

	; Reset cooldown progress bar
	UpdateTimerLabel()
	
	if WaitProgress and WaitProgress.Value != 0 and (isActive <= 2 or (MinutesToWait > 0 or SecondsToWait > 0))
		WaitProgress.Value := 0
    
	local finalText  := Round((WaitProgress and WaitProgress.Value or 0), 0) "%"
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

; ############################### ;
; ######## Core Function ######## ;
; ############################### ;

ToggleCore(optionalControl?, forceState?, *) {
	; Variables
	global isActive
	global FirstRun
	global activeText_Core
	global CoreToggleButton
	global ProfilesDir
	global SelectedProcessExe
	global cooldownToggleDebounce

	if cooldownToggleDebounce and isActive != 2
		return

	cooldownToggleDebounce := true	
	SetTimer((*) => (
		cooldownToggleDebounce := false
	), 1000)

	local newMode := forceState or switchActiveState()
	
	updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "isActive", newMode)

	isActive := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "isActive", 0, "int")
	activeText_Core := (isActive == 3 and "Enabled") or (isActive == 2 and "Waiting...") or "Disabled"
	
	if CoreToggleButton and CoreToggleButton.Text != "Auto-Clicker: " activeText_Core
		CoreToggleButton.Text := "Auto-Clicker: " activeText_Core

	setTrayIcon(icons[isActive].Icon)
	ResetCooldown()
	UpdateTimerLabel()
}

RunCore(ID := SelectedProcessExe, FirstRun := false) {
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

	global LastActiveWindow
	global doMouseLock
	global lastUpdateTimes
	; Check for process
	if !FindTargetHWND()
		ResetCooldown()
	; 	ToggleCore(, 2)
	
	; Check if the toggle has been switched off
	if isActive == 1
		return

<<<<<<< HEAD
	if (FirstRun or isCompleted) and (ID or FindTargetHWND()) {
		ResetCooldown(ID)

		if IsAltTabOpen() or (SecondsToWait < 10 and SelectedProcessExe and !WinActive(SelectedProcessExe))
=======
	if (FirstRun or (WaitProgress and WaitProgress.Value >= 100)) and (ID or FindTargetHWND()) {
		ResetCooldown()
		
		if IsAltTabOpen() or (SecondsToWait < 10 and ProcessWindowCache[SelectedProcessExe] and !ProcessWindowCache[SelectedProcessExe].Has(WinActive("A")))
>>>>>>> parent of 38be338 ([Broken Build])
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

		; Find and activate process(es)
		local target := ID or FindTargetHWND()
		if target
			ClickWindow(target)
		
		; Activate previous application window & reposition mouse
		local lastActiveWindowID := ""
		try lastActiveWindowID := WinExist(windowID)

		if not LastActiveWindow and lastActiveWindowID and (MinutesToWait > 0 or SecondsToWait > 0) {
			WinActivate lastActiveWindowID
			MouseMove OldPosX, OldPosY, 0
		}

		if doMouseLock
			Sleep(25)

		if (MinutesToWait > 0 or SecondsToWait > 0) and WaitProgress
			WaitProgress.Value := 0

		lastUpdateTimes.Set(ID, A_TickCount)
		; lastUpdateTime := A_TickCount
	}
	
	; Unblock Inputs
	BlockInput("Off")
	BlockInput("Default")
	BlockInput("MouseMoveOff")

	UpdateTimerLabel()
}

; ############################### ;
; ########### Classes ########### ;
; ############################### ;

class arr extends Array {
	; Constructor
	arr() {
		this := []
	}

	GetIndex(AtValue) {
		for pos, val in this {
			if (AtValue == val)
				return pos
		}
		return false
	}

	GetValue(AtIndex) {
		for pos, val in this
			if (AtIndex == pos)
				return val or true
		return false
	}

	removeAll() {
		for pos, val in this
			this.RemoveAt(pos)
		
		return this
	}
}

class math {
	static huge(*) {
		return 2^1024 - 1
	}
    static clamp(number, minimum := 0, maximum := math.huge()) {
        return Min(Max(number, minimum), maximum)
    }
	static round(number, decimalPlaces := 0) {
			return Round(number, decimalPlaces)
	}
	static random(min, max := math.huge()) {
		return Random(min, max)
	}
	static isInteger(value) {
		return (value is Integer)
	}
	static isNumber(value) {
		return (value is Number)
	}
	static isFloat(value) {
		return (value is Float)
	}
	static min(value1, value2) {
		return Min(value1, value2)
	}
	static max(value1, value2) {
		return Max(value1, value2)
	}
	static abs(value) {
		return Abs(value)
	}
	static sqrt(value) {
		return Sqrt(value)
	}
	static sin(value) {
		return Sin(value)
	}
	static cos(value) {
		return Cos(value)
	}
	static tan(value) {
		return Tan(value)
	}
	static asin(value) {
		return Asin(value)
	}
	static acos(value) {
		return Acos(value)
	}
	static atan(value) {
		return Atan(value)
	}
	static log10(value) {
		return Log(value)
	}
	static log(value) {
		return Ln(value)
	}
	static exp(value) {
		return Exp(value)
	}
	static floor(value) {
		return Floor(value)
	}
	static ceil(value) {
		return Ceil(value)
	}
	static sign(value) {
		return (value > 0) ? 1 : (value < 0) ? -1 : 0
	}
	static pi() {
		return 3.14159265358979323846
	}
	static mod(value, divisor) {
		return Mod(value, divisor)
	}
	static pow(base, exponent) {
		return base ** exponent
	}
}

class Color3 {
	static new(r, g, b) {
		return Color3.fromRGB(math.clamp(r,,1) * 255, math.clamp(g,,1) * 255, math.clamp(b,,1) * 255)
	}

	static fromRGB(r, g, b) {
		return Format("{1:02X}{2:02X}{3:02X}", Round(r), Round(g), Round(b))
	}

	static fromHex(hex) {
		if IsA(hex, "string") && SubStr(hex, 1, 1) == "#"
			hex := "0x" . SubStr(hex, 2)
		hex := Integer(hex)
		r := (hex >> 16) & 0xFF
		g := (hex >> 8) & 0xFF
		b := hex & 0xFF
		return [r / 255, g / 255, b / 255]
	}

	static toRGB(hex) {
		if IsA(hex, "string") && SubStr(hex, 1, 1) == "#"
			hex := "0x" . SubStr(hex, 2)
		hex := Integer(hex)
		return [
			(hex >> 16) & 0xFF,
			(hex >> 8) & 0xFF,
			hex & 0xFF
		]
	}

	static toHSV(r, g, b, &h, &s, &v) {
		r := r / 255, g := g / 255, b := b / 255
		local maximum := Max(r, g, b), minimum := Min(r, g, b)
		local delta := maximum - minimum
		h := 0, s := 0, v := maximum
	
		if (delta != 0) {
			if (maximum == r)
				h := Mod((g - b) / delta, 6)
			else if (maximum == g)
				h := ((b - r) / delta) + 2
			else
				h := ((r - g) / delta) + 4
	
			h := h / 6 ; Convert from 0–360 → 0–1 range
			if (h < 0)
				h += 1
			s := delta / maximum
		}

		return this.new(h, s, v)
	}	
}

; ################################ ;
; ####### Sound Functions ######## ;
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
; ###### Info Bar Functions ###### ;
; ################################ ;

LoadNewTip(*) {
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

LoadTipsFromAHKFile(*) {
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

UpdateAllTipBoxes(*) {
	global TipScrollData, tips

	for hwnd, data in TipScrollData {
		data["TipList"] := tips
		data["LastIndexes"] := []
	}
}

ScrollTip(*) {
	global initializing
	if initializing
		return

	data := TipScrollData[MainUI]
	ctrl := data["Ctrl"]
	text := data["CurrentText"]
	offset := data["Offset"]

	; Move leftward
	offset -= 1
	ctrl.Move(offset)

	; When it fully scrolls off screen, reset position

	if offset < -(UI_Width) - 100 {
		Sleep(Random(30000, 90000))
		return LoadNewTip()
	}
	else
		data["Offset"] := offset
}

; ################################ ;
; ####### Sidebar Functions ###### ;
; ################################ ;

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

; ################################ ;
; ####### Window Functions ####### ;
; ################################ ;

WM_SYSCOMMAND_Handler(wParam, lParam, msgNum, hwnd) {
    global MainUI, MainUI_PosX, MainUI_PosY
	global SelectedProcessExe, ProfilesDir, localScriptDir
    if (wParam = 0xF020) { ; 0xF020 (SC_MINIMIZE) indicates the user is minimizing the window.
        ; Save the current (restored) position before the minimize animation starts.
        pos := WinGetMinMax(MainUI.Title) != -1 and WinGetPos(&X := MainUI_PosX,&Y := MainUI_PosY,,,MainUI.Title)
		pos := {X: X, Y: Y}

		MainUI_PosX := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosX", A_ScreenWidth / 2, "int")
		MainUI_PosY := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosY", A_ScreenHeight / 2, "int")
    }
}

SendNotification(message, config := Map(
	"Type", "info",
	"OnYes", "", "OnNo", "",
	"OnOk", "", "OnCancel", "", "OnClose", "",
	"Duration", 4000,
	"Title", "JACS - Notification"
)) {
	static notificationQueue := Map()				; Pending notifications (unique key → data)
	static notificationQueueKeys := []				; FIFO list of queued keys
	static closeFunctions := Map()					; Timers for closing
	static themeFunctions := Map()					; Timers for theme updates
	static slotAssignments := Map()					; hwnd → slotIndex
	static notificationGUIs := []					; Active notification windows
	static notificationCounter := 0					; Unique counter for queue keys
	static slotStates := [false, false, false]		; Slot availability (3 slots)

	global isActive
	global intWindowColor, intControlColor, intProgressBarColor
	global ControlTextColor, linkColor, HeaderHeight
	global buttonHeight, buttonFontSize, buttonFontWeight, buttonFont

	local popupWidth := 300, popupHeight := 150
	local popupMarginX := 10, popupMarginY := 10

	; Skip if already shown in active GUIs 
	for _, hwnd in notificationGUIs {
		if hwnd && WinExist(hwnd) {
			ui := GuiFromHwnd(hwnd)
			for _, ctrl in ui {
				if ctrl.Type = "Text" && ctrl.Text == message
					return
			}
		}
	}

	; Skip if message is already queued 
	for _, key in notificationQueueKeys {
		if notificationQueue.Has(key) && notificationQueue[key]["Message"] == message
			return
	}

	; If 3 active, queue instead 
	if notificationGUIs.Length >= 3 {
		notificationCounter += 1
		uniqueKey := Format("{}_{}", A_TickCount, notificationCounter)
		notificationQueue[uniqueKey] := Map("Message", message, "Config", config)
		notificationQueueKeys.Push(uniqueKey)
		return
	}

	; Find free visual slot (0 = none) 
	local slotIndex := 0
	for i, used in slotStates {
		if !used {
			slotIndex := i
			break
		}
	}
	if slotIndex = 0 {
		notificationCounter += 1
		uniqueKey := Format("{}_{}", A_TickCount, notificationCounter)
		notificationQueue[uniqueKey] := Map("Message", message, "Config", config)
		notificationQueueKeys.Push(uniqueKey)
		return
	}
	slotStates[slotIndex] := true

	; Config values 
	local type     := config.Get("Type", "info")
	local duration := config.Get("Duration", 4000)
	local onYes    := config.Get("OnYes", "")
	local onNo     := config.Get("OnNo", "")
	local onOk     := config.Get("OnOk", "")
	local onCancel := config.Get("OnCancel", "")
	local onClose  := config.Get("OnClose", "")
	local title    := config.Get("Title", "JACS")

	; Create GUI 
	MonitorGetWorkArea(1, &monLeft, &monTop, &monRight, &monBottom)
	screenW := monRight - monLeft
	screenH := monBottom - monTop
	local shellX := monRight - popupWidth - 25
	local shellY := screenH / 2
	local slotYOffsets := [shellY + screenH * 0.25, shellY, shellY - screenH * 0.25]
	shellY := slotYOffsets[slotIndex]
	
	NotiShellGui := Gui("+AlwaysOnTop -Caption +ToolWindow +LastFound")
	NotiShellGui.BackColor := getActiveStatusColor()
	NotiInnerGui := Gui("+Parent" NotiShellGui.Hwnd " -Caption +ToolWindow +LastFound +E0x20")
	NotiInnerGui.MarginX := popupMarginX
	NotiInnerGui.MarginY := popupMarginY
	NotiInnerGui.BackColor := intWindowColor
	NotiInnerGui.SetFont("s" buttonFontSize " c" ControlTextColor " w" buttonFontWeight, buttonFont)

	id := NotiShellGui.Hwnd
	notificationGUIs.Push(id)
	slotAssignments[id] := slotIndex

	NotiInnerGui.OnEvent("Escape", closeNotification)
	NotiShellGui.OnEvent("Escape", closeNotification)

	innerW := popupWidth - (popupMarginX * 2)
	titleLabel := NotiInnerGui.Add("Text", "vHeader" getUniqueID() " Center w" innerW - (popupMarginX * 2) " h" HeaderHeight, title)
	titleLabel.SetFont("s16 c" ControlTextColor " w" buttonFontWeight, "Ink Free")

	messageBox := NotiInnerGui.Add("Text", "vMessageBox Center xm w" innerW - (popupMarginX * 2), message)
	messageBox.SetFont("s" buttonFontSize " c" ControlTextColor " w" buttonFontWeight, buttonFont)
	
	local totalButtons := type = "yesno" ? 2 : 1
	size := getControlSize(messageBox)
	local totalObjectsHeight := size.H + (buttonHeight*totalButtons) + HeaderHeight + (NotiShellGui.MarginY*2)
	local FinalHeight := popupHeight + (totalObjectsHeight - popupHeight) + popupMarginY * 2

	; Add buttons
	btnY := FinalHeight - buttonHeight - popupMarginY
	
	singleW := innerW / 2.5
	singleX := (innerW - singleW) / 2
	doubleW := innerW / 3
	doubleX1 := (innerW - doubleW * 2 - popupMarginX/2) / 2
	doubleX2 := doubleX1 + doubleW + popupMarginX/2

	if (type = "yesno") {
		btnYes := NotiInnerGui.Add("Button","vInvisBG_Yes" getUniqueID() Format(" x{} y{} w{} h{}", doubleX1, btnY, doubleW, buttonHeight), "Yes")
		btnNo  := NotiInnerGui.Add("Button","vInvisBG_No" getUniqueID() Format(" x{} y{} w{} h{}", doubleX2, btnY, doubleW, buttonHeight), "No")
		btnYes.SetFont("s" buttonFontSize " c" ControlTextColor " w" buttonFontWeight, buttonFont)
		btnNo.SetFont("s" buttonFontSize " c" ControlTextColor " w" buttonFontWeight, buttonFont)
		btnYes.Opt("BackgroundTrans")
		btnNo.Opt("BackgroundTrans")

		btnYes.OnEvent("Click", (*) => (closeNotification(id), IsFunc(onYes) ? onYes.Call() : ""))
		btnNo.OnEvent("Click", (*) => (closeNotification(id), IsFunc(onNo) ? onNo.Call() : ""))
	} else if (type = "ok") {
		btnOk := NotiInnerGui.Add("Button", "vInvisBG_Ok" getUniqueID() Format(" x{} y{} w{} h{}", singleX, btnY, singleW, buttonHeight), "OK")
		btnOk.OnEvent("Click", (*) => (closeNotification(id), IsFunc(onOk) ? onOk.Call() : ""))
	} else if (type = "cancel") {
		btnCancel := NotiInnerGui.Add("Button", "vInvisBG_Cancel" getUniqueID() Format(" x{} y{} w{} h{}", singleX, btnY, singleW, buttonHeight), "Cancel")
		btnCancel.OnEvent("Click", (*) => (closeNotification(id), IsFunc(onCancel) ? onCancel.Call() : ""))
	} else {
		btnClose := NotiInnerGui.Add("Button", "vInvisBG_Close" getUniqueID() Format(" x{} y{} w{} h{}", singleX, btnY, singleW, buttonHeight), "Close")
		btnClose.OnEvent("Click", (*) => (closeNotification(id), IsFunc(onClose) ? onClose.Call() : ""))
	}

	NotiShellGui.Show("NoActivate x" shellX " y" shellY " w" popupWidth " h" FinalHeight)
	NotiInnerGui.Show("NoActivate w" innerW " h" FinalHeight)

	SetRoundedCorners(id, 16)
	SetRoundedCorners(NotiInnerGui.Hwnd, 16)
	ApplyThemeToGui(NotiInnerGui, LoadThemeFromINI(currentTheme))
	WinSetTransparent(0, id)
	SetTimer((*) => FadeWindow(id, "in", 500), -1, id)
	themeFunctions[id] := SetTimer(() => NotiShellGui.BackColor := getActiveStatusColor(), 500, id)
	closeFunctions[id] := SetTimer(() => closeNotification(id), -duration, id)
	
	if IsFunc(onNo)
		SetTimer(() => onNo.Call(), -duration, id)
	else if IsFunc(onOk)
		SetTimer(() => onOk.Call(), -duration, id)
	else if IsFunc(onCancel)
		SetTimer(() => onCancel.Call(), -duration, id)
	else if IsFunc(onClose)
		SetTimer(() => onClose.Call(), -duration, id)
	
	
	; Close & dequeue logic 
	closeNotification(hwnd := id) {
		if !slotAssignments.Has(hwnd)
			return
	
		; Get current slot before removal
		oldSlot := slotAssignments[hwnd]
	
		; Remove from GUI tracking
		removeFromArray(notificationGUIs, hwnd)
		closeFunctions.Delete(hwnd)
		themeFunctions.Delete(hwnd)
		SetTimer(() => FadeWindow(hwnd, "out", 500), -1, hwnd)
		slotStates[oldSlot] := false

		; Capture current assignments *before* modifying
		local currentAssignments := slotAssignments.Clone()

		; Now safe to remove the closed notification
		slotAssignments.Delete(hwnd)
	
		; Pull next notification from queue if any
		if notificationQueueKeys.Length > 0 {
			nextKey := notificationQueueKeys.RemoveAt(1)
			next := notificationQueue[nextKey]
			notificationQueue.Delete(nextKey)
			SendNotification(next["Message"], next["Config"])
		}
	}
}

IsAltTabOpen() {
    return (
        WinExist("ahk_class MultitaskingViewFrame")
        || WinExist("ahk_class TaskSwitcherWnd")
        || WinExist("ahk_class #32771")
    ) != 0
}

SaveMainUIPosition(*) {
    global MainUI_PosX
    global MainUI_PosY
    global MainUI
	global monitorNum
	global ProfilesDir
	global SelectedProcessExe
	
	WinGetPos(&x, &y,,,"ahk_id" MainUI.Hwnd)

	local exists := false

	try
		exists := WinExist(MainUI.Title) and true
	catch
		exists := false


	local needsUpdate := false
	if x == -32000 or !exists {
		x := Integer(A_ScreenWidth / 2)
		needsUpdate := true
	}
	if y == -32000 or !exists {
		y := Integer(A_ScreenHeight / 2)
		needsUpdate := true
	}

	if needsUpdate {
		updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosX", x)
		updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosY", y)
		MainUI_PosX := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosX", Integer(A_ScreenWidth / 2), "int")
		MainUI_PosY := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosY", Integer(A_ScreenWidth / 2), "int")

		; if not exiting, reload the GUI to apply the new position
		if !MainUI
			return
		if MainUI and 
			MainUI.Show("X" . x . " Y" . y)
		
		return
	}


    monitorNum := MonitorGetNumberFromPoint(x, y)

    updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosX", x)
	updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosY", y)
    updateIniProfileSetting(ProfilesDir, SelectedProcessExe, "monitorNum", monitorNum)

	MainUI_PosX := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosX", Integer(A_ScreenWidth / 2), "int")
	MainUI_PosY := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "MainUI_PosY", Integer(A_ScreenWidth / 2), "int")
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

FindTargetHWND(*) {
	global SelectedProcessExe
	global ProcessWindowCache

	local foundWindow := ProcessWindowCache.Has(SelectedProcessExe) and ProcessWindowCache[SelectedProcessExe] or false
	if foundWindow and foundWindow.Length == 1
		return foundWindow[1]
	
	return foundWindow
}

<<<<<<< HEAD
=======
StartProcessWindowWatcher(exeName := "") {
	static watcherTimers := Map()
	static ProcessCoreTimers := Map()

	global SelectedProcessExe
	global ProcessWindowCache
	global isActive

	if !exeName or exeName == ""
		exeName := SelectedProcessExe

	if !exeName
		return SendNotification("No process selected to watch.")

	if !watcherTimers.Has(exeName)
		watcherTimers[exeName] := false

	updateList() {
		try {
			local all := WinGetList("ahk_exe " exeName)
			local filtered := []

			for hwnd in all {
				try {
					if !WinExist(hwnd)
						continue
					if WinGetMinMax(hwnd) == -1  ; hidden/minimized
						continue
					if WinGetTitle(hwnd) == ""   ; no title
						continue
					WinGetPos(&x, &y, &w, &h, hwnd)
					if (w < 200 || h < 200)      ; too small = not real window
						continue
					filtered.Push(hwnd)
				}
				catch
					continue
			}

			ProcessWindowCache[exeName] := filtered
		}
		catch {
			ProcessWindowCache[exeName] := []
		}
	}

	updateList()

	for exeName, hwnds in ProcessWindowCache {
		if !ProcessWindowCache.Has(exeName)
			ProcessWindowCache[exeName] := []

		if isActive > 1 {
			for _, ID in ProcessWindowCache[SelectedProcessExe] {
				if ProcessCoreTimers.Has(ID) {
					continue
				}
				else {
					RunCore(ID, true)
					ProcessCoreTimers.Set(ID, SetTimer(
						RunCore.Bind(ID, false),
						100,
						ID
					))
				}
			}
		}
		else if isActive == 1 {
			for _, ID in ProcessWindowCache[SelectedProcessExe] {
				if ProcessCoreTimers.Has(ID)
					ProcessCoreTimers.Delete(ID)
			}
		}
	}

	if ProcessWindowCache.Has(exeName) && !watcherTimers[exeName]
		watcherTimers[exeName] := true
}

>>>>>>> parent of 38be338 ([Broken Build])
ClickWindow(optionalHWND := "") {
	global SelectedProcessExe, LastActiveWindow := false
	global MouseSpeed, MouseClickRateOffset, MouseClickRadius, MouseClicks
	global KeyToSend, MinutesToWait, SecondsToWait
	local target := "ahk_exe " . SelectedProcessExe

	try
		LastActiveWindow := WinActive(SelectedProcessExe)
	catch
		LastActiveWindow := false

	doClick(targetID, loopAmount := 1) {
		loop loopAmount {
			local WindowX := 0, WindowY := 0, Width := 0, Height := 0
			local CenterX := 0, CenterY := 0, OffsetX := 0, OffsetY := 0
			local cachedWindowID := "", hoverCtrl := ""

			cachedWindowID := targetID
			if !cachedWindowID
				return MsgBox("Invalid window ID.")

			ActivateWindow(cachedWindowID)

			try WinGetPos(&WindowX, &WindowY, &Width, &Height, cachedWindowID)
			if (Width <= 0 || Height <= 0)
				return MsgBox("Invalid window dimensions.")

			CenterX := WindowX + (Width / 2)
			CenterY := WindowY + (Height / 2)
			OffsetX := Random(-MouseClickRadius, MouseClickRadius)
			OffsetY := Random(-MouseClickRadius, MouseClickRadius)

			MouseGetPos(&mouseX, &mouseY, &hoverWindow, &hoverCtrl)

			if (hoverWindow && hoverWindow != cachedWindowID && (MinutesToWait > 0 || SecondsToWait > 0)) {
				MouseMove(CenterX + OffsetX, CenterY + OffsetY, MouseSpeed ? Random(0, MouseSpeed) : 0)
			}

			if !hoverCtrl && hoverWindow && cachedWindowID && hoverWindow == cachedWindowID {
				Click(KeyToSend == "RButton" ? "Right" : "Left")
			}

			if loopAmount > 1
				Sleep(Random(10, MouseClickRateOffset || 10))
		}
	}

	; Loop through all windows of selected exe
	if optionalHWND
		return doClick(optionalHWND, MouseClicks || 5)
	
	ActivateWindow(target) {
		try {
			if (MinutesToWait <= 0 || SecondsToWait <= 0)
				return
			if WinGetMinMax(target) == -1 {
				WinRestore(target)
				Sleep(100)
			}

			if !WinActive(target) && WinGetMinMax(target) != -1 {
				WinActivate(target)
				; WinWaitActive(target,,250)
			}
		}
	}
}

isMouseClickingOnTargetWindow(key?, override*) {
<<<<<<< HEAD
	global initializing, ProcessWindowCache, SelectedProcessExe

=======
	global initializing
>>>>>>> parent of 38be338 ([Broken Build])
	if initializing
		return

	local process := FindTargetHWND()
	if not process
		return
	
	checkWindow(*) {
		if GetKeyState(key) == 0
			return SetTimer(checkWindow, 0, 1)
		
		MouseGetPos(&mouseX, &mouseY, &hoverWindow)
		
		if hoverWindow == process
<<<<<<< HEAD
			ResetCooldown(hoverWindow)
=======
			return ResetCooldown()
>>>>>>> parent of 38be338 ([Broken Build])
	}
	
	if override[1]
		return checkWindow()
	
	; SetTimer(checkWindow, 100, 1)
	while (GetKeyState(key) == 1)
		checkWindow()
}

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

SetRoundedCorners(hwnd, radius := 12) {
    ; Handle GUI object
	WinGetPos(&x,&y, &w, &h, hwnd)
	hRgn := DllCall("CreateRoundRectRgn"
		, "int", 0, "int", 0
		, "int", w, "int", h
		, "int", radius, "int", radius
		, "ptr")
	
	DllCall("SetWindowRgn"
		, "ptr", hwnd
		, "ptr", hRgn
		, "int", true)
}

moveCenterOfControl(ctrl, targetX, targetY) {
	local center := ctrl.GetPos(&startX, &startY, &width, &height)
	local centerX := startX + (width / 2)
	local centerY := startY + (height / 2)
	local offsetX := targetX - centerX
	local offsetY := targetY - centerY
	
	ctrl.Move(offsetX, offsetY)
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

evenlySpaceControls(guiObject) {
	global buttonHeight
	global PixelOffset

	local buttonCount := 0
	local remainingHeight := 0
	WinGetPos(&MainX, &MainY, &MainW, &MainH, guiObject.hwnd)

	for i, control in guiObject {
		if control.Name != "Section" {
			buttonCount++
			local height := getControlSize(control)
			local totalHeight := buttonHeight * buttonCount + (guiObject.MarginY * (buttonCount - 1)) + PixelOffset * 2
			local remainingHeight := (MainW - guiObject.MarginX) - totalHeight + (guiObject.MarginY * 2)

			control.Y := (remainingHeight / 2) + (buttonHeight * (i - 1)) + guiObject.MarginY * i + PixelOffset
		}
	}

	return remainingHeight
}

GuiGetClientHeight(guiObj) {
	; Gets only the height of the usable area inside the GUI
	local x, y, w, h := 0
	if !guiObj
		return 0
	
	try guiObj.GetClientPos(&x, &y, &w, &h)
	return h
}

; ################################ ;
; ########## Tray Menu ########### ;
; ################################ ;

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

DeleteTrayTabs(*) {
	TabNames := [
		"&Edit Script",
		"&Window Spy",
		"&Pause Script",
		"&Suspend Hotkeys",
		"&Help",
		"&Open"
	]

	if doDebug
		return

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

; ################################ ;
; ####### Theme Functions ######## ;
; ################################ ;

ApplyThemeToGui(guiObj, themeMap) {
	if !guiObj or !themeMap
		return

	IsTransparent(val) {
		static transparentSet := Map("0", 1, "none", 1, "n/a", 1, "transparent", 1, "zero", 1, "clear", 1)
		return transparentSet.Has(val) ? true : false
	}

	; Prevent full-black backgrounds which can create Z-index rendering issues
	if themeMap.Has("Background") and (themeMap["Background"] = "000000" or themeMap["Background"] = "0x000000")
		themeMap["Background"] := "0a0a0a"
	
	for _, ctrl in guiObj {
		; Skip invalid controls
		if !ctrl || !ctrl.HasProp("Type")
			continue
		
		local type := ctrl.Type
		local BG_Invis_Force := InStr(ctrl.Name, "InvisBG_", 1) != 0 ? true : false

		try {
			fg := "", bg := "", opt := "", fs := "", font := "", fw := ""

			switch type {
				case "Button":
					if InStr(ctrl.Name, "IconButton", 1) {
						fg := themeMap["ButtonTextColor"]
						fs := themeMap["ButtonFontSize"]
						font := themeMap["ButtonFontStyle"]
						fw := themeMap["ButtonFontWeight"]
					} else if InStr(ctrl.Name, "InvisBG_", 1) {	
						fg := themeMap["ButtonTextColor"]
						fs := themeMap["ButtonFontSize"]
						font := themeMap["ButtonFontStyle"]
						fw := themeMap["ButtonFontWeight"]

						opt := "BackgroundTrans" (fg ? " c" fg : "")
						continue
					}

					if BG_Invis_Force
						bg := "Trans"
					else
						bg := IsTransparent(themeMap["Background"]) ? "Trans" : themeMap["Background"]
					
					opt := "Background" bg (fg ? " c" fg : "")
				case "Text", "GroupBox":
					if InStr(ctrl.Name, "SideBarBackground", 1) {
							local doSideBarDebug := false
							if doSideBarDebug
								bg := "cc0000"
							else {
								bg := "Trans"
							if ctrl.Visible
								ctrl.Visible := false
						}
					} else if InStr(ctrl.Name, "DescriptionBox", 1) {
						if BG_Invis_Force
							bg := "Trans"
						else
							bg := IsTransparent(themeMap["DescriptionBoxColor"]) ? "Trans" : themeMap["DescriptionBoxColor"] ? themeMap["DescriptionBoxColor"] : themeMap["Background"]
							fg := themeMap["DescriptionBoxTextColor"]
					} else if InStr(ctrl.Name, "NotificationTitle", 1) {
						if BG_Invis_Force
							bg := "Trans"
						else
							bg := IsTransparent(themeMap["MainMenuBackground"]) ? "Trans" : themeMap["MainMenuBackground"] ? themeMap["MainMenuBackground"] : themeMap["Background"]
						fg := themeMap["HeaderColor"]
					} else if InStr(ctrl.Name, "Header", 1) {
						if BG_Invis_Force
							bg := "Trans"
						else
							bg := IsTransparent(themeMap["MainMenuBackground"]) ? "Trans" : themeMap["MainMenuBackground"] ? themeMap["MainMenuBackground"] : themeMap["Background"]
						fg := themeMap["HeaderColor"]
					} else if InStr(ctrl.Name, "DescriptionGroupBox", 1) {
						bg := "Trans"
						fg := themeMap["DescriptionBoxTextColor"]
 					} else {
						if BG_Invis_Force
							bg := "Trans"
						else
							bg := IsTransparent(themeMap["TextLabelBackgroundColor"]) ? "Trans" : themeMap["TextLabelBackgroundColor"] ? themeMap["TextLabelBackgroundColor"] : themeMap["Background"]
						fg := themeMap["TextColor"]
					}

					opt := "Background" bg " c" fg
				case "Edit":
					bg := IsTransparent(themeMap["Background"]) ? "Trans" : themeMap["Background"]
					fg := themeMap["TextColor"]
					if BG_Invis_Force
						bg := "Trans"
					opt := "Background" bg " Smooth c" fg
				case "CheckBox":
					bg := IsTransparent(themeMap["Background"]) ? "Trans" : themeMap["Background"]
					fg := themeMap["TextColor"]
					if BG_Invis_Force
						bg := "Trans"
					opt := "Background" bg " Smooth c" fg
				case "Progress":
					fg := themeMap["ProgressBarColor"]
					bg := themeMap["ProgressBarBackground"]
					opt := "Background" bg " Smooth c" fg
				case "Link":
					fg := themeMap["LinkColor"]
					opt := "c" fg
				case "Slider":
					fg := themeMap["TextColor"]
					bg := "Trans"
					opt := "Background" bg " Smooth c" fg
				default:
					continue ; Skip unsupported or unknown control types
			}
			
			; Sanitize fg/bg for comparison
			fg := fg ?? ""
			bg := bg ?? ""
			fs := fs ?? ""
			fw := fw ?? ""
			font := font ?? ""

			; Check if update is needed
			needsUpdate := (
				!ctrl.HasOwnProp("_lastFG") || ctrl._lastFG != fg

				|| !ctrl.HasOwnProp("_lastBG") || ctrl._lastBG != bg

				|| !ctrl.HasOwnProp("_lastFS") || ctrl._lastFS != fs

				|| !ctrl.HasOwnProp("_lastFW") || ctrl._lastFW != fw
				
				|| !ctrl.HasOwnProp("_lastFont") || ctrl._lastFont != font
			)

			if needsUpdate {
				try ctrl.Opt(opt)
				try ctrl.SetFont("s" fs " w" fw, font)
				try ctrl.Redraw()

				ctrl._lastFG := fg
				ctrl._lastBG := bg
				ctrl._lastFS := fs
				ctrl._lastFW := fw
				ctrl._lastFont := font
			}
		}
	}

	; Update GUI background
	if guiObj.BackColor != themeMap["MainMenuBackground"]
		guiObj.BackColor := themeMap["MainMenuBackground"]
}

CheckDeviceTheme(*) {
	global currentTheme
	global MainUI
	global SettingsUI
	global WindowSettingsUI
	global ExtrasUI
	global ScriptSettingsUI
	global PatchUI

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
	if PatchUI
		try updateGUITheme(PatchUI)
}

GetDefaultThemes(*) {
	return Map(
		"Dark Mode", Map(
			"MainMenuBackground", "303030",
			"Background", "303030",
			"TextLabelBackgroundColor", "none",
			"TextColor", "dddddd",
			"ButtonTextColor", "000000",
			"LinkColor", "99c3ff",
			"ProgressBarColor", "5c5cd8",
			"ProgressBarBackground", "404040",
			"DescriptionBoxColor", "404040",
			"DescriptionBoxTextColor", "FFFFFF",
			"HeaderColor", "ff4840",
			"ButtonFontSize", "12",
			"ButtonFontWeight", "w700",
			"ButtonFontStyle", "Consolas",
		),
		"Light Mode", Map(
			"MainMenuBackground", "EEEEEE",
			"Background", "EEEEEE",
			"TextLabelBackgroundColor", "none",
			"TextColor", "000000",
			"ButtonTextColor", "000000",
			"LinkColor", "4787e7",
			"ProgressBarColor", "54cc54",
			"ProgressBarBackground", "FFFFFF",
			"DescriptionBoxColor", "CCCCCC",
			"DescriptionBoxTextColor", "000000",
			"HeaderColor", "ff4840",
			"ButtonFontSize", "12",
			"ButtonFontWeight", "w700",
			"ButtonFontStyle", "Consolas",
		),
		"Custom", Map(
			"MainMenuBackground", "FFFFFF",
			"Background", "FFFFFF",
			"TextLabelBackgroundColor", "none",
			"TextColor", "000000",
			"ButtonTextColor", "000000",
			"LinkColor", "7d4dc2",
			"ProgressBarColor", "a24454",
			"ProgressBarBackground", "EEEEEE",
			"DescriptionBoxColor", "AAAAAA",
			"DescriptionBoxTextColor", "000000",
			"HeaderColor", "ff4840",
			"ButtonFontSize", "12",
			"ButtonFontWeight", "w700",
			"ButtonFontStyle", "Consolas",
		)
	)
}

GetThemeKeys() {
	defaults := GetDefaultThemes()
	
	local keys := []
	for themeName, themeData in defaults ; loop through all themes
		for dataName, dataValue in themeData ; loop through all theme data
			if !keys.Has(dataName) ; if the key doesn't exist, add it
				keys.Push(dataName)
	return keys
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
	dataSets := GetDefaultThemes()

	if !FileExist(localScriptDir "\themes.ini") {
		themeFile := localScriptDir "\themes.ini"
		SaveThemeToINI(dataSets["Dark Mode"], "Dark Mode")
		SaveThemeToINI(dataSets["Light Mode"], "Light Mode")
		SaveThemeToINI(dataSets["Custom"], "Custom")
	} else
		themeFile := localScriptDir "\themes.ini"

	; Check themes in ini file
	for themeName, themeData in dataSets { ; loop through all themes
		local cachedTheme := LoadThemeFromINI(themeName) ; check if theme exists in ini file
		if !cachedTheme { ; if not, save it
			SaveThemeToINI(themeData, themeName, themeFile)
			cachedTheme := LoadThemeFromINI(themeName) ; reload the theme from ini file
		}
		
		for dataName, dataValue in themeData { ; loop through all theme data
			existingValue := IniRead(themeFile, themeName, dataName, "__MISSING__") ; check if the value exists in the ini file
			
			if existingValue == "__MISSING__" ; if not, write it to the ini file
				IniWrite(dataValue, themeFile, themeName, dataName)
		}
	}

	; Get theme from ini file
	global currentTheme := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "SelectedTheme", "Dark Mode")
	local themeData := LoadThemeFromINI(currentTheme)

	global MainUI_BG := themeData["MainMenuBackground"]
	global intWindowColor := themeData["Background"]
	global intControlColor := themeData["Background"]
	global intProgressBarColor := themeData["ProgressBarBackground"]
	global ControlTextColor := themeData["ButtonTextColor"]
	global linkColor := themeData["LinkColor"]
	global buttonFontSize := themeData["ButtonFontSize"]
	global buttonFontWeight := themeData["ButtonFontWeight"]
	global buttonFont := themeData["ButtonFontStyle"]
}

updateGUITheme(GUIObject) {
	if not GUIObject
		return

    global currentTheme
    theme := LoadThemeFromINI(currentTheme)
    try ApplyThemeToGui(GUIObject, theme)
}

LoadThemeFromINI(themeName, filePath := localScriptDir "\themes.ini") {
	local theme := Map()
	for _, key in GetThemeKeys()
		theme[key] := IniRead(filePath, themeName, key, "")
	return theme
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

isPixelColorInRadius(x, y, color, radius) {
	local pixelColor := PixelGetColor(x, y, "RGB")
	local distance := Sqrt((x - x) ** 2 + (y - y) ** 2)
	return (pixelColor = color && distance <= radius)
}

; ############################### ;
; ###### Utility Functions ###### ;
; ############################### ;

tick() {
    static EPOCH_OFFSET := 116444736000000000  ; 100ns intervals from 1601 to 1970
    buf := Buffer(8, 0)                         ; allocate 8 bytes
    DllCall("GetSystemTimeAsFileTime", "Ptr", buf.Ptr)
    fileTime := NumGet(buf, 0, "Int64")         ; read 64-bit FILETIME
	; Free the buffer
	buf := unset                                   ; release the buffer
    return math.round((fileTime - EPOCH_OFFSET) / 10000000) ; convert to seconds
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

ReloadScript(*) {
	SaveMainUIPosition()
	Reload
}

; ################################ ;
; ########## Animations ########## ;
; ################################ ;

FadeWindow(hwnd, direction := "in", duration := 300, autoClose := true) {
    global fadeLock

    if fadeLock {
        SetTimer(FadeWindow.Bind(hwnd, direction, duration, autoClose), -duration)
        return
    }

    fadeLock := true

    steps := 30
    interval := duration // steps

    Loop steps {
        t := A_Index / steps
        eased := easeInOutSine(t)
        opacity := direction = "in"
            ? Round(eased * 255)
            : Round((1 - eased) * 255)

        WinSetTransparent(opacity, hwnd)
        Sleep interval
    }

    if direction = "in" {
        WinSetTransparent(255, hwnd)
    } else {
        WinSetTransparent(0, hwnd)
        if autoClose
            WinClose(hwnd)
    }

    fadeLock := false
}

easeInOutSine(t) {
    return -(math.cos(math.pi() * t) - 1) / 2
}

; ################################ ;
; ####### Debug Functions ######## ;
; ################################ ;

Print(vals*) {
	local output := ""
	for _, val in vals
		output .= PrintValue(val, "")
	return output
}

PrintValue(val, indent) {
	local output := ""

	if !IsObject(val) {
		return indent . val . "`n"
	}

	local typename := ""
	try typename := Type(val)
	catch
		typename := "Unknown"

	; Use known names for readability
	switch typename {
		case "Array":
			output .= indent . "Array:`n"
		case "Map":
			output .= indent . "Map:`n"
		case "Func":
			output .= indent . "Function:`n"
		case "Gui":
			output .= indent . "GUI:`n"
		case "BoundFunc":
			output .= indent . "Bound Function:`n"
		default:
			output .= indent . typename . ":`n"
	}

	; Try to iterate contents safely
	try {
		for key, item in val {
			if IsObject(item)
				output .= indent . "  " . key . ":`n" . PrintValue(item, indent . "    ")
			else
				output .= indent . "  " . key . ": " . item . "`n"
		}
	} catch {
		output .= indent . "  (non-iterable)" . "`n"
	}

	return output
}

IsA(val, typeName) {
	switch StrLower(typeName) {
		case "array":
			return val is Array
		case "function":
			return val is Func
		case "gui":
			return val is Gui
		case "object":
			return val is Object
		case "map":
			return val is Map
		case "buffer":
			return val is Buffer
		case "string":
			return val is String
		case "number":
			return val is Number
		case "integer":
			return val is Integer
		case "float":
			return val is Float
		case "Number":
			return val is Number
	}
}

; ################################ ;
; ####### Extra Functions ######## ;
; ################################ ;

Lerp(start, stop, step) {
    return start + (stop - start) * (step / 100)
}

IsFunc(obj) {
	if (obj is Func)
		return true
	
	return false
}

MeasureWrappedTextHeight(ctrl, text) {
	rc := Buffer(16, 0) ; RECT (left, top, right, bottom)
	; Set width limit to control's client width
	client := Buffer(16, 0)
	DllCall("GetClientRect", "ptr", ctrl.Hwnd, "ptr", client)
	clientW := NumGet(client, 8, "int")

	; Initialize RECT with desired width and zero height
	NumPut("int", 0, rc, 0)              ; left
	NumPut("int", 0, rc, 4)              ; top
	NumPut("int", clientW, rc, 8)        ; right
	NumPut("int", 0, rc, 12)             ; bottom

	hdc := DllCall("GetDC", "ptr", ctrl.Hwnd, "ptr")
	hFont := SendMessage(0x31, 0, 0, ctrl)
	if hFont
		DllCall("SelectObject", "ptr", hdc, "ptr", hFont)

	DT_WORDBREAK := 0x10
	DT_CALCRECT := 0x400
	flags := DT_WORDBREAK | DT_CALCRECT

	DllCall("DrawText", "ptr", hdc, "str", text, "int", -1, "ptr", rc, "uint", flags)
	DllCall("ReleaseDC", "ptr", ctrl.Hwnd, "ptr", hdc)

	; Height = bottom - top
	return NumGet(rc, 12, "int") - NumGet(rc, 4, "int")
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

MeasureTextHeight(ctrl, text := "Ag") {
	static SIZE := Buffer(8, 0)  ; holds width (int32) and height (int32)
	local L_hwnd := ctrl.Hwnd
	hdc := DllCall("GetDC", "ptr", L_hwnd, "ptr")
	
	hFont := SendMessage(0x31, 0, 0, ctrl) ; WM_GETFONT
	if hFont
		DllCall("SelectObject", "ptr", hdc, "ptr", hFont)

	; Use a typical character pair to measure full ascent + descent height
	DllCall("GetTextExtentPoint32", "ptr", hdc, "str", text, "int", StrLen(text), "ptr", SIZE)
	DllCall("ReleaseDC", "ptr", L_hwnd, "ptr", hdc)

	height := NumGet(SIZE, 4, "int")
	return height
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
	global buttonFontSize, buttonFontWeight, buttonFont

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
	buttonFontSize := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "ButtonFontSize", "12", "int")
	buttonFontWeight := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "ButtonFontSize", "12", "int")
	buttonFont := readIniProfileSetting(ProfilesDir, SelectedProcessExe, "ButtonFontSize", "12", "int")
	
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
	SelectedProcessExe := name
    updateIniProfileSetting(ProfilesDir, "SelectedProcessExe", "Process", name)
}

GetSelectedProcessName() {
	global ProfilesDir
	if !IniSectionExists(ProfilesDir, "SelectedProcessExe")
		updateIniProfileSetting(ProfilesDir, "SelectedProcessExe", "Process", "RobloxPlayerBeta.exe")
    return readIniProfileSetting(ProfilesDir, "SelectedProcessExe", "Process", "RobloxPlayerBeta.exe")
}

createDefaultSettingsData(*) {
    global selectedProcessExe, ProfilesDir

	if !IniKeyExists(ProfilesDir, "General", "AcceptedWarning")
		IniWrite("false", ProfilesDir, "General", "AcceptedWarning")
	
    selectedExe := GetSelectedProcessName()
	loadProfileSettings(selectedExe)
}

createDefaultDirectories(*) {
	global localScriptDir, Utilities, icons
	if !DirExist(localScriptDir)
		DirCreate(localScriptDir)

	if !DirExist(localScriptDir "images")
		DirCreate(localScriptDir "images")

	if !DirExist(localScriptDir "images\icons")
		DirCreate(localScriptDir "images\icons")

	if !DirExist(Utilities)
		DirCreate(Utilities)

	for i,IconData in icons {
		if !FileExist(IconData.Icon)
			DownloadURL(IconData.URL, IconData.Icon)
	}
}

; ################################ ;
; ####### Update Functions ####### ;
; ################################ ;

IsVersionNewer(localVersion, onlineVersion) {
	if !localVersion || !onlineVersion
		return "Failed"

	localParts := StrSplit(localVersion, ".")
	onlineParts := StrSplit(onlineVersion, ".")
	
	; Compare each version segment numerically
	Loop localParts.Length {
		localPart := localParts[A_Index]
		onlinePart := onlineParts && onlineParts.Has(A_Index) ? onlineParts[A_Index] : unset
		if !onlinePart or !IsSet(onlinePart)
			return "Failed"

		; Treat missing parts as 0 (e.g., "1.2" vs "1.2.1")
		localPart := localPart != "" ? localPart : 0
		onlinePart := onlinePart != "" ? onlinePart : 0

		if (onlinePart > localPart)
			return "Outdated"
		else if (onlinePart < localPart)
			return "Beta"
	}
	return "Updated" ; Versions are equal
}

GetLatestReleaseVersion(JSON := "") {
    local URL_API := "https://api.github.com/repos/WoahItsJeebus/JACS/releases/latest"
    local tempJSONFile := JSON or A_Temp "\latest_release.json"
    
	if !JSON
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
    
    global URL_SCRIPT
	global tempUpdateFile
	global latestVersion := GetLatestReleaseVersion()
	
	global localScriptDir
	local getStatus := IsVersionNewer(version, latestVersion)
    if getStatus == "Outdated" {
        if !autoUpdateDontAsk {
            SendNotification("Get the latest version from GitHub?", Map(
				"Type", "yesno",
				"OnYes", (*) => (
					autoUpdateDontAsk := true
					Run("https://github.com/WoahItsJeebus/JACS/releases/latest")
				),
				"OnNo", (*) => (
					autoUpdateDontAsk := true
					SetTimer(AutoUpdate, 0)
				),
				"Duration", 15000,
				"Title", "JACS - Update Available!",
			))
        }
    } else if getStatus == "Updated" {
		autoUpdateDontAsk := false
		SetTimer(AutoUpdate, 0)
	} else if getStatus == "Beta" {
		autoUpdateDontAsk := true
		SendNotification("Using JACS beta version " version ". Continuing with onboard script", Map(
			"Duration", 5000,
			"Title", "JACS - Update Status",
		))
	} else if getStatus == "Failed" {
		autoUpdateDontAsk := true
		SendNotification("JACS update check failed. Continuing with onboard script", Map(
			"Duration", 5000,
			"Title", "JACS - Update Status",
		))
	} else {
		autoUpdateDontAsk := true
		SendNotification("JACS update check returned `"Other`"", Map(
			"Duration", 5000,
			"Title", "JACS - Update Status",
		))
	}
}

AutoUpdate(*) {
	global autoUpdateDontAsk
	if autoUpdateDontAsk
		return toggleAutoUpdate(false)
	
	GetUpdate()
}

toggleAutoUpdate(doUpdate := false) {
	if !doUpdate
		return SetTimer(AutoUpdate, 0)

	GetUpdate()
	return SetTimer(AutoUpdate, 60000)
}

; ################################ ;
; ######## INI Functions ######### ;
; ################################ ;

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

IniKeyExists(filePath, section, key) {
    return IniRead(filePath, section, key, "__MISSING__") != "__MISSING__"
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

updateIniProfileSetting(filePath, section, key, value) {
    SplitPath(filePath,, &dir)
    if !DirExist(dir)
        DirCreate(dir)

    existing := IniRead(filePath, section, key, "")
    if (existing != value)
        IniWrite(value, filePath, section, key)
}

updateIniProfileSection(filePath, section, settingsMap) {
    for key, val in settingsMap
        updateIniProfileSetting(filePath, section, key, val)
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

RollThankYou(*) {
	local randomNumber := Random(1,10000)
	local OSVer := GetWinOSVersion()
	
	if randomNumber != 1 or (OSVer != "11" and OSVer != "10")
		return
	
	doNotif(*) {
		SendNotification("Hey! I want to thank you for using my script! It's nice to see my work getting out there and being used!", Map(
			"Type", "info",
			"OnYes", "",
			"OnNo", "",
			"Duration", 4000,
			"Title", "JACS - Thank You!",
		))
	}

	SetTimer(doNotif, -1)
}

getUniqueID() {
	static IDs := arr()
	local pickedID := math.random(1, 1000000)
	if  IDs.GetValue(pickedID) {
		return getUniqueID()
	}
	IDs.Push(pickedID)

	return pickedID
}

getActiveStatusColor() {
	global isActive
	return isActive == 1 ? "df5b5b"
		: isActive == 2 ? "e0e25b"
		: isActive == 3 ? "49e649"
		: "68c1da"
}

getControls(GUIObj) {
	local controls := []
	if !GUIObj or Type(GUIObj) != "Gui"
		return MsgBox("Invalid GUI object.")

	for ctrl in GUIObj {
		if !ctrl.HasProp("Type")
			continue

		switch ctrl.Type {
			case "Text", "Button", "Edit", "Link", "Progress":
				controls.Push(ctrl)
			case "ListView":
				controls.Push(ctrl)
			case "Tab":
				controls.Push(ctrl)
			default:
				continue
		}
	}


	return controls.Length > 0 and controls
}

; Get the size of a control
getControlSize(ctrlObj) {
	local x, y, w, h
	ctrlObj.GetPos(&x, &y, &w, &h)
	return {X: x, Y: y, W: w, H: h}
}

SlideGUI(GUIHwnd, x, y, duration := 200) {
	local startX, startY, endX, endY
	local GUIObj := GuiFromHwnd(GUIHwnd)
	GUIObj.GetPos(&startX, &startY, &w, &h)

	endX := x
	endY := y

	; Calculate the distance to move
	deltaX := endX - startX
	deltaY := endY - startY

	; Calculate the number of steps based on the duration and speed
	steps := 20
	stepDuration := duration / steps

	; Move the GUI in small increments
	Loop steps {
		startX += deltaX / steps
		startY += deltaY / steps
		GUIObj.Move(startX, startY)
		Sleep stepDuration
	}
}

debugFuncs(*) {
	local hotkeys := Map(
		"!F12", (*) => ReloadScript(),
		"^F12", (*) => ReloadScript(),
		"!F1", (*) => SendNotification("This is an `"ok`" test notification", Map(
			"Type", "ok",
			"Title", "JACS - Debug Notification",
			"OnOk", (*) => SendNotification("You clicked OK!", Map(
				"Type", "info",
				"Title", "JACS - Debug Notification",
			)),
		)),
		"!F2", (*) => SendNotification("This is a `"yesno`" test notification", Map(
			"Type", "yesno",
			"OnYes", (*) => SendNotification("You clicked Yes!", Map(
				"Title", "JACS - Debug Notification",
				"Type", "info",
			)),
			"OnNo", (*) => SendNotification("You clicked No!", Map(
				"Title", "JACS - Debug Notification",
				"Type", "info",
			)),
		)),
		"!F3", (*) => SendNotification("This is a `"cancel`" test notification", Map(
			"Title", "JACS - Debug Notification",
			"Type", "cancel",
			"OnCancel", (*) => SendNotification("You clicked Cancel!", Map(
				"Type", "info",
				"Title", "JACS - Debug Notification",
			)),
		)),
		"!F4", (*) => SendNotification("This is a `"info`" test notification", Map(
			"Title", "JACS - Debug Notification",
			"Type", "info",
		)),
		"!F5", (*) => SendNotification("This is a `"close`" test notification", Map(
			"Title", "JACS - Debug Notification",
			"Type", "close",
			"OnClose", (*) => SendNotification("You clicked Close!", Map(
				"Type", "info",
				"Title", "JACS - Debug Notification",
			)),
		)),
		"!F6", (*) => (
			h := 0, s := 0, v := 0
			SendNotification(Print(color3.toHSV(255, 90, 90, &h, &s, &v), tick()), Map(
				"Type", "info",
				"Title", "JACS - Debug Notification",
			))
		),
		"!F7", (*) => SendNotification(Print(tick())),
	)

	for key, function in hotkeys {
		try Hotkey(key, hotkeys[key], "On")
			catch Error as e
				SendNotification("Error: " e.Message, Map(
					"Type", "info",
					"Title", "JACS - Debug Keys Error",
				))
	}
}

if doDebug
	debugFuncs()

debugNotif(msg := "1", title := "", options := "16", duration := 2) {
	SendNotification(msg, Map(
		"Type", "info",
		"OnYes", "",
		"OnNo", "",
		"Duration", 5000,
		"Title", title,
	))
	; SendNotification(msg, title, options, duration)
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

; ################################# ;
; ##### Map & Array Functions ##### ;
; ################################# ;

getAllKeys(mapObj) {
	local keys := []
	if !mapObj or !IsA(mapObj,"Map")
		return MsgBox("Invalid Map object.")

	for key, value in mapObj {
		keys.Push(key)
	}

	return keys
}

getMapLength(map) {
	local length := 0
	for key, value in map {
		length++
	}
	return length
}

refreshArray(arr) {
	local newArr := []
	for _, item in arr {
		if item != "" {
			newArr.Push(item)
		}
	}
	return newArr
}

removeFromArray(array, item) {
	for i, value in array {
		if (value == item) {
			array.RemoveAt(i)
			break
		}
	}
	return array
}

ArrayHasValue(arrayTarget, target) {
	for pos, val in arrayTarget {
		if (target == val)
			return pos
	}
	return false
}

ArrayHasKey := (array, value) => ArrayHasValue(array, value)

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

global versionTags := GetGitHubReleaseTags(GeneralData["author"], GeneralData["repo"])

ShowPatchNotesGUI(release := "latest") {
    global GeneralData
	global versionTags

	if !GeneralData["versionData"].Has(release) {
		local initialLatestData := GetGitHubReleaseInfo(GeneralData["author"], GeneralData["repo"], release)
		GeneralData["versionData"][release] := Map("Patchnotes", "")
		GeneralData["versionData"][release]["Patchnotes"] := GetGitHubReleaseInfo(GeneralData["author"], GeneralData["repo"], release)["body"]
	}

	; 	"author", "WoahItsJeebus",
	; 	"repo", "JACS",
	; 	"versionData", Map()
	
	global AlwaysOnTopActive
	global MainUI_PosX
	global MainUI_PosY
	global PatchUI, ExtrasUI, MainUI
	global buttonFontSize, buttonFontWeight, buttonFont, buttonHeight, intWindowColor, ControlTextColor

	local Popout_Width := "700"
	local Popout_Height := "400"
	local marginX := 10
	local marginY := 10

	local AOTStatus := AlwaysOnTopActive == true and "+AlwaysOnTop" or "-AlwaysOnTop"
	local AOT_Text := (AlwaysOnTopActive == true and "On") or "Off"
	githubResponse := GeneralData["versionData"][release]["Patchnotes"] ? Map("title", release, "body", GeneralData["versionData"][release]["Patchnotes"]) : GetGitHubReleaseInfo(GeneralData["author"], GeneralData["repo"], release)
	patchNotes := githubResponse
	
    ; Create GUI Window
	if PatchUI {
		PatchUI.Destroy()
		PatchUI := ""
	}

	PatchUI := Gui(AOTStatus)
	if ExtrasUI
		PatchUI.Opt("+Owner" . MainUI.Hwnd)

	PatchUI.MarginX := marginX/2
	PatchUI.MarginY := marginY/2
	PatchUI.BackColor := intWindowColor
	PatchUI.Title := "Patchnotes"
	
	local PatchnotesLabel := PatchUI.Add("Text", "Section Center vPatchnotesLabel h40 w" (Popout_Width-marginX), "Patchnotes: " patchNotes["title"])
	PatchNotesLabel.GetPos(,,&LabelWidth,&LabelHeight)

	local VersionList := PatchUI.Add("DropDownList", "xm+" Popout_Width/3 - marginX " Section Center vVersionList R10 h" buttonHeight " w" (Popout_Width-marginX)/2.5, ["latest"])
	VersionList.Value := 1
	; VersionList.Move((Popout_Width/3) - marginX)
	VersionList.GetPos(,,&LabelWidth,&ListHeight)

	local addedHeight := LabelHeight + ListHeight
	local BodyBox := PatchUI.Add("Edit", "x" marginX " ys+" buttonHeight+marginY " vPatchnotes VScroll Section ReadOnly h" (Popout_Height+marginY) - addedHeight " w" Popout_Width-marginX, patchNotes["body"])

	if versionTags.Length > 0
		for index, tag in versionTags
			VersionList.Add([tag])

	
	PatchnotesLabel.SetFont("s" 20 " w" buttonFontWeight, buttonFont)
	VersionList.SetFont("s" buttonFontSize " w" buttonFontWeight, buttonFont)
	BodyBox.SetFont("s14 w600", "Consolas")

	PatchnotesLabel.Opt("Background" intWindowColor . " c" ControlTextColor)
	VersionList.Opt("Background" intWindowColor . " c" ControlTextColor)
	BodyBox.Opt("Background555555" . " c" ControlTextColor)

	VersionList.OnEvent("Change", SelectNewOption)

	PatchUI.Show("Hide AutoSize")

	WinGetClientPos(&MainX, &MainY, &MainW, &MainH, MainUI.Title)
	WinGetPos(,,&patchUI_width,&patchUI_height, PatchUI.Title)
	
	SelectNewOption()
	CheckDeviceTheme()
	
	CenterX := MainX + (MainW / 2) - (patchUI_width / 2)
	CenterY := MainY + (MainH / 2) - (patchUI_height / 2)
	PatchUI.Show("AutoSize X" CenterX " Y" CenterY)

	SelectNewOption(*) {
		githubResponse := GeneralData["versionData"].Has([VersionList.Text]) ? Map("title", VersionList.Text, "body", GeneralData["versionData"][VersionList.Text]["Patchnotes"]) : GetGitHubReleaseInfo(GeneralData["author"], GeneralData["repo"], VersionList.Text)
		if !GeneralData["versionData"].Has(VersionList.Text) {
			GeneralData["versionData"][VersionList.Text] := Map("Patchnotes", "")
			GeneralData["versionData"][VersionList.Text]["Patchnotes"] := githubResponse["body"]
		}

		patchNotes := githubResponse
		
		if BodyBox {
			BodyBox.Text := patchNotes["body"]
			PatchnotesLabel.Text := "Patchnotes: " (StrLower(VersionList.Text) == "latest" ? patchNotes["title"] . " (Latest)" : patchNotes["title"])
		}
	}
}

GetGitHubReleaseInfo(owner, repo, release := "latest") {
    static MAX_ATTEMPTS := 10
    static BASE_DELAY_MS := 1000  ; Start with 1 second delay

    url := (release != "latest")
        ? "https://api.github.com/repos/" owner "/" repo "/releases/tags/" release
        : "https://api.github.com/repos/" owner "/" repo "/releases/latest"

    attempt := 0
    loop {
        attempt++
        try {
            req := ComObject("Msxml2.XMLHTTP")
            req.open("GET", url, false)
            req.setRequestHeader("User-Agent", "AHK-Client") ; GitHub requires this
            req.send()

            ; Successful request
            if (req.status = 200) {
                res := JSON_parse(req.responseText)
                return Map(
                    "title", res.name,
                    "tag", res.tag_name,
                    "body", StripMarkdown(res.body)
                )
            }

            ; Retry on 429 (Too Many Requests) or 5xx errors or GitHub-specific abuse detection
            if (req.status = 429 || (req.status >= 500 && req.status < 600) || (req.status = 403 && InStr(req.responseText, "abuse detection"))) {
                if (attempt >= MAX_ATTEMPTS)
                    throw Error("Max retry attempts reached: " req.status " - " req.statusText, -1)
                Sleep(BASE_DELAY_MS * (2 ** (attempt - 1))) ; exponential backoff
                continue
            }

            ; Any other error, fail immediately
            throw Error(req.status " - " req.statusText, -1)

        } catch as e {
            if (attempt >= MAX_ATTEMPTS)
                throw Error("Persistent failure after " attempt " attempts.`n" e.Message, -1)
            Sleep(BASE_DELAY_MS * (2 ** (attempt - 1)))
        }
    }
}

GetGitHubReleaseTags(owner, repo) {
    ; repo should be something like "username/repo"
	url := "https://api.github.com/repos/" owner "/" repo "/releases"

    http := ComObject("WinHttp.WinHttpRequest.5.1")
    http.Open("GET", url, false)
    
	try
		http.Send()
	catch Error as e {
		SendNotification("Failed to fetch release tags. Error: " Print*(e.Message))
		return []
	}

	; Check if the request was successful
	if (http.Status != 200) {
		SendNotification("Failed to fetch release tags. Status: " Print*(http.Status))
		return []
	}

    jsonStr := http.ResponseText
    tags := arr()
    pos := 1
    ; Extract tag_name values directly from the JSON string.
    while RegExMatch(jsonStr, '"tag_name"\s*:\s*"([^"]+)"[\s\S]*?"prerelease"\s*:\s*(true|false)', &m, pos) {
		tag := m[1]

		; Accept both stable and pre-release tags like 2.7.0-beta.1
		if RegExMatch(tag, "^\d+(\.\d+)*$")  ; only accept version-like tags
			tags.Push(tag)

		pos := m.Pos + m.Len
	}

    return tags
}

JSON_parse(str) {
	htmlfile := ComObject("htmlfile")
	htmlfile.write('<meta http-equiv="X-UA-Compatible" content="IE=edge">')
	return htmlfile.parentWindow.JSON.parse(str)
}

StripHeadersOnly(text) {
    ; Normalize line endings
    text := StrReplace(text, "`r`n", "`n")
    text := StrReplace(text, "`r", "`n")
    if InStr(text, "\n")
        text := StrReplace(text, "\n", "`n")

    ; Split into lines
    lines := StrSplit(text, "`n")

    ; Loop through each line and replace headers
    for i, line in lines {
        ; Match #, ##, or ### headers
        if RegExMatch(line, "^\s*#{1,3}\s*(.+?)\s*$", &m)
            lines[i] := "[" m[1] "]"
    }

    ; Join lines back together
	return JoinArray(lines, "`n")
}

StripMarkdown(text) {
	; Normalize all line endings to `\n`
	text := StrReplace(text, "`r`n", "`n")
	text := StrReplace(text, "`r", "`n")

	; Ensure literal \n sequences are converted to actual newlines (common in JSON strings)
    if InStr(text, "\n")
        text := StrReplace(text, "\n", "`n")

	; Remove any remaining raw URLs (after markdown links are handled)
    text := RegExReplace(text, "https?://[^\s\)]+", "")
	
	; Wrap all headers in brackets
	text := StripHeadersOnly(text)
	
    ; Remove specific HTML tags like <ins>, <del>, <mark>
    text := RegExReplace(text, "(?i)<(ins|del|mark)>(.*?)<\/\1>", "$2")
	
    ; Convert Markdown-style hyperlinks [text](url) → text
    text := RegExReplace(text, "\[(.*?)\]\(.*?\)", "$1")
	
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
	
	; Reinstate newlines to "`n" for consistency
	text := StrReplace(text, "`n", "`r`n")

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
	SaveMainUIPosition()
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

global Keys := Map(
	"~W", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("W", false)
	),
	"~A", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("A", false)
	),
	"~S", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("S", false)
	),
	"~D", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("D", false)
	),
	"~Space", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("Space", false)
	),
	"~Left", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("Left", false)
	),
	"~Right", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("Right", false)
	),
	"~Up", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("Up", false)
	),
	"~Down", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("Down", false)
	),
	"~/", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("/", false)
	),
	"~LButton", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("LButton", false)
	),
	"~RButton", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("RButton", false)
	),
	"~WheelUp", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("WheelUp", true)
	),
	"~WheelDown", Map(
		"Function", isMouseClickingOnTargetWindow.Bind("WheelDown", true)
	),
	"~!BackSpace", Map(
		"Function", ToggleHide_Hotkey.Bind()
	),
	"~!\", Map(
		"Function", cooldownFailsafe.Bind()
	)
)

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