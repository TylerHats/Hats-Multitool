# Time Zone Module - Tyler Hatfield - v2.7

# Create TZ GUI
# Prepare form
$TZGUI = New-Object System.Windows.Forms.Form
$TZGUI.Text = "Hat's Multitool"
$TZGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$TZGUI.ClientSize = New-Object System.Drawing.Size(400, 160)
$TZGUI.StartPosition = 'CenterScreen'
$TZGUI.Icon = $HMTIcon
$TZGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$TZGUI.MaximizeBox = $false
$TZGUI.Font = $font
$TZGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$TZGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
Set-DarkTitleBar -TargetForm $TZGUI

# Form size variables
$padding = 20

# Add descriptive label
$y = 15
$TZlabel = New-Object System.Windows.Forms.Label
$TZlabel.Text = "Select a Time Zone from the dropdown:"
$TZlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TZlabel.Location = New-Object System.Drawing.Point($padding, $y)
$TZlabel.AutoSize = $true
$TZlabel.TextAlign = 'TopLeft'
$TZGUI.Controls.Add($TZlabel)

# Add dropdown list
$y += 35
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point($padding, $y)
$comboBox.DropDownStyle = 'DropDownList' # Prevents text input
$comboBox.Items.AddRange(@("Eastern Standard Time", "Central Standard Time", "Mountain Standard Time", "Pacific Standard Time"))
$comboBox.SelectedIndex = 0
$TZGUI.Controls.Add($comboBox)

# Add Okay button
$y += 50
$TZOkayButton = New-Object System.Windows.Forms.Button
$TZOkayButton.Size = New-Object System.Drawing.Size(95, 40)
$TZOkayButton.Top = $y
$TZOkayButton.Text = 'OK'
$TZOkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TZOkayButton.FlatStyle = 'Flat'
$TZOkayButton.FlatAppearance.BorderSize = 1
$TZGUI.Controls.Add($TZOkayButton)
$TZGUI.AcceptButton = $TZOkayButton

# Fix Scaling and Layout Dynamically
$TZGUI.Add_Load({
    # Stretch the ComboBox to fill the scaled window width (minus padding on both sides)
    $comboBox.Width = $TZGUI.ClientSize.Width - ($padding * 2)
    
    # Center the OK button
    $TZOkayButton.Left = ($TZGUI.ClientSize.Width - $TZOkayButton.Width) / 2

    # Wrap the window height to the bottom of the OK button with padding
    $TZGUI.ClientSize = [System.Drawing.Size]::new($TZGUI.ClientSize.Width, ($TZOkayButton.Bottom + $padding))
})

# Define a function to handle the Okay button click
$TZOkayButton.Add_Click({
    $TZOkayButton.Enabled = $false
    $TimeZone = $comboBox.SelectedItem
    
    if ($TimeZone -like "*eastern*") {
        Log-Message "Setting Time Zone to Eastern Standard Time..."
        try { Set-TimeZone -Name "Eastern Standard Time" -ErrorAction Stop } catch { Log-Message "Failed to set Time Zone: $_" "Error" }
    } elseif ($TimeZone -like "*central*") {
        Log-Message "Setting Time Zone to Central Standard Time..."
        try { Set-TimeZone -Name "Central Standard Time" -ErrorAction Stop } catch { Log-Message "Failed to set Time Zone: $_" "Error" }
    } elseif ($TimeZone -like "*mountain*") {
        Log-Message "Setting Time Zone to Mountain Standard Time..."
        try { Set-TimeZone -Name "Mountain Standard Time" -ErrorAction Stop } catch { Log-Message "Failed to set Time Zone: $_" "Error" }
    } elseif ($TimeZone -like "*pacific*") {
        Log-Message "Setting Time Zone to Pacific Standard Time..."
        try { Set-TimeZone -Name "Pacific Standard Time" -ErrorAction Stop } catch { Log-Message "Failed to set Time Zone: $_" "Error" }
    }
    
    Log-Message "Syncing Windows Time Service..." "Info"
    
    # Robust Time Sync Logic
    Set-Service -Name w32time -StartupType Automatic -ErrorAction SilentlyContinue
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
$TZGUI.ShowDialog() | Out-Null