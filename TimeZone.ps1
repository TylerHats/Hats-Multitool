# Time Zone Module - Tyler Hatfield - v2.0

# Create TZ GUI
# Prepare form
$TZGUI = New-Object System.Windows.Forms.Form
$TZGUI.Text = "Hat's Multitool"
$TZGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$TZGUI.Size = New-Object System.Drawing.Size(200, 500)
$TZGUI.StartPosition = 'CenterScreen'
$TZGUI.Icon = $HMTIcon
$TZGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$TZGUI.MaximizeBox = $false
$TZGUI.Font = $font
$TZGUI.AutoScaleMode = [Windows.Forms.AutoScaleMode]::Dpi

# Form size variables
$checkboxHeight = 30    # Height of each checkbox
$buttonHeight = 80      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Adjust GUI Height
$TZGUIHeight = ($buttonHeight * 1) + $labelHeight + ($padding * 3)
$TZGUI.Size = New-Object System.Drawing.Size(300, $TZGUIHeight)
$TZGUI.StartPosition = 'CenterScreen'

# Add descriptive label
$y = 15
$TZlabel = New-Object System.Windows.Forms.Label
$TZlabel.Text = "Select a Time Zone from the dropdown:"
$TZlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TZlabel.Size = New-Object System.Drawing.Size(260, 20)
$TZlabel.Location = New-Object System.Drawing.Point(10, $y)
$TZlabel.AutoSize = $true
$TZlabel.TextAlign = 'TopLeft'
$TZGUI.Controls.Add($TZlabel)

# Add dropdown list
$y += 30
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(10,$y)
$comboBox.Size = New-Object System.Drawing.Size(260,20)
$comboBox.DropDownStyle = 'DropDownList' # Prevents text input
$comboBox.Items.AddRange(@("Eastern Standard Time", "Central Standard Time", "Mountain Standard Time", "Pacific Standard Time"))
$comboBox.SelectedIndex = 0
$TZGUI.Controls.Add($comboBox)

# Add Okay button
$y += 40
$TZOkayButton = New-Object System.Windows.Forms.Button
$TZOkayButton.Location = New-Object System.Drawing.Point(105, $y)
$TZOkayButton.Size = New-Object System.Drawing.Size(75, 30)
$TZOkayButton.Text = 'OK'
$TZOkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TZOkayButton.FlatStyle = 'Flat'
$TZOkayButton.FlatAppearance.BorderSize = 1
$TZGUI.Controls.Add($TZOkayButton)

# Define a function to handle the Okay button click
$TZOkayButton.Add_Click({
	$TZOkayButton.Enabled = $false
    $TimeZone = $comboBox.SelectedItem
	if ($TimeZone -like "*eastern*") {
		Log-Message "Setting Time Zone to Eastern Standard Time..."
		Set-TimeZone -Name "Eastern Standard Time" | Out-File -Append -FilePath $logPath
	} elseif ($TimeZone -like "*central*") {
		Log-Message "Setting Time Zone to Central Standard Time..."
		Set-TimeZone -Name "Central Standard Time" | Out-File -Append -FilePath $logPath
	} elseif ($TimeZone -like "*mountain*") {
		Log-Message "Setting Time Zone to Mountain Standard Time..."
		Set-TimeZone -Name "Mountain Standard Time" | Out-File -Append -FilePath $logPath
	} elseif ($TimeZone -like "*pacific*") {
		Log-Message "Setting Time Zone to Pacific Standard Time..."
		Set-TimeZone -Name "Pacific Standard Time" | Out-File -Append -FilePath $logPath
	}
	if ((Get-Service -Name w32time).Status -ne 'Running') {
		Start-Service -Name w32time | Out-File -Append -FilePath $logPath
	}
	w32tm /resync | Out-File -Append -FilePath $logPath
	$TZGUI.Close()
})

# Display GUI
$TZGUI.ShowDialog() | Out-Null