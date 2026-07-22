# GUI Setup File - Tyler Hatfield - v2.16

# Main Menu GUI ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Prepare form
$MainMenu = New-Object System.Windows.Forms.Form
$MainMenu.Text = "Hat's Multitool"
$MainMenu.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$MainMenu.ClientSize = New-Object System.Drawing.Size(200, 500)
$MainMenu.StartPosition = 'CenterScreen'
$MainMenu.Icon = $HMTIcon
$MainMenu.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$MainMenu.MaximizeBox = $false
$MainMenu.MinimizeBox = $true
$MainMenu.Font = $font
$MainMenu.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$MainMenu.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $MainMenu

# Form size variables
$checkboxHeight = 30    # Height of each checkbox
$buttonHeight = 80      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Adjust GUI Height
$MainMenuHeight = ($buttonHeight * 5)
$MainMenu.ClientSize = New-Object System.Drawing.Size(300, $MainMenuHeight)
$MainMenu.StartPosition = 'CenterScreen'

# Add Setup button
$y = 25
$MainMenuSetupButton = New-Object System.Windows.Forms.Button
$MainMenuSetupButton.Location = New-Object System.Drawing.Point(50, $y)
$MainMenuSetupButton.Size = New-Object System.Drawing.Size(200, 40)
$MainMenuSetupButton.Text = 'PC Setup and Config'
$MainMenuSetupButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuSetupButton.FlatStyle = 'Flat'
$MainMenuSetupButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuSetupButton)

# Add Tools button
$MainMenuToolsButton = New-Object System.Windows.Forms.Button
$y += 65
$MainMenuToolsButton.Location = New-Object System.Drawing.Point(50, $y)
$MainMenuToolsButton.Size = New-Object System.Drawing.Size(200, 40)
$MainMenuToolsButton.Text = 'Tools'
$MainMenuToolsButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuToolsButton.FlatStyle = 'Flat'
$MainMenuToolsButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuToolsButton)

# Add Troubleshooting button
$MainMenuTroubleshootingButton = New-Object System.Windows.Forms.Button
$y += 65
$MainMenuTroubleshootingButton.Location = New-Object System.Drawing.Point(50, $y)
$MainMenuTroubleshootingButton.Size = New-Object System.Drawing.Size(200, 40)
$MainMenuTroubleshootingButton.Text = 'Troubleshooting'
$MainMenuTroubleshootingButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuTroubleshootingButton.FlatStyle = 'Flat'
$MainMenuTroubleshootingButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuTroubleshootingButton)
$MainMenuTroubleshootingButton.Enabled = $true

# Account button removed to leave blank space
$y += 65


# About button
$MainMenuAboutButton = New-Object System.Windows.Forms.Button
$y += 65
$MainMenuAboutButton.Location = New-Object System.Drawing.Point(50, $y)
$MainMenuAboutButton.Size = New-Object System.Drawing.Size(95, 40)
$MainMenuAboutButton.Text = 'About'
$MainMenuAboutButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuAboutButton.FlatStyle = 'Flat'
$MainMenuAboutButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuAboutButton)

# Exit button
$MainMenuExitButton = New-Object System.Windows.Forms.Button
$MainMenuExitButton.Location = New-Object System.Drawing.Point(155, $y)
$MainMenuExitButton.Size = New-Object System.Drawing.Size(95, 40)
$MainMenuExitButton.Text = 'Exit'
$MainMenuExitButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuExitButton.FlatStyle = 'Flat'
$MainMenuExitButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuExitButton)

$MainMenu.Add_Shown({
    # Enforce TopMost rendering
    $this.TopMost = $true 
    # Grab the foreground focus
    [HMT.NativeMethods]::SetForegroundWindow($this.Handle) | Out-Null
    $this.Activate()
    $this.BringToFront()
    # Restore normal window z-order
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

$MainMenuTroubleshootingButton.Add_Click({
    $Global:NextAction = 'Troubleshooting'
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
    Set-RoundedControl $MainMenuTroubleshootingButton
    Set-RoundedControl $MainMenuAboutButton
    Set-RoundedControl $MainMenuExitButton
    $w = [int](300 * $global:HMTScaleFactor)
    $p = [int](30 * $global:HMTScaleFactor)
    $MainMenu.ClientSize = [System.Drawing.Size]::new($w, ($MainMenuExitButton.Bottom + $p))
})

# Catch window close event
$MainMenu.Add_FormClosing({
    param($_sender, $e)
    [void]$_sender
    # $e.CloseReason tells you why it's closing
    # UserClosing covers the “X” or Alt-F4
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and $Global:IntClose -ne $true) {
        User-Exit
    }
})

# About Menu GUI ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Prepare form
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

# Load high-resolution logo
$IconBox = New-Object System.Windows.Forms.PictureBox
$IconBox.Size = New-Object System.Drawing.Size(100, 100)
$IconBox.Location = New-Object System.Drawing.Point(110, 20)
$IconBox.SizeMode = 'StretchImage'

$PngIconPath = Join-Path -Path $PSScriptRoot -ChildPath "HMTIcon.png"
if (Test-Path $PngIconPath) {
    $IconBox.Image = [System.Drawing.Image]::FromFile($PngIconPath)
} else {
    # Fallback to the ICO if the PNG is missing for some reason
    if ($HMTIcon) { $IconBox.Image = $HMTIcon.ToBitmap() }
}
$AboutGUI.Controls.Add($IconBox)

# Program Title Label
$y = 135
$AboutTitle = New-Object System.Windows.Forms.Label
$AboutTitle.Text = "Hat's Multitool"
$AboutTitle.Font = New-Object System.Drawing.Font($font.FontFamily, 22, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$AboutTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$AboutTitle.AutoSize = $false
$AboutTitle.Size = New-Object System.Drawing.Size(320, 30)
$AboutTitle.Location = New-Object System.Drawing.Point(0, $y)
$AboutTitle.TextAlign = 'MiddleCenter'
$AboutGUI.Controls.Add($AboutTitle)

# Pull current version number
$jsonPath = Join-Path -Path $PSScriptRoot -ChildPath "AppManifest.json" # Update filename if needed
if (Test-Path -Path $jsonPath) {
    $configData = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
    $CurVerAbout = $configData.version
} else {
	$CurVerAbout = "X.X.X"
    Log-Message "Failed to locate version number: Could not find $jsonPath" "Error"
}

# Version Label
$y += 40
$AboutVersion = New-Object System.Windows.Forms.Label
$AboutVersion.Text = "v$CurVerAbout"
$AboutVersion.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
$AboutVersion.AutoSize = $false
$AboutVersion.Size = New-Object System.Drawing.Size(320, 25)
$AboutVersion.Location = New-Object System.Drawing.Point(0, $y)
$AboutVersion.TextAlign = 'MiddleCenter'
$AboutGUI.Controls.Add($AboutVersion)

# Author / Copyright Label
$y += 30
$AboutAuthor = New-Object System.Windows.Forms.Label
$AboutAuthor.Text = "Created by Tyler Hatfield`n$([char]0x00A9) $(Get-Date -Format 'yyyy') Hat's Things LLC`nReleased under the GPLv3 License"
$AboutAuthor.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$AboutAuthor.AutoSize = $false
$AboutAuthor.Size = New-Object System.Drawing.Size(320, 60)
$AboutAuthor.Location = New-Object System.Drawing.Point(0, $y)
$AboutAuthor.TextAlign = 'MiddleCenter'
$AboutGUI.Controls.Add($AboutAuthor)

# GitHub Link
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

# Close Button
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

# Calculate dynamic layout post-DPI scaling
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

# Catch Close to just hide instead of exit completely
$AboutGUI.Add_FormClosing({
    param($_sender, $e)
    [void]$_sender
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing) {
        $e.Cancel = $true
        $AboutGUI.Hide()
    }
})

# Setup Module Selection GUI ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Prepare form
$ModGUI = New-Object System.Windows.Forms.Form
$ModGUI.Text = "Hat's Multitool"
$ModGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$ModGUI.ClientSize = New-Object System.Drawing.Size(400, 500)
$ModGUI.StartPosition = 'CenterScreen'
$ModGUI.Icon = $HMTIcon
$ModGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$ModGUI.MaximizeBox = $false
$ModGUI.MinimizeBox = $true
$ModGUI.ShowInTaskbar = $true
$ModGUI.Font = $font
$ModGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$ModGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $ModGUI

# Form size variables
$checkboxHeight = 30    # Height of each checkbox
$buttonHeight = 90      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Module List Array
$modules = @(
    @{ Name = 'Time Zone' },
    @{ Name = 'Local Accounts' },
    @{ Name = 'System Properties' },
    @{ Name = 'Setup Options' },
    @{ Name = 'Bloat Cleanup' },
    @{ Name = 'Programs' }
)

# Adjust GUI Height
$ModGUIHeight = ($modules.Count * $checkboxHeight) + ($buttonHeight * 2) + ($padding * 3) + $labelHeight
$ModGUI.ClientSize = New-Object System.Drawing.Size(300, $ModGUIHeight)
$ModGUI.StartPosition = 'CenterScreen'

# Prepare Module Checkboxes
$ModGUIcheckboxes = @{ }
$y = 15
$ModGUIlabel = New-Object System.Windows.Forms.Label
$ModGUIlabel.Text = "Please Select Modules:"
$ModGUIlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModGUIlabel.Location = New-Object System.Drawing.Point(20, $y)
$ModGUIlabel.AutoSize = $true
$ModGUI.Controls.Add($ModGUIlabel)
$y += 30
$ModCLB = New-Object System.Windows.Forms.CheckedListBox
$ModCLB.Location = New-Object System.Drawing.Point(20, $y)
$ModCLB.Size = New-Object System.Drawing.Size(260, 180)
$ModCLB.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$ModCLB.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModCLB.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$ModCLB.CheckOnClick = $true
$ModGUI.Controls.Add($ModCLB)

foreach ($module in $modules) {
    $ModCLB.Items.Add($module.Name) | Out-Null
}

$y += 180

# Add “Select All” button
$SelectAllButton = New-Object System.Windows.Forms.Button
$y += 15
$SelectAllButton.Text = "Select All"
$SelectAllButton.Size = New-Object System.Drawing.Size(115,40)
$SelectAllButton.Location = New-Object System.Drawing.Point(92, $y)
$SelectAllButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SelectAllButton.FlatStyle = 'Flat'
$SelectAllButton.FlatAppearance.BorderSize = 1
$ModGUI.Controls.Add($SelectAllButton)

# Add OK button
$ModGUIokButton = New-Object System.Windows.Forms.Button
$y += 55
$ModGUIokButton.Location = New-Object System.Drawing.Point(92, $y)
$ModGUIokButton.Size = New-Object System.Drawing.Size(115, 40)
$ModGUIokButton.Text = "OK"
$ModGUIokButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModGUIokButton.FlatStyle = 'Flat'
$ModGUIokButton.FlatAppearance.BorderSize = 1
$ModGUI.Controls.Add($ModGUIokButton)

# Add Back button
$ModGUIBackButton = New-Object System.Windows.Forms.Button
$y += 55
$ModGUIBackButton.Location = New-Object System.Drawing.Point(92, $y)
$ModGUIBackButton.Size = New-Object System.Drawing.Size(115, 40)
$ModGUIBackButton.Text = "Back"
$ModGUIBackButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModGUIBackButton.FlatStyle = 'Flat'
$ModGUIBackButton.FlatAppearance.BorderSize = 1
$ModGUI.Controls.Add($ModGUIBackButton)

# when clicked, check every checkbox in the hashtable
$SelectAllButton.Add_Click({
    for ($i = 0; $i -lt $ModCLB.Items.Count; $i++) {
        $ModCLB.SetItemChecked($i, $true)
    }
})

# Define a function to handle the OK button click
$ModGUIokButton.Add_Click({
    $selectedModules = @()
    foreach ($item in $ModCLB.CheckedItems) {
        $selectedModules += $item
    }
    $totalModules = $selectedModules.Count
    
    if ($totalModules -eq 0) {
        Log-Message "No modules selected to run." "Skip"
        $Global:NextAction = 'Main' # Route back to Main Menu
        $ModGUI.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        return
    }

    # Reset module configuration state
    foreach ($module in $modules) {
        $varName = "Run_" + ($module.Name -replace '\s','')
        Set-Variable -Name $varName -Value $false -Scope Global
    }

    # Apply current module selection
    foreach ($moduleName in $selectedModules) {
        Set-Variable -Name ("Run_" + ($moduleName -replace '\s','')) -Value $true -Scope Global
    }
    
    # Hand off execution to the controller loop and exit this window
    $Global:NextAction = 'RunSetup'
    $ModGUI.DialogResult = [System.Windows.Forms.DialogResult]::OK
})

# Define back button function
$ModGUIBackButton.Add_Click({
	$ModGUI.Hide()
})

$ModGUI.Add_Load({
    Invoke-HMTScale $ModGUI
    Set-RoundedControl $SelectAllButton
    Set-RoundedControl $ModGUIokButton
    Set-RoundedControl $ModGUIBackButton
    $p = [int](20 * $global:HMTScaleFactor)
    $ModGUI.ClientSize = [System.Drawing.Size]::new($ModGUI.ClientSize.Width, ($ModGUIBackButton.Bottom + $p))
})

# Catch closes to close program properly
$ModGUI.Add_FormClosing({
    param($_sender, $e)
    [void]$_sender
    # $e.CloseReason tells you why it's closing
    # UserClosing covers the “X” or Alt-F4
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and $Global:IntClose -ne $true) {
        User-Exit
    }
})

# Tools Menu GUI ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Prepare Form
$ToolsGUI = New-Object System.Windows.Forms.Form
$ToolsGUI.Text = "Hat's Multitool"
$ToolsGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$ToolsGUI.ClientSize = New-Object System.Drawing.Size(400, 500)
$ToolsGUI.StartPosition = 'CenterScreen'
$ToolsGUI.Icon = $HMTIcon
$ToolsGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$ToolsGUI.MaximizeBox = $false
$ToolsGUI.MinimizeBox = $true
$ToolsGUI.ShowInTaskbar = $true
$ToolsGUI.Font = $font
$ToolsGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$ToolsGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $ToolsGUI
$ExtProgramDir = Join-Path -Path $PSScriptRoot -ChildPath "ExtPrograms"

# Form size variables
$buttonHeight = 75      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Adjust GUI Height
$y = 20
$ToolsGUIHeight = ($buttonHeight * 11) + ($padding * 0) + ($labelHeight * 1)
$ToolsGUI.ClientSize = New-Object System.Drawing.Size(705, $ToolsGUIHeight)
$ToolsGUI.StartPosition = 'CenterScreen'

# Add info text
$y = 20
$ToolsInfo = New-Object System.Windows.Forms.Label
$ToolsInfo.Text = "Select a tool from the list below to run it:"
$ToolsInfo.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ToolsInfo.Location = New-Object System.Drawing.Point(30, $y)
$ToolsInfo.AutoSize = $true
$ToolsInfo.TextAlign = 'TopLeft'
$ToolsGUI.Controls.Add($ToolsInfo)
$y += 30

# Add ListView
$ToolsListView = New-Object System.Windows.Forms.ListView
$ToolsListView.Location = New-Object System.Drawing.Point(30, $y)
$ToolsListView.Size = New-Object System.Drawing.Size(590, 350)
$ToolsListView.View = [System.Windows.Forms.View]::Details
$ToolsListView.FullRowSelect = $true
$ToolsListView.GridLines = $false
$ToolsListView.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::Nonclickable
$ToolsListView.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
$ToolsListView.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ToolsListView.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$ToolsListView.OwnerDraw = $true
$ToolsListView.Add_DrawColumnHeader({
    param($sender, $e)
    $g = $e.Graphics
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#2f3136"))
    $g.FillRectangle($brush, $e.Bounds)
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#d9d9d9"))
    $g.DrawString($e.Header.Text, $sender.Font, $textBrush, ($e.Bounds.X + 4), ($e.Bounds.Y + 4))
    $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#555555"))
    $g.DrawRectangle($pen, $e.Bounds.X, $e.Bounds.Y, $e.Bounds.Width - 1, $e.Bounds.Height - 1)
})
$ToolsListView.Add_DrawItem({ param($sender, $e) $e.DrawDefault = $true })
$ToolsListView.Add_DrawSubItem({ param($sender, $e) $e.DrawDefault = $true })

$ToolsListView.Columns.Add("Tool", 180) | Out-Null
$ToolsListView.Columns.Add("Description", 600) | Out-Null
$val = 1
[HMT.NativeMethods]::DwmSetWindowAttribute($ToolsListView.Handle, 20, [ref]$val, 4) | Out-Null
[HMT.NativeMethods]::DwmSetWindowAttribute($ToolsListView.Handle, 19, [ref]$val, 4) | Out-Null
[HMT.NativeMethods]::SetWindowTheme($ToolsListView.Handle, "DarkMode_Explorer", $null) | Out-Null
$ToolsGUI.Controls.Add($ToolsListView)

# Define Tools
$toolsList = @(
    [pscustomobject]@{ Name = "Hat's User Move Tool"; Desc = "A tool to help collect user and system data for transferring to new machines." }
    [pscustomobject]@{ Name = "McAfee MCPR Tool"; Desc = "Removes installed McAfee consumer products." }
    [pscustomobject]@{ Name = "Ninja Removal Script"; Desc = "Launches the Ninja Agent removal script." }
    [pscustomobject]@{ Name = "Windows Disk Cleanup"; Desc = "Launches the Windows Disk Cleanup GUI." }
    [pscustomobject]@{ Name = "Patch Cleaner"; Desc = "Scans and allows removal of unnecessary driver store files." }
    [pscustomobject]@{ Name = "WizTree"; Desc = "Scans a selected drive or folder and displays all contents and their relative sizes." }
    [pscustomobject]@{ Name = "BleachBit"; Desc = "A system and program temporary data cleaner to help reclaim drive space." }
    [pscustomobject]@{ Name = "BlueScreenView"; Desc = "A memory dump and minidump reader to help identify causes of BSOD events." }
    [pscustomobject]@{ Name = "User Profile Wizard"; Desc = "A tool to migrate user profile data between domains or computers." }
    [pscustomobject]@{ Name = "Little Registry Cleaner"; Desc = "A simple registry cleaner program." }
    [pscustomobject]@{ Name = "DISM++"; Desc = "An advanced GUI tool based around DISM for Windows image management." }
    [pscustomobject]@{ Name = ".NET 3.5 (Includes v2 and v3)"; Desc = "Installs .NET 3.5, which includes versions 2 and 3." }
    [pscustomobject]@{ Name = "Display Driver Uninstaller"; Desc = "Runs the Display Driver Uninstaller tool to clean graphics drivers for fresh installs." }
    [pscustomobject]@{ Name = "HDDScan"; Desc = "Runs the HDDScan program to verify the block health and SMART data of a drive." }
    [pscustomobject]@{ Name = "Win11 Upgrade Assistant"; Desc = "Runs the Windows 11 Upgrade Assistant program." }
    [pscustomobject]@{ Name = "Crystal Disk Mark"; Desc = "Runs Crystal Disk Mark SSD/HDD testing utility." }
    [pscustomobject]@{ Name = "Crystal Disk Info"; Desc = "Runs Crystal Disk Info utility." }
)

foreach ($t in $toolsList) {
    $item = New-Object System.Windows.Forms.ListViewItem($t.Name)
    $item.SubItems.Add($t.Desc) | Out-Null
    $ToolsListView.Items.Add($item) | Out-Null
}

$ToolsListView.AutoResizeColumns([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
if ($ToolsListView.Columns[0].Width -lt 180) { $ToolsListView.Columns[0].Width = 180 }
$reqListWidth = $ToolsListView.Columns[0].Width + $ToolsListView.Columns[1].Width + 6
$itemHeight = 20
if ($ToolsListView.Items.Count -gt 0) { $itemHeight = $ToolsListView.GetItemRect(0).Height }
$reqListHeight = ($ToolsListView.Items.Count * $itemHeight) + 30
$ToolsListView.Size = New-Object System.Drawing.Size($reqListWidth, $reqListHeight)
$ToolsListView.Columns[1].Width = $ToolsListView.ClientSize.Width - $ToolsListView.Columns[0].Width

$reqFormWidth = $reqListWidth + 60
$ToolsGUI.MinimumSize = New-Object System.Drawing.Size(($reqFormWidth + 20), ($reqListHeight + 150))
$ToolsGUI.Width = $reqFormWidth + 20
$ToolsGUI.Height = $reqListHeight + 150

$y = $reqListHeight + 65
$TLaunchButton = New-Object System.Windows.Forms.Button
$TLaunchButton.Location = New-Object System.Drawing.Point(30, $y)
$TLaunchButton.Size = New-Object System.Drawing.Size(200, 40)
$TLaunchButton.Text = "Launch Selected Tool"
$TLaunchButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TLaunchButton.FlatStyle = 'Flat'
$TLaunchButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($TLaunchButton)

$TBackButton = New-Object System.Windows.Forms.Button
$TBackButton.Location = New-Object System.Drawing.Point(($reqFormWidth - 145), $y)
$TBackButton.Size = New-Object System.Drawing.Size(115, 40)
$TBackButton.Text = "Back"
$TBackButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TBackButton.FlatStyle = 'Flat'
$TBackButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($TBackButton)

$ToolsListView.Add_DoubleClick({ $TLaunchButton.PerformClick() })

$TLaunchButton.Add_Click({
    if ($ToolsListView.SelectedItems.Count -eq 0) { return }
    $selected = $ToolsListView.SelectedItems[0].Text
    $TLaunchButton.Enabled = $false
    
    try {
        switch ($selected) {
            "Hat's User Move Tool" {
                $MoveToolPath = Join-Path -Path $PSScriptRoot -ChildPath "UserMoveTool.ps1"
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy RemoteSigned -WindowStyle Hidden -File `"$MoveToolPath`""
            }
            "McAfee MCPR Tool" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $MCPRPath = Join-Path -Path $ExtProgramDir -ChildPath "MCPR.exe"
                Show-DownloadDialog -DisplayName 'McAfee MCPR Tool' -Url 'https://download.mcafee.com/molbin/iss-loc/SupportTools/MCPR/MCPR.exe' -OutputPath "$MCPRPath"
                if (Test-Path -LiteralPath $MCPRPath) { Start-Process $MCPRPath }
            }
            "Ninja Removal Script" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $NRScriptPath = Join-Path -Path $ExtProgramDir -ChildPath "NinjaOneAgentRemoval.ps1"
                Show-DownloadDialog -DisplayName 'Ninja Removal Script' -Url 'https://hatsthings.com/MultitoolFiles/NinjaOneAgentRemoval.ps1' -OutputPath "$NRScriptPath"
                if (Test-Path -LiteralPath $NRScriptPath) {
                    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy RemoteSigned -File `"$NRScriptPath`""
                }
            }
            "Windows Disk Cleanup" {
                Log-Message "Starting Windows Disk Cleanup diaglog." "logonly"
                Start-Process -FilePath cleanmgr.exe -Verb RunAs
            }
            "Patch Cleaner" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $PatchCleanerPath = Join-Path -Path $ExtProgramDir -ChildPath "PatchCleanerPortable.zip"
                Show-DownloadDialog -DisplayName 'Patch Cleaner' -Url 'https://master.dl.sourceforge.net/project/patchcleaner/PatchCleaner_Portable/v1.4.2.0/PatchCleanerPortable_1_4_2_0.zip?viasf=1' -OutputPath "$PatchCleanerPath"
                if (Test-Path -LiteralPath $PatchCleanerPath) {
                    Expand-Archive -LiteralPath $PatchCleanerPath -DestinationPath $ExtProgramDir -Force
                    $PatchCleanerExePath = Get-ChildItem -Path $ExtProgramDir -Filter "PatchCleaner.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($PatchCleanerExePath) { Start-Process $PatchCleanerExePath }
                }
            }
            "WizTree" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $WizTreeZipPath = Join-Path -Path $ExtProgramDir -ChildPath "WizTree.zip"
                $wizTreeUrl = 'https://antibodysoftware-17031.kxcdn.com/files/wiztree_4_26_portable.zip'
                try {
                    $wtPage = Invoke-WebRequest -Uri "https://diskanalyzer.com/download" -UseBasicParsing -ErrorAction Stop
                    if ($wtPage.Content -match 'href="(files/wiztree_[^"]+_portable\.zip)"') {
                        $wizTreeUrl = "https://diskanalyzer.com/" + $matches[1]
                    }
                } catch { Write-Warning "Failed to fetch WizTree download URL." }
                Show-DownloadDialog -DisplayName 'WizTree' -Url $wizTreeUrl -OutputPath "$WizTreeZipPath"
                if (Test-Path -LiteralPath $WizTreeZipPath) {
                    Expand-Archive -LiteralPath $WizTreeZipPath -DestinationPath $ExtProgramDir -Force
                    $WizTreeExePath = Get-ChildItem -Path $ExtProgramDir -Filter "WizTree64.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($WizTreeExePath) { Start-Process $WizTreeExePath }
                }
            }
            "BleachBit" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $BleachZipPath = Join-Path -Path $ExtProgramDir -ChildPath "BleachBit.zip"
        
                # Stable fallback URL if the GitHub API is throttled or offline
                $version = "6.0.2"
                try {
                    # Fetch just the release metadata to grab the latest version tag string
                    $ghJson = Invoke-RestMethod -Uri "https://api.github.com/repos/bleachbit/bleachbit/releases/latest" -ErrorAction Stop
                    if ($ghJson.tag_name) {
                        # Strip the leading 'v' from the tag (e.g., 'v6.0.2' -> '6.0.2')
                        $version = $ghJson.tag_name -replace '^v', ''
                    }
                } catch { 
                    Write-Warning "Failed to fetch current BleachBit version from GitHub API. Defaulting to v$version." 
                }
                
                # Construct the precise, case-sensitive URL for their hosting engine
                $bbUrl = "https://download.bleachbit.org/BleachBit-$version-portable.zip"
        
                Show-DownloadDialog -DisplayName 'BleachBit' -Url $bbUrl -OutputPath "$BleachZipPath"
                if (Test-Path -LiteralPath $BleachZipPath) {
                    Expand-Archive -LiteralPath $BleachZipPath -DestinationPath $ExtProgramDir -Force
                    
                    # Dynamically locate the executable regardless of folder naming schemes
                    $BleachExePath = Get-ChildItem -Path $ExtProgramDir -Filter "bleachbit.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($BleachExePath) {
                        Start-Process $BleachExePath
                    } else {
                        Log-Message "Could not locate extracted BleachBit executable." "Error"
                    }
                }
            }
            "BlueScreenView" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $BSVZipPath = Join-Path -Path $ExtProgramDir -ChildPath "BSV.zip"
                Show-DownloadDialog -DisplayName 'BlueScreenView' -Url 'https://www.nirsoft.net/utils/bluescreenview-x64.zip' -OutputPath "$BSVZipPath"
                if (Test-Path -LiteralPath $BSVZipPath) {
                    Expand-Archive -LiteralPath $BSVZipPath -DestinationPath $ExtProgramDir -Force
                    $BSVExePath = Get-ChildItem -Path $ExtProgramDir -Filter "BlueScreenView.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($BSVExePath) { Start-Process $BSVExePath }
                }
            }
            "User Profile Wizard" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $UPWPath = Join-Path -Path $ExtProgramDir -ChildPath "UserProfileWiz.msi"
                $profWizUrl = "https://www.forensit.com/Downloads/Profwiz.msi"
                try {
                    Show-DownloadDialog -DisplayName 'User Profile Wizard' -Url $profWizUrl -OutputPath "$UPWPath"
                } catch {
                    Log-Message "Primary ForensIT download blocked by Cloudflare (403), attempting mirror..." "Warning"
                    try {
                        Show-DownloadDialog -DisplayName 'User Profile Wizard (Mirror)' -Url "https://hatsthings.com/MultitoolFiles/Profwiz.msi" -OutputPath "$UPWPath"
                    } catch {
                        Log-Message "Mirror download failed. Opening ForensIT downloads page in browser..." "Warning"
                        PopupError "ForensIT direct download is blocked by Cloudflare bot protection.`nOpening the ForensIT downloads page in your browser..." "Warning"
                        Start-Process "https://www.forensit.com/downloads.html"
                    }
                }
                if (Test-Path -LiteralPath $UPWPath) { Start-Process $UPWPath }
            }
            "Little Registry Cleaner" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $LRCPath = Join-Path -Path $ExtProgramDir -ChildPath "LRC.zip"
        
                Show-DownloadDialog -DisplayName 'Little Registry Cleaner' -Url 'https://github.com/little-apps/LittleRegistryCleaner/releases/download/1.6/Little_Registry_Cleaner_Portable_Edition_06_28_2013.zip' -OutputPath "$LRCPath"
                if (Test-Path -LiteralPath $LRCPath) {
                    Expand-Archive -LiteralPath $LRCPath -DestinationPath $ExtProgramDir -Force
            
                    $LRCEPath = Get-ChildItem -Path $ExtProgramDir -Filter "Little Registry Cleaner.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
            
                    if ($LRCEPath) {
                        Start-Process $LRCEPath
                    } else {
                        Log-Message "Could not find extracted Little Registry Cleaner executable." "Error"
                    }
                }
            }
            "DISM++" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $DISMPPPath = Join-Path -Path $ExtProgramDir -ChildPath "DISMPP.zip"
                $dismUrl = 'https://github.com/Chuyu-Team/Dism-Multi-language/releases/download/v10.1.1002.2/Dism++10.1.1002.1B.zip'
                try {
                    $ghJson = Invoke-RestMethod -Uri "https://api.github.com/repos/Chuyu-Team/Dism-Multi-language/releases/latest" -ErrorAction Stop
                    $ghAsset = $ghJson.assets | Where-Object { $_.name -match 'Dism.*\.zip' } | Select-Object -First 1
                    if ($ghAsset.browser_download_url) { $dismUrl = $ghAsset.browser_download_url }
                } catch { Write-Warning "Failed to fetch DISM++ download URL." }
                Show-DownloadDialog -DisplayName 'DISM++' -Url $dismUrl -OutputPath "$DISMPPPath"
                if (Test-Path -LiteralPath $DISMPPPath) {
                    Expand-Archive -LiteralPath $DISMPPPath -DestinationPath $ExtProgramDir -Force
                    $DISMPPEPath = Get-ChildItem -Path $ExtProgramDir -Filter "Dism++x64.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($DISMPPEPath) { Start-Process $DISMPPEPath }
                }
            }
            ".NET 3.5 (Includes v2 and v3)" {
                Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy RemoteSigned", "-Command Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart" -Verb RunAs
            }
            "Display Driver Uninstaller" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $DDUPath = Join-Path -Path $ExtProgramDir -ChildPath "DDU.exe"
                $dduUrl = "https://download.wagnardsoft.com/DDU/DDU%20v18.1.5.6.exe"
                try {
                    $dduPage = Invoke-WebRequest -Uri "https://www.wagnardsoft.com/display-driver-uninstaller-ddu" -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -UseBasicParsing -ErrorAction Stop
                    if ($dduPage.Content -match 'alt="Download Display Driver Uninstaller \(DDU\) ([0-9\.]+)"') {
                        $dduVer = $matches[1]
                        $dduUrl = "https://download.wagnardsoft.com/DDU/DDU%20v$dduVer.exe"
                    }
                } catch { Write-Warning "Failed to fetch current DDU version." }
        
                Show-DownloadDialog -DisplayName 'Display Driver Uninstaller' -Url $dduUrl -OutputPath "$DDUPath"
                if (Test-Path -LiteralPath $DDUPath) {
                    Start-Process $DDUPath -ArgumentList "-y -o`"$ExtProgramDir`"" -Wait
                    $DDUEPath = Get-ChildItem -Path $ExtProgramDir -Filter "Display Driver Uninstaller.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($DDUEPath) { Start-Process $DDUEPath }
                }
            }
            "HDDScan" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $HDDSPath = Join-Path -Path $ExtProgramDir -ChildPath "HDDS.zip"
                Show-DownloadDialog -DisplayName 'HDDScan' -Url 'https://hddscan.com/download/HDDScan.zip' -OutputPath "$HDDSPath"
                if (Test-Path -LiteralPath $HDDSPath) {
                    Expand-Archive -LiteralPath $HDDSPath -DestinationPath $ExtProgramDir -Force
                    $HDDSEPath = Get-ChildItem -Path $ExtProgramDir -Filter "HDDScan.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($HDDSEPath) { Start-Process $HDDSEPath }
                }
            }
            "Win11 Upgrade Assistant" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $W11APath = Join-Path -Path $ExtProgramDir -ChildPath "W11UA.exe"
        
                $w11Url = "https://go.microsoft.com/fwlink/?linkid=2171764"
        
                Show-DownloadDialog -DisplayName 'Win11 Upgrade Assistant' -Url $w11Url -OutputPath "$W11APath"
                if (Test-Path -LiteralPath $W11APath) { Start-Process $W11APath }
            }
            "Crystal Disk Mark" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $CDMPath = Join-Path -Path $ExtProgramDir -ChildPath "CDM.zip"
                $cdmUrl = 'https://master.dl.sourceforge.net/project/crystaldiskmark/9.0.3/CrystalDiskMark9_0_3.zip?viasf=1'
                try {
                    $sfJson = Invoke-RestMethod -Uri "https://sourceforge.net/projects/crystaldiskmark/best_release.json" -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -UseBasicParsing -ErrorAction Stop
                    if ($sfJson.release.filename) { 
                        $cdmUrl = "https://master.dl.sourceforge.net/project/crystaldiskmark" + $sfJson.release.filename + "?viasf=1"
                    }
                } catch { Write-Warning "Failed to fetch Crystal Disk Mark download URL." }
                Show-DownloadDialog -DisplayName 'Crystal Disk Mark' -Url $cdmUrl -OutputPath "$CDMPath"
                if (Test-Path -LiteralPath $CDMPath) {
                    Expand-Archive -LiteralPath $CDMPath -DestinationPath $ExtProgramDir -Force
                    $CDMEPath = Get-ChildItem -Path $ExtProgramDir -Filter "DiskMark64.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($CDMEPath) { Start-Process $CDMEPath }
                }
            }
            "Crystal Disk Info" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $CDIPath = Join-Path -Path $ExtProgramDir -ChildPath "CDI.zip"
                $cdiUrl = 'https://master.dl.sourceforge.net/project/crystaldiskinfo/9.9.1/CrystalDiskInfo9_9_1.zip?viasf=1'
                try {
                    $sfJson = Invoke-RestMethod -Uri "https://sourceforge.net/projects/crystaldiskinfo/best_release.json" -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -UseBasicParsing -ErrorAction Stop
                    if ($sfJson.release.filename) { 
                        $cdiUrl = "https://master.dl.sourceforge.net/project/crystaldiskinfo" + $sfJson.release.filename + "?viasf=1"
                    }
                } catch { Write-Warning "Failed to fetch Crystal Disk Info download URL." }
                Show-DownloadDialog -DisplayName 'Crystal Disk Info' -Url $cdiUrl -OutputPath "$CDIPath"
                if (Test-Path -LiteralPath $CDIPath) {
                    Expand-Archive -LiteralPath $CDIPath -DestinationPath $ExtProgramDir -Force
                    $CDIEPath = Get-ChildItem -Path $ExtProgramDir -Filter "DiskInfo64.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($CDIEPath) { Start-Process $CDIEPath }
                }
            }
        }
    } finally {
        $TLaunchButton.Enabled = $true
    }
})

$TBackButton.Add_Click({
    $ToolsGUI.Hide()
})

$ToolsGUI.Add_Load({
    Invoke-HMTScale $ToolsGUI
    Set-RoundedControl $TLaunchButton
    Set-RoundedControl $TBackButton
    $p = [int](20 * $global:HMTScaleFactor)
    
    $ToolsGUI.MinimumSize = [System.Drawing.Size]::Empty
    
    $itemHeight = 20
    if ($ToolsListView.Items.Count -gt 0) { $itemHeight = $ToolsListView.GetItemRect(0).Height }
    $reqListHeight = ($ToolsListView.Items.Count * $itemHeight) + [int](30 * $global:HMTScaleFactor)
    $ToolsListView.Height = $reqListHeight
    
    $ToolsListView.AutoResizeColumns([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
    $minCol0 = [int](180 * $global:HMTScaleFactor)
    if ($ToolsListView.Columns[0].Width -lt $minCol0) { $ToolsListView.Columns[0].Width = $minCol0 }
    $reqListWidth = $ToolsListView.Columns[0].Width + $ToolsListView.Columns[1].Width + [int](6 * $global:HMTScaleFactor)
    $ToolsListView.Width = $reqListWidth
    
    $y = $ToolsListView.Bottom + [int](15 * $global:HMTScaleFactor)
    $TLaunchButton.Top = $y
    $TBackButton.Top = $y
    
    $reqFormWidth = $reqListWidth + [int](60 * $global:HMTScaleFactor)
    $TBackButton.Left = $reqFormWidth - $TBackButton.Width - [int](30 * $global:HMTScaleFactor)
    
    $ToolsGUI.ClientSize = [System.Drawing.Size]::new($reqFormWidth, ($TBackButton.Bottom + $p))
    $ToolsGUI.MinimumSize = $ToolsGUI.Size
    
    $ToolsListView.Columns[1].Width = $ToolsListView.ClientSize.Width - $ToolsListView.Columns[0].Width
})

# Catch closes to close program properly
$ToolsGUI.Add_FormClosing({
    param($_sender, $e)
    [void]$_sender
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and $Global:IntClose -ne $true) {
        User-Exit
    }
})

#Troubleshooting GUI ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Prepare Form
$TroubleGUI = New-Object System.Windows.Forms.Form
$TroubleGUI.Text = "Hat's Multitool"
$TroubleGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$TroubleGUI.ClientSize = New-Object System.Drawing.Size(400, 500)
$TroubleGUI.StartPosition = 'CenterScreen'
$TroubleGUI.Icon = $HMTIcon
$TroubleGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$TroubleGUI.MaximizeBox = $false
$TroubleGUI.MinimizeBox = $true
$TroubleGUI.ShowInTaskbar = $true
$TroubleGUI.Font = $font
$TroubleGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$TroubleGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $TroubleGUI
$ExtProgramDir = Join-Path -Path $PSScriptRoot -ChildPath "ExtPrograms"

# Form size variables
$buttonHeight = 75      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Adjust GUI Height (Increased multiplier to 6 to fit new rows)
$y = 20
$TroubleGUIHeight = ($buttonHeight * 6) + ($padding * 0) + ($labelHeight * 1)
$TroubleGUI.ClientSize = New-Object System.Drawing.Size(705, $TroubleGUIHeight)
$TroubleGUI.StartPosition = 'CenterScreen'

# Add info text
$TroubleInfo = New-Object System.Windows.Forms.Label
$TroubleInfo.Text = "Press a button to launch the relevant tool:"
$TroubleInfo.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TroubleInfo.Location = New-Object System.Drawing.Point(30, $y)
$TroubleInfo.AutoSize = $true
$TroubleInfo.TextAlign = 'TopCenter'
$TroubleGUI.Controls.Add($TroubleInfo)
$y += 30

# Add ListView
$TrListView = New-Object System.Windows.Forms.ListView
$TrListView.Location = New-Object System.Drawing.Point(30, $y)
$TrListView.Size = New-Object System.Drawing.Size(590, 250)
$TrListView.View = [System.Windows.Forms.View]::Details
$TrListView.FullRowSelect = $true
$TrListView.GridLines = $false
$TrListView.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::Nonclickable
$TrListView.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
$TrListView.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TrListView.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$TrListView.OwnerDraw = $true
$TrListView.Add_DrawColumnHeader({
    param($sender, $e)
    $g = $e.Graphics
    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#2f3136"))
    $g.FillRectangle($brush, $e.Bounds)
    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#d9d9d9"))
    $g.DrawString($e.Header.Text, $sender.Font, $textBrush, ($e.Bounds.X + 4), ($e.Bounds.Y + 4))
    $pen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#555555"))
    $g.DrawRectangle($pen, $e.Bounds.X, $e.Bounds.Y, $e.Bounds.Width - 1, $e.Bounds.Height - 1)
})
$TrListView.Add_DrawItem({ param($sender, $e) $e.DrawDefault = $true })
$TrListView.Add_DrawSubItem({ param($sender, $e) $e.DrawDefault = $true })

$TrListView.Columns.Add("Tool", 180) | Out-Null
$TrListView.Columns.Add("Description", 600) | Out-Null
$val = 1
[HMT.NativeMethods]::DwmSetWindowAttribute($TrListView.Handle, 20, [ref]$val, 4) | Out-Null
[HMT.NativeMethods]::DwmSetWindowAttribute($TrListView.Handle, 19, [ref]$val, 4) | Out-Null
[HMT.NativeMethods]::SetWindowTheme($TrListView.Handle, "DarkMode_Explorer", $null) | Out-Null
$TroubleGUI.Controls.Add($TrListView)

function Show-TcpCheckerDialog {
    $tcpForm = New-Object System.Windows.Forms.Form
    $tcpForm.Text = "TCP Port & Connection Checker"
    $tcpForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $tcpForm.ClientSize = New-Object System.Drawing.Size(420, 310)
    $tcpForm.StartPosition = 'CenterScreen'
    $tcpForm.Icon = $HMTIcon
    $tcpForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $tcpForm.MaximizeBox = $false
    $tcpForm.MinimizeBox = $true
    $tcpForm.Font = $font
    $tcpForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $tcpForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $tcpForm

    $y = 15
    $lblHost = New-Object System.Windows.Forms.Label
    $lblHost.Text = "Target Host (IP or Domain):"
    $lblHost.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblHost.Location = New-Object System.Drawing.Point(20, $y)
    $lblHost.AutoSize = $true
    $tcpForm.Controls.Add($lblHost)

    $y += 25
    $txtHost = New-Object System.Windows.Forms.TextBox
    $txtHost.Location = New-Object System.Drawing.Point(20, $y)
    $txtHost.Width = 260
    $tcpForm.Controls.Add($txtHost)
    [HMT.NativeMethods]::SendMessage($txtHost.Handle, 0x1501, 1, "e.g. 8.8.8.8 or google.com")

    $lblPort = New-Object System.Windows.Forms.Label
    $lblPort.Text = "Port:"
    $lblPort.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblPort.Location = New-Object System.Drawing.Point(295, ($y - 25))
    $lblPort.AutoSize = $true
    $tcpForm.Controls.Add($lblPort)

    $txtPort = New-Object System.Windows.Forms.TextBox
    $txtPort.Location = New-Object System.Drawing.Point(295, $y)
    $txtPort.Width = 100
    $txtPort.Text = "443"
    $tcpForm.Controls.Add($txtPort)

    $y += 35
    $btnTest = New-Object System.Windows.Forms.Button
    $btnTest.Location = New-Object System.Drawing.Point(20, $y)
    $btnTest.Size = New-Object System.Drawing.Size(140, 35)
    $btnTest.Text = "Test Connection"
    $btnTest.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnTest.FlatStyle = 'Flat'
    $btnTest.FlatAppearance.BorderSize = 1
    $tcpForm.Controls.Add($btnTest)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point(280, $y)
    $btnClose.Size = New-Object System.Drawing.Size(115, 35)
    $btnClose.Text = "Close"
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $tcpForm.Controls.Add($btnClose)

    $y += 45
    $txtResult = New-Object System.Windows.Forms.TextBox
    $txtResult.Location = New-Object System.Drawing.Point(20, $y)
    $txtResult.Size = New-Object System.Drawing.Size(375, 170)
    $txtResult.Multiline = $true
    $txtResult.ReadOnly = $true
    $txtResult.ScrollBars = 'Vertical'
    $txtResult.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtResult.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $tcpForm.Controls.Add($txtResult)

    $btnClose.Add_Click({ $tcpForm.Close() })

    $btnTest.Add_Click({
        $targetHost = $txtHost.Text.Trim()
        $targetPortStr = $txtPort.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($targetHost)) {
            $txtResult.Text = "Please enter a valid IP address or domain name."
            return
        }
        $port = 443
        [int]::TryParse($targetPortStr, [ref]$port) | Out-Null

        $btnTest.Enabled = $false
        $btnTest.Text = "Testing..."
        $txtResult.Text = "Testing connection to ${targetHost}:${port}..."
        [System.Windows.Forms.Application]::DoEvents()

        try {
            $tcpRes = Test-NetConnection -ComputerName $targetHost -Port $port -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            
            $pingStr = "FAILED"
            try {
                $pinger = [System.Net.NetworkInformation.Ping]::new()
                $reply = $pinger.Send($targetHost, 2000)
                if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                    $pingStr = "SUCCESS ($($reply.RoundtripTime) ms, TTL=$($reply.Options.Ttl))"
                } else {
                    $pingStr = "FAILED ($($reply.Status))"
                }
            } catch {
                $pingStr = "FAILED ($($_))"
            }

            $sb = New-Object System.Text.StringBuilder
            [void]$sb.AppendLine("Target Host:      $targetHost")
            [void]$sb.AppendLine("Resolved IP:      $(if ($tcpRes.RemoteAddress) { $tcpRes.RemoteAddress } else { 'N/A' })")
            [void]$sb.AppendLine("Target Port:      $port")
            [void]$sb.AppendLine("ICMP Ping:        $pingStr")
            [void]$sb.AppendLine("TCP Connection:   $(if ($tcpRes.TcpTestSucceeded) { 'SUCCESS' } else { 'FAILED' })")
            $txtResult.Text = $sb.ToString()
        } catch {
            $txtResult.Text = "Error testing connection: $_"
        } finally {
            $btnTest.Text = "Test Connection"
            $btnTest.Enabled = $true
        }
    })

    $tcpForm.Add_Load({
        Invoke-HMTScale $tcpForm
        Set-RoundedControl $btnTest
        Set-RoundedControl $btnClose
    })

    Show-HMTDialog $tcpForm | Out-Null
}

function Show-StorageHealthDialog {
    $shForm = New-Object System.Windows.Forms.Form
    $shForm.Text = "Storage SMART & Health Summary"
    $shForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $shForm.ClientSize = New-Object System.Drawing.Size(825, 360)
    $shForm.StartPosition = 'CenterScreen'
    $shForm.Icon = $HMTIcon
    $shForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $shForm.MaximizeBox = $false
    $shForm.MinimizeBox = $true
    $shForm.Font = $font
    $shForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $shForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $shForm

    $y = 15
    $shLV = New-Object System.Windows.Forms.ListView
    $shLV.Location = New-Object System.Drawing.Point(20, $y)
    $shLV.Size = New-Object System.Drawing.Size(785, 250)
    $shLV.View = [System.Windows.Forms.View]::Details
    $shLV.FullRowSelect = $true
    $shLV.GridLines = $true
    $shLV.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $shLV.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $shLV.Columns.Add("Disk #", 50) | Out-Null
    $shLV.Columns.Add("Model", 220) | Out-Null
    $shLV.Columns.Add("Media Type", 85) | Out-Null
    $shLV.Columns.Add("Size", 80) | Out-Null
    $shLV.Columns.Add("Wearout", 75) | Out-Null
    $shLV.Columns.Add("Total Writes", 95) | Out-Null
    $shLV.Columns.Add("Health Status", 95) | Out-Null
    $shLV.Columns.Add("Status", 80) | Out-Null
    [HMT.NativeMethods]::SetWindowTheme($shLV.Handle, "DarkMode_Explorer", $null) | Out-Null
    $shForm.Controls.Add($shLV)

    $populateDisks = {
        $shLV.Items.Clear()
        try {
            $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
            if ($disks) {
                foreach ($d in $disks) {
                    $counter = $d | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
                    $wearStr = if ($counter -and $null -ne $counter.Wear) { "$($counter.Wear)%" } else { "N/A" }
                    $writesStr = "N/A"
                    if ($counter -and $null -ne $counter.BytesWritten -and $counter.BytesWritten -gt 0) {
                        if ($counter.BytesWritten -ge 1TB) {
                            $writesStr = "$([math]::Round($counter.BytesWritten / 1TB, 2)) TB"
                        } else {
                            $writesStr = "$([math]::Round($counter.BytesWritten / 1GB, 1)) GB"
                        }
                    }

                    $item = New-Object System.Windows.Forms.ListViewItem([string]$d.DeviceId)
                    $item.SubItems.Add([string]$d.FriendlyName) | Out-Null
                    $item.SubItems.Add([string]$d.MediaType) | Out-Null
                    $sizeGb = [math]::Round($d.Size / 1GB, 1)
                    $item.SubItems.Add("$sizeGb GB") | Out-Null
                    $item.SubItems.Add($wearStr) | Out-Null
                    $item.SubItems.Add($writesStr) | Out-Null
                    $item.SubItems.Add([string]$d.HealthStatus) | Out-Null
                    $item.SubItems.Add(([string]($d.OperationalStatus -join ', '))) | Out-Null
                    $shLV.Items.Add($item) | Out-Null
                }
            } else {
                $item = New-Object System.Windows.Forms.ListViewItem("N/A")
                $item.SubItems.Add("No PhysicalDisks detected via WMI/CIM.") | Out-Null
                $shLV.Items.Add($item) | Out-Null
            }
        } catch {
            $item = New-Object System.Windows.Forms.ListViewItem("Err")
            $item.SubItems.Add("Error querying disk health: $_") | Out-Null
            $shLV.Items.Add($item) | Out-Null
        }
    }

    $y += 265
    $btnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh.Location = New-Object System.Drawing.Point(20, $y)
    $btnRefresh.Size = New-Object System.Drawing.Size(115, 35)
    $btnRefresh.Text = "Refresh"
    $btnRefresh.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnRefresh.FlatStyle = 'Flat'
    $btnRefresh.FlatAppearance.BorderSize = 1
    $shForm.Controls.Add($btnRefresh)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point(690, $y)
    $btnClose.Size = New-Object System.Drawing.Size(115, 35)
    $btnClose.Text = "Close"
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $shForm.Controls.Add($btnClose)

    $btnRefresh.Add_Click({ &$populateDisks })
    $btnClose.Add_Click({ $shForm.Close() })

    $shForm.Add_Load({
        Invoke-HMTScale $shForm
        Set-RoundedControl $btnRefresh
        Set-RoundedControl $btnClose
        &$populateDisks
    })

    Show-HMTDialog $shForm | Out-Null
}

function Show-PacketLossTestDialog {
    $pltForm = New-Object System.Windows.Forms.Form
    $pltForm.Text = "Packet Loss & Ping Test"
    $pltForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $pltForm.ClientSize = New-Object System.Drawing.Size(680, 520)
    $pltForm.StartPosition = 'CenterScreen'
    $pltForm.Icon = $HMTIcon
    $pltForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $pltForm.MaximizeBox = $false
    $pltForm.MinimizeBox = $true
    $pltForm.Font = $font
    $pltForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $pltForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $pltForm

    # Inputs Layout
    $y = 15
    $lblHost = New-Object System.Windows.Forms.Label
    $lblHost.Text = "Target Host / IP:"
    $lblHost.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblHost.Location = New-Object System.Drawing.Point(20, $y)
    $lblHost.AutoSize = $true
    $pltForm.Controls.Add($lblHost)

    $lblPps = New-Object System.Windows.Forms.Label
    $lblPps.Text = "Pings / Sec:"
    $lblPps.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblPps.Location = New-Object System.Drawing.Point(215, $y)
    $lblPps.AutoSize = $true
    $pltForm.Controls.Add($lblPps)

    $lblSize = New-Object System.Windows.Forms.Label
    $lblSize.Text = "Size (Bytes):"
    $lblSize.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblSize.Location = New-Object System.Drawing.Point(340, $y)
    $lblSize.AutoSize = $true
    $pltForm.Controls.Add($lblSize)

    $lblDuration = New-Object System.Windows.Forms.Label
    $lblDuration.Text = "Duration (s):"
    $lblDuration.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblDuration.Location = New-Object System.Drawing.Point(475, $y)
    $lblDuration.AutoSize = $true
    $pltForm.Controls.Add($lblDuration)

    $y += 25
    $txtHost = New-Object System.Windows.Forms.TextBox
    $txtHost.Location = New-Object System.Drawing.Point(20, $y)
    $txtHost.Width = 180
    $txtHost.Text = "8.8.8.8"
    $pltForm.Controls.Add($txtHost)

    $txtPps = New-Object System.Windows.Forms.TextBox
    $txtPps.Location = New-Object System.Drawing.Point(215, $y)
    $txtPps.Width = 100
    $txtPps.Text = "2"
    $pltForm.Controls.Add($txtPps)

    $txtSize = New-Object System.Windows.Forms.TextBox
    $txtSize.Location = New-Object System.Drawing.Point(340, $y)
    $txtSize.Width = 115
    $txtSize.Text = "32"
    $pltForm.Controls.Add($txtSize)

    $txtDuration = New-Object System.Windows.Forms.TextBox
    $txtDuration.Location = New-Object System.Drawing.Point(475, $y)
    $txtDuration.Width = 115
    $txtDuration.Text = "60"
    $pltForm.Controls.Add($txtDuration)

    # Start / Close Buttons
    $y += 35
    $btnStart = New-Object System.Windows.Forms.Button
    $btnStart.Location = New-Object System.Drawing.Point(20, $y)
    $btnStart.Size = New-Object System.Drawing.Size(140, 35)
    $btnStart.Text = "Start Test"
    $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnStart.FlatStyle = 'Flat'
    $btnStart.FlatAppearance.BorderSize = 1
    $pltForm.Controls.Add($btnStart)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point(545, $y)
    $btnClose.Size = New-Object System.Drawing.Size(115, 35)
    $btnClose.Text = "Close"
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $pltForm.Controls.Add($btnClose)

    # Stats Banner Labels
    $y += 45
    $lblStats = New-Object System.Windows.Forms.Label
    $lblStats.Location = New-Object System.Drawing.Point(20, $y)
    $lblStats.Size = New-Object System.Drawing.Size(640, 22)
    $lblStats.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    $lblStats.Text = "Sent: 0  |  Recv: 0  |  Lost: 0 (0.0%)  |  Min: -- ms  |  Avg: -- ms  |  Max: -- ms"
    $pltForm.Controls.Add($lblStats)

    $y += 24
    $lblReason = New-Object System.Windows.Forms.Label
    $lblReason.Location = New-Object System.Drawing.Point(20, $y)
    $lblReason.Size = New-Object System.Drawing.Size(640, 20)
    $lblReason.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblReason.Text = "Last Drop Reason: None"
    $pltForm.Controls.Add($lblReason)

    # Real-Time Graph Canvas Panel
    $y += 25
    $pnlGraph = New-Object System.Windows.Forms.Panel
    $pnlGraph.Location = New-Object System.Drawing.Point(20, $y)
    $pnlGraph.Size = New-Object System.Drawing.Size(640, 240)
    $pnlGraph.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1e24")
    $pnlGraph.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $pltForm.Controls.Add($pnlGraph)

    # State variables
    $script:pltRunning = $false
    $script:sentCount = 0
    $script:recvCount = 0
    $script:lostCount = 0
    $script:minRtt = 999999
    $script:maxRtt = 0
    $script:sumRtt = 0
    $script:pingHistory = [System.Collections.ArrayList]::new()
    $script:maxTargetPackets = 120
    $script:lastReasonText = "None"

    # Graph Paint Event Handler
    $pnlGraph.Add_Paint({
        param($sender, $e)
        $g = $e.Graphics
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

        $w = $pnlGraph.ClientSize.Width
        $h = $pnlGraph.ClientSize.Height

        # Draw Gridlines & Latency Labels
        $gridPen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#33363d"), 1)
        $gridPen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
        $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#72767d"))

        # Max Y scale dynamically based on ping history (minimum 100ms)
        $maxY = 100
        foreach ($p in $script:pingHistory) {
            if ($p.Success -and $p.RTT -gt $maxY) { $maxY = $p.RTT }
        }
        $maxY = [math]::Ceiling($maxY / 50) * 50  # round to multiple of 50ms

        # 3 horizontal gridlines
        for ($i = 1; $i -le 3; $i++) {
            $yPos = $h - ($h * ($i / 4.0))
            $g.DrawLine($gridPen, 0, $yPos, $w, $yPos)
            $msVal = [int]($maxY * ($i / 4.0))
            $g.DrawString("${msVal}ms", $pnlGraph.Font, $textBrush, 5, ($yPos - 14))
        }
        $gridPen.Dispose()
        $textBrush.Dispose()

        # Draw History Packets
        if ($script:pingHistory.Count -gt 0) {
            $totSlots = [math]::Max($script:maxTargetPackets, $script:pingHistory.Count)
            $colWidth = [math]::Max(2.0, ($w / $totSlots))
            $greenPen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#43b581"), [math]::Max(1.5, ($colWidth * 0.7)))
            $redPen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#f04747"), [math]::Max(2.0, ($colWidth * 0.8)))

            for ($idx = 0; $idx -lt $script:pingHistory.Count; $idx++) {
                $pt = $script:pingHistory[$idx]
                $xPos = [float]($idx * $colWidth)

                if ($pt.Success) {
                    $rttRatio = [float]($pt.RTT / $maxY)
                    if ($rttRatio -gt 1.0) { $rttRatio = 1.0 }
                    $yLine = $h - ($h * $rttRatio)
                    if ($yLine -ge $h) { $yLine = $h - 2 }
                    $g.DrawLine($greenPen, $xPos, [float]$h, $xPos, [float]$yLine)
                } else {
                    # Draw full red vertical bar for lost packet
                    $g.DrawLine($redPen, $xPos, 0.0, $xPos, [float]$h)
                }
            }
            $greenPen.Dispose()
            $redPen.Dispose()
        }
    })

    # Async / Timer logic
    $timer = New-Object System.Windows.Forms.Timer
    
    $stopTest = {
        $script:pltRunning = $false
        $timer.Stop()
        $btnStart.Text = "Start Test"
        $txtHost.Enabled = $true
        $txtPps.Enabled = $true
        $txtSize.Enabled = $true
        $txtDuration.Enabled = $true
    }

    $timer.Add_Tick({
        if (-not $script:pltRunning) { return }

        $target = $txtHost.Text.Trim()
        $size = 32
        [int]::TryParse($txtSize.Text.Trim(), [ref]$size) | Out-Null
        if ($size -lt 1) { $size = 32 }
        if ($size -gt 65500) { $size = 65500 }

        $pinger = New-Object System.Net.NetworkInformation.Ping
        $buffer = [byte[]]::new($size)
        $timeout = 1500

        $script:sentCount++

        try {
            $reply = $pinger.Send($target, $timeout, $buffer)
            if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                $script:recvCount++
                $rtt = [int]$reply.RoundtripTime
                $script:sumRtt += $rtt
                if ($rtt -lt $script:minRtt) { $script:minRtt = $rtt }
                if ($rtt -gt $script:maxRtt) { $script:maxRtt = $rtt }

                [void]$script:pingHistory.Add([pscustomobject]@{ Success = $true; RTT = $rtt; Status = "Success" })
            } else {
                $script:lostCount++
                $reason = $reply.Status.ToString()
                $script:lastReasonText = $reason
                [void]$script:pingHistory.Add([pscustomobject]@{ Success = $false; RTT = 0; Status = $reason })
            }
        } catch {
            $script:lostCount++
            $reason = $_.Exception.Message
            $script:lastReasonText = $reason
            [void]$script:pingHistory.Add([pscustomobject]@{ Success = $false; RTT = 0; Status = $reason })
        }

        # Update stats text
        $lossPct = 0.0
        if ($script:sentCount -gt 0) {
            $lossPct = [math]::Round(($script:lostCount / $script:sentCount) * 100, 1)
        }
        $avgRtt = 0
        if ($script:recvCount -gt 0) {
            $avgRtt = [int]($script:sumRtt / $script:recvCount)
        }
        $minStr = if ($script:minRtt -eq 999999) { "--" } else { "$($script:minRtt)" }

        $lblStats.Text = "Sent: $($script:sentCount)  |  Recv: $($script:recvCount)  |  Lost: $($script:lostCount) ($lossPct%)  |  Min: ${minStr}ms  |  Avg: ${avgRtt}ms  |  Max: $($script:maxRtt)ms"
        if ($lossPct -gt 0) {
            $lblStats.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ff6b6b")
        } else {
            $lblStats.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#51cf66")
        }

        if ($script:lostCount -gt 0) {
            $lblReason.Text = "Last Drop Reason: $($script:lastReasonText)"
            $lblReason.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ff6b6b")
        } else {
            $lblReason.Text = "Last Drop Reason: None"
            $lblReason.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
        }

        $pnlGraph.Invalidate()

        # Check total duration limit
        $durationSec = 60
        [int]::TryParse($txtDuration.Text.Trim(), [ref]$durationSec) | Out-Null
        $ppsVal = 2
        [int]::TryParse($txtPps.Text.Trim(), [ref]$ppsVal) | Out-Null

        if ($durationSec -gt 0 -and $script:sentCount -ge ($durationSec * $ppsVal)) {
            &$stopTest
        }
    })

    $btnStart.Add_Click({
        if ($script:pltRunning) {
            &$stopTest
        } else {
            $target = $txtHost.Text.Trim()
            if ([string]::IsNullOrWhiteSpace($target)) { return }

            $pps = 2
            [int]::TryParse($txtPps.Text.Trim(), [ref]$pps) | Out-Null
            if ($pps -lt 1) { $pps = 1 }
            if ($pps -gt 10) { $pps = 10 }

            $dur = 60
            [int]::TryParse($txtDuration.Text.Trim(), [ref]$dur) | Out-Null

            $script:sentCount = 0
            $script:recvCount = 0
            $script:lostCount = 0
            $script:minRtt = 999999
            $script:maxRtt = 0
            $script:sumRtt = 0
            $script:pingHistory.Clear()
            $script:maxTargetPackets = if ($dur -gt 0) { $dur * $pps } else { 120 }
            $script:lastReasonText = "None"

            $script:pltRunning = $true
            $btnStart.Text = "Cancel Test"
            $txtHost.Enabled = $false
            $txtPps.Enabled = $false
            $txtSize.Enabled = $false
            $txtDuration.Enabled = $false

            $intervalMs = [math]::Max(100, [int](1000 / $pps))
            $timer.Interval = $intervalMs
            $timer.Start()
        }
    })

    $btnClose.Add_Click({
        &$stopTest
        $pltForm.Close()
    })

    $pltForm.Add_FormClosing({
        &$stopTest
    })

    $pltForm.Add_Load({
        Invoke-HMTScale $pltForm
        Set-RoundedControl $btnStart
        Set-RoundedControl $btnClose
    })

    Show-HMTDialog $pltForm | Out-Null
}

# Define Tools
$troubleList = @(
    [pscustomobject]@{ Name = "Check Disk (Read Only)"; Desc = "Runs Check Disk in read only mode on C: to check for errors in the file system." }
    [pscustomobject]@{ Name = "DISM Repair"; Desc = "Launches DISM targeting the running image with restore and cleanup options." }
    [pscustomobject]@{ Name = "SFC Repair"; Desc = "Launches standard SFC repair command." }
    [pscustomobject]@{ Name = "Enable Safe Boot (w/Network)"; Desc = "Sets the BCD file to boot with Safe Boot with networking enabled." }
    [pscustomobject]@{ Name = "Generate Battery Report"; Desc = "Generates and opens a detailed HTML report of laptop battery health and cycle history." }
    [pscustomobject]@{ Name = "Reliability Monitor"; Desc = "Opens the Windows Reliability Monitor timeline to view crash and software installation history." }
    [pscustomobject]@{ Name = "Flush DNS & Reset IP"; Desc = "Releases IP, Renews IP, Flushes DNS, and clears the ARP cache." }
    [pscustomobject]@{ Name = "Restart Windows Explorer"; Desc = "Forcefully kills and restarts the explorer.exe process to resolve frozen taskbars or stuck folders." }
    [pscustomobject]@{ Name = "Read Motherboard OEM Product Key"; Desc = "Reads the OEM Windows product key embedded in the BIOS/ACPI MSDM table." }
    [pscustomobject]@{ Name = "TCP Port & Connection Checker"; Desc = "Launches a GUI tool to test IP/hostname reachability and open TCP ports." }
    [pscustomobject]@{ Name = "Storage SMART & Health Summary"; Desc = "Displays physical disk drive model, media type, operational status, and SMART health." }
    [pscustomobject]@{ Name = "Packet Loss Test"; Desc = "Runs a real-time continuous ping test measuring latency graph, packet loss rate, and drop reasons." }
    [pscustomobject]@{ Name = "Windows Update Reset"; Desc = "Stops update services, clears SoftwareDistribution & catroot2 caches, and resets Windows Update components." }
    [pscustomobject]@{ Name = "Reset HOSTS File to Default"; Desc = "Resets the Windows HOSTS file (C:\Windows\System32\drivers\etc\hosts) back to clean Microsoft default." }
)

foreach ($t in $troubleList) {
    $item = New-Object System.Windows.Forms.ListViewItem($t.Name)
    $item.SubItems.Add($t.Desc) | Out-Null
    $TrListView.Items.Add($item) | Out-Null
}

$TrListView.AutoResizeColumns([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
if ($TrListView.Columns[0].Width -lt 180) { $TrListView.Columns[0].Width = 180 }
$reqListWidth = $TrListView.Columns[0].Width + $TrListView.Columns[1].Width + 6
$itemHeight = 20
if ($TrListView.Items.Count -gt 0) { $itemHeight = $TrListView.GetItemRect(0).Height }
$reqListHeight = ($TrListView.Items.Count * $itemHeight) + 30
$TrListView.Size = New-Object System.Drawing.Size($reqListWidth, $reqListHeight)
$TrListView.Columns[1].Width = $TrListView.ClientSize.Width - $TrListView.Columns[0].Width

$reqFormWidth = $reqListWidth + 60
$TroubleGUI.MinimumSize = New-Object System.Drawing.Size(($reqFormWidth + 20), ($reqListHeight + 180))
$TroubleGUI.Width = $reqFormWidth + 20
$TroubleGUI.Height = $reqListHeight + 180

$y = $reqListHeight + 95
$TrLaunchButton = New-Object System.Windows.Forms.Button
$TrLaunchButton.Location = New-Object System.Drawing.Point(30, $y)
$TrLaunchButton.Size = New-Object System.Drawing.Size(200, 40)
$TrLaunchButton.Text = "Launch Selected Tool"
$TrLaunchButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TrLaunchButton.FlatStyle = 'Flat'
$TrLaunchButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($TrLaunchButton)

$ConsoleButton = New-Object System.Windows.Forms.Button
$ConsoleButton.Location = New-Object System.Drawing.Point(($reqFormWidth - 270), $y)
$ConsoleButton.Size = New-Object System.Drawing.Size(115, 40)
$ConsoleButton.Text = "Show Console"
$ConsoleButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ConsoleButton.FlatStyle = 'Flat'
$ConsoleButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($ConsoleButton)
$script:ConsoleClicked = 0

$BackButton = New-Object System.Windows.Forms.Button
$BackButton.Location = New-Object System.Drawing.Point(($reqFormWidth - 145), $y)
$BackButton.Size = New-Object System.Drawing.Size(115, 40)
$BackButton.Text = "Back"
$BackButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$BackButton.FlatStyle = 'Flat'
$BackButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($BackButton)

$TrListView.Add_DoubleClick({
    if ($TrLaunchButton.Enabled -and $TrListView.SelectedItems.Count -gt 0) {
        $TrLaunchButton.PerformClick()
    }
})

$TrLaunchButton.Add_Click({
    if ($TrListView.SelectedItems.Count -eq 0) { return }
    $selected = $TrListView.SelectedItems[0].Text
    $TrLaunchButton.Enabled = $false
    
    try {
        switch ($selected) {
            "Check Disk (Read Only)" {
                Start-Process cmd.exe -ArgumentList '/c chkdsk C: & pause' -Verb RunAs
            }
            "DISM Repair" {
                Start-Process cmd.exe -ArgumentList '/c dism /online /cleanup-image /restorehealth & pause' -Verb RunAs
            }
            "SFC Repair" {
                Start-Process cmd.exe -ArgumentList '/c sfc /scannow & pause' -Verb RunAs
            }
            "Enable Safe Boot (w/Network)" {
                Start-Process "$env:WINDIR\System32\bcdedit.exe" -ArgumentList "/set {default} safeboot networking" -Verb RunAs
            }
            "Generate Battery Report" {
                $ReportPath = Join-Path $env:TEMP "battery-report.html"
                Start-Process powercfg.exe -ArgumentList "/batteryreport /output `"$ReportPath`"" -Wait -WindowStyle Hidden
                if (Test-Path $ReportPath) {
                    Start-Process $ReportPath
                } else {
                    Log-Message "Battery report failed to generate." "Error"
                }
            }
            "Reliability Monitor" {
                Start-Process perfmon.exe -ArgumentList "/rel"
            }
            "Flush DNS & Reset IP" {
                Clear-DnsClientCache
                Restart-NetAdapter -Name "*"
            }
            "Restart Windows Explorer" {
                Stop-Process -Name explorer -Force
                Start-Process "$env:WINDIR\explorer.exe"
            }
            "Read Motherboard OEM Product Key" {
                $oemKey = (Get-CimInstance -ClassName SoftwareLicensingService -ErrorAction SilentlyContinue).OA3xOriginalProductKey
                if (-not [string]::IsNullOrWhiteSpace($oemKey)) {
                    [Windows.Forms.Clipboard]::SetText($oemKey)
                    PopupError "OEM Product Key found:`n`n$oemKey`n`n(Key copied to clipboard!)" "Information"
                    Log-Message "Retrieved OEM Product Key: $oemKey" "Success"
                } else {
                    PopupError "No OEM Product Key found embedded in the motherboard/BIOS MSDM table." "Warning"
                    Log-Message "No OEM Product Key found in BIOS MSDM table." "Skip"
                }
            }
            "TCP Port & Connection Checker" {
                Show-TcpCheckerDialog
            }
            "Storage SMART & Health Summary" {
                Show-StorageHealthDialog
            }
            "Packet Loss Test" {
                Show-PacketLossTestDialog
            }
            "Windows Update Reset" {
                Log-Message "Resetting Windows Update components..." "Info"
                Stop-Service -Name wuauserv, bits, cryptsvc, msiserver -ErrorAction SilentlyContinue
                
                $sdPath = "$env:WINDIR\SoftwareDistribution"
                $crPath = "$env:WINDIR\System32\catroot2"
                if (Test-Path $sdPath) { Rename-Item -Path $sdPath -NewName "SoftwareDistribution.old.$((Get-Date).ToString('yyyyMMddHHmmss'))" -ErrorAction SilentlyContinue }
                if (Test-Path $crPath) { Rename-Item -Path $crPath -NewName "catroot2.old.$((Get-Date).ToString('yyyyMMddHHmmss'))" -ErrorAction SilentlyContinue }

                Start-Service -Name wuauserv, bits, cryptsvc, msiserver -ErrorAction SilentlyContinue
                Log-Message "Successfully reset Windows Update services and cleared caches." "Success"
                PopupError "Windows Update components have been reset and services restarted." "Information"
            }
            "Reset HOSTS File to Default" {
                $hostsPath = "$env:WINDIR\System32\drivers\etc\hosts"
                if (Test-Path $hostsPath) {
                    Copy-Item -Path $hostsPath -Destination "$hostsPath.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))" -Force -ErrorAction SilentlyContinue
                }
                $defaultHosts = @"
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# 127.0.0.1       localhost
# ::1             localhost
"@
                Set-Content -Path $hostsPath -Value $defaultHosts -Encoding UTF8 -Force
                Log-Message "Reset HOSTS file to default (backup saved to hosts.bak)." "Success"
                PopupError "HOSTS file has been reset to default.`nA backup of the previous file was created." "Information"
            }
        }
    } finally {
        $TrLaunchButton.Enabled = $true
    }
})

# Define console button
$ConsoleButton.Add_Click({
	if ($ConsoleClicked -eq 0) {
		Show-ConsoleWindow
		$ConsoleButton.Text = "Hide Console"
		$script:ConsoleClicked = 1
	} else {
		Hide-ConsoleWindow
		$ConsoleButton.Text = "Show Console"
		$script:ConsoleClicked = 0
	}
})

# Define back button
$BackButton.Add_Click({
	$TroubleGUI.Hide()
})

$TroubleGUI.Add_Load({
    Invoke-HMTScale $TroubleGUI
    Set-RoundedControl $TrLaunchButton
    Set-RoundedControl $ConsoleButton
    Set-RoundedControl $BackButton
    $p = [int](20 * $global:HMTScaleFactor)
    
    $TroubleGUI.MinimumSize = [System.Drawing.Size]::Empty
    
    $itemHeight = 20
    if ($TrListView.Items.Count -gt 0) { $itemHeight = $TrListView.GetItemRect(0).Height }
    $reqListHeight = ($TrListView.Items.Count * $itemHeight) + [int](30 * $global:HMTScaleFactor)
    $TrListView.Height = $reqListHeight
    
    $TrListView.AutoResizeColumns([System.Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
    $minCol0 = [int](180 * $global:HMTScaleFactor)
    if ($TrListView.Columns[0].Width -lt $minCol0) { $TrListView.Columns[0].Width = $minCol0 }
    $reqListWidth = $TrListView.Columns[0].Width + $TrListView.Columns[1].Width + [int](6 * $global:HMTScaleFactor)
    $TrListView.Width = $reqListWidth
    
    $y = $TrListView.Bottom + [int](15 * $global:HMTScaleFactor)
    $TrLaunchButton.Top = $y
    $ConsoleButton.Top = $y
    $BackButton.Top = $y
    
    $reqFormWidth = $reqListWidth + [int](60 * $global:HMTScaleFactor)
    $BackButton.Left = $reqFormWidth - $BackButton.Width - [int](30 * $global:HMTScaleFactor)
    $ConsoleButton.Left = $BackButton.Left - $ConsoleButton.Width - [int](10 * $global:HMTScaleFactor)
    
    $TroubleGUI.ClientSize = [System.Drawing.Size]::new($reqFormWidth, ($BackButton.Bottom + $p))
    $TroubleGUI.MinimumSize = $TroubleGUI.Size
    
    $TrListView.Columns[1].Width = $TrListView.ClientSize.Width - $TrListView.Columns[0].Width
})

# Catch closes to close program properly
$TroubleGUI.Add_FormClosing({
    param($_sender, $e)
    [void]$_sender
    # $e.CloseReason tells you why it's closing
    # UserClosing covers the “X” or Alt-F4
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and $Global:IntClose -ne $true) {
        User-Exit
    }
})
