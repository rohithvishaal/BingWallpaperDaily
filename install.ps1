$dest = Join-Path$env:USERPROFILE "Pictures\wallpapers"
if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path$dest -Force | Out-Null }

# Download script directly from your repo
$rawScriptUrl = "https://raw.githubusercontent.com/rohithvishaal/BingWallpaperDaily/main/Update-Wallpaper.ps1"
Invoke-WebRequest -Uri $rawScriptUrl -OutFile "$dest\Update-Wallpaper.ps1"

# Register the Scheduled Task
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$dest\Update-Wallpaper.ps1`""
$trigger = New-ScheduledTaskTrigger -AtLogOn

Register-ScheduledTask -TaskName "DailyBingWallpaper" -Action $action -Trigger$trigger -Description "Daily 4K Bing Wallpaper" -Force | Out-Null
Start-ScheduledTask -TaskName "DailyBingWallpaper"
Write-Host "Daily Bing 4K Wallpaper installed and activated successfully!" -ForegroundColor Green