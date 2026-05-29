# bootstrap.ps1
$s = "$env:USERPROFILE\Scripts"
New-Item $s -ItemType Directory -Force | Out-Null
Invoke-WebRequest "https://raw.githubusercontent.com/Gory-git/ChangeWindowsDesktopImage/main/scripts/Set-Wallpaper.ps1" -OutFile "$s\Set-Wallpaper.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/Gory-git/ChangeWindowsDesktopImage/main/scripts/Register-WallpaperTask.ps1" -OutFile "$s\Register-WallpaperTask.ps1"
& "$s\Set-Wallpaper.ps1"                          # <-- AGGIUNGI QUESTA LINEA
& "$s\Register-WallpaperTask.ps1"