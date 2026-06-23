# Background Reminder Module - Tyler Hatfield - v1.8

# Prepare form
$BGR = New-Object System.Windows.Forms.Form
$BGR.Text = "HMT"
$BGR.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$BGR.ClientSize = New-Object System.Drawing.Size(350, 70)
$BGR.StartPosition = 'CenterScreen'
$BGR.Icon = $HMTIcon
$BGR.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$BGR.MaximizeBox = $false
$BGR.Font = $font
$BGR.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$BGR.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $BGR

# Global variable for dynamic text updating from modules
if (-not $global:BGRBaseText) {
    $global:BGRBaseText = "Hat's Multitool is running"
}

# Add descriptive label
$global:BGRlabel = New-Object System.Windows.Forms.Label
$global:BGRlabel.Text = $global:BGRBaseText
$global:BGRlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$global:BGRlabel.Dock = [System.Windows.Forms.DockStyle]::Fill
$global:BGRlabel.TextAlign = 'MiddleCenter'
$BGR.Controls.Add($global:BGRlabel)

# Define a function to handle window closing
$BGR.Add_FormClosed({
        param($_sender, $e)
        $null = $_sender
        $BGRTimer.Stop()
        if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and (-not $BGRCodeExit)) {
            Log-Message "User exited, running cleanup."
            User-Exit
        }
    })

# Animation Timer Logic
$global:bgrDotCount = 0
$global:bgrTickCount = 0
$BGRTimer = New-Object System.Windows.Forms.Timer
$BGRTimer.Interval = 250 # Updates every 250 milliseconds
$BGRTimer.Add_Tick({
        $global:bgrTickCount++
        if ($global:bgrTickCount -ge 4) {
            $global:bgrTickCount = 0
            $global:bgrDotCount++
            if ($global:bgrDotCount -gt 3) { $global:bgrDotCount = 0 }
        }

        # Multiply the dot character by the count to create the trail
        $dots = "." * $global:bgrDotCount
        if ($null -ne $global:BGRlabel -and -not $global:BGRlabel.IsDisposed) {
            $global:BGRlabel.Text = "$($global:BGRBaseText)$dots"
        }
    })

# Start the timer and Display GUI
$BGRTimer.Start()
$BGR.Show() | Out-Null