# Windows Update PS Script Module - Tyler Hatfield - v2.0

<# 
.SYNOPSIS
  Install all available Windows Updates using PSWindowsUpdate.
  If the environment variable $env:installCumulativeWU is set to "y" or "yes",
  do not skip any updates that contain "Cumulative" in their title.

.DESCRIPTION
  1. Checks if PSWindowsUpdate module is installed and imports it.
  2. Retrieves a list of available updates.
  3. If $env:installCumulativeWU is "yes" or "y", does not filter out updates with "Cumulative" in the title.
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
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$logPathName = "PCSetupScriptLog.txt"
$logPath = Join-Path $DesktopPath $logPathName
Clear-Host
$Host.UI.RawUI.WindowTitle = "Hat's Windows Update Script"
Write-Host "`n`n`n`n`n`n`n`n`n"

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
if (-not ($env:installCumulativeWU -match '^(y|yes)$')) {
    $excludeCumulative = $true
    Write-Host "Excluding Cumulative updates..."
}

# Filter out cumulative updates if required
if ($excludeCumulative) {
	$updatesToInstall = $allUpdates | Where-Object { $_.Title -notmatch 'Cumulative' }
	$excludedUpdates = @()
    foreach ($update in $allUpdates) {
		if ($update.Title -like "*Cumulative*") { $excludedUpdates += $update.KB }
	}
	foreach ($ExKB in $excludedUpdates) {
		Hide-WindowsUpdate -KBArticleID "$ExKB" -Confirm:$false | Out-Null
	}
}
else {
    $updatesToInstall = $allUpdates
}

if ($updatesToInstall) {
    Write-Host "The following updates will be installed:"
    $updatesToInstall | Format-Table Title, KB, Size -AutoSize
    Write-Host "`nInstalling updates..."
    Install-WindowsUpdate -AcceptAll -IgnoreReboot *> $null
	if ($excludeCumulative) {
		Write-Host "Unhiding Cumulative updates to allow installation at a later date..."
		foreach ($ExKB in $excludedUpdates) {
			Show-WindowsUpdate -KBArticleID "$ExKB" -Confirm:$false -IgnoreReboot *> $null
		}
	}
	$RebootStatus = Get-WURebootStatus -Silent
    if ($RebootStatus) {
        Write-Host "A reboot is required to apply updates, please reboot the system." -ForegroundColor "Yellow"
    }
}
else {
    Write-Host "No updates to install after applying the filter."
}
Read-Host "Press Enter to exit the script"

# Post execution cleanup
$cleanupCheckValue = "ScriptFolderIsReadyForCleanup"
$logContents = Get-Content -Path $logPath
if ($logContents -contains $cleanupCheckValue) {
	[System.Environment]::SetEnvironmentVariable("installCumulativeWU", $null, [System.EnvironmentVariableTarget]::Machine)
	$folderToDelete = "$PSScriptRoot"
	$deletionCommand = "Start-Sleep -Seconds 2; Remove-Item -Path '$folderToDelete' -Recurse -Force"
	Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-Command", $deletionCommand
	exit 0
} else {
	Add-Content -Path $logPath -Value $cleanupCheckValue
	exit 0
}