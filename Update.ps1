# Self Update Module - Tyler Hatfield - v2.10

# Locate local configuration JSON
$jsonPath = Join-Path -Path $PSScriptRoot -ChildPath "AppManifest.json" # Update filename if needed

# Verify configuration existence
if (Test-Path -Path $jsonPath) {
    # Parse JSON configuration
    $configData = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
    
    # Extract the version string
    $Global:currentVersionString = $configData.version
    
    Log-Message "Loaded version: $Global:currentVersionString" "Info"
} else {
    $Global:currentVersionString = $null
    $skipUpdate = 1
    Log-Message "Update check failed: Could not find $jsonPath" "Error"
}

# Initialize Update GUI
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
$ULabel.Size = New-Object System.Drawing.Size($UpdateGUI.ClientSize.Width, 50)
$ULabel.Location = New-Object System.Drawing.Point(0, $y)
$ULabel.AutoSize = $false
$ULabel.TextAlign = 'TopCenter'
$UpdateGUI.Controls.Add($ULabel)

# Add Yes button
$y += 55
$UYOkayButton = New-Object System.Windows.Forms.Button
$UYOkayButton.Size = New-Object System.Drawing.Size(95, 40)
$UYOkayButton.Top = $y
$UYOkayButton.Text = 'Yes'
$UYOkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$UYOkayButton.FlatStyle = 'Flat'
$UYOkayButton.FlatAppearance.BorderSize = 1
$UpdateGUI.Controls.Add($UYOkayButton)
$UpdateGUI.AcceptButton = $UYOkayButton

# Add No button
$UNOkayButton = New-Object System.Windows.Forms.Button
$UNOkayButton.Size = New-Object System.Drawing.Size(95, 40)
$UNOkayButton.Top = $y
$UNOkayButton.Text = 'No'
$UNOkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$UNOkayButton.FlatStyle = 'Flat'
$UNOkayButton.FlatAppearance.BorderSize = 1
$UpdateGUI.Controls.Add($UNOkayButton)
$UpdateGUI.CancelButton = $UNOkayButton

# Calculate dynamic layout post-DPI scaling
$UpdateGUI.Add_Load({
    $ULabel.Width = $UpdateGUI.ClientSize.Width
    $totalButtonWidth = $UYOkayButton.Width + 20 + $UNOkayButton.Width
    $startX = ($UpdateGUI.ClientSize.Width - $totalButtonWidth) / 2
    $UYOkayButton.Left = $startX
    $UNOkayButton.Left = $startX + $UYOkayButton.Width + 20
    $UpdateGUI.ClientSize = [System.Drawing.Size]::new($UpdateGUI.ClientSize.Width, ($UYOkayButton.Bottom + 20))
})

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
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutPath
    )
    
    # Terminate GUI
    [System.Windows.Forms.Application]::OpenForms | ForEach-Object { $_.Hide() }
    [System.Windows.Forms.Application]::DoEvents()

    # Prepare cleanup command
    $copyLogCmd = if ($global:HasErrors) { "Copy-Item -Path '$($global:TempLogPath)' -Destination '$logPath' -Force -ErrorAction SilentlyContinue;" } else { "" }
    $updateCleanup = "Wait-Process -Id $PID -ErrorAction SilentlyContinue; while (`$true) { `$lockingProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object { `$_.Path -like '$PSScriptRoot\*' }; if (-not `$lockingProcs) { break }; `$lockingProcs | Wait-Process -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1 }; Start-Sleep -Seconds 1; if (Test-Path -LiteralPath '$PSScriptRoot') { Remove-Item -LiteralPath '$PSScriptRoot' -Recurse -Force }; $copyLogCmd Remove-Item -LiteralPath '$($global:TempLogPath)' -Force -ErrorAction SilentlyContinue; Start-Process -FilePath '$OutPath' -WindowStyle Minimized"
    
    # Execute async cleanup process
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -NonInteractive -WindowStyle Hidden -Command `"$updateCleanup`""
    $psi.WorkingDirectory = $env:TEMP
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    [System.Diagnostics.Process]::Start($psi) | Out-Null

    # Terminate current process
    [System.Diagnostics.Process]::GetCurrentProcess().Kill()
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
            $env:hatsUpdated = $null
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