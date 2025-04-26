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
	Log-Message "- Program sections have been broken up into 'modules' for dynamic use.`n- Each 'module' has been updated with minor changes for better interactivity.`n- Certain code has been reworked in preparation for a GUI.`n- The script has been renamed to the 'Hat's Multitool'.`n- This update is experimental due to the amount of changes, please report any issues on GitHub at HatsThings.com/go/Hats-Scripts" "Info"
	[System.Environment]::SetEnvironmentVariable("hatsUpdated", $null, [System.EnvironmentVariableTarget]::Machine)
	Write-Host ""
}

# Prompt Hint
Log-Message "Hint: When prompted for input, a capital letter infers a default if the prompt is left blank." "Skip"
Write-Host ""

# GUI For Module Selection
# Prepare form
Log-Message "Preparing Module List..." "Info"
Add-Type -AssemblyName System.Windows.Forms
$ModGUI = New-Object System.Windows.Forms.Form
$ModGUI.Text = 'Module Selection List'
$ModGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$ModGUI.Size = New-Object System.Drawing.Size(400, 500)
$ModGUI.StartPosition = 'CenterScreen'

# Form size variables
$checkboxHeight = 30    # Height of each checkbox
$buttonHeight = 80      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Module List Array
$modules = @(
    @{ Name = 'Time Zone Setting' },
	@{ Name = 'Windows Updates' },
    @{ Name = 'Local Account Setup' },
    @{ Name = 'Bloat Cleanup' },
    @{ Name = 'Program Installation' },
    @{ Name = 'System Management' }
)

# Adjust GUI Height
$ModGUIHeight = ($modules.Count * $checkboxHeight) + $buttonHeight + $padding + $labelHeight
$ModGUI.Size = New-Object System.Drawing.Size(400, $ModGUIHeight)
$ModGUI.StartPosition = 'CenterScreen'

# Prepare Module Checkboxes
$ModGUIcheckboxes = @{ }
$y = 20
$ModGUIlabel = New-Object System.Windows.Forms.Label
$ModGUIlabel.Text = "Modules:"
$ModGUIlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModGUIlabel.Location = New-Object System.Drawing.Point(20, $y)
$ModGUIlabel.AutoSize = $true
$ModGUI.Controls.Add($ModGUIlabel)
$y += $labelHeight
foreach ($module in $modules) {
    $ModGUIcheckbox = New-Object System.Windows.Forms.CheckBox
    $ModGUIcheckbox.Location = New-Object System.Drawing.Point(20, $y)
    $ModGUIcheckbox.Text = $module.Name
	$ModGUIcheckbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $ModGUIcheckbox.AutoSize = $true
    $ModGUI.Controls.Add($ModGUIcheckbox)
    $ModGUIcheckboxes[$module.Name] = $ModGUIcheckbox
    $y += $checkboxHeight
}

# Add OK button
$ModGUIokButton = New-Object System.Windows.Forms.Button
$y += 50
$ModGUIokButton.Location = New-Object System.Drawing.Point( (400 - 75)/2, $y)
$ModGUIokButton.Size = New-Object System.Drawing.Size(75, 30)
$ModGUIokButton.Text = "OK"
$ModGUIokButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModGUI.Controls.Add($ModGUIokButton)

# Define a function to handle the OK button click
$ModGUIokButton.Add_Click({
    # Disable OK button to prevent further clicks
    $ModGUIokButton.Enabled = $false

    # Set module enablement variables
    $selectedModules = $ModGUIcheckboxes.GetEnumerator() | Where-Object { $_.Value.Checked } | ForEach-Object { $_.Key }
    $totalModules = $selectedModules.Count
    if ($totalModules -eq 0) {
        Log-Message "No modules selected to run." "Skip"
        $ModGUI.Close()
        return
    }
    foreach ($moduleName in $selectedModules) {
		Set-Variable -Name ("Run_" + ($moduleName -replace '\s','')) -Value $true -Scope Global
    }
    # Close the form once installation is complete
    $ModGUI.Close()
})

# Show the GUI
$ModGUI.ShowDialog() | Out-null

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