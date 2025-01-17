# PC Setup Script - Tyler Hatfield - v1.13
# Elevation check
$IsElevated = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544'
if (-not $IsElevated) {
    Write-Host "This script requires elevation. Please grant Administrator permissions." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Script setup
try {
	$dWidth = (Get-Host).UI.RawUI.BufferSize.Width
	$dHeight = 40
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
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$logPathName = "PCSetupScriptLog.txt"
$logPath = Join-Path $DesktopPath $logPathName
$WUSPath = Join-Path -Path $PSScriptRoot -ChildPath 'Windows Update Script.ps1'
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath 'Script Functions.ps1'
. "$functionPath"
$serialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber
if ($failedResize -eq 1) {Log-Message "Failed to resize window." "Error"}
if ($failedColor -eq 1) {Log-Message "Failed to change background color." "Error"}

# Set time zone and sync
Log-Message "Setting Time Zone to Eastern Standard Time..."
Set-TimeZone -Name "Eastern Standard Time" | Out-File -Append -FilePath $logPath
if ((Get-Service -Name w32time).Status -ne 'Running') {
    Start-Service -Name w32time | Out-File -Append -FilePath $logPath
}
w32tm /resync | Out-File -Append -FilePath $logPath

# Setup prerequisites and start Windows updates
Log-Message "Starting Windows Updates in the Background..."
Install-PackageProvider -Name NuGet -Force | Out-File -Append -FilePath $logPath
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted | Out-File -Append -FilePath $logPath
Install-Module -Name PSWindowsUpdate -Force | Out-File -Append -FilePath $logPath
Set-ExecutionPolicy Bypass -force | Out-File -Append -FilePath $logPath
Set-DODownloadMode -DownloadMode 3 | Out-File -Append -FilePath $logPath
Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass", "-File `"$WUSPath`"" -WindowStyle Minimized

# Set/Create local admin account
Log-Message "Setup Local Account(s)..."
$RepeatFunction = 1
While ($RepeatFunction -eq 1) {
    Log-Message "Please enter a username or leave blank to skip this section:" "Prompt"
	$AdminUser = Read-Host
	if (-not $AdminUser -eq "") {
		Log-Message "Please enter a password (can be empty):" "Prompt"
		$AdminPass = Read-Host
		$UExists = Get-LocalUser -Name $AdminUser -ErrorAction SilentlyContinue
		if (-not $UExists) {
			Log-Message "The specified user does not exist, create account now? (y/N):" "Prompt"
			$MakeUser = Read-Host
			if ($MakeUser -eq "y" -or $MakeUser -eq "Y") {
				Net User $AdminUser $AdminPass /add | Out-File -Append -FilePath $logPath
			} else {
				Log-Message "Skipping account creation." "Skip"
			}
		} else {
			Log-Message "Update the user's password? (y/N):" "Prompt"
			$UpdateUser = Read-Host
			if ($UpdateUser.ToLower() -eq "y" -or $UpdateUser.ToLower() -eq "yes") {
				Net User $AdminUser $AdminPass | Out-File -Append -FilePath $logPath
			}
		}
		$LocalUserCheck = "$env:COMPUTERNAME\$AdminUser"
		$IsAdmin = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LocalUserCheck }
		if ($UExists -and -not $IsAdmin) {
			Log-Message "The specified user is not a local admin, elevate now? (y/N):" "Prompt"
			$MakeAdmin = Read-Host
			if ($MakeAdmin -eq "y" -or $MakeAdmin -eq "Y") {
				Net Localgroup Administrators $AdminUser /add | Out-File -Append -FilePath $logPath
			} else {
				Log-Message "Skipping account elevation." "Skip"
			}
		} elseif ($UExists -and $IsAdmin) {
			Log-Message "Skipping account elevation, user account is already a local administrator." "Skip"
		}
		Log-Message "Repeat this segment to add, edit or test another user account? (y/N):" "Prompt"
		$RFQ = Read-Host
		if (-not ($RFQ.ToLower() -eq "y" -or $RFQ.ToLower() -eq "yes")) {
			$RepeatFunction = 0
		}
	} else {
		Log-Message "Skipping account management." "Skip"
		$RepeatFunction = 0
	}
}

# Update WinGet and set defaults
Log-Message "Updating WinGet and App Installer..."
Set-WinUserLanguageList -Language en-US -force
$WinGetSource = "https://aka.ms/getwinget"
$tempFolder = $env:TEMP
$WinGetFile = "AppInstallerUpdate.MSIXBundle"
$WinGetDest = Join-Path -Path $tempFolder -ChildPath $WinGetFile
try {
	Invoke-WebRequest -Uri $WinGetSource -Outfile $WinGetDest -ErrorAction Stop | Out-File -Append -FilePath $logPath
} catch {
	try {
		Invoke-WebRequest -Uri $WinGetSource -Outfile $WinGetDest -ErrorAction Stop | Out-File -Append -FilePath $logPath
	} catch {
		Log-Message "Failed to download AppInstaller update package. Skipping..." "Error"
	}
}
try {
	Add-AppxPackage -Path $WinGetDest -ForceApplicationShutdown -ForceUpdateFromAnyVersion | Out-File -Append -FilePath $logPath
} catch {
	Log-Message "Failed to install AppInstaller update. Skipping..." "Error"
}
Winget Source Update --disable-interactivity | Out-File -Append -FilePath $logPath
WinGet Upgrade --id Microsoft.Appinstaller --accept-package-agreements --accept-source-agreements | Out-File -Append -FilePath $logPath
Log-Message "Updating System Packages and Apps (This may take some time)..."
WinGet Upgrade --ALL --accept-package-agreements --accept-source-agreements | Out-File -Append -FilePath $logPath

# Remove commond Windows bloat
Log-Message "Would you like to remove common Windows bloat programs? (y/N):" "Prompt"
$RemoveBloat = Read-Host
if ($RemoveBloat.ToLower() -eq "y" -or $RemoveBloat.ToLower() -eq "yes") {
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*bingfinance*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*bingnews*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*bingsports*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*gethelp*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*getstarted*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*mixedreality*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*people*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*solitaire*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*wallet*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*windowsfeedback*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*windowsmaps*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*xbox*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*zunevideo*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
} else {
	Log-Message "Skipping bloat removal." "Skip"
}

# Install programs based on selections, prepare Windows "Form"
Log-Message "Preparing Software List..."
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Program List'
$form.Size = New-Object System.Drawing.Size(400, 500)
$form.StartPosition = 'CenterScreen'

# Dynamic size based on number of programs
$checkboxHeight = 30    # Height of each checkbox
$progressBarHeight = 70 # Height of the progress bar
$buttonHeight = 80      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20           # Padding around the elements

# Calculate total height based on the number of programs
$programs = @(
    @{ Name = 'Acrobat Reader'; WingetID = 'Adobe.Acrobat.Reader.64-bit' },
    @{ Name = 'Google Chrome'; WingetID = 'Google.Chrome' },
    @{ Name = 'MS Teams'; WingetID = 'Microsoft.Teams' },
    @{ Name = 'Firefox'; WingetID = 'Mozilla.Firefox' },
    @{ Name = '7-Zip'; WingetID = '7zip.7zip' },
    @{ Name = 'Google Drive'; WingetID = 'Google.Drive' },
    @{ Name = 'Dropbox'; WingetID = 'Dropbox.Dropbox' },
    @{ Name = 'Zoom'; WingetID = 'Zoom.Zoom' },
    @{ Name = 'Outlook Classic (In testing)'; WingetID = '9NRX63209R7B' },
    @{ Name = 'Teams (In testing)'; WingetID = 'XP8BT8DW290MPQ'}
)

$closedPrograms = @(
    @{ Name = 'Demo (Do not use)'; Params = '' }
)

# Adjust form size based on the number of programs
$formHeight = ($programs.Count * $checkboxHeight) + ($closedPrograms.Count * $checkboxHeight) + $progressBarHeight + $buttonHeight + $padding + ($labelHeight * 2)
$form.Size = New-Object System.Drawing.Size(400, $formHeight)
$form.StartPosition = 'CenterScreen'

# Prepare WinGet Checkboxes
$checkboxes = @{ }
$y = 20
$label = New-Object System.Windows.Forms.Label
$label.Text = "WinGet Programs:"
$label.Location = New-Object System.Drawing.Point(20, $y)
$label.AutoSize = $true
$form.Controls.Add($label)
$y += $labelHeight
foreach ($program in $programs) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Location = New-Object System.Drawing.Point(20, $y)
    $checkbox.Text = $program.Name
    $checkbox.AutoSize = $true
    $form.Controls.Add($checkbox)
    $checkboxes[$program.Name] = $checkbox
    $y += $checkboxHeight
}

# Prepare Closed Source Checkboxes
$y += 20
$closedCheckboxes = @{ }
$labelClosed = New-Object System.Windows.Forms.Label
$labelClosed.Text = "Closed Source Programs:"
$labelClosed.Location = New-Object System.Drawing.Point(20, $y)
$labelClosed.AutoSize = $true
$form.Controls.Add($labelClosed)
$y += $labelHeight
foreach ($program in $closedPrograms) {
    $closedCheckbox = New-Object System.Windows.Forms.CheckBox
    $closedCheckbox.Location = New-Object System.Drawing.Point(20, $y)
    $closedCheckbox.Text = $program.Name
    $closedCheckbox.AutoSize = $true
    $form.Controls.Add($closedCheckbox)
    $closedCheckboxes[$program.Name] = $closedCheckbox
    $y += $checkboxHeight
}

# Add progress bar to GUI
$progressBar = New-Object System.Windows.Forms.ProgressBar
$y += 10
$progressBar.Location = New-Object System.Drawing.Point(20, $y)
$progressBar.Size = New-Object System.Drawing.Size(340, 20)
$progressBar.Minimum = 0
$form.Controls.Add($progressBar)

# Add OK button
$okButton = New-Object System.Windows.Forms.Button
$y += 50
$okButton.Location = New-Object System.Drawing.Point(150, $y)
$okButton.Size = New-Object System.Drawing.Size(75, 30)
$okButton.Text = "OK"
$form.Controls.Add($okButton)

# Define a function to handle the OK button click
$okButton.Add_Click({
    # Disable OK button to prevent further clicks
    $okButton.Enabled = $false

    # Install selected programs
    $selectedPrograms = $checkboxes.GetEnumerator() | Where-Object { $_.Value.Checked } | ForEach-Object { $_.Key }
    $totalPrograms = $selectedPrograms.Count
    if ($totalPrograms -eq 0) {
        Log-Message "No programs selected for installation." "Skip"
        $form.Close()
        return
    }

    # Set progress bar maximum to match selected programs
    $progressBar.Maximum = $totalPrograms

    # Install programs and update progress bar
    $progressBar.Value = 0
    foreach ($programName in $selectedPrograms) {
        $program = $programs | Where-Object { $_.Name -eq $programName }
        if ($program -ne $null) {
            Log-Message "Installing $($program.Name)..."
            try {
                # Corrected WinGet command execution
                $wingetArgs = @(
                    "install",
                    "-e",  # Exact match flag
                    "--id", $program.WingetID,
                    "--scope", "machine",
                    "--accept-package-agreements",
                    "--accept-source-agreements"
                )

                # Use Start-Process with the correct arguments
                $process = Start-Process -FilePath "winget" -ArgumentList $wingetArgs -PassThru -Wait -WindowStyle Hidden

                # Capture the result
                if ($process.ExitCode -eq 0) {
                    $message = "$($program.Name): Installed successfully."
                    Log-Message $message "Success"
                } else {
                    $message = "$($program.Name): Installation failed with exit code $($process.ExitCode)."
                    Log-Message $message "Error"
                }
            } catch {
                $message = "$($program.Name): Installation failed. Error: $_"
                Log-Message $message "Error"
            }
        }
        $progressBar.Value += 1
        Start-Sleep -Milliseconds 200 # Simulate progress bar movement
    }

    # Close the form once installation is complete
    $form.Close()
})

# Show the GUI
$form.ShowDialog() | Out-null

# Rename PC and join to domain (if needed)
Log-Message "The PC is currently named: $env:computername"
Log-Message "Would you like to change the PC name? (y/N):" "Prompt"
$Rename = Read-Host
if ($Rename -eq "y" -or $Rename -eq "Y") {
    Log-Message "The serial number is: $serialNumber"
    Log-Message "Enter the new PC name and press Enter:" "Prompt"
    $PCName = Read-Host
    Log-Message "Would you like to join this PC to an Active Directory Domain? (y/N):" "Prompt"
	$Domain = Read-Host
	if ($Domain -eq "y" -or $Domain -eq "Y") {
        Log-Message "Enter the domain address and press Enter (Include the suffix, Ex: .local):" "Prompt"
		$DomainName = Read-Host
		$DomainCredential = Get-Credential -Message "Enter credentials with permission to add this device to $DomainName"
		Add-Computer -DomainName $DomainName -NewName $PCName -Credential $DomainCredential | Out-File -Append -FilePath $logPath
	} else {
		Rename-Computer -NewName $PCName -Force | Out-File -Append -FilePath $logPath
	}
} else {
    Log-Message "Would you like to join this PC to an Active Directory Domain? (y/N):" "Prompt"
	$Domain = Read-Host
	if ($Domain -eq "y" -or $Domain -eq "Y") {
        Log-Message "Enter the domain address and press Enter (Include the suffix, Ex: .local):" "Prompt"
		$DomainName = Read-Host
		$DomainCredential = Get-Credential -Message "Enter credentials with permission to add this device to $DomainName`:"
		Add-Computer -DomainName $DomainName -Credential $DomainCredential | Out-File -Append -FilePath $logPath
	}
}
if ($Domain -eq "y" -or $Domain -eq "Y" -or $Rename -eq "y" -or $Rename -eq "Y") {
	Log-Message "PC rename and/or domain join complete." "Success"
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
$folderToDelete = $PSScriptRoot
$deletionCommand = "Start-Sleep -Seconds 2; Remove-Item -Path `"$folderToDelete`" -Recurse -Force"
Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-Command", $deletionCommand
exit 0