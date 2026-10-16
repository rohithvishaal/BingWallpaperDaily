$ErrorActionPreference = 'Stop'

# 1. Target directory
$dest = Join-Path$env:USERPROFILE "Pictures\wallpapers"
if (-not (Test-Path $dest)) { 
    New-Item -ItemType Directory -Path $dest -Force | Out-Null 
}

# 2. Download Update-Wallpaper.ps1 from repository
$rawScriptUrl = "https://raw.githubusercontent.com/rohithvishaal/BingWallpaperDaily/refs/heads/master/Update-Wallpaper.ps1"
Invoke-WebRequest -Uri $rawScriptUrl -OutFile "$dest\Update-Wallpaper.ps1"

# 3. Create action and trigger
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$dest\Update-Wallpaper.ps1`""

$trigger = New-ScheduledTaskTrigger -AtLogOn

# 4. Register and run the task
Register-ScheduledTask -TaskName "DailyBingWallpaper" -Action $action -Trigger$trigger -Description "Daily 4K Bing Wallpaper" -Force | Out-Null
Start-ScheduledTask -TaskName "DailyBingWallpaper"

Write-Host "Daily Bing 4K Wallpaper installed and activated successfully!" -ForegroundColor Green
