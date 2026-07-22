# Bloat Cleanup Module - Tyler Hatfield - v2.1

# $RemoveBloat = "y"

$global:BGRBaseText = "Starting Bloat Cleanup"
[System.Windows.Forms.Application]::DoEvents()

<#
List of common Windows 11 OEM and Consumer bloatware.
Wildcards (*) are used to catch varying version names.
#>
$bloatApps = @(
    "*TikTok*",
    "*Instagram*",
    "*Facebook*",
    "*Spotify*",
    "*Disney*",
    "*Netflix*",
    "*PrimeVideo*",
    "*McAfee*",
    "*Norton*",
    "*LinkedInForWindows*",
    "*BingNews*",
    "*BingWeather*",
    "*WindowsMaps*",
    "*ZuneVideo*",          # Old Movies & TV
    "*ZuneMusic*",          # Old Groove Music
    "*Cortana*",
    "*MicrosoftSolitaireCollection*",
    "*GetHelp*",
    "*Getstarted*",
    "*YourPhone*",
    "*windowscommunicationsapps*"
)

# $totalBloat = $bloatApps.Count
$removedCount = 0

foreach ($app in $bloatApps) {
    Log-Message "Attempting to remove $app..." "Info"
    $global:BGRBaseText = "Removing $app"
    [System.Windows.Forms.Application]::DoEvents()

    try {
        # 1. Remove from all existing user profiles
        $installed = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
        if ($installed) {
            $installed | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        }

        # 2. Remove the provisioned package so it doesn't install for new users
        $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $app -or $_.PackageName -like $app }
        if ($provisioned) {
            foreach ($prov in $provisioned) {
                Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue | Out-Null
            }
        }

        $removedCount++
    }
    catch {
        Log-Message "Failed to completely remove $app. Error: $_" "Error"
    }
}

Log-Message "Appx Debloat complete. Processed $removedCount package targets." "Success"

$global:BGRBaseText = "Disabling Telemetry & Services"
[System.Windows.Forms.Application]::DoEvents()
Log-Message "Disabling Telemetry and Tracking services..." "Info"
Stop-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name "dmwappushservice" -ErrorAction SilentlyContinue
Set-Service -Name "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue

# Disable Telemetry System-wide in Registry Policy
$telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (-not (Test-Path $telemetryPath)) { New-Item -Path $telemetryPath -Force | Out-Null }
Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

$global:BGRBaseText = "Disabling Bing Search & Ads"
[System.Windows.Forms.Application]::DoEvents()
Log-Message "Applying registry tweaks for Bing Search and Advertising (System-wide & New User Default)..." "Info"

# 1. HKLM System-wide Policies
$hklmExplorerPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $hklmExplorerPath)) { New-Item -Path $hklmExplorerPath -Force | Out-Null }
Set-ItemProperty -Path $hklmExplorerPath -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

$hklmSearchPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
if (-not (Test-Path $hklmSearchPath)) { New-Item -Path $hklmSearchPath -Force | Out-Null }
Set-ItemProperty -Path $hklmSearchPath -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $hklmSearchPath -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $hklmSearchPath -Name "AllowCortana" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# 2. HKCU Current User Settings
if (-not (Test-Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer")) { New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force | Out-Null }
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0 -Force -ErrorAction SilentlyContinue

# 3. Default User Profile Hive (New Users)
$defNtUser = 'C:\Users\Default\NTUSER.DAT'
if (Test-Path $defNtUser) {
    & reg.exe load "HKU\DefUser" "$defNtUser" | Out-Null
    try {
        & reg.exe add "HKU\DefUser\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f | Out-Null
        & reg.exe add "HKU\DefUser\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\DefUser\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\DefUser\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f | Out-Null
        Log-Message "Applied Search & Telemetry policies to Default User profile template." "Success"
    } finally {
        & reg.exe unload "HKU\DefUser" | Out-Null
    }
}

Log-Message "Bloat cleanup complete." "Info"
$global:BGRBaseText = "Hat's Multitool is running"
[System.Windows.Forms.Application]::DoEvents()