# WinGet Setup Module - Tyler Hatfield - v2.0

# Prepare form
$WGSGUI = New-Object System.Windows.Forms.Form
$WGSGUI.Text = "Hat's Multitool"
$WGSGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$WGSGUI.Size = New-Object System.Drawing.Size(400, 110)
$WGSGUI.StartPosition = 'CenterScreen'
$WGSGUI.Icon = $HMTIcon
$WGSGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$WGSGUI.MaximizeBox = $false
$WGSGUI.Font = $font
$WGSGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font

# Add descriptive label
$y = 20
$WGSlabel = New-Object System.Windows.Forms.Label
$WGSlabel.Text = "WinGet is preparing for app installs..."
$WGSlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$WGSlabel.Size = New-Object System.Drawing.Size(400, 30)
$WGSlabel.Location = New-Object System.Drawing.Point(0, $y)
$WGSlabel.AutoSize = $false
$WGSlabel.TextAlign = 'TopCenter'
$WGSGUI.Controls.Add($WGSlabel)

# Define a function to handle running functions while shown
$WGSGUI.Add_Shown({
	Log-Message "Updating WinGet and App Installer..."
	Set-WinUserLanguageList -Language en-US -force *>&1 | Out-File -Append -FilePath $logPath
	$ProgressPreference = 'Continue'
	winget source add --name HatsRepoAdd https://cdn.winget.microsoft.com/cache *>&1 | Out-File -Append -FilePath $logPath
	winget Source Update --disable-interactivity *>&1 | Out-File -Append -FilePath $logPath
	if ($LASTEXITCODE -ne 0) { winget Source Update *>&1 | Out-File -Append -FilePath $logPath }
	winget Upgrade --id Microsoft.Appinstaller --accept-package-agreements --accept-source-agreements *>&1 | Out-File -Append -FilePath $logPath
	$WGSGUI.Close()
})

# Display GUI
$WGSGUI.ShowDialog() | Out-Null