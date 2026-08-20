# GUI Main Menu & About - Tyler Hatfield - v2.20

# Main Menu GUI ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Prepare form
$MainMenu = New-Object System.Windows.Forms.Form
$MainMenu.Text = "Hat's Multitool"
$MainMenu.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$MainMenu.ClientSize = New-Object System.Drawing.Size(320, 360)
$MainMenu.StartPosition = 'CenterScreen'
$MainMenu.Icon = $HMTIcon
$MainMenu.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$MainMenu.MaximizeBox = $false
$MainMenu.MinimizeBox = $true
$MainMenu.Font = $font
$MainMenu.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$MainMenu.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $MainMenu

# Pull current version number
$jsonPath = Join-Path -Path $PSScriptRoot -ChildPath "AppManifest.json"
$CurVerAbout = "X.X.X"
if (Test-Path -Path $jsonPath) {
    try {
        $configData = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
        $CurVerAbout = $configData.version
    } catch {}
}

# Tasteful Header Section
$HeaderPanel = New-Object System.Windows.Forms.Panel
$HeaderPanel.Location = New-Object System.Drawing.Point(0, 0)
$HeaderPanel.Size = New-Object System.Drawing.Size(320, 90)
$HeaderPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
$MainMenu.Controls.Add($HeaderPanel)

$HeaderIconBox = New-Object System.Windows.Forms.PictureBox
$HeaderIconBox.Size = New-Object System.Drawing.Size(46, 46)
$HeaderIconBox.Location = New-Object System.Drawing.Point(20, 22)
$HeaderIconBox.SizeMode = 'StretchImage'
$PngIconPath = Join-Path -Path $PSScriptRoot -ChildPath "HMTIcon.png"
if (Test-Path $PngIconPath) {
    $HeaderIconBox.Image = [System.Drawing.Image]::FromFile($PngIconPath)
} elseif ($HMTIcon) {
    $HeaderIconBox.Image = $HMTIcon.ToBitmap()
}
$HeaderPanel.Controls.Add($HeaderIconBox)

$HeaderTitle = New-Object System.Windows.Forms.Label
$HeaderTitle.Text = "Hat's Multitool"
$HeaderTitle.Font = Get-HMTFont $font.FontFamily 16 ([System.Drawing.FontStyle]::Bold)
$HeaderTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$HeaderTitle.Location = New-Object System.Drawing.Point(74, 22)
$HeaderTitle.Size = New-Object System.Drawing.Size(235, 24)
$HeaderPanel.Controls.Add($HeaderTitle)

$HeaderSubtitle = New-Object System.Windows.Forms.Label
$HeaderSubtitle.Text = "v$CurVerAbout | System Setup & Utilities"
$HeaderSubtitle.UseMnemonic = $false
$HeaderSubtitle.Font = Get-HMTFont $font.FontFamily 11
$HeaderSubtitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
$HeaderSubtitle.Location = New-Object System.Drawing.Point(74, 48)
$HeaderSubtitle.Size = New-Object System.Drawing.Size(235, 20)
$HeaderPanel.Controls.Add($HeaderSubtitle)

# Add Setup button
$y = 110
$MainMenuSetupButton = New-Object System.Windows.Forms.Button
$MainMenuSetupButton.Location = New-Object System.Drawing.Point(40, $y)
$MainMenuSetupButton.Size = New-Object System.Drawing.Size(240, 42)
$MainMenuSetupButton.Text = 'PC Setup and Config'
$MainMenuSetupButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuSetupButton.FlatStyle = 'Flat'
$MainMenuSetupButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuSetupButton)

# Add Unified Tools & Troubleshooting button
$y += 58
$MainMenuToolsButton = New-Object System.Windows.Forms.Button
$MainMenuToolsButton.Location = New-Object System.Drawing.Point(40, $y)
$MainMenuToolsButton.Size = New-Object System.Drawing.Size(240, 42)
$MainMenuToolsButton.Text = 'Tools & Troubleshooting'
$MainMenuToolsButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuToolsButton.FlatStyle = 'Flat'
$MainMenuToolsButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuToolsButton)

# About button & Exit button row
$y += 58
$MainMenuAboutButton = New-Object System.Windows.Forms.Button
$MainMenuAboutButton.Location = New-Object System.Drawing.Point(40, $y)
$MainMenuAboutButton.Size = New-Object System.Drawing.Size(115, 42)
$MainMenuAboutButton.Text = 'About'
$MainMenuAboutButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuAboutButton.FlatStyle = 'Flat'
$MainMenuAboutButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuAboutButton)

$MainMenuExitButton = New-Object System.Windows.Forms.Button
$MainMenuExitButton.Location = New-Object System.Drawing.Point(165, $y)
$MainMenuExitButton.Size = New-Object System.Drawing.Size(115, 42)
$MainMenuExitButton.Text = 'Exit'
$MainMenuExitButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuExitButton.FlatStyle = 'Flat'
$MainMenuExitButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuExitButton)

$MainMenu.Add_Shown({
    $this.TopMost = $true 
    [HMT.NativeMethods]::SetForegroundWindow($this.Handle) | Out-Null
    $this.Activate()
    $this.BringToFront()
    $this.TopMost = $false 
})

$Global:NextAction = 'Main'

$MainMenuSetupButton.Add_Click({
    foreach ($cb in $ModGUIcheckboxes.Values) {
        $cb.Checked = $false
    }
    $Global:NextAction = 'Setup'
    $MainMenu.DialogResult = [System.Windows.Forms.DialogResult]::OK
})

$MainMenuToolsButton.Add_Click({
    $Global:NextAction = 'Tools'
    $MainMenu.DialogResult = [System.Windows.Forms.DialogResult]::OK
})

$MainMenuAboutButton.Add_Click({
    $Global:NextAction = 'About'
    $MainMenu.DialogResult = [System.Windows.Forms.DialogResult]::OK
})

$MainMenuExitButton.Add_Click({
    $Global:NextAction = 'Exit'
    $MainMenu.Close()
})

$MainMenu.Add_Load({
    Invoke-HMTScale $MainMenu
    Set-RoundedControl $MainMenuSetupButton
    Set-RoundedControl $MainMenuToolsButton
    Set-RoundedControl $MainMenuAboutButton
    Set-RoundedControl $MainMenuExitButton
    
    $w = [int](320 * $global:HMTScaleFactor)
    $p = [int](25 * $global:HMTScaleFactor)
    $HeaderPanel.Width = $w
    
    $iconW = $HeaderIconBox.Width
    $gap = [int](10 * $global:HMTScaleFactor)
    $textW = [Math]::Max($HeaderTitle.PreferredWidth, $HeaderSubtitle.PreferredWidth)
    $totalHeaderW = $iconW + $gap + $textW
    $startX = [int](($w - $totalHeaderW) / 2)
    if ($startX -lt [int](12 * $global:HMTScaleFactor)) { $startX = [int](12 * $global:HMTScaleFactor) }
    
    $HeaderIconBox.Left = $startX
    $HeaderTitle.Left = $startX + $iconW + $gap
    $HeaderSubtitle.Left = $startX + $iconW + $gap
    $HeaderTitle.Width = $w - $HeaderTitle.Left - [int](10 * $global:HMTScaleFactor)
    $HeaderSubtitle.Width = $HeaderTitle.Width

    $MainMenu.ClientSize = [System.Drawing.Size]::new($w, ($MainMenuExitButton.Bottom + $p))
})

$MainMenu.Add_FormClosing({
    param($_sender, $e)
    [void]$_sender
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and $Global:IntClose -ne $true) {
        User-Exit
    }
})

# About Menu GUI ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
$AboutGUI = New-Object System.Windows.Forms.Form
$AboutGUI.Text = "About Hat's Multitool"
$AboutGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$AboutGUI.ClientSize = New-Object System.Drawing.Size(320, 380)
$AboutGUI.StartPosition = 'CenterScreen'
$AboutGUI.Icon = $HMTIcon
$AboutGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$AboutGUI.MaximizeBox = $false
$AboutGUI.MinimizeBox = $true
$AboutGUI.ShowInTaskbar = $true
$AboutGUI.Font = $font
$AboutGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$AboutGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $AboutGUI

$IconBox = New-Object System.Windows.Forms.PictureBox
$IconBox.Size = New-Object System.Drawing.Size(100, 100)
$IconBox.Location = New-Object System.Drawing.Point(110, 20)
$IconBox.SizeMode = 'StretchImage'

if (Test-Path $PngIconPath) {
    $IconBox.Image = [System.Drawing.Image]::FromFile($PngIconPath)
} elseif ($HMTIcon) {
    $IconBox.Image = $HMTIcon.ToBitmap()
}
$AboutGUI.Controls.Add($IconBox)

$y = 135
$AboutTitle = New-Object System.Windows.Forms.Label
$AboutTitle.Text = "Hat's Multitool"
$AboutTitle.Font = Get-HMTFont $font.FontFamily 22 ([System.Drawing.FontStyle]::Bold)
$AboutTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$AboutTitle.AutoSize = $false
$AboutTitle.Size = New-Object System.Drawing.Size(320, 30)
$AboutTitle.Location = New-Object System.Drawing.Point(0, $y)
$AboutTitle.TextAlign = 'MiddleCenter'
$AboutGUI.Controls.Add($AboutTitle)

$y += 40
$AboutVersion = New-Object System.Windows.Forms.Label
$AboutVersion.Text = "v$CurVerAbout"
$AboutVersion.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
$AboutVersion.AutoSize = $false
$AboutVersion.Size = New-Object System.Drawing.Size(320, 25)
$AboutVersion.Location = New-Object System.Drawing.Point(0, $y)
$AboutVersion.TextAlign = 'MiddleCenter'
$AboutGUI.Controls.Add($AboutVersion)

$y += 30
$AboutAuthor = New-Object System.Windows.Forms.Label
$AboutAuthor.Text = "Created by Tyler Hatfield`n$([char]0x00A9) $(Get-Date -Format 'yyyy') Hat's Things LLC`nReleased under the GPLv3 License"
$AboutAuthor.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$AboutAuthor.AutoSize = $false
$AboutAuthor.Size = New-Object System.Drawing.Size(320, 60)
$AboutAuthor.Location = New-Object System.Drawing.Point(0, $y)
$AboutAuthor.TextAlign = 'MiddleCenter'
$AboutGUI.Controls.Add($AboutAuthor)

$y += 65
$GithubLink = New-Object System.Windows.Forms.LinkLabel
$GithubLink.Text = "View Source on GitHub"
$GithubLink.LinkColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
$GithubLink.ActiveLinkColor = [System.Drawing.ColorTranslator]::FromHtml("#7289DA")
$GithubLink.AutoSize = $false
$GithubLink.Size = New-Object System.Drawing.Size(320, 25)
$GithubLink.Location = New-Object System.Drawing.Point(0, $y)
$GithubLink.TextAlign = 'MiddleCenter'
$GithubLink.Add_LinkClicked({
    Start-Process "https://github.com/TylerHats/Hats-Multitool/"
})
$AboutGUI.Controls.Add($GithubLink)

$y += 35
$AboutCloseBtn = New-Object System.Windows.Forms.Button
$AboutCloseBtn.Text = "Close"
$AboutCloseBtn.Size = New-Object System.Drawing.Size(100, 40)
$AboutCloseBtn.Location = New-Object System.Drawing.Point(110, $y) 
$AboutCloseBtn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$AboutCloseBtn.FlatStyle = 'Flat'
$AboutCloseBtn.FlatAppearance.BorderSize = 1
$AboutCloseBtn.Add_Click({ $AboutGUI.Hide() })
$AboutGUI.Controls.Add($AboutCloseBtn)

$AboutGUI.Add_Load({
    Invoke-HMTScale $AboutGUI
    Set-RoundedControl $AboutCloseBtn
    $w = $AboutGUI.ClientSize.Width
    $IconBox.Left = ($w - $IconBox.Width) / 2
    $AboutTitle.Width = $w
    $AboutVersion.Width = $w
    $AboutAuthor.Width = $w
    $GithubLink.Width = $w
    $AboutCloseBtn.Left = ($w - $AboutCloseBtn.Width) / 2
    $p = [int](20 * $global:HMTScaleFactor)
    $AboutGUI.ClientSize = [System.Drawing.Size]::new($w, ($AboutCloseBtn.Bottom + $p))
})

$AboutGUI.Add_FormClosing({
    param($_sender, $e)
    [void]$_sender
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing) {
        $e.Cancel = $true
        $AboutGUI.Hide()
    }
})
