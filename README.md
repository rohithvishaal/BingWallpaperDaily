# Bing Daily 4K Wallpaper Automator for Windows

An automated PowerShell utility that downloads Microsoft Bing's daily wallpaper in native 4K UHD (`3840x2160`), applies it as your Windows desktop background, and fires a native Windows toast notification with the file path.

---
## Install (open powershel and paste this command)
```ps1
irm https://raw.githubusercontent.com/rohithvishaal/BingWallpaperDaily/refs/heads/master/install.ps1 | iex
```
## Features

* **True 4K UHD:** Queries the Bing archive via the `_UHD.jpg` endpoint (`3840x2160`) instead of the standard 1080p stream.
* **Date-Stamped Archive:** Saves files chronologically as `bing_YYYY-MM-DD.jpg` in your Pictures folder.
* **Once-Per-Day Guard:** Triggers on logon, checks if today's wallpaper already exists, and exits immediately on subsequent logins or reboots.
* **Boot-Resilient Network Wait:** Polls DNS for up to 30 seconds after logon to ensure Wi-Fi/Ethernet is connected before downloading.
* **Windows Toast Notification:** Sends a native notification displaying the update status and file save location.
* **Aspect Scaling:** Automatically configures desktop registry settings to **Fill** mode (`WallpaperStyle = 10`).

---

## Repository Structure

```text
bing-wallpaper/
│
├── Update-Wallpaper.ps1       # Main PowerShell automation script
└── README.md                  # Setup and usage guide
```

---

## (Manual) Setup & Installation

### 1. File Placement

Create your destination directory and place `Update-Wallpaper.ps1` inside it:

* **Target Path:** `C:\Users\<YOUR_USERNAME>\Pictures\wallpapers\Update-Wallpaper.ps1`

You can quickly copy the script from the repository into this location using PowerShell:

```powershell
$dest = Join-Path $env:USERPROFILE "Pictures\wallpapers"
if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest -Force }
Copy-Item ".\Update-Wallpaper.ps1" -Destination $dest
```

---

### 2. Register the Scheduled Task

To trigger the script automatically every time you log on, open standard PowerShell (no administrator privileges required) and run:

```powershell
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$HOME\Pictures\wallpapers\Update-Wallpaper.ps1`""

$trigger = New-ScheduledTaskTrigger -AtLogOn

Register-ScheduledTask `
    -TaskName "DailyBingWallpaper" `
    -Action $action `
    -Trigger $trigger `
    -Description "Fetches daily 4K Bing wallpaper on first user logon to Pictures\wallpapers" `
    -Force
```

---

## Testing

* **Run manually:**
  ```powershell
  powershell.exe -ExecutionPolicy Bypass -File "$HOME\Pictures\wallpapers\Update-Wallpaper.ps1"
  ```

* **Trigger the scheduled task directly:**
  ```powershell
  Start-ScheduledTask -TaskName "DailyBingWallpaper"
  ```

---

## Maintenance & Removal

* **Check task status:**
  ```powershell
  Get-ScheduledTask -TaskName "DailyBingWallpaper"
  ```

* **Disable the task:**
  ```powershell
  Disable-ScheduledTask -TaskName "DailyBingWallpaper"
  ```

* **Remove the task completely:**
  ```powershell
  Unregister-ScheduledTask -TaskName "DailyBingWallpaper" -Confirm:$false
  ```
