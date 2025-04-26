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

# Check program version against remote, update if needed
$currentVersion = "2.0.0"
$skipUpdate = 0
Try {
	$remoteRequest = Invoke-WebRequest -Uri "https://hatsthings.com/HatsScriptsVersion.txt"
} catch {
	Log-Message "Unable to determine remote version, skipping self update check."
	$skipUpdate = 1
}
if ($skipUpdate -ne 1) {
	$remoteVersion = $remoteRequest.Content
	if ($currentVersion -eq $remoteVersion) {
		Log-Message "The script is up to date. (Version $currentVersion)" "Info"
	} else {
		Log-Message "Updating and relaunching the script... (Current Version: $currentVersion - Remote Version: $remoteVersion)" "Info"
		$sourceURL = "https://github.com/TylerHats/Hats-Scripts/releases/latest/download/Hats-Setup-Script-v$remoteVersion.exe"
		$shell = New-Object -ComObject Shell.Application
		$downloadsFolder = $shell.Namespace('shell:Downloads').Self.Path
		$outputPath = "$downloadsFolder\Hats-Setup-Script-v$remoteVersion.exe"
		Try {
			Invoke-WebRequest -Uri $sourceURL -OutFile $outputPath *>&1
		} catch {
			Log-Message "Failed to download update, please update manually." "Error"
			Pause
			Exit
		}
		# Cleanup and exit current script, then launch updated script
		$env:hatsUpdated = "1"
		$folderToDelete = "$PSScriptRoot"
		$deletionCommand = "Start-Sleep -Seconds 2; Remove-Item -Path '$folderToDelete' -Recurse -Force; Add-Content -Path '$logPath' -Value 'Script self cleanup completed during self update'; Start-Process '$outputPath'"
		Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-Command", $deletionCommand
		exit 0
	}
}

# Changelog Display
if ($env:hatsUpdated -eq "1") {
	Write-Host ""
	Log-Message "- Program sections have been broken up into 'modules' for dynamic use.`n- Each 'module' has been updated with minor changes for better interactivity.`n- Certain code has been reworked in preperation for a GUI.`n- The script has been renamed to the 'Hat's Multitool'.`n- This update is expirimental due to the ammount of changes, please report any issues on GitHub at HatsThings.com/go/Hats-Scripts" "Info"
	[System.Environment]::SetEnvironmentVariable("hatsUpdated", $null, [System.EnvironmentVariableTarget]::Machine)
	Write-Host ""
}


# Prompt Hint
Log-Message "Hint: When prompted for input, a capital letter infers a default if the prompt is left blank." "Skip"
Write-Host ""

# Run Time Zone Module
$TZPath = Join-Path -Path $PSScriptRoot -ChildPath 'TimeZone.ps1'
. "$TZPath"
Write-Host ""

# Setup prerequisites and start Windows update module
$WindowsUpdateModPath = Join-Path -Path $PSScriptRoot -ChildPath 'WindowsUpdate.ps1'
Log-Message "Install Cumulative updates for Windows? (These can be very slow) (y/N):" "Prompt"
$env:installCumulativeWU = Read-Host
Log-Message "Starting Windows Updates in the Background..."
$ProgressPreference = 'SilentlyContinue'
Install-PackageProvider -Name NuGet -Force | Out-File -Append -FilePath $logPath
Install-Module -Name PSWindowsUpdate -Force | Out-File -Append -FilePath $logPath
Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass", "-File `"$WindowsUpdateModPath`""
Write-Host ""

# Run accounts module
$AccountsModPath = Join-Path -Path $PSScriptRoot -ChildPath 'Accounts.ps1'
. "$AccountsModPath"
Write-Host ""

# Run WinGet setup module
$WinGetSetupModPath = Join-Path -Path $PSScriptRoot -ChildPath 'WinGetSetup.ps1'
. "$WinGetSetupModPath"
Write-Host ""

# Run bloat cleanup module
$BloatCleanupModPath = Join-Path -Path $PSScriptRoot -ChildPath 'BloatCleanup.ps1'
. "$BloatCleanupModPath"
Write-Host ""

# Run program installation module
$ProgramsModPath = Join-Path -Path $PSScriptRoot -ChildPath 'Programs.ps1'
. "$ProgramsModPath"
Write-Host ""

# Run system management module
$SystemManagementModPath = Join-Path -Path $PSScriptRoot -ChildPath 'SystemManagement.ps1'
. "$SystemManagementModPath"
Write-Host ""

# Final setup options
$regPathNumLock = "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard"
if (Test-Path $regPathNumLock) {
    # Set the InitialKeyboardIndicators value to 2 (Enables numlock by default)
    Set-ItemProperty -Path $regPathNumLock -Name "InitialKeyboardIndicators" -Value "2"
    Log-Message "Enabled NUM Lock at boot by default." "Success"
} else {
    Log-Message "Registry path $regPathNumLock does not exist." "Error"
}

# Reminders/Closing
Log-Message "Script setup is complete!"
Log-Message "Confirm updates have completed in the minimized window and restart to apply updates, PC name change and domain joining if needed."
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