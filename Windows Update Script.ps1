# Windows Update PS Script Module - Tyler Hatfield - v2.0

<# 
.SYNOPSIS
  Install all available Windows Updates using PSWindowsUpdate.
  If the environment variable $env:installCumulativeWU is set to "y" or "yes",
  skip any updates that contain "Cumulative" in their title.

.DESCRIPTION
  1. Checks if PSWindowsUpdate module is installed and imports it.
  2. Retrieves a list of available updates.
  3. If $env:installCumulativeWU is "y" or "yes", filters out updates with "Cumulative" in the title.
  4. Installs remaining updates.
  5. Optional: prompts for or forces a reboot if required (commented out below).

#>

# Script Setup
$failedResize = 0
$failedColor = 0
try {
	$dWidth = (Get-Host).UI.RawUI.BufferSize.Width
	$dHeight = 40
	$rawUI = $Host.UI.RawUI
	$newSize = New-Object System.Management.Automation.Host.Size ($dWidth, $dHeight)
	$rawUI.WindowSize = $newSize
} catch {
	$failedResize = 1
}
try {
	$host.UI.RawUI.BackgroundColor = "Black"
} catch {
	$failedColor = 1
}
Clear-Host
$Host.UI.RawUI.WindowTitle = "Hat's Windows Update Script"

# Make sure PSWindowsUpdate is available. If not, attempt to install it (optional).
try {
    Import-Module PSWindowsUpdate -ErrorAction Stop
}
catch {
    Write-Host "PSWindowsUpdate module not found. Installing now..."
    Install-Module -Name PSWindowsUpdate -Scope CurrentUser -Force
    Import-Module PSWindowsUpdate
}

Write-Host "Checking for available Windows updates..."

# Get all available updates
$allUpdates = Get-WindowsUpdate -AcceptAll -Verbose:$false -IgnoreReboot

# Determine if we should exclude updates that contain "Cumulative"
$excludeCumulative = $false
if ($env:installCumulativeWU -match '^(y|yes)$') {
    $excludeCumulative = $true
    Write-Host "Excluding Cumulative updates..."
}

# Filter out cumulative updates if required
if ($excludeCumulative) {
    $updatesToInstall = $allUpdates | Where-Object { $_.Title -notmatch 'Cumulative' }
}
else {
    $updatesToInstall = $allUpdates
}

if ($updatesToInstall) {
    Write-Host "The following updates will be installed:"
    $updatesToInstall | Format-Table Title, KB, Size -AutoSize
    Write-Host "`nInstalling updates..."

    # Install the selected updates
    # -AcceptAll automatically accepts the EULA if necessary
    # -AutoReboot will automatically reboot if required
    $updatesToInstall | Install-WindowsUpdate -AcceptAll -IgnoreReboot -Verbose

    # If you prefer to confirm or handle the reboot manually, you could remove -AutoReboot 
    # and check for a pending reboot here:
    # Install-WindowsUpdate -Updates $updatesToInstall -AcceptAll -IgnoreReboot
    if (Get-WURebootStatus) {
        Write-Host "A reboot is required to apply updates, please reboot the system."
    }
}
else {
    Write-Host "No updates to install after applying the filter."
}
Read-Host "Press Enter to exit the script"