# PC Setup and Config Script - Tyler Hatfield - v1.21

# Open background reminder window to fill any gaps between main GUIs
$BackgroundReminderPath = Join-Path -Path $PSScriptRoot -ChildPath 'BGReminder.ps1'
$BGRCodeExit = $false
. "$BackgroundReminderPath"
	
# Run Time Zone Module
if ($Run_TimeZone) {
	$TZPath = Join-Path -Path $PSScriptRoot -ChildPath 'TimeZone.ps1'
	. "$TZPath"
	if ($UserExit -eq $true) {User-Exit}
}

# Run accounts module
if ($Run_LocalAccounts) {
	$AccountsModPath = Join-Path -Path $PSScriptRoot -ChildPath 'Accounts.ps1'
	. "$AccountsModPath"
}

# Run bloat cleanup module
if ($Run_BloatCleanup) {
	$BloatCleanupModPath = Join-Path -Path $PSScriptRoot -ChildPath 'BloatCleanup.ps1'
	. "$BloatCleanupModPath"
}

# Run WinGet setup module ~ Dorment, likely not needed for fresh Win11 installs and has been causing issues
#if ($Run_Programs) {
#	$WinGetSetupModPath = Join-Path -Path $PSScriptRoot -ChildPath 'WinGetSetup.ps1'
#	. "$WinGetSetupModPath"
#}

# Run program installation module
if ($Run_Programs) {
	$ProgramsModPath = Join-Path -Path $PSScriptRoot -ChildPath 'Programs.ps1'
	. "$ProgramsModPath"
}

# Run system management module
if ($Run_SystemProperties) {
	$SystemManagementModPath = Join-Path -Path $PSScriptRoot -ChildPath 'SystemManagement.ps1'
	. "$SystemManagementModPath"
}

# Final setup options
if ($Run_SetupOptions) {
	$FOPath = Join-Path -Path $PSScriptRoot -ChildPath 'FinalOptions.ps1'
	. "$FOPath"
	if ($UserExit -eq $true) {User-Exit}
	
# Close background reminder window
$BGRCodeExit = $true
$BGR.Close()
}