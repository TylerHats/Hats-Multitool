# Windows Update Module - Tyler Hatfield - v2.6

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
	$dHeight = 50
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
$commonPath = Join-Path -Path $PSScriptRoot -ChildPath 'Common.ps1'
. "$commonPath"
Clear-Host
$Host.UI.RawUI.WindowTitle = "Hat's Windows Update Script"
Write-Host "`n`n`n`n`n`n`n`n"
$origWriteHost = Get-Command Write-Host

# Set Download Mode
try {
	Set-DODownloadMode -DownloadMode 3 -ErrorAction Stop *>&1 | Out-File -Append -FilePath $logPath
} catch {
	Log-Message "Delivery Optimization mode setting failed, continuing with defaults..." "Error"
}

# Make sure PSWindowsUpdate is available. If not, attempt to install it (optional).
try {
    Import-Module PSWindowsUpdate -ErrorAction Stop
} catch {
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
	$clearEnvVarUpdateCommand = [System.Environment]::SetEnvironmentVariable("installCumulativeWU", $null, [System.EnvironmentVariableTarget]::Machine)
	Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-Command $clearEnvVarUpdateCommand" -Verb RunAs -WindowStyle Hidden
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
	function Write-Host { }
    Install-WindowsUpdate -AcceptAll -IgnoreReboot *> $null
	Remove-Item Function:\Write-Host
	if ($excludeCumulative) {
		Write-Host "Unhiding Cumulative updates to allow installation at a later date..."
		function Write-Host { }
		foreach ($ExKB in $excludedUpdates) {
			Show-WindowsUpdate -KBArticleID "$ExKB" -Confirm:$false -IgnoreReboot *> $null
		}
		Remove-Item Function:\Write-Host
	}
	function Write-Host { }
	$RebootStatus = Get-WURebootStatus -Silent
	Remove-Item Function:\Write-Host
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
	User-Exit
} else {
	Add-Content -Path $logPath -Value $cleanupCheckValue
	exit 0
}