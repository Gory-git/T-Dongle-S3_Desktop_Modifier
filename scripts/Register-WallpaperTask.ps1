<#
.SYNOPSIS
    Registers a Task Scheduler job to run Set-Wallpaper.ps1 at every logon.
.NOTES
    Must be run as Administrator.
#>

$scriptPath = "$env:USERPROFILE\Scripts\Set-Wallpaper.ps1"
$taskName   = "SetDesktopWallpaperAtLogon"
$taskDesc   = "Downloads and sets desktop wallpaper at user logon."

# Verifica che lo script esista
if (-not (Test-Path $scriptPath)) {
    throw "Script not found at: $scriptPath - copy Set-Wallpaper.ps1 there first."
}

# Parametri dell'azione
$action = New-ScheduledTaskAction `
    -Execute    "powershell.exe" `
    -Argument   "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""

# Trigger: all'accesso dell'utente corrente
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"

# Impostazioni: riprova se fallisce, timeout 1 minuto, connessione non richiesta
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit     (New-TimeSpan -Minutes 2) `
    -RestartCount           3 `
    -RestartInterval        (New-TimeSpan -Minutes 1) `
    -StartWhenAvailable     `
    -RunOnlyIfNetworkAvailable

# Registrazione
Register-ScheduledTask `
    -TaskName   $taskName `
    -Action     $action `
    -Trigger    $trigger `
    -Settings   $settings `
    -Description $taskDesc `
    -RunLevel   Limited `
    -Force | Out-Null

Write-Verbose "Task '$taskName' registered successfully."
Write-Verbose "   Script path : $scriptPath"
Write-Verbose "   Trigger     : At logon for $env:USERNAME"
