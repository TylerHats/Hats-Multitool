# PC Setup and Config Script - Tyler Hatfield - v1.1

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