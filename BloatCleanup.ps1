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
        # 1. Remove from the current user profile
        Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue

        # 2. Remove the provisioned package so it doesn't install for new users
        $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $app }
        if ($provisioned) {
            Remove-AppxProvisionedPackage -Online -PackageName $provisioned.PackageName -ErrorAction SilentlyContinue | Out-Null
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

$global:BGRBaseText = "Disabling Bing Search & Ads"
[System.Windows.Forms.Application]::DoEvents()
Log-Message "Applying registry tweaks for Bing Search and Advertising..." "Info"
if (-not (Test-Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer")) { New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force | Out-Null }
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0 -Force -ErrorAction SilentlyContinue

Log-Message "Bloat cleanup complete." "Info"
$global:BGRBaseText = "Hat's Multitool is running"
[System.Windows.Forms.Application]::DoEvents()