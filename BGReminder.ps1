# Background Reminder Module - Tyler Hatfield - v1.7

# Prepare form
$BGR = New-Object System.Windows.Forms.Form
$BGR.Text = "HMT"
$BGR.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$BGR.ClientSize = New-Object System.Drawing.Size(275, 60)
$BGR.StartPosition = 'CenterScreen'
$BGR.Icon = $HMTIcon
$BGR.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$BGR.MaximizeBox = $false
$BGR.Font = $font
$BGR.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$BGR.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
Set-DarkTitleBar -TargetForm $BGR

# Add descriptive label (Removed the dots from the base string)
$BGRlabel = New-Object System.Windows.Forms.Label
$BGRlabel.Text = "Hat's Multitool is running"
$BGRlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$BGRlabel.Dock = [System.Windows.Forms.DockStyle]::Fill
$BGRlabel.TextAlign = 'MiddleCenter'
$BGR.Controls.Add($BGRlabel)

# Define a function to handle window closing
$BGR.Add_FormClosed({
    param($_sender, $e)
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and (-not $BGRCodeExit)) {
        Log-Message "User exited, running cleanup."
        User-Exit
    }
})

# Animation Timer Logic
$global:bgrDotCount = 0
$BGRTimer = New-Object System.Windows.Forms.Timer
$BGRTimer.Interval = 1000 # Updates every 1000 milliseconds (a second)
$BGRTimer.Add_Tick({
    $global:bgrDotCount++
    if ($global:bgrDotCount -gt 3) { $global:bgrDotCount = 0 }
    
    # Multiply the dot character by the count to create the trail
    $dots = "." * $global:bgrDotCount 
    $BGRlabel.Text = "Hat's Multitool is running$dots"
})

# Start the timer and Display GUI
$BGRTimer.Start()
$BGR.Show() | Out-Null