# Core Script - Tyler Hatfield - v1

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
	$failedResize = 1
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
Write-Host ""

# Prompt Hint
Log-Message "Hint: When prompted for input, a capital letter infers a default if the prompt is left blank." "Skip"
Write-Host ""

# Load GUI Configs
$GUIPath = Join-Path -Path $PSScriptRoot -ChildPath 'GUIs.ps1'
. "$GUIPath"

# Display Main Menu GUI
Hide-ConsoleWindow
$MainMenu.ShowDialog() | Out-null

# Display Module Selection GUI
if ($Show_SetupGUI) {
	$ModGUI.ShowDialog() | Out-null
	Show-ConsoleWindow
}

# Run Time Zone Module
if ($Run_TimeZoneSetting) {
	$TZPath = Join-Path -Path $PSScriptRoot -ChildPath 'TimeZone.ps1'
	. "$TZPath"
	Write-Host ""
}

# Setup prerequisites and start Windows update module
if ($Run_WindowsUpdates) {
	$WindowsUpdateModPath = Join-Path -Path $PSScriptRoot -ChildPath 'WindowsUpdate.ps1'
	Log-Message "Install Cumulative updates for Windows? (These can be very slow) (y/N):" "Prompt"
	$env:installCumulativeWU = Read-Host
	Log-Message "Starting Windows Updates in the Background..."
	$ProgressPreference = 'SilentlyContinue'
	Install-PackageProvider -Name NuGet -Force | Out-File -Append -FilePath $logPath
	Install-Module -Name PSWindowsUpdate -Force | Out-File -Append -FilePath $logPath
	Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass", "-File `"$WindowsUpdateModPath`""
	Write-Host ""
}

# Run accounts module
if ($Run_LocalAccountSetup) {
	$AccountsModPath = Join-Path -Path $PSScriptRoot -ChildPath 'Accounts.ps1'
	. "$AccountsModPath"
	Write-Host ""
}

# Run WinGet setup module
if ($Run_ProgramInstallation) {
	$WinGetSetupModPath = Join-Path -Path $PSScriptRoot -ChildPath 'WinGetSetup.ps1'
	. "$WinGetSetupModPath"
	Write-Host ""
}

# Run bloat cleanup module
if ($Run_BloatCleanup) {
	$BloatCleanupModPath = Join-Path -Path $PSScriptRoot -ChildPath 'BloatCleanup.ps1'
	. "$BloatCleanupModPath"
	Write-Host ""
}

# Run program installation module
if ($Run_ProgramInstallation) {
	$ProgramsModPath = Join-Path -Path $PSScriptRoot -ChildPath 'Programs.ps1'
	. "$ProgramsModPath"
	Write-Host ""
}

# Run system management module
if ($Run_SystemManagement) {
	$SystemManagementModPath = Join-Path -Path $PSScriptRoot -ChildPath 'SystemManagement.ps1'
	. "$SystemManagementModPath"
	Write-Host ""
}

# Final setup options
$regPathNumLock = "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard"
if (Test-Path $regPathNumLock) {
    # Set the InitialKeyboardIndicators value to 2 (Enables numlock by default) and disable Fast Startup for registry loading
    Set-ItemProperty -Path $regPathNumLock -Name "InitialKeyboardIndicators" -Value "2"
	powercfg /hibernate off *>&1 | Out-File -Append -FilePath $logPath
    Log-Message "Enabled NUM Lock at boot by default." "Success"
} else {
    Log-Message "Registry path $regPathNumLock does not exist." "Error"
}

# Reminders/Closing
Log-Message "Setup is complete!"
Log-Message "Confirm updates have completed in the minimized window and restart to apply updates, PC name change and domain/EntraID joining if needed."
Log-Message "Press enter to exit the script." "Success"
Read-Host

# Post execution cleanup
$cleanupCheckValue = "ScriptFolderIsReadyForCleanup"
$logContents = Get-Content -Path $logPath
if ($logContents -contains $cleanupCheckValue) {
	[System.Environment]::SetEnvironmentVariable("installCumulativeWU", $null, [System.EnvironmentVariableTarget]::Machine)
	$folderToDelete = "$PSScriptRoot"
	$deletionCommand = "Start-Sleep -Seconds 2; Remove-Item -Path '$folderToDelete' -Recurse -Force; Add-Content -Path '$logPath' -Value 'Script self cleanup completed'"
	Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-Command", $deletionCommand
	exit 0
} else {
	Add-Content -Path $logPath -Value $cleanupCheckValue
	exit 0
}