# Self Update Module - Tyler Hatfield - v2.9

# Define the path to your JSON file in the current directory
$jsonPath = Join-Path -Path $PSScriptRoot -ChildPath "AppManifest.json" # Update filename if needed

# Check if the file exists to avoid errors
if (Test-Path -Path $jsonPath) {
    # Read the raw JSON text and convert it to a PowerShell object
    $configData = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
    
    # Extract the version string
    $Global:currentVersionString = $configData.version
    
    Log-Message "Loaded version: $Global:currentVersionString" "Info"
} else {
    $Global:currentVersionString = $null
    $skipUpdate = 1
    Log-Message "Update check failed: Could not find $jsonPath" "Error"
}

# Prepare Update GUI
$UpdateGUI = New-Object System.Windows.Forms.Form
$UpdateGUI.Text = "Hat's Multitool"
$UpdateGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$UpdateGUI.ClientSize = New-Object System.Drawing.Size(400, 160)
$UpdateGUI.StartPosition = 'CenterScreen'
$UpdateGUI.Icon = $HMTIcon
$UpdateGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$UpdateGUI.MaximizeBox = $false
$UpdateGUI.Font = $font
$UpdateGUI.TopMost = $true
$UpdateGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$UpdateGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
Set-DarkTitleBar -TargetForm $UpdateGUI

# Add descriptive label
$y = 15
$ULabel = New-Object System.Windows.Forms.Label
$ULabel.Text = "Update text:"
$ULabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ULabel.Size = New-Object System.Drawing.Size(340, 50)
$ULabel.Location = New-Object System.Drawing.Point(30, $y)
$ULabel.AutoSize = $false
$ULabel.TextAlign = 'TopCenter'
$UpdateGUI.Controls.Add($ULabel)

# Add Yes button
$y += 55
$UYOkayButton = New-Object System.Windows.Forms.Button
$UYOkayButton.Location = New-Object System.Drawing.Point(95, $y)
$UYOkayButton.Size = New-Object System.Drawing.Size(95, 40)
$UYOkayButton.Text = 'Yes'
$UYOkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$UYOkayButton.FlatStyle = 'Flat'
$UYOkayButton.FlatAppearance.BorderSize = 1
$UpdateGUI.Controls.Add($UYOkayButton)
$UpdateGUI.AcceptButton = $UYOkayButton

# Add No button
$UNOkayButton = New-Object System.Windows.Forms.Button
$UNOkayButton.Location = New-Object System.Drawing.Point(210, $y)
$UNOkayButton.Size = New-Object System.Drawing.Size(95, 40)
$UNOkayButton.Text = 'No'
$UNOkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$UNOkayButton.FlatStyle = 'Flat'
$UNOkayButton.FlatAppearance.BorderSize = 1
$UpdateGUI.Controls.Add($UNOkayButton)
$UpdateGUI.CancelButton = $UNOkayButton

# Define a function to handle the yes button click
$UYOkayButton.Add_Click({
    $UYOkayButton.Enabled = $false
    $script:GUIResponse = "y"
    $UpdateGUI.Close()
})

# Define a function to handle the no button click
$UNOkayButton.Add_Click({
    $UNOkayButton.Enabled = $false
    $script:GUIResponse = "n"
    $UpdateGUI.Close()
})

# Cleanup Function for Updates
function Invoke-SelfUpdateCleanup {
    param([string]$OutPath)
    
    $updateCleanup = @"
    Wait-Process -Id $PID -ErrorAction SilentlyContinue

    # Loop to catch any lingering or child processes running from our folder
    while (`$true) {
        `$lockingProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object { `$_.Path -like "$PSScriptRoot\*" }
        if (-not `$lockingProcs) { break }
        `$lockingProcs | Wait-Process -ErrorAction SilentlyContinue
    }

    Start-Sleep -Seconds 1 
    if (Test-Path -LiteralPath "$PSScriptRoot") {
        Remove-Item -LiteralPath "$PSScriptRoot" -Recurse -Force
    }

    Add-Content -LiteralPath "$logPath" -Value 'Script self cleanup completed during self update'
    Start-Process -FilePath "$OutPath" -WindowStyle Minimized
"@
    
    $encodedUpdate = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($updateCleanup))
    Start-Process -FilePath 'powershell.exe' -ArgumentList "-NoProfile -WindowStyle Hidden -EncodedCommand $encodedUpdate" -WorkingDirectory $env:TEMP
}

# Check program version against remote, update if needed
if ($skipUpdate -ne 1) {
    $shell = New-Object -ComObject Shell.Application
    $downloadsFolder = $shell.Namespace('shell:Downloads').Self.Path
    [version]$currentVersion = $Global:currentVersionString
    $skipUpdate = 0
    Try {
        $remoteRequest = Invoke-WebRequest -Uri "https://hatsthings.com/MultitoolFiles/HatsMultitoolVersion.txt" -UseBasicParsing
    } catch {
        Log-Message "Unable to determine remote version, skipping self update check." "Error"
        Write-Host ""
        $skipUpdate = 1
    }
}

if ($skipUpdate -ne 1) {
    $remoteVersionString = $remoteRequest.Content.Trim()
    [version]$remoteVersion = $remoteVersionString
    if ($currentVersion -eq $remoteVersion) {
        if ($env:hatsUpdated -eq "1") {
            Log-Message "Program updated successfully! (Version $currentVersion)" "Success"
        } else {
            Log-Message "The Hat's Multitool is up to date. (Version $currentVersion)" "Info"
            Write-Host ""
        }
    } elseif ($currentVersion -gt $remoteVersion) {
        $ULabel.Text = "You're running a beta version, downgrade`nto the latest? (v$Global:currentVersionString > v$remoteVersionString)"
        Close-ImageSplash
        $UpdateGUI.ShowDialog() | Out-Null
        
        if ($script:GUIResponse -match 'y|yes') {
            Log-Message "Downloading and relaunching the script... (Current Version: $currentVersion - Remote Version: $remoteVersion)" "Info"
            $sourceURL = "https://github.com/TylerHats/Hats-Multitool/releases/download/v$remoteVersion/Hats-Multitool-v$remoteVersion.exe"
            $outputPath = "$downloadsFolder\Hats-Multitool-v$remoteVersion.exe"
            Try {
                Invoke-WebRequest -Uri $sourceURL -OutFile $outputPath *>&1
            } catch {
                PopupError "Failed to download update, please update manually." "Error"
                $ForceExit = $true
            }
            if (-not $ForceExit) {
                Invoke-SelfUpdateCleanup -OutPath $outputPath
                $ForceExit = $true
            }
        } else {
            Log-Message "Proceed with caution, and if you run into errors please redownload from the web.`n" "Skip"
        }
    } else {
        Log-Message "Updating and relaunching the script... (Current Version: $currentVersion - Remote Version: $remoteVersion)" "Info"
        $sourceURL = "https://github.com/TylerHats/Hats-Multitool/releases/download/v$remoteVersion/Hats-Multitool-v$remoteVersion.exe"
        $outputPath = "$downloadsFolder\Hats-Multitool-v$remoteVersion.exe"
        Try {
            Invoke-WebRequest -Uri $sourceURL -OutFile $outputPath *>&1
        } catch {
            Log-Message "Failed to download update, please update manually." "Error"
            $ForceExit = $true
        }
        if (-not $ForceExit) {
            $env:hatsUpdated = "1"
            Invoke-SelfUpdateCleanup -OutPath $outputPath
            $ForceExit = $true
        }
    }
}