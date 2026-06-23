# Bloat Cleanup Module - Tyler Hatfield - v2.0

# $RemoveBloat = "y"

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
    "*ZuneMusic*"          # Old Groove Music
)

# $totalBloat = $bloatApps.Count
$removedCount = 0

foreach ($app in $bloatApps) {
    Log-Message "Attempting to remove $app..." "Info"
    
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