#Requires AutoHotkey v2.0.19+
#SingleInstance Force

; -------------------------------
; Simplified Launcher for GitHub-updated AHK Script
; -------------------------------

; Define local paths
A_LocalAppData := EnvGet("LOCALAPPDATA")
localScriptDir := A_LocalAppData "\JACS"
localScriptPath := localScriptDir "\JACS.ahk"
cacheFilePath := localScriptDir "\launcher-cache.txt"

; Check for an existing local script & extract its version
if FileExist(localScriptPath) {
    scriptContent := FileRead(localScriptPath)
    ; Look for: version := "X.X.X"
    if RegExMatch(scriptContent, 'version\s*:=\s*"(\d+\.\d+\.\d+)"', &m)
        localVersion := m[1]
    else
        localVersion := "0.0.0"
} else {
    localVersion := ""
}

if !FileExist(localScriptDir)
    DirCreate(localScriptDir)

; Use the last successful release lookup as a cache so GitHub rate limits
; do not block normal launches.
latestVersion := LoadCachedReleaseTag(cacheFilePath, 360)

try {
    releaseInfo := GetGitHubReleaseInfo("WoahItsJeebus", "JACS")
    if releaseInfo.Has("tag") && (releaseInfo["tag"] != "") {
        latestVersion := NormalizeVersion(releaseInfo["tag"])
        SaveCachedReleaseTag(cacheFilePath, latestVersion)
    }
} catch {
    ; Keep the cached version if the API is unavailable or rate limited.
}

; Compare Versions
IsVersionNewer(localVersion, latestVersion) {
    localVersion := NormalizeVersion(localVersion)
    latestVersion := NormalizeVersion(latestVersion)

    if (localVersion = "" || latestVersion = "")
        return false

    localParts := StrSplit(localVersion, ".")
    latestParts := StrSplit(latestVersion, ".")
    for index, part in latestParts {
        localPart := (index <= localParts.Length) ? localParts[index] : 0
        if (part + 0 > localPart + 0)
            return true
        else if (part + 0 < localPart + 0)
            return false
    }
    return false
}

if (localVersion = "" or IsVersionNewer(localVersion, latestVersion)) {
    ; Download the updated script
    newScriptURL := "https://github.com/WoahItsJeebus/JACS/releases/latest/download/JACS.ahk"
    tempFilePath := A_Temp "\temp_script.ahk"
    
    try {
        Download(newScriptURL, tempFilePath)
    } catch {
        MsgBox "Failed to download the updated script. Please check your connection."
        ExitApp()
    }
    
    FileCopy(tempFilePath, localScriptPath, true)
    FileDelete(tempFilePath)
}

if (latestVersion = "" && FileExist(localScriptPath)) {
    Run(localScriptPath)
    ExitApp()
}

if (latestVersion = "" && !FileExist(localScriptPath)) {
    newScriptURL := "https://github.com/WoahItsJeebus/JACS/releases/latest/download/JACS.ahk"
    tempFilePath := A_Temp "\temp_script.ahk"

    try {
        Download(newScriptURL, tempFilePath)
        FileCopy(tempFilePath, localScriptPath, true)
        FileDelete(tempFilePath)
    } catch {
        MsgBox "Failed to retrieve the launcher script. Please check your connection."
        ExitApp()
    }
}

GetGitHubReleaseInfo(owner, repo, release:="latest") {
    req := ComObject("Msxml2.XMLHTTP")
    req.open("GET", "https://api.github.com/repos/" owner "/" repo "/releases/" release, false)
    req.setRequestHeader("User-Agent", "JACS Launcher")
    req.setRequestHeader("Accept", "application/vnd.github+json")
    req.send()

    if req.status != 200
        throw Error(req.status " - " req.statusText, -1)

    res := JSON_parse(req.responseText)

    try {
        return Map( 
            "title", res.name,     ; The release title (name)
            "tag", NormalizeVersion(res.tag_name),   ; The release version/tag
            "body", StripMarkdown(res.body)       ; The release body
		)
    }
    catch PropertyError {
        throw Error(res.message, -1)
    }

}

NormalizeVersion(version) {
    version := Trim(version)
    version := RegExReplace(version, "i)^v")
    return version
}

LoadCachedReleaseTag(cachePath, maxAgeMinutes := 360) {
    if !FileExist(cachePath)
        return ""

    try {
        cacheData := StrSplit(Trim(FileRead(cachePath)), "`n", "`r")
        if (cacheData.Length < 2)
            return ""

        cachedTag := NormalizeVersion(cacheData[1])
        cachedStamp := cacheData[2]
        if (cachedTag = "" || cachedStamp = "")
            return ""

        if (DateDiff(A_Now, cachedStamp, "Minutes") > maxAgeMinutes)
            return ""

        return cachedTag
    } catch {
        return ""
    }
}

SaveCachedReleaseTag(cachePath, tag) {
    try {
        if FileExist(cachePath)
            FileDelete(cachePath)

        FileAppend(NormalizeVersion(tag) "`n" A_Now, cachePath, "UTF-8")
    }
}

JSON_parse(str) {
	htmlfile := ComObject("htmlfile")
	htmlfile.write('<meta http-equiv="X-UA-Compatible" content="IE=edge">')
	return htmlfile.parentWindow.JSON.parse(str)
}

StripMarkdown(text) {
    ; Remove HTML tags (like <ins>, <del>, <mark>)
    text := RegExReplace(text, "<(ins|del|mark)>(.*?)<\/\1>", "$2")

    ; Remove full URLs (http/https links)
    text := RegExReplace(text, "https?://[^\s]+", "")

    ; Remove Markdown-style headings
    text := RegExReplace(text, "m)^#+\s*", "")

    ; Format common Markdown symbols
    text := RegExReplace(text, "\*\*(.*?)\*\*", "$1")  ; Bold
    text := RegExReplace(text, "\*(.*?)\*", "$1")      ; Italics
    text := RegExReplace(text, "``(.*?)``", "'$1'")    ; Inline code → 'code'
    text := RegExReplace(text, "~~(.*?)~~", "[$1]")    ; Strikethrough → [text]
    text := RegExReplace(text, ">\s?", "")             ; Blockquotes
    text := RegExReplace(text, "\[(.*?)\]\(.*?\)", "$1")  ; Remove hyperlinks but keep text

    ; Handle lists correctly
    text := RegExReplace(text, "-\s?", "• ")           ; Convert Markdown lists to bullet points
    text := RegExReplace(text, "\n\s*-", "\n•")        ; Ensure list continuity

    return text
}

; --- Step 5: Launch the script ---
Run(localScriptPath)
ExitApp()
