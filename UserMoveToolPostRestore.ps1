# UserMoveToolPostRestore.ps1 v1.0
# Runs once per user login via Active Setup

$ProgData = "C:\ProgramData\UserMoveTool"
$SettingsFile = Join-Path $ProgData "PendingSettings.json"
$Staging = Join-Path $ProgData "StagedFiles"

if (-not (Test-Path $SettingsFile)) { exit }

$Pending = Get-Content $SettingsFile -Raw | ConvertFrom-Json
$CurrentUser = $env:USERNAME

# If this user is in the pending migration list
if ($Pending.PSObject.Properties.Name -contains $CurrentUser) {

    # 1. Robocopy Move (Instantaneous move across same volume)
    $Src = Join-Path $Staging $CurrentUser
    if (Test-Path $Src) {
        Start-Process cmd.exe -ArgumentList "/c robocopy `"$Src`" `"$env:USERPROFILE`" /E /MOVE /IS /IT" -WindowStyle Hidden -Wait
    }

    # 2. Registry Injections
    $uSettings = $Pending.$CurrentUser
    if ($uSettings.AppsUseLightTheme -ne $null) { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -Value $uSettings.AppsUseLightTheme -ErrorAction SilentlyContinue }
    if ($uSettings.TaskbarAl -ne $null) { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarAl -Value $uSettings.TaskbarAl -ErrorAction SilentlyContinue }

    # 3. Network Drives
    if ($uSettings.MappedDrives) {
        foreach ($drive in $uSettings.MappedDrives) {
            Start-Process cmd.exe -ArgumentList "/c net use $($drive.Drive): `"$($drive.Path)`" /persistent:yes" -WindowStyle Hidden
        }
    }

    # 4. Self-Cleanup
    Remove-Item $Src -Recurse -Force -ErrorAction SilentlyContinue
}

# Final Destruct check: If no staging folders are left, destroy everything
$Remaining = Get-ChildItem $Staging -Directory -ErrorAction SilentlyContinue
if (-not $Remaining) {
    Remove-Item $ProgData -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\HatMigration" -Force -ErrorAction SilentlyContinue
}

#NEEDS REWRITTEN FOR GUI ITEMS
