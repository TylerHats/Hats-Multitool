# PC Setup and Config Script - Tyler Hatfield - v1.21

# Initialize background reminder UI
$BackgroundReminderPath = Join-Path -Path $PSScriptRoot -ChildPath 'BGReminder.ps1'
$BGRCodeExit = $false
. "$BackgroundReminderPath"
	
# Execute Time Zone module
if ($Run_TimeZone) {
	Log-Message "Starting Time Zone module..." "Info"
	$TZPath = Join-Path -Path $PSScriptRoot -ChildPath 'TimeZone.ps1'
	. "$TZPath"
}

# Execute Local Accounts module
if ($Run_LocalAccounts) {
	Log-Message "Starting Local Accounts module..." "Info"
	$AccountsModPath = Join-Path -Path $PSScriptRoot -ChildPath 'Accounts.ps1'
	. "$AccountsModPath"
}

# Execute System Management module
if ($Run_SystemProperties) {
	Log-Message "Starting System Properties module..." "Info"
	$SystemManagementModPath = Join-Path -Path $PSScriptRoot -ChildPath 'SystemManagement.ps1'
	. "$SystemManagementModPath"
}

# Execute Final Options module
if ($Run_SetupOptions) {
	Log-Message "Starting Setup Options module..." "Info"
	$FOPath = Join-Path -Path $PSScriptRoot -ChildPath 'FinalOptions.ps1'
	. "$FOPath"
}

# Execute Bloat Cleanup module
if ($Run_BloatCleanup) {
	Log-Message "Starting Bloat Cleanup module..." "Info"
	$BloatCleanupModPath = Join-Path -Path $PSScriptRoot -ChildPath 'BloatCleanup.ps1'
	. "$BloatCleanupModPath"
}

# Execute Programs module
if ($Run_Programs) {
	Log-Message "Starting Programs module..." "Info"
	$ProgramsModPath = Join-Path -Path $PSScriptRoot -ChildPath 'Programs.ps1'
	. "$ProgramsModPath"
}

# Terminate background reminder UI
$BGRCodeExit = $true
$BGR.Close()

if ($global:RunUserExitOnComplete -eq $true) {
	Log-Message "Auto-exit enabled by Programs module. Closing and cleaning up..." "Info"
	User-Exit
}