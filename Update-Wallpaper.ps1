$today        = (Get-Date).ToString("yyyy-MM-dd")
$targetFolder = Join-Path $env:USERPROFILE "Pictures\wallpapers"
$targetFile   = Join-Path $targetFolder "bing_$today.jpg"

if (-not (Test-Path $targetFolder)) {
    New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
}

# 1. Guard: If today's wallpaper already exists, ignore and exit immediately
if (Test-Path $targetFile) {
    exit 0
}

# 2. Wait up to 30 seconds for an active internet connection on boot
$online = $false
for ($i = 0; $i -lt 6; $i++) {
    try {
        $null = [System.Net.Dns]::GetHostEntry("www.bing.com")
        $online = $true
        break
    } catch {
        Start-Sleep -Seconds 5
    }
}

if (-not $online) { exit 1 }

# 3. Fetch today's official Bing UHD (4K - 3840x2160) wallpaper URL
$api = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"
$response = Invoke-RestMethod -Uri $api
$imgUrl = "https://www.bing.com" + $response.images[0].urlbase + "_UHD.jpg"

# 4. Download wallpaper
Invoke-WebRequest -Uri $imgUrl -OutFile $targetFile

# 5. Set wallpaper scaling to "Fill" (WallpaperStyle = 10, TileWallpaper = 0)
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value 10
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value 0

# 6. Apply as desktop background
if (-not ([System.Management.Automation.PSTypeName]'Wallpaper').Type) {
    Add-Type -TypeDefinition 'using System.Runtime.InteropServices; public class Wallpaper { [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni); }'
}
[Wallpaper]::SystemParametersInfo(0x0014, 0, $targetFile, 0x01 -bor 0x02)

# 7. Trigger Windows Toast Notification
try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

    $xmlString = "<toast><visual><binding template='ToastGeneric'><text>Bing Wallpaper Updated</text><text>Saved to: $targetFile</text></binding></visual></toast>"
    $xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xmlDoc.LoadXml($xmlString)
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xmlDoc)
    $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
} catch {
    # Suppress if notifications are disabled in Windows Settings
}
