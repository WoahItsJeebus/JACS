#Requires AutoHotkey v2.0.19
#SingleInstance Force

; =======================
;  CONFIG / CONSTANTS
; =======================

; Hotkeys to toggle the UI (change if you want)
ToggleHotkeys := [
    "^!F12",   ; Ctrl+Alt+F12
    "^!F11"    ; Ctrl+Alt+F11 (alternate)
]

; Registry path for UI visibility
kRegPath   := "HKCU\Software\Jeebus\AutoRunManager"
; INI file to store profiles
ConfigFile := A_ScriptDir "\AutoRunManager.ini"

; Check interval in milliseconds for watched programs
CheckIntervalMs := 1000

; =======================
;  GLOBALS
; =======================

global Profiles := []          ; Array of profile objects
global CurrentProfileIndex := 0
global MainGui, lvProfiles, lvFiles
global UIVisible := 1          ; Will be overridden by registry
global CheckTimerRunning := false

; =======================
;  STARTUP
; =======================

Init()

Init(*) {
    global UIVisible, ToggleHotkeys, kRegPath, CheckIntervalMs, CheckTimerRunning

    ; Read UI visibility from registry (default = visible)
    try
		UIVisible := RegRead(kRegPath, "UIVisible", 1)
    catch
		UIVisible := 1

    LoadProfiles()
    CreateMainGui()
    RefreshProfileLV()

    if UIVisible
        MainGui.Show()
    else
        MainGui.Hide()

    ; Set up hotkeys to toggle GUI
    for _, hk in ToggleHotkeys {
        Hotkey(hk, ToggleGuiVisibility.Bind(), "On")
    }

    ; Set up periodic checker
    SetTimer(CheckProfiles, CheckIntervalMs)
    CheckTimerRunning := true
}

; =======================
;  GUI SETUP
; =======================

CreateMainGui(*) {
    global MainGui, lvProfiles, lvFiles

    MainGui := Gui("+Resize", "AutoRun Manager")

    ; Left side: Profiles
    MainGui.Add("Text", "x10 y10", "Profiles:")
    lvProfiles := MainGui.Add("ListView"
        , "x10 y30 w420 h220 Grid AltSubmit -Multi"
        , ["On", "Name", "Exe", "Title filter"])
    
    lvProfiles.OnEvent("ItemSelect", LV_Profiles_Select)
    lvProfiles.OnEvent("DoubleClick", LV_Profiles_ToggleEnabled)

    btnAddProf    := MainGui.Add("Button", "x10  y260 w80",  "Add")
    btnEditProf   := MainGui.Add("Button", "x100 y260 w80",  "Edit")
    btnRemoveProf := MainGui.Add("Button", "x190 y260 w80",  "Remove")

    btnAddProf.OnEvent("Click",  AddProfile)
    btnEditProf.OnEvent("Click", EditProfile)
    btnRemoveProf.OnEvent("Click", RemoveProfile)

    ; Right side: Files for selected profile
    MainGui.Add("Text", "x450 y10", "Files to run for selected profile:")
    lvFiles := MainGui.Add("ListView"
        , "x450 y30 w440 h220 Grid AltSubmit -Multi"
        , ["Path"])

    btnAddFile    := MainGui.Add("Button", "x450 y260 w90",  "Add file")
    btnRemoveFile := MainGui.Add("Button", "x550 y260 w90",  "Remove file")

    btnAddFile.OnEvent("Click", AddFileToProfile)
    btnRemoveFile.OnEvent("Click", RemoveFileFromProfile)

    ; Close/minimize behavior
    MainGui.OnEvent("Close", Gui_OnClose)
    MainGui.OnEvent("Escape", Gui_OnEscape)
}

Gui_OnClose(*) {
    ; Just hide instead of exiting
    ToggleGuiVisibility()
}

Gui_OnEscape(*) {
    ToggleGuiVisibility()
}

ToggleGuiVisibility(*) {
    global MainGui, UIVisible, kRegPath

    if MainGui.Visible {
        MainGui.Hide()
        UIVisible := 0
    } else {
        MainGui.Show()
        UIVisible := 1
    }

    try RegWrite(UIVisible, "REG_DWORD", kRegPath, "UIVisible")
}

; =======================
;  PROFILES - DATA MODEL
; =======================

; Profile object template:
; {
;   Name:    "Roblox",
;   Exe:     "RobloxPlayerBeta.exe",
;   Title:   "Roblox",   ; optional
;   Enabled: true,
;   Files:   [ "C:\path\file1.ahk", "C:\path\file2.exe" ],
;   SeenPIDs: Map()      ; runtime only
; }

CreateEmptyProfile(name := "", exe := "", title := "") {
    profile := {
        Name:    name,
        Exe:     exe,
        Title:   title,
        Enabled: true,
        Files:   [],
        SeenPIDs: Map()
    }
    return profile
}

; =======================
;  LOAD / SAVE PROFILES
; =======================

LoadProfiles(*) {
    global Profiles, ConfigFile

    Profiles := []

    if !FileExist(ConfigFile)
        return

    count := IniRead(ConfigFile, "General", "ProfileCount", 0)
    count := count + 0

    Loop count {
        idx := A_Index
        section := "Profile" idx

        name    := IniRead(ConfigFile, section, "Name", "")
        exe     := IniRead(ConfigFile, section, "Exe", "")
        title   := IniRead(ConfigFile, section, "Title", "")
        enabled := IniRead(ConfigFile, section, "Enabled", 1)
        fileCnt := IniRead(ConfigFile, section, "FileCount", 0)

        files := []
        fileSection := section "_Files"

        Loop fileCnt {
            path := IniRead(ConfigFile, fileSection, "File" A_Index, "")
            if path != ""
                files.Push(path)
        }

        p := {
            Name:    name,
            Exe:     exe,
            Title:   title,
            Enabled: enabled ? true : false,
            Files:   files,
            SeenPIDs: Map()
        }

        Profiles.Push(p)
    }
}

SaveProfiles(*) {
    global Profiles, ConfigFile

    if FileExist(ConfigFile)
        FileDelete(ConfigFile)

    IniWrite(Profiles.Length, ConfigFile, "General", "ProfileCount")

    for idx, p in Profiles {
        section := "Profile" idx
        IniWrite(p.Name,                 ConfigFile, section, "Name")
        IniWrite(p.Exe,                  ConfigFile, section, "Exe")
        IniWrite(p.Title,                ConfigFile, section, "Title")
        IniWrite(p.Enabled ? 1 : 0,      ConfigFile, section, "Enabled")
        IniWrite(p.Files.Length,         ConfigFile, section, "FileCount")

        fileSection := section "_Files"
        for fi, path in p.Files {
            IniWrite(path, ConfigFile, fileSection, "File" fi)
        }
    }
}

; =======================
;  GUI <-> PROFILES
; =======================

RefreshProfileLV(*) {
    global lvProfiles, Profiles, CurrentProfileIndex

    lvProfiles.Delete()  ; delete all rows, keep columns

    for idx, p in Profiles {
        onText := p.Enabled ? "✓" : ""
        lvProfiles.Add(, onText, p.Name, p.Exe, p.Title)
    }

    if Profiles.Length {
        if CurrentProfileIndex < 1 || CurrentProfileIndex > Profiles.Length
            CurrentProfileIndex := 1
        lvProfiles.Modify(CurrentProfileIndex, "Select Focus")
    } else {
        CurrentProfileIndex := 0
    }

    RefreshFileLV()
}

RefreshFileLV(*) {
    global lvFiles, Profiles, CurrentProfileIndex

    lvFiles.Delete()

    if !CurrentProfileIndex
        return
    if CurrentProfileIndex > Profiles.Length
        return

    p := Profiles[CurrentProfileIndex]
    for i, path in p.Files {
        lvFiles.Add(, path)
    }
}

LV_Profiles_Select(ctrl, row*) {
    global CurrentProfileIndex
    CurrentProfileIndex := row and row[1]
    RefreshFileLV()
}

LV_Profiles_ToggleEnabled(ctrl, row) {
    global Profiles
    if !row
        return
    p := Profiles[row]
    p.Enabled := !p.Enabled
    SaveProfiles()
    RefreshProfileLV()
}

; =======================
;  PROFILE BUTTON HANDLERS
; =======================

AddProfile(*) {
    global Profiles

    nameBox := InputBox(
        "Enter a display name for this profile (e.g. Roblox):"
        , "Add Profile"
    )
    if nameBox.Result = "Cancel"
        return
    name := Trim(nameBox.Value)
    if (name = "")
        return

    exeBox := InputBox(
        "Enter the process .exe name (e.g. RobloxPlayerBeta.exe):"
        , "Add Profile"
        , "w300"
    )
    if exeBox.Result = "Cancel"
        return
    exe := Trim(exeBox.Value)
    if (exe = "")
        return

    titleBox := InputBox(
        "OPTIONAL: Enter a window title filter (substring, case-insensitive).`n" .
        "Leave blank to match any title for that exe."
        , "Add Profile"
        , "w400"
    )
    if titleBox.Result = "Cancel"
        return
    title := Trim(titleBox.Value)

    p := CreateEmptyProfile(name, exe, title)
    Profiles.Push(p)
    SaveProfiles()
    RefreshProfileLV()
}

EditProfile(*) {
    global Profiles, CurrentProfileIndex

    if !CurrentProfileIndex {
        MsgBox("Select a profile first.", "Edit Profile", "Icon!")
        return
    }

    p := Profiles[CurrentProfileIndex]

    nameBox := InputBox(
        "Edit display name:"
        , "Edit Profile - Name"
        , "w300", p.Name
    )
    if nameBox.Result = "Cancel"
        return
    name := Trim(nameBox.Value)
    if (name = "")
        return

    exeBox := InputBox(
        "Edit process .exe name (e.g. RobloxPlayerBeta.exe):"
        , "Edit Profile - Exe"
        , "w300", p.Exe
    )
    if exeBox.Result = "Cancel"
        return
    exe := Trim(exeBox.Value)
    if (exe = "")
        return

    titleBox := InputBox(
        "Edit window title filter (substring, case-insensitive).`n" .
        "Leave blank to match any title."
        , "Edit Profile - Title"
        , "w400", p.Title
    )
    if titleBox.Result = "Cancel"
        return
    title := Trim(titleBox.Value)

    p.Name  := name
    p.Exe   := exe
    p.Title := title

    SaveProfiles()
    RefreshProfileLV()
}

RemoveProfile(*) {
    global Profiles, CurrentProfileIndex

    if !CurrentProfileIndex {
        MsgBox("Select a profile first.", "Remove Profile", "Icon!")
        return
    }

    p := Profiles[CurrentProfileIndex]
    ans := MsgBox(
        "Remove profile '" p.Name "'?"
        , "Confirm Remove"
        , "YesNo Icon!"
    )
    if ans != "Yes"
        return

    Profiles.RemoveAt(CurrentProfileIndex)
    if CurrentProfileIndex > Profiles.Length
        CurrentProfileIndex := Profiles.Length
    SaveProfiles()
    RefreshProfileLV()
}

; =======================
;  FILE BUTTON HANDLERS
; =======================

AddFileToProfile(*) {
    global Profiles, CurrentProfileIndex

    if !CurrentProfileIndex {
        MsgBox("Select a profile first.", "Add File", "Icon!")
        return
    }

    path := FileSelect(1, , "Select a file to run for this profile")
    if path = ""
        return

    p := Profiles[CurrentProfileIndex]
    p.Files.Push(path)
    SaveProfiles()
    RefreshFileLV()
}

RemoveFileFromProfile(*) {
    global Profiles, CurrentProfileIndex, lvFiles

    if !CurrentProfileIndex {
        MsgBox("Select a profile first.", "Remove File", "Icon!")
        return
    }

    row := lvFiles.GetNext(0, "F")
    if !row {
        MsgBox("Select a file entry first.", "Remove File", "Icon!")
        return
    }

    p := Profiles[CurrentProfileIndex]
    if row > p.Files.Length
        return

    filePath := p.Files[row]
    ans := MsgBox(
        "Remove file:`n" filePath "?"
        , "Confirm Remove File"
        , "YesNo Icon!"
    )
    if ans != "Yes"
        return

    p.Files.RemoveAt(row)
    SaveProfiles()
    RefreshFileLV()
}

; =======================
;  PROCESS MONITOR
; =======================

CheckProfiles(*) {
    global Profiles

    for idx, p in Profiles {
        if !p.Enabled
            continue
        if p.Exe = ""
            continue

        ; Build WinTitle criteria:
        ; If a Title filter is provided, we use "TitleSubstring ahk_exe Exe"
        ; If not, just "ahk_exe Exe"
        criteria := (p.Title != "" ? p.Title " " : "") "ahk_exe " p.Exe

        hwndList := []
        try hwndList := WinGetList(criteria)
        catch
            hwndList := []

        ; Clean up SeenPIDs (remove processes that no longer exist)
        stale := []
        for pid, _ in p.SeenPIDs {
            if !ProcessExist(pid)
                stale.Push(pid)
        }
        for _, pid in stale {
            p.SeenPIDs.Delete(pid)
        }

        if hwndList.Length = 0
            continue

        for _, hwnd in hwndList {
            pid := 0
            try pid := WinGetPID("ahk_id " hwnd)
            if !pid
                continue

            if !p.SeenPIDs.Has(pid) {
                ; New process detected for this profile
                p.SeenPIDs[pid] := true
                RunFilesForProfile(p)
            }
        }
    }
}

RunFilesForProfile(p) {
    if p.Files.Length = 0
        return

    for _, path in p.Files {
        if path = ""
            continue
        if !FileExist(path) {
            TrayTip("AutoRun Manager"
                , "File not found: " path
                , "Icon!")
            continue
        }

        try {
            Run(path)
        } catch Error as err {
            TrayTip("AutoRun Manager"
                , "Failed to run: " path "`n" err.Message
                , "Icon!")
        }
    }
}