# Background Reminder Module - Tyler Hatfield - v1.3

# Prepare form
$BGR = New-Object System.Windows.Forms.Form
$BGR.Text = "HMT"
$BGR.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$BGR.Size = New-Object System.Drawing.Size(275, 100)
$BGR.StartPosition = 'CenterScreen'
$BGR.Icon = $HMTIcon
$BGR.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$BGR.MaximizeBox = $false
$BGR.Font = $font
$BRG.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$BRG.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
Set-DarkTitleBar -TargetForm $BGR

# Add descriptive label
$y = 15
$BGRlabel = New-Object System.Windows.Forms.Label
$BGRlabel.Text = "Hat's Multitool is running..."
$BGRlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$BGRlabel.Size = New-Object System.Drawing.Size(265, 20)
$BGRlabel.Location = New-Object System.Drawing.Point(0, $y)
$BGRlabel.AutoSize = $false
$BGRlabel.TextAlign = 'MiddleCenter'
$BGR.Controls.Add($BGRlabel)

# Define a function to handle window closing
$BGR.Add_FormClosed({
	param($sender, $e)
	if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and (-not $BGRCodeExit)) {
		Log-Message "User exited, running cleanup."
		User-Exit
	}
})

# Display GUI
$BGR.Show() | Out-Null