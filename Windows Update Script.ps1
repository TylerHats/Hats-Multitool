# Windows Update PS Script Module - Tyler Hatfield - v1.3
# Define noUpdates Function
function noUpdatesEnd {
	Read-Host "Press enter to exit the script" 
	exit
}

# Import the PSWindowsUpdate module
Import-Module PSWindowsUpdate

# Function to display progress
function Show-ProgressBar {
    param(
        [string]$status,
        [int]$percent
    )
    
    Write-Progress -PercentComplete $percent -Activity "$status" -Status "$status" -CurrentOperation "Please wait..."
}

# Step 1: Get all available updates
$updates = Get-WindowsUpdate | Where-Object { 
    $_.Title -notlike "*Cumulative*" -and
    $_.Title -notlike "*Feature Update*" -and
    $_.Title -notlike "*Upgrade*"
}
Write-Host "Updates to be installed:"
$updates | ForEach-Object { Write-Host $_.Title }

# Check if there are any updates to install
if (-not $updates -or $updates.Count -eq 0) {
    Write-Host "No updates available."
    noUpdatesEnd
}

# Step 2: Show progress for downloading updates
$totalUpdates = $updates.Count
$counter = 0

foreach ($update in $updates) {
    $counter++
    Show-ProgressBar -status "Downloading updates..." -percent (($counter / $totalUpdates) * 100)
    Start-Sleep -Seconds 1  # Simulate download time for each update (adjust as needed)
}

# Step 3: Proceed with installing updates
Write-Host "`nDownloading completed. Installing updates..."

try {
	Install-WindowsUpdate -Updates $updates -AcceptAll -IgnoreReboot -Verbose
} catch {
	Write-Host "Batch installation failed, attempting indevidual installation"
	$counter = 0
	foreach ($update in $updates) {
		$counter++
		Show-ProgressBar -status "Installing updates..." -percent (($counter / $totalUpdates) * 100)

		# Install each update (no re-scan after installation)
		Install-WindowsUpdate -UpdateID $update.UpdateID -AcceptAll -IgnoreReboot -Verbose

		Start-Sleep -Seconds 2  # Simulate installation time (adjust as needed)
	}
}

# Check if a reboot is required after installation
$rebootRequired = (Get-WindowsUpdate -IsPending).Count -gt 0

if ($rebootRequired) {
    Write-Host "`nA reboot is required to complete the installation of updates."
    # Optional: Uncomment the following line to automatically restart the system.
    # Restart-Computer -Force
}

Write-Host "`nUpdate process completed."