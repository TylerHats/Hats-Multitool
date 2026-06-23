# PC Setup and Config Script - Tyler Hatfield - v1.21

# Initialize background reminder UI
$BackgroundReminderPath = Join-Path -Path $PSScriptRoot -ChildPath 'BGReminder.ps1'
$BGRCodeExit = $false
. "$BackgroundReminderPath"
	
# Execute Time Zone module
if ($Run_TimeZone) {
	$TZPath = Join-Path -Path $PSScriptRoot -ChildPath 'TimeZone.ps1'
	. "$TZPath"
}

# Execute Local Accounts module
if ($Run_LocalAccounts) {
	$AccountsModPath = Join-Path -Path $PSScriptRoot -ChildPath 'Accounts.ps1'
	. "$AccountsModPath"
}

# Execute Bloat Cleanup module
if ($Run_BloatCleanup) {
	$BloatCleanupModPath = Join-Path -Path $PSScriptRoot -ChildPath 'BloatCleanup.ps1'
	. "$BloatCleanupModPath"
}

# Execute Programs module
if ($Run_Programs) {
	$ProgramsModPath = Join-Path -Path $PSScriptRoot -ChildPath 'Programs.ps1'
	. "$ProgramsModPath"
}

# Execute System Management module
if ($Run_SystemProperties) {
	$SystemManagementModPath = Join-Path -Path $PSScriptRoot -ChildPath 'SystemManagement.ps1'
	. "$SystemManagementModPath"
}

# Execute Final Options module
if ($Run_SetupOptions) {
	$FOPath = Join-Path -Path $PSScriptRoot -ChildPath 'FinalOptions.ps1'
	. "$FOPath"
}
# Terminate background reminder UI
$BGRCodeExit = $true
$BGR.Close()