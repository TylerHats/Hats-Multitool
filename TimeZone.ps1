# Time Zone Module - Tyler Hatfield - v2.8

# Create TZ GUI
# Prepare form
$TZGUI = New-Object System.Windows.Forms.Form
$stepSuffix = if ($global:HMTSetupTotalSteps -gt 1) { " ($($global:HMTSetupCurrentStepIndex)/$($global:HMTSetupTotalSteps))" } else { "" }
$TZGUI.Text = "Time Zone$stepSuffix"
$TZGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$TZGUI.ClientSize = New-Object System.Drawing.Size(400, 160)
$TZGUI.StartPosition = 'CenterScreen'
$TZGUI.Icon = $HMTIcon
$TZGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$TZGUI.MaximizeBox = $false
$TZGUI.MinimizeBox = $true
$TZGUI.ShowInTaskbar = $true
$TZGUI.Font = $font
$TZGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$TZGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $TZGUI

# Form size variables
$padding = 20

# Add descriptive label
$y = 10
$TZlabel = New-Object System.Windows.Forms.Label
$TZlabel.Text = "Select your time zone:"
$TZlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TZlabel.Size = New-Object System.Drawing.Size(260, 20)
$TZlabel.Location = New-Object System.Drawing.Point($padding, $y)
$TZlabel.AutoSize = $true
$TZlabel.TextAlign = 'TopLeft'
$TZGUI.Controls.Add($TZlabel)

# Add dropdown list
$y += 35
$TZCB = New-Object System.Windows.Forms.ComboBox
$TZCB.Size = New-Object System.Drawing.Size(340, 20)
$TZCB.Location = New-Object System.Drawing.Point($padding, $y)
$TZCB.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$TZCB.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$TZCB.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3a3c43")
$TZCB.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$timeZones = (Get-TimeZone -ListAvailable).Id
$currentTZ = (Get-TimeZone).Id
$TZCB.Items.AddRange($timeZones)
$TZCB.SelectedItem = $currentTZ
$TZGUI.Controls.Add($TZCB)

# Add OK button
$y += 45
$TZOKButton = New-Object System.Windows.Forms.Button
$TZOKButton.Location = New-Object System.Drawing.Point($padding, $y)
$TZOKButton.Size = New-Object System.Drawing.Size(80, 30)
$TZOKButton.Text = "OK"
$TZOKButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
$TZOKButton.FlatStyle = 'Flat'
$TZOKButton.FlatAppearance.BorderSize = 1
$TZGUI.Controls.Add($TZOKButton)
$TZGUI.AcceptButton = $TZOKButton

# Dynamic Sizing Trigger
$TZGUI.Add_Load({
    Invoke-HMTScale $TZGUI
    Set-RoundedControl $TZOKButton
    $p = [int]($padding * $global:HMTScaleFactor)
    
    $TZCB.Width = $TZGUI.ClientSize.Width - ($p * 2)
    $TZOKButton.Left = $TZGUI.ClientSize.Width - $p - $TZOKButton.Width
    $TZGUI.ClientSize = New-Object System.Drawing.Size($TZGUI.ClientSize.Width, ($TZOKButton.Bottom + $p))
})

# OK button event
$TZOKButton.Add_Click({
    # Set selected time zone
    $selectedTZ = $TZCB.SelectedItem.ToString()
    Set-TimeZone -Id $selectedTZ
    Log-Message "Time Zone configured to $selectedTZ." "Success"
    
    # Configure NTP peer servers
    Log-Message "Configuring NTP servers..." "Info"
    $cmdOutput = w32tm /config /manualpeerlist:"pool.ntp.org,0x8 time.windows.com,0x8 time.google.com,0x8 time.cloudflare.com,0x8" /syncfromflags:manual /reliable:YES /update 2>&1
    if ($LASTEXITCODE -ne 0) { Log-Message "w32tm peer configuration failed: $cmdOutput" "Error" }
    
    # Configure Windows Time Service (w32time) startup type to Automatic
    Set-Service -Name w32time -StartupType Automatic
    
    # Ensure Windows Time Service is running
    if ((Get-Service -Name w32time).Status -ne 'Running') {
        try { Start-Service -Name w32time -ErrorAction Stop } catch { Log-Message "Failed to start w32time: $_" "Error" }
    } else {
        # If it is running, restart it to flush stale peer connections
        try { Restart-Service -Name w32time -Force -ErrorAction Stop } catch { Log-Message "Failed to restart w32time: $_" "Error" }
    }
    
    # Force the config to update, give the service 2 seconds to poll NTP servers, then force resync
    $cmdOutput = w32tm /config /update 2>&1
    if ($LASTEXITCODE -ne 0) { Log-Message "w32tm config update failed: $cmdOutput" "Error" }
    Start-Sleep -Seconds 2
    $cmdOutput = w32tm /resync /force 2>&1
    if ($LASTEXITCODE -ne 0) { Log-Message "w32tm resync failed: $cmdOutput" "Error" }
    
    $TZGUI.Close()
})

# Display GUI
Show-HMTSetupWindow $TZGUI | Out-Null