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
    [int]$WallpaperStyle = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── COSTANTI ───────────────────────────────────────────────────────────────────

# Log file
$logFile = "$env:APPDATA\WallpaperScript\wallpaper.log"

# Cartella per il download
$downloadFolder = "$env:TEMP\WallpaperDownloads"

# ── 1. Logging helper ────────────────────────────────────────────────────────
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

# ── 2. P/Invoke: Win32 SystemParametersInfo ──────────────────────────────────
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

# ════════════════════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════════════════════

Write-Log "--- New session started ---"

# Crea cartella download se non esiste
if (-not (Test-Path $downloadFolder)) {
    New-Item -ItemType Directory -Path $downloadFolder -Force | Out-Null
}

# Genera nome file casuale
$guid = [System.Guid]::NewGuid().ToString("N").Substring(0, 12)
$extension = "jpg"
$fileName = "{0}.{1}" -f $guid, $extension
$destinationPath = Join-Path -Path $downloadFolder -ChildPath $fileName

Write-Log "Generated file: $fileName"

# ── Download ─────────────────────────────────────────────────────────────────
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

# ── Applica le impostazioni di Windows ────────────────────────────────────────
$regPath = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $regPath -Name WallpaperStyle -Value $WallpaperStyle
Set-ItemProperty -Path $regPath -Name TileWallpaper -Value 0

# ── Applica lo sfondo ────────────────────────────────────────────────────────
$result = [NativeMethods]::SystemParametersInfo(20, 0, $destinationPath, 3)

if ($result) {
    Write-Log "Wallpaper applied successfully: $destinationPath"
    Write-Verbose "Wallpaper updated successfully."
    Write-Verbose "   Path : $destinationPath"
} else {
    $errCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
    Write-Log "SystemParametersInfo failed. Win32 error: $errCode" -Level "ERROR"
    Write-Error "Failed to set wallpaper. Win32 error: $errCode"
    exit 1
}

# ── Forza il refresh del desktop ─────────────────────────────────────────────
Start-Sleep -Milliseconds 500
$explorer = Get-Process -Name explorer -ErrorAction SilentlyContinue
if ($explorer) {
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 1000
    Start-Process explorer.exe
    Write-Log "Explorer restarted to refresh wallpaper"
}

# ── Pulisci vecchi file wallpaper (oltre 10 giorni) ──────────────────────────
$cutoffDate = (Get-Date).AddDays(-10)
Get-ChildItem -Path $downloadFolder -File -ErrorAction SilentlyContinue | 
    Where-Object { $_.LastWriteTime -lt $cutoffDate } | 
    Remove-Item -Force -ErrorAction SilentlyContinue

Write-Log "Cleanup completed"
