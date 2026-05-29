<#
.SYNOPSIS
    Downloads an image from the web and sets it as the desktop wallpaper.
    Destination folder and filename are fully randomized at each run.
.NOTES
    Author : You
    Requires: Windows 10/11, PowerShell 5.1+
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
    [string]$ImageUrl = "https://uploads.dailydot.com/2024/11/two-guys-kissing-meme.jpg?q=65&auto=format&w=1600&ar=2:1&fit=crop",

    # Stile: 0=Centered, 2=Stretched, 6=Fit, 10=Fill, 22=Span
    [ValidateSet(0, 1, 2, 6, 10, 22)]
    [int]$WallpaperStyle = 10,

    # Se $true, elimina i wallpaper scaricati nelle sessioni precedenti
    [bool]$CleanupOldFiles = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── COSTANTI ─────────────────────────────────────────────────────────────────

# File di registro: mappa ogni sessione → path usato
# Viene salvato in AppData per non dipendere dalla cartella random
$registryFile = "$env:APPDATA\WallpaperScript\session_registry.json"

# Pool di cartelle "padre" tra cui scegliere casualmente
$parentFolderPool = @(
    $env:TEMP,
    "$env:LOCALAPPDATA\Microsoft\Windows",
    "$env:APPDATA\Microsoft\Windows",
    "$env:USERPROFILE\AppData\LocalLow",
    [System.IO.Path]::GetTempPath()
)

# Estensioni valide coerenti con l'URL
$validExtensions = @("jpg", "jpeg", "png", "bmp")

# ── 1. Logging helper ────────────────────────────────────────────────────────
$logFile = "$env:APPDATA\WallpaperScript\wallpaper.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry     = "[$timestamp][$Level] $Message"
    Write-Verbose $entry

    $logDir = Split-Path $logFile
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    Add-Content -Path $logFile -Value $entry -ErrorAction SilentlyContinue
}

# ── 2. Generatore di path randomico ──────────────────────────────────────────
function New-RandomWallpaperPath {
    <#
    .SYNOPSIS
        Generates a fully random destination path for the wallpaper file.
    .OUTPUTS
        [hashtable] with keys: FolderPath, FilePath, FolderName, FileName
    #>

    # Cartella padre casuale dal pool
    $parentFolder = $parentFolderPool | Get-Random

    # Nome cartella: aggettivo + sostantivo + numero (es. "silent_bridge_4821")
    # Rende il nome plausibile come cartella di sistema/app
    $adjectives = @(
        "silent","local","common","native","shared","system",
        "default","managed","remote","secure","active","runtime"
    )
    $nouns = @(
        "bridge","cache","config","data","handler","index",
        "loader","module","parser","queue","router","worker"
    )
    $randomSuffix = Get-Random -Minimum 1000 -Maximum 9999
    $folderName   = "{0}_{1}_{2}" -f ($adjectives | Get-Random), ($nouns | Get-Random), $randomSuffix

    # Nome file: GUID troncato + estensione casuale
    $guid      = [System.Guid]::NewGuid().ToString("N").Substring(0, 12)  # es. "3f8a1c9d2b7e"
    $extension = $validExtensions | Get-Random
    $fileName  = "{0}.{1}" -f $guid, $extension

    $folderPath = Join-Path -Path $parentFolder -ChildPath $folderName
    $filePath   = Join-Path -Path $folderPath   -ChildPath $fileName

    return @{
        FolderPath = $folderPath
        FilePath   = $filePath
        FolderName = $folderName
        FileName   = $fileName
    }
}

# ── 3. Gestione registro sessioni ─────────────────────────────────────────────
function Get-SessionRegistry {
    $registryDir = Split-Path $registryFile
    if (-not (Test-Path $registryDir)) {
        New-Item -ItemType Directory -Path $registryDir -Force | Out-Null
    }

    if (Test-Path $registryFile) {
        try {
            $content = Get-Content $registryFile -Raw | ConvertFrom-Json
            # ConvertFrom-Json restituisce PSCustomObject; convertiamo in lista
            return [System.Collections.Generic.List[object]]($content)
        }
        catch {
            Write-Log "Registry file corrupted, resetting." -Level "WARN"
        }
    }
    return [System.Collections.Generic.List[object]]::new()
}

function Save-SessionRegistry {
    param([System.Collections.Generic.List[object]]$Registry)
    $Registry | ConvertTo-Json -Depth 3 | Set-Content -Path $registryFile -Encoding UTF8
}

function Add-SessionEntry {
    param(
        [System.Collections.Generic.List[object]]$Registry,
        [string]$FilePath,
        [string]$FolderPath
    )
    $entry = [PSCustomObject]@{
        SessionId  = [System.Guid]::NewGuid().ToString()
        FilePath   = $FilePath
        FolderPath = $FolderPath
        Timestamp  = (Get-Date -Format "o")  # ISO 8601
    }
    $Registry.Add($entry)
    return $entry
}

# ── 4. Cleanup sessioni precedenti ───────────────────────────────────────────
function Remove-OldWallpapers {
    param([System.Collections.Generic.List[object]]$Registry)

    # Mantieni solo l'ultima sessione (quella corrente non è ancora aggiunta)
    $toRemove = $Registry | Select-Object -SkipLast 0  # tutte le precedenti

    foreach ($entry in $toRemove) {
        try {
            if (Test-Path $entry.FilePath) {
                Remove-Item -Path $entry.FilePath -Force
                Write-Log "Deleted old wallpaper: $($entry.FilePath)"
            }
            # Rimuovi la cartella solo se è vuota
            if ((Test-Path $entry.FolderPath) -and
                @(Get-ChildItem $entry.FolderPath -Force).Count -eq 0) {
                Remove-Item -Path $entry.FolderPath -Force
                Write-Log "Deleted empty folder: $($entry.FolderPath)"
            }
        }
        catch {
            Write-Log "Could not delete $($entry.FilePath): $_" -Level "WARN"
        }
    }

    # Svuota il registro (il nuovo entry verrà aggiunto dopo)
    $Registry.Clear()
}

# ── 5. P/Invoke: Win32 SystemParametersInfo ──────────────────────────────────
$signature = @"
using System;
using System.Runtime.InteropServices;

public static class NativeMethods {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool SystemParametersInfo(
        uint uiAction,
        uint uiParam,
        string pvParam,
        uint fWinIni
    );
}
"@

if (-not ([System.Management.Automation.PSTypeName]'NativeMethods').Type) {
    Add-Type -TypeDefinition $signature -Language CSharp
}

# ═══════════════════════════════════════════════════════════════════════════════
#  MAIN
# ═══════════════════════════════════════════════════════════════════════════════

Write-Log "─── New session started ───"

# Carica registro sessioni
$sessionRegistry = Get-SessionRegistry

# Cleanup vecchi file (se abilitato)
if ($CleanupOldFiles -and $sessionRegistry.Count -gt 0) {
    Write-Log "Cleanup enabled. Removing $($sessionRegistry.Count) previous entry/entries."
    Remove-OldWallpapers -Registry $sessionRegistry
}

# Genera path randomico
$randomPath = New-RandomWallpaperPath
$destinationFolder = $randomPath.FolderPath
$destinationPath   = $randomPath.FilePath

Write-Log "Generated random folder : $destinationFolder"
Write-Log "Generated random file   : $($randomPath.FileName)"

# Crea cartella
if (-not (Test-Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null
    Write-Log "Created folder: $destinationFolder"
}

# ── Download ──────────────────────────────────────────────────────────────────
try {
    Write-Log "Downloading from: $ImageUrl"

    $webClient = [System.Net.WebClient]::new()
    $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    $webClient.DownloadFile($ImageUrl, $destinationPath)
    $webClient.Dispose()

    Write-Log "Image saved to: $destinationPath"
}
catch {
    Write-Log "Download failed: $_" -Level "ERROR"
    Write-Error "Download failed. Check your internet connection or the URL."
    exit 1
}

# ── Registro del registro di Windows (stile sfondo) ──────────────────────────
$regPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $regPath -Name WallpaperStyle -Value $WallpaperStyle
Set-ItemProperty -Path $regPath -Name TileWallpaper  -Value $(if ($WallpaperStyle -eq 1) { 1 } else { 0 })

# ── Applica lo sfondo ─────────────────────────────────────────────────────────
Remove-ItemProperty -Path $regPath -Name "Wallpaper" -ErrorAction SilentlyContinue

$result = [NativeMethods]::SystemParametersInfo(20, 0, $destinationPath, 3)

if ($result) {
    Write-Log "Wallpaper applied: $destinationPath"
    Write-Host "✅ Wallpaper updated successfully." -ForegroundColor Green
    Write-Host "   Path : $destinationPath"
} else {
    $errCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    Write-Log "SystemParametersInfo failed. Win32 error: $errCode" -Level "ERROR"
    Write-Error "Failed to set wallpaper. Win32 error: $errCode"
    exit 1
}

# ── Salva la sessione nel registro ────────────────────────────────────────────
Add-SessionEntry -Registry $sessionRegistry -FilePath $destinationPath -FolderPath $destinationFolder | Out-Null
Save-SessionRegistry -Registry $sessionRegistry
Write-Log "Session registered. Total tracked entries: $($sessionRegistry.Count)"
# Forza il refresh del desktop
Start-Sleep -Milliseconds 500
$explorer = Get-Process -Name explorer -ErrorAction SilentlyContinue
if ($explorer) {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 1000
    Start-Process explorer.exe
    Write-Log "Explorer restarted to refresh wallpaper"
}