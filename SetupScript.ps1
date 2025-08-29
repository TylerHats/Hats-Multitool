# PC Setup and Config Script - Tyler Hatfield - v1.12

# Core setup Script
if ($SetupScriptRuns -eq 0) {
# Run Time Zone Module
if ($Run_TimeZoneSetting) {
	$TZPath = Join-Path -Path $PSScriptRoot -ChildPath 'TimeZone.ps1'
	. "$TZPath"
	if ($UserExit -eq $true) {User-Exit}
	Write-Host ""
}

# Setup prerequisites and start Windows update module
if ($Run_WindowsUpdates) {
	$Global:WinUpdatesRun = $true
	$WindowsUpdateModPath = Join-Path -Path $PSScriptRoot -ChildPath 'WinUpdateGUI.ps1'
	#Log-Message "Install Cumulative updates for Windows? (These can be very slow) (y/N):" "Prompt"
	#$env:installCumulativeWU = Read-Host
	Log-Message "Launching Windows Update GUI..."
	$ProgressPreference = 'SilentlyContinue'
	Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass", "-File `"$WindowsUpdateModPath`""
	#$child = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass", "-File `"$WindowsUpdateModPath`"" -PassThru
	Write-Host ""
	<#Start-Sleep -Milliseconds 1000
	$hwnd = [ConsoleUtils.NativeMethods]::GetConsoleWindow()
	for ($i = 0; $i -lt 5; $i++) {
		Start-Sleep -Milliseconds 200
		[ConsoleUtils.NativeMethods]::ShowWindow($hwnd, 9) | Out-Null
		[ConsoleUtils.NativeMethods]::SetForegroundWindow($hwnd) | Out-Null
	}#>
}

Show-ConsoleWindow
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

Show-ConsoleWindow
# Run bloat cleanup module
if ($Run_BloatCleanup) {
	$BloatCleanupModPath = Join-Path -Path $PSScriptRoot -ChildPath 'BloatCleanup.ps1'
	. "$BloatCleanupModPath"
	Write-Host ""
}

Hide-ConsoleWindow
# Run program installation module
if ($Run_ProgramInstallation) {
	$ProgramsModPath = Join-Path -Path $PSScriptRoot -ChildPath 'Programs.ps1'
	. "$ProgramsModPath"
	Write-Host ""
}

Show-ConsoleWindow
# Run system management module
if ($Run_SystemManagement) {
	$SystemManagementModPath = Join-Path -Path $PSScriptRoot -ChildPath 'SystemManagement.ps1'
	. "$SystemManagementModPath"
	Write-Host ""
}

# Final setup options
Hide-ConsoleWindow
if ($Run_SettingsandOptions) {
	$FOPath = Join-Path -Path $PSScriptRoot -ChildPath 'FinalOptions.ps1'
	. "$FOPath"
	if ($UserExit -eq $true) {User-Exit}
	Write-Host ""
	<# OLD CODE
	$regPathNumLock = "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard"
	if (Test-Path $regPathNumLock) {
		# Set the InitialKeyboardIndicators value to 2147483650 (Enables numlock by default)
		Set-ItemProperty -Path $regPathNumLock -Name "InitialKeyboardIndicators" -Value "2147483650"
		powercfg /hibernate off *>&1 | Out-File -Append -FilePath $logPath
		Log-Message "Enabled NUM Lock at boot by default." "Success"
		Write-Host ""
	} else {
		Log-Message "Registry path $regPathNumLock does not exist." "Error"
		Write-Host ""
	}
	#>
}

$SetupScriptRuns += 1
$MainMenuSetupButton.Enabled = $false
} else {
	Show-ConsoleWindow
	Log-Message "Something appears to have gone wrong, the setup script has already run. Please try opening the program fresh." "Error"
}