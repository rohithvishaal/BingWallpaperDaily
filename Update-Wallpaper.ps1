$ErrorActionPreference = 'Stop'

$today        = (Get-Date).ToString("yyyy-MM-dd")
$targetFolder = Join-Path $env:USERPROFILE "Pictures\wallpapers"
$targetFile   = Join-Path $targetFolder "bing_$today.jpg"
$tempFile     = "$targetFile.part"

if (-not (Test-Path $targetFolder)) {
    New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
}

# 1. Guard: If today's wallpaper already exists, exit immediately
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

try {
    # 3. Fetch today's Bing image base URL
    $api = "https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US"
    $response = Invoke-RestMethod -Uri $api -UseBasicParsing
    $urlBase  = $response.images[0].urlbase

    # 4. Download to a temp file first so a failed/partial download
    #    never trips the once-per-day guard. Try 4K, fall back to 1080p.
    try {
        Invoke-WebRequest -Uri "https://www.bing.com${urlBase}_UHD.jpg" -OutFile $tempFile -UseBasicParsing
    } catch {
        Invoke-WebRequest -Uri "https://www.bing.com${urlBase}_1920x1080.jpg" -OutFile $tempFile -UseBasicParsing
    }
    Move-Item -Path $tempFile -Destination $targetFile -Force
} catch {
    if (Test-Path $tempFile) { Remove-Item $tempFile -Force -ErrorAction SilentlyContinue }
    exit 1
}

# 5. Set wallpaper scaling to "Fill" (these values are REG_SZ strings)
$desktopKey = "HKCU:\Control Panel\Desktop"
Set-ItemProperty -Path $desktopKey -Name WallpaperStyle -Value "10" -Type String
Set-ItemProperty -Path $desktopKey -Name TileWallpaper  -Value "0"  -Type String

# 6. Apply as desktop background
if (-not ([System.Management.Automation.PSTypeName]'Wallpaper').Type) {
    Add-Type -TypeDefinition 'using System.Runtime.InteropServices; public class Wallpaper { [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni); }'
}
[void][Wallpaper]::SystemParametersInfo(0x0014, 0, $targetFile, 0x01 -bor 0x02)

# 7. Trigger Windows Toast Notification
try {
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

    $safePath  = [System.Security.SecurityElement]::Escape($targetFile)
    $xmlString = "<toast><visual><binding template='ToastGeneric'><text>Bing Wallpaper Updated</text><text>Saved to: $safePath</text></binding></visual></toast>"
    $xmlDoc = New-Object Windows.Data.Xml.Dom.XmlDocument
    $xmlDoc.LoadXml($xmlString)
    $toast = [Windows.UI.Notifications.ToastNotification]::new($xmlDoc)
    $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
} catch {
    # Suppress if notifications are disabled in Windows Settings
}
