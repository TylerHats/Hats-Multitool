# Self Update Module - Tyler Hatfield - v2.2

#Current version variable
$currentVersionString = "3.3.0"

# Prepare Update GUI
# Prepare form
$UpdateGUI = New-Object System.Windows.Forms.Form
$UpdateGUI.Text = "Hat's Multitool"
$UpdateGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$UpdateGUI.Size = New-Object System.Drawing.Size(400, 160)
$UpdateGUI.StartPosition = 'CenterScreen'
$UpdateGUI.Icon = $HMTIcon
$UpdateGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$UpdateGUI.MaximizeBox = $false
$UpdateGUI.Font = $font
$UpdateGUI.TopMost = $true
$UpdateGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font

# Add descriptive label
$y = 10
$ULabel = New-Object System.Windows.Forms.Label
$ULabel.Text = "Update text:"
$ULabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ULabel.Size = New-Object System.Drawing.Size(340, 50)
$ULabel.Location = New-Object System.Drawing.Point(20, $y)
$ULabel.AutoSize = $false
$ULabel.TextAlign = 'TopCenter'
$UpdateGUI.Controls.Add($ULabel)

# Add yes button
$y += 57
$UYOkayButton = New-Object System.Windows.Forms.Button
$UYOkayButton.Location = New-Object System.Drawing.Point(120, $y)
$UYOkayButton.Size = New-Object System.Drawing.Size(50, 30)
$UYOkayButton.Text = 'Yes'
$UYOkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$UYOkayButton.FlatStyle = 'Flat'
$UYOkayButton.FlatAppearance.BorderSize = 1
$UpdateGUI.Controls.Add($UYOkayButton)
$UpdateGUI.AcceptButton = $UYOkayButton

# Add no button
$UNOkayButton = New-Object System.Windows.Forms.Button
$UNOkayButton.Location = New-Object System.Drawing.Point(215, $y)
$UNOkayButton.Size = New-Object System.Drawing.Size(50, 30)
$UNOkayButton.Text = 'No'
$UNOkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$UNOkayButton.FlatStyle = 'Flat'
$UNOkayButton.FlatAppearance.BorderSize = 1
$UpdateGUI.Controls.Add($UNOkayButton)
$UpdateGUI.AcceptButton = $UNOkayButton

# Define a function to handle the yes button click
$UYOkayButton.Add_Click({
	$UYOkayButton.Enabled = $false
    $GUIResponse = "y"
	$UpdateGUI.Close()
})

# Define a function to handle the no button click
$UNOkayButton.Add_Click({
	$UNOkayButton.Enabled = $false
    $GUIResponse = "n"
	$UpdateGUI.Close()
})

# Check program version against remote, update if needed
$shell = New-Object -ComObject Shell.Application
$downloadsFolder = $shell.Namespace('shell:Downloads').Self.Path
[version]$currentVersion = $currentVersionString
$skipUpdate = 0
Try {
	$remoteRequest = Invoke-WebRequest -Uri "https://hatsthings.com/HatsScriptsVersion.txt" -UseBasicParsing
} catch {
	Log-Message "Unable to determine remote version, skipping self update check."
	Write-Host ""
	$skipUpdate = 1
}
if ($skipUpdate -ne 1) {
	$remoteVersionString = $remoteRequest.Content
	[version]$remoteVersion = $remoteVersionString
	if ($currentVersion -eq $remoteVersion) {
		if ($env:hatsUpdated -eq "1") {
			Log-Message "Program updated successfully! (Version $currentVersion)" "Success"
		} else {
			Log-Message "The Hat's Multitool is up to date. (Version $currentVersion)" "Info"
			Write-Host ""
		}
	} elseif ($currentVersion -gt $remoteVersion) {
		$ULabel.Text = "You're running a beta version, downgrade`nto the latest? (v$currentVersionString > v$remoteVersionString)"
		Close-ImageSplash
		$UpdateGUI.ShowDialog() | Out-Null
		if ($GUIResponse -match 'y|yes') {
			Log-Message "Downloading and relaunching the script... (Current Version: $currentVersion - Remote Version: $remoteVersion)" "Info"
			$sourceURL = "https://github.com/TylerHats/Hats-Multitool/releases/download/v$remoteVersion/Hats-Multitool-v$remoteVersion.exe"
			$outputPath = "$downloadsFolder\Hats-Multitool-v$remoteVersion.exe"
			Add-MpPreference -ExclusionPath $downloadsFolder *>&1 | Out-File -FilePath $logPath -Append
			Try {
				Invoke-WebRequest -Uri $sourceURL -OutFile $outputPath *>&1
			} catch {
				PopupError "Failed to download update, please update manually." "Error"
				$ForceExit = $true
			}
			# Cleanup and exit current script, then launch updated script
			$folderToDelete = "$PSScriptRoot"
			$deletionCommand = "Start-Sleep -Seconds 2; Remove-Item -Path '$folderToDelete' -Recurse -Force; Add-Content -Path '$logPath' -Value 'Script self cleanup completed during self update'; Start-Process '$outputPath' -WindowStyle Minimized"
			Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-Command", $deletionCommand
			$ForceExit = $true
		} else {
			Log-Message "Proceed with caution, and if you run into errors please redownload from the web.`n" "Skip"
		}
	} else {
		Log-Message "Updating and relaunching the script... (Current Version: $currentVersion - Remote Version: $remoteVersion)" "Info"
		$sourceURL = "https://github.com/TylerHats/Hats-Multitool/releases/download/v$remoteVersion/Hats-Multitool-v$remoteVersion.exe"
		$outputPath = "$downloadsFolder\Hats-Multitool-v$remoteVersion.exe"
		Add-MpPreference -ExclusionPath $downloadsFolder | Out-File -FilePath $logPath -Append
		Try {
			Invoke-WebRequest -Uri $sourceURL -OutFile $outputPath *>&1
		} catch {
			Log-Message "Failed to download update, please update manually." "Error"
			Pause
			$ForceExit = $true
		}
		# Cleanup and exit current script, then launch updated script
		$env:hatsUpdated = "1"
		$folderToDelete = "$PSScriptRoot"
		$deletionCommand = "Start-Sleep -Seconds 2; Remove-Item -Path '$folderToDelete' -Recurse -Force; Add-Content -Path '$logPath' -Value 'Script self cleanup completed during self update'; Start-Process '$outputPath' -WindowStyle Minimized"
		Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-Command", $deletionCommand
		$ForceExit = $true
	}
}