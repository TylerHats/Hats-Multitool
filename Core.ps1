# Core Script - Tyler Hatfield - v1.3

# Elevation check
$IsElevated = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544'
if (-not $IsElevated) {
    Write-Host "This script requires elevation. Please grant Administrator permissions." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Script setup
$failedResize = 0
$failedColor = 0
try {
	$dWidth = (Get-Host).UI.RawUI.BufferSize.Width
	$dHeight = 50
	$rawUI = $Host.UI.RawUI
	$newSize = New-Object System.Management.Automation.Host.Size ($dWidth, $dHeight)
	$rawUI.WindowSize = $newSize
} catch {
	try {
		$dWidth = (Get-Host).UI.RawUI.BufferSize.Width
		$dHeight = 35
		$rawUI = $Host.UI.RawUI
		$newSize = New-Object System.Management.Automation.Host.Size ($dWidth, $dHeight)
		$rawUI.WindowSize = $newSize
	} catch {
		$failedResize = 1
	}
}
try {
	$host.UI.RawUI.BackgroundColor = "Black"
} catch {
	$failedColor = 1
}
Clear-Host
$Host.UI.RawUI.WindowTitle = "Hat's Multitool"
$commonPath = Join-Path -Path $PSScriptRoot -ChildPath 'Common.ps1'
. "$commonPath"
if ($failedResize -eq 1) {Log-Message "Failed to resize window." "Error"}
if ($failedColor -eq 1) {Log-Message "Failed to change background color." "Error"}

# Run Self Update Module
$UpdateModPath = Join-Path -Path $PSScriptRoot -ChildPath 'Update.ps1'
. "$UpdateModPath"
if ($ForceExit -eq $true) {exit 0}

# Prompt Hint
Log-Message "Hint: When prompted for input, a capital letter infers a default if the prompt is left blank." "Skip"
Write-Host ""

# Load GUI Configs
$GUIPath = Join-Path -Path $PSScriptRoot -ChildPath 'GUIs.ps1'
. "$GUIPath"
Write-Host ""

# Display Main Menu GUI
Hide-ConsoleWindow | Out-Null
$MainMenu.ShowDialog() | Out-null
if ($UserExit -eq $true) {User-Exit}

# Run PC Setup/Config GUI and Script
if ($Show_SetupGUI) {
	$ModGUI.ShowDialog() | Out-null
	if ($UserExit -eq $true) {User-Exit}
	Show-ConsoleWindow | Out-Null
	$SetupScriptModPath = Join-Path -Path $PSScriptRoot -ChildPath 'SetupScript.ps1'
	. "$SetupScriptModPath"
}

# Run Tools option
#WIP

# Run Troubleshooting option
#WIP

# Run Account option
#WIP

# Failsafe for no selected options
if ($Show_SetupGUI -ne $true) {
	Show-ConsoleWindow | Out-Null
	Log-Message "No options were selected in the Main Menu before it exited, skipping to end." "Error"
}

# Reminders/Closing
Log-Message "The multitool run has completed!"
Log-Message "Verify no other windows are still working on background tasks after closing, then reboot if needed to complete setup, updates, etc."
Write-Host ""
Log-Message "Press enter to exit the core script and run self-cleanup." "Success"
Read-Host

# Post execution cleanup
$cleanupCheckValue = "ScriptFolderIsReadyForCleanup"
$logContents = Get-Content -Path $logPath
if ($logContents -contains $cleanupCheckValue -or $WinUpdatesRun -ne $true) {
	User-Exit
} else {
	Add-Content -Path $logPath -Value $cleanupCheckValue
	exit 0
}