# Funktion zum Generieren eines zufälligen Registrierungsschlüssels
function Generate-RandomKey {
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    $key = ""
    for ($i = 0; $i -lt 5; $i++) {
        if ($i -gt 0) {
            $key += "-"
        }
        $key += -join (1..4 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
    }
    return $key
}

# Funktion zum Suchen der ausführbaren Datei des Spiels
function Find-GameExecutable {
    $driveLetters = Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root
    $exeName = "CNC3EP1.exe"
    foreach ($drive in $driveLetters) {
        $gamePath = Get-ChildItem -Path $drive -Recurse -ErrorAction SilentlyContinue -Filter $exeName -Force | Select-Object -First 1
        if ($gamePath) {
            return $gamePath.FullName
        }
    }
    return $null
}

# Generiere einen zufälligen Schlüssel
$randomKey = Generate-RandomKey

# Erstelle den Inhalt der .reg Datei
$regContent = @"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Electronic Arts\Electronic Arts\Command and Conquer 3 Kanes Wrath\ergc]
@="$randomKey"
"@

# Speicher die .reg Datei
$regFilePath = "$env:TEMP\change_key.reg"
$regContent | Out-File -FilePath $regFilePath -Encoding ASCII

# Finde die ausführbare Datei des Spiels
$gameExecutable = Find-GameExecutable
if (-not $gameExecutable) {
    Write-Error "Game executable not found."
    exit 1
}

# Pfad zur .bat Datei
$batFilePath = "$env:TEMP\start_game.bat"

# Erstelle den Inhalt der .bat Datei
$batContent = @"
@echo off
start "" "$gameExecutable"
timeout /t 10 /nobreak
regedit /s "$regFilePath"
"@

# Speicher die .bat Datei
$batContent | Out-File -FilePath $batFilePath -Encoding ASCII

# Pfad zur Verknüpfung auf dem Desktop
$shortcutPath = [System.IO.Path]::Combine([Environment]::GetFolderPath("Desktop"), "Command and Conquer 3 Kane's Wrath.lnk")

# Erstelle die Verknüpfung
$WScriptShell = New-Object -ComObject WScript.Shell
$shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $batFilePath
$shortcut.IconLocation = $gameExecutable
$shortcut.Save()

Write-Output "Shortcut has been created on the Desktop. The game will start first and the registry key will be changed after 10 seconds."
