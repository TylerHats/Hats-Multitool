# Programs Module - Tyler Hatfield - v1.4

# Install programs based on selections, prepare Windows "Form"
Log-Message "Preparing Software List..."
Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Program Selection List'
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$form.Size = New-Object System.Drawing.Size(400, 500)
$form.StartPosition = 'CenterScreen'
$HMTIconPath = Join-Path -Path $PSScriptRoot -ChildPath "HMTIconSmall.ico"
$HMTIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($HMTIconPath)
$form.Icon = $HMTIcon
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Font = $font

# Dynamic size based on number of programs
$checkboxHeight = 30    # Height of each checkbox
$progressBarHeight = 70 # Height of the progress bar
$buttonHeight = 80      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20           # Padding around the elements

<#
Program list using multiple variable per program in an array:
Name = The Program's display name, should be human readable
WingetID = If the program is to be installed using Winget, this must be filled out
Type = Program type, current options are: Winget, MSOffice
#>
$programs = @(
    @{ Name = 'Acrobat Reader'; WingetID = 'Adobe.Acrobat.Reader.64-bit'; Type = 'Winget' },
	@{ Name = 'Creative Cloud'; WingetID = 'Adobe.CreativeCloud'; Type = 'Winget' },
    @{ Name = 'Google Chrome'; WingetID = 'Google.Chrome'; Type = 'Winget' },
    @{ Name = 'Firefox'; WingetID = 'Mozilla.Firefox'; Type = 'Winget' },
    @{ Name = '7-Zip'; WingetID = '7zip.7zip'; Type = 'Winget' },
    @{ Name = 'Google Drive'; WingetID = 'Google.Drive'; Type = 'Winget' },
    @{ Name = 'Dropbox'; WingetID = 'Dropbox.Dropbox'; Type = 'Winget' },
	@{ Name = 'VLC Media Player'; WingetID = 'VideoLAN.VLC'; Type = 'Winget' },
    @{ Name = 'Zoom'; WingetID = 'Zoom.Zoom'; Type = 'Winget' },
    @{ Name = 'Outlook Classic'; WingetID = ''; Type = 'MSOutlook' },
    @{ Name = 'Microsoft Teams'; WingetID = ''; Type = 'Teams' },
	@{ Name = 'Microsoft Office (64-Bit)'; WingetID = ''; Type = 'MSOffice' }
)

# Adjust form size based on the number of programs
$formHeight = ($programs.Count * $checkboxHeight) + $progressBarHeight + $buttonHeight + ($padding * 2) + $labelHeight
$form.Size = New-Object System.Drawing.Size(400, $formHeight)
$form.StartPosition = 'CenterScreen'

# Prepare Program Checkboxes
$checkboxes = @{ }
$y = 20
$label = New-Object System.Windows.Forms.Label
$label.Text = "Programs:"
$label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$label.Location = New-Object System.Drawing.Point(20, $y)
$label.AutoSize = $true
$form.Controls.Add($label)
$y += $labelHeight
foreach ($program in $programs) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Location = New-Object System.Drawing.Point(20, $y)
    $checkbox.Text = $program.Name
	$checkbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $checkbox.AutoSize = $true
    $form.Controls.Add($checkbox)
    $checkboxes[$program.Name] = $checkbox
    $y += $checkboxHeight
}

$outlookCheckbox = $checkboxes["Outlook Classic"]
$officeCheckbox = $checkboxes["Microsoft Office (64-Bit)"]

# Add an event handler for the Outlook checkbox:
$outlookCheckbox.Add_CheckedChanged({
    if ($outlookCheckbox.Checked) {
        # When Outlook is checked, disable and uncheck Microsoft Office
        $officeCheckbox.Enabled = $false
        $officeCheckbox.Checked = $false
    }
    else {
        # When Outlook is unchecked, re-enable Microsoft Office
        $officeCheckbox.Enabled = $true
    }
})

# Add an event handler for the Microsoft Office checkbox:
$officeCheckbox.Add_CheckedChanged({
    if ($officeCheckbox.Checked) {
        # When Microsoft Office is checked, disable and uncheck Outlook
        $outlookCheckbox.Enabled = $false
        $outlookCheckbox.Checked = $false
    }
    else {
        # When Microsoft Office is unchecked, re-enable Outlook
        $outlookCheckbox.Enabled = $true
    }
})

# Status label
$y += 15
$statuslabel = New-Object System.Windows.Forms.Label
$statuslabel.Text = "Status: Idle"
$statuslabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$statuslabel.Size = New-Object System.Drawing.Size(340, 20)
$statuslabel.Location = New-Object System.Drawing.Point(20, ($y-10))
$statuslabel.AutoSize = $true
$statuslabel.TextAlign = 'TopLeft'
$form.Controls.Add($statuslabel)

# Container panel with border
$y += 20
$trackPanel = New-Object System.Windows.Forms.Panel
$trackPanel.Size        = [System.Drawing.Size]::new(340,22)
$trackPanel.Location    = [System.Drawing.Point]::new(20,$y)
$trackPanel.BorderStyle = 'FixedSingle'
$trackPanel.BackColor   = [System.Drawing.Color]::DarkGray
$form.Controls.Add($trackPanel)

# Fill panel for progress
$fillPanel = New-Object System.Windows.Forms.Panel
$fillPanel.Size      = [System.Drawing.Size]::new(0,19)
$fillPanel.Location  = [System.Drawing.Point]::new(1,1)
$fillPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
$trackPanel.Controls.Add($fillPanel)

# Add OK button
$okButton = New-Object System.Windows.Forms.Button
$y += 40
$okButton.Location = New-Object System.Drawing.Point(150, $y)
$okButton.Size = New-Object System.Drawing.Size(75, 30)
$okButton.Text = "OK"
$okButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$okButton.FlatStyle = 'Flat'
$okButton.FlatAppearance.BorderSize = 1
$form.Controls.Add($okButton)
$form.AcceptButton = $okButton

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

    # Set progress bar maximum
    $progressValueMax = $totalPrograms
    $maxWidth = $trackPanel.ClientSize.Width - 2

    # Install programs and update progress bar
    $progressValue = 0
    foreach ($programName in $selectedPrograms) {
        $program = $programs | Where-Object { $_.Name -eq $programName }
        if ($program.Type -eq "MSOffice") {
			try {
			Log-Message "Installing Microsoft Office (x64)..." "Info"
            $statuslabel.Text = 'Installing: MS Office (x64)...'
            [System.Windows.Forms.Application]::DoEvents()
			$workingDir = Join-Path -Path "$PSScriptRoot" -ChildPath "OfficeODT"
			if (-Not (Test-Path $workingDir)) { New-Item -ItemType Directory -Path $workingDir }
			$odtUrl = "https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_18526-20146.exe"
			$odtExe = "$workingDir\OfficeDeploymentTool.exe"
			if (-Not (Test-Path $odtExe)) {
			    Log-Message "Downloading Office Deployment Tool..." "Info"
			    try {Invoke-WebRequest -Uri $odtUrl -OutFile $odtExe *>&1 | Out-File -Append -FilePath $logPath} catch {Log-Message "ODT download failed, check your internet connection." "Error"}
				Unblock-File -Path $odtExe *>&1 | Out-File -Append -FilePath $logPath
			}
			Log-Message "Extracting Office Deployment Tool..." "Info"
			& $odtExe /extract:$workingDir /quiet
            if ($LASTEXITCODE -ne 0) {
                throw "ODT extraction failed (exit code $LASTEXITCODE)"
            }
			$configXml = @'
<Configuration>
  <Add OfficeClientEdition="64" Channel="Monthly">
    <Product ID="O365BusinessRetail">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Display Level="Basic" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="1"/>
</Configuration>
'@
			$configFile = "$workingDir\officeconfiguration.xml"
			$configXml | Out-File -FilePath $configFile -Encoding ascii
			Start-Process -FilePath "$workingDir\setup.exe" -ArgumentList "/configure `"$configFile`"" -Wait
			Log-Message "Microsoft Office: Installed successfully." "Success"
			 } catch {
				Log-Message "Microsoft Office: Installation failed, please review the log." "Error"
			 }
		} elseif ($program.Type -eq "MSOutlook") {
			try {
			Log-Message "Installing Microsoft Outlook (Classic)..." "Info"
            $statuslabel.Text = 'Installing: Outlook (Classic)...'
            [System.Windows.Forms.Application]::DoEvents()
			$workingDir = Join-Path -Path "$PSScriptRoot" -ChildPath "OfficeODT"
			if (-Not (Test-Path $workingDir)) { New-Item -ItemType Directory -Path $workingDir }
			$odtUrl = "https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_18526-20146.exe"
			$odtExe = "$workingDir\OfficeDeploymentTool.exe"
			if (-Not (Test-Path $odtExe)) {
			    Log-Message "Downloading Office Deployment Tool..." "Info"
			    try {Invoke-WebRequest -Uri $odtUrl -OutFile $odtExe *>&1 | Out-File -Append -FilePath $logPath} catch {Log-Message "ODT download failed, check your internet connection." "Error"}
				Unblock-File -Path $odtExe *>&1 | Out-File -Append -FilePath $logPath
			}
			Log-Message "Extracting Office Deployment Tool..." "Info"
			& $odtExe /extract:$workingDir /quiet
            if ($LASTEXITCODE -ne 0) {
                throw "ODT extraction failed (exit code $LASTEXITCODE)"
            }
			$configXml = @'
<Configuration>
  <Add OfficeClientEdition="64" Channel="Monthly">
    <Product ID="OutlookRetail">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Display Level="Basic" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="1"/>
</Configuration>
'@
			$configFile = "$workingDir\outlookconfiguration.xml"
			$configXml | Out-File -FilePath $configFile -Encoding ascii
			Start-Process -FilePath "$workingDir\setup.exe" -ArgumentList "/configure `"$configFile`"" -Wait
			Log-Message "Microsoft Outlook: Installed successfully." "Success"
			 } catch {
				Log-Message "Microsoft Outlook: Installation failed, please review the log." "Error"
			}
		} elseif ($program.Type -eq "Teams") {
			Log-Message "Installing Microsoft Teams..."
            $statuslabel.Text = 'Installing: Microsoft Teams...'
            [System.Windows.Forms.Application]::DoEvents()
			try {
				#Teams Installation code
				$bootstrapperURL = "https://statics.teams.cdn.office.net/production-teamsprovision/lkg/teamsbootstrapper.exe"
                $workingDir = Join-Path -Path "$PSScriptRoot" -ChildPath "Teams"
                if (-Not (Test-Path $workingDir)) { New-Item -ItemType Directory -Path $workingDir }
				$teamsEXE = "$workingDir\teamsbootstrapper.exe"
				Log-Message "Downloading Teams Bootstrapper..." "Info"
			    try {Invoke-WebRequest -Uri $bootstrapperURL -OutFile $teamsEXE *>&1 | Out-File -Append -FilePath $logPath} catch {Log-Message "Bootstrapper download failed, check your internet connection." "Error"}
				Unblock-File -Path $teamsEXE *>&1 | Out-File -Append -FilePath $logPath
				Start-Process -FilePath "$teamsEXE" -ArgumentList "-p" -Wait
			} catch {
				Log-Message "Microsoft Teams installation failed." "Error"
			}
		} elseif ($program -ne $null) {
			$maxWaitSeconds = 60    # 1 minute
			$waitIntervalSeconds = 20
			$elapsedSeconds = 0
			$WaitInstall = "blank"
			# Loop while msiexec.exe is running
			while (Get-Process -Name msiexec -ErrorAction SilentlyContinue) {
<#				if ($WaitInstall -eq "blank") {
			 	   	Log-Message "Another installation is in progress. Would you like to wait or continue? (c/W):" "Prompt"
					$WaitInstall = Read-Host
				}
				if ($WaitInstall.ToLower() -eq "c" -or $WaitInstall.ToLower() -eq "continue") {
					Log-Message "Ignoring background installation and continuing..." "Info"
					break
				}
				Log-Message "Waiting $waitIntervalSeconds seconds and checking again..." "Info"
			    Start-Sleep -Seconds $waitIntervalSeconds
			    $elapsedSeconds += $waitIntervalSeconds
			    if ($elapsedSeconds -ge $maxWaitSeconds) {
			        Log-Message "Waited for $maxWaitSeconds seconds and the installer still has not cleared. Would you like to kill MSIEXEC.exe? (y/N):" "Prompt"
			        $KillMSIE = Read-Host
					if ($KillMSIE.ToLower() -eq "y" -or $KillMSIE.ToLower() -eq "yes") {
						Log-Message "Killing MSIEXEC.exe and continuing WinGet updates..." "Info"
						try {Get-Process -Name "msiexec" -ErrorAction Stop | Stop-Process -Force -ErrorAction Stop *>&1 | Out-File -Append -FilePath $logPath} catch {Log-Message "Failed to kill process MSIEXEC.exe, continuing..." "Error"}
					} else {
						Log-Message "Ignoring background installation and continuing WinGet program install..." "Info"
					}
					break
 			   } #>
				#Log-Message "Killing MSIEXEC.exe and continuing WinGet installations..." "Info"
				Get-Process -Name "msiexec" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue *>&1 | Out-File -Append -FilePath $logPath
				break
			}
            Log-Message "Installing $($program.Name)..."
            $statuslabel.Text = "Installing: $($program.Name)..."
            [System.Windows.Forms.Application]::DoEvents()
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
					Get-Process -Name "msiexec" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue *>&1 | Out-File -Append -FilePath $logPath

                } else {
                    $message = "$($program.Name): Installation failed with exit code $($process.ExitCode)."
                    Log-Message $message "Error"
                }
            } catch {
                $message = "$($program.Name): Installation failed. Error: $_"
                Log-Message $message "Error"
            }
        }
        $progressValue += 1
        $progressPercent = ($progressValue / $progressValueMax)
        $fillPanel.Width = [int]($maxWidth * $progressPercent)
        # Start-Sleep -Milliseconds 200 # Simulate progress bar movement
    }

    # Close the form once installation is complete
    $form.Close()
})

# Show the GUI
$form.ShowDialog() | Out-null