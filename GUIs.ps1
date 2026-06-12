# GUI Setup File - Tyler Hatfield - v2.9

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
$MainMenu.Font = $font
$MainMenu.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$MainMenu.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
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
$MainMenuSetupButton.Location = New-Object System.Drawing.Point(42, $y)
$MainMenuSetupButton.Size = New-Object System.Drawing.Size(200, 40)
$MainMenuSetupButton.Text = 'PC Setup and Config'
$MainMenuSetupButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuSetupButton.FlatStyle = 'Flat'
$MainMenuSetupButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuSetupButton)

# Add Tools button
$MainMenuToolsButton = New-Object System.Windows.Forms.Button
$y += 65
$MainMenuToolsButton.Location = New-Object System.Drawing.Point(42, $y)
$MainMenuToolsButton.Size = New-Object System.Drawing.Size(200, 40)
$MainMenuToolsButton.Text = 'Tools'
$MainMenuToolsButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuToolsButton.FlatStyle = 'Flat'
$MainMenuToolsButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuToolsButton)

# Add Troubleshooting button
$MainMenuTroubleshootingButton = New-Object System.Windows.Forms.Button
$y += 65
$MainMenuTroubleshootingButton.Location = New-Object System.Drawing.Point(42, $y)
$MainMenuTroubleshootingButton.Size = New-Object System.Drawing.Size(200, 40)
$MainMenuTroubleshootingButton.Text = 'Troubleshooting'
$MainMenuTroubleshootingButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuTroubleshootingButton.FlatStyle = 'Flat'
$MainMenuTroubleshootingButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuTroubleshootingButton)
$MainMenuTroubleshootingButton.Enabled = $true

# Add Account button
$MainMenuAccountButton = New-Object System.Windows.Forms.Button
$y += 65
$MainMenuAccountButton.Location = New-Object System.Drawing.Point(42, $y)
$MainMenuAccountButton.Size = New-Object System.Drawing.Size(200, 40)
$MainMenuAccountButton.Text = 'Account'
$MainMenuAccountButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuAccountButton.FlatStyle = 'Flat'
$MainMenuAccountButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuAccountButton)
$MainMenuAccountButton.Enabled = $false # Disabled, WIP

# About button
$MainMenuAboutButton = New-Object System.Windows.Forms.Button
$y += 65
$MainMenuAboutButton.Location = New-Object System.Drawing.Point(42, $y)
$MainMenuAboutButton.Size = New-Object System.Drawing.Size(95, 40)
$MainMenuAboutButton.Text = 'About'
$MainMenuAboutButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuAboutButton.FlatStyle = 'Flat'
$MainMenuAboutButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuAboutButton)

# Exit button
$MainMenuExitButton = New-Object System.Windows.Forms.Button
$MainMenuExitButton.Location = New-Object System.Drawing.Point(147, $y)
$MainMenuExitButton.Size = New-Object System.Drawing.Size(95, 40)
$MainMenuExitButton.Text = 'Exit'
$MainMenuExitButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuExitButton.FlatStyle = 'Flat'
$MainMenuExitButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuExitButton)

$MainMenu.Add_Shown({
    $this.Activate()
    $this.BringToFront()
    [HMT.NativeMethods]::SetForegroundWindow($this.Handle)
})

# Define a function to handle the Setup button click
$MainMenuSetupButton.Add_Click({
	# Scrub the GUI: Reset all checkboxes to unchecked
    foreach ($cb in $ModGUIcheckboxes.Values) {
        $cb.Checked = $false
    }
    $MainMenu.Hide()
	$ModGUI.ShowDialog() | Out-Null
    $MainMenu.Show()
})

# Define Tools button click
$MainMenuToolsButton.Add_Click({
    $MainMenu.Hide()
	$ToolsGUI.ShowDialog() | Out-Null
    $MainMenu.Show()
})

# Define Troubleshooting button click
$MainMenuTroubleshootingButton.Add_Click({
    $MainMenu.Hide()
	$TroubleGUI.ShowDialog() | Out-Null
    $MainMenu.Show()
})

# Define Account button click
#WIP

# Define Exit button click
$MainMenuExitButton.Add_Click({
    $MainMenu.Close()
})

# Define About button click
$MainMenuAboutButton.Add_Click({
    $MainMenu.Hide()
    $AboutGUI.ShowDialog() | Out-Null
    $MainMenu.Show()
})

# Catch closes to close program properly
$MainMenu.Add_FormClosing({
    param($sender, $e)
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
$AboutGUI.ClientSize = New-Object System.Drawing.Size(350, 480)
$AboutGUI.StartPosition = 'CenterScreen'
$AboutGUI.Icon = $HMTIcon
$AboutGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$AboutGUI.MaximizeBox = $false
$AboutGUI.Font = $font
$AboutGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$AboutGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
Set-DarkTitleBar -TargetForm $AboutGUI

# Big Icon (Pulls the crisp PNG from script root)
$IconBox = New-Object System.Windows.Forms.PictureBox
$IconBox.Size = New-Object System.Drawing.Size(128, 128)
$IconBox.Location = New-Object System.Drawing.Point(111, 30) # Centered exactly (350-128)/2
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
$AboutTitle = New-Object System.Windows.Forms.Label
$AboutTitle.Text = "Hat's Multitool"
$AboutTitle.Font = New-Object System.Drawing.Font($font.FontFamily, 16, [System.Drawing.FontStyle]::Bold)
$AboutTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$AboutTitle.AutoSize = $false
$AboutTitle.Size = New-Object System.Drawing.Size($AboutGUI.ClientSize.Width, 30)
$AboutTitle.Location = New-Object System.Drawing.Point(0, 175)
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
$AboutVersion = New-Object System.Windows.Forms.Label
$AboutVersion.Text = "v$CurVerAbout"
$AboutVersion.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
$AboutVersion.AutoSize = $false
$AboutVersion.Size = New-Object System.Drawing.Size($AboutGUI.ClientSize.Width, 25)
$AboutVersion.Location = New-Object System.Drawing.Point(0, 205)
$AboutVersion.TextAlign = 'MiddleCenter'
$AboutGUI.Controls.Add($AboutVersion)

# Author / Copyright Label
$AboutAuthor = New-Object System.Windows.Forms.Label
$AboutAuthor.Text = "Created by Tyler Hatfield`n$([char]0x00A9) $(Get-Date -Format 'yyyy') Hat's Things LLC`nReleased under the GPLv3 License"
$AboutAuthor.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$AboutAuthor.AutoSize = $false
$AboutAuthor.Size = New-Object System.Drawing.Size($AboutGUI.ClientSize.Width, 60)
$AboutAuthor.Location = New-Object System.Drawing.Point(0, 235)
$AboutAuthor.TextAlign = 'MiddleCenter'
$AboutGUI.Controls.Add($AboutAuthor)

# GitHub Link
$GithubLink = New-Object System.Windows.Forms.LinkLabel
$GithubLink.Text = "View Source on GitHub"
$GithubLink.LinkColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
$GithubLink.ActiveLinkColor = [System.Drawing.ColorTranslator]::FromHtml("#7289DA")
$GithubLink.AutoSize = $false
$GithubLink.Size = New-Object System.Drawing.Size($AboutGUI.ClientSize.Width, 25)
$GithubLink.Location = New-Object System.Drawing.Point(0, 305)
$GithubLink.TextAlign = 'MiddleCenter'
$GithubLink.Add_LinkClicked({
    Start-Process "https://github.com/TylerHats/Hats-Multitool/"
})
$AboutGUI.Controls.Add($GithubLink)

# Close Button
$AboutCloseBtn = New-Object System.Windows.Forms.Button
$AboutCloseBtn.Text = "Close"
$AboutCloseBtn.Size = New-Object System.Drawing.Size(100, 40)
$AboutCloseBtn.Location = New-Object System.Drawing.Point(125, 360) # Centered exactly (350-100)/2
$AboutCloseBtn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$AboutCloseBtn.FlatStyle = 'Flat'
$AboutCloseBtn.FlatAppearance.BorderSize = 1
$AboutCloseBtn.Add_Click({ $AboutGUI.Hide() })
$AboutGUI.Controls.Add($AboutCloseBtn)

# Catch Close to just hide instead of exit completely
$AboutGUI.Add_FormClosing({
    param($sender, $e)
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
$ModGUI.Font = $font
$ModGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$ModGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
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
    @{ Name = 'Bloat Cleanup' },
    @{ Name = 'Programs' },
    @{ Name = 'System Properties' },
	@{ Name = 'Setup Options' }
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
$y += $labelHeight
foreach ($module in $modules) {
    $ModGUIcheckbox = New-Object System.Windows.Forms.CheckBox
    $ModGUIcheckbox.Location = New-Object System.Drawing.Point(20, $y)
    $ModGUIcheckbox.Text = $module.Name
	$ModGUIcheckbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $ModGUIcheckbox.AutoSize = $true
    $ModGUI.Controls.Add($ModGUIcheckbox)
    $ModGUIcheckboxes[$module.Name] = $ModGUIcheckbox
    $y += $checkboxHeight
}

# Add “Select All” button
$SelectAllButton = New-Object System.Windows.Forms.Button
$y += 15
$SelectAllButton.Text = "Select All"
$SelectAllButton.Size = New-Object System.Drawing.Size(115,40)
$SelectAllButton.Location = New-Object System.Drawing.Point(85, $y)
$SelectAllButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SelectAllButton.FlatStyle = 'Flat'
$SelectAllButton.FlatAppearance.BorderSize = 1
$ModGUI.Controls.Add($SelectAllButton)

# Add OK button
$ModGUIokButton = New-Object System.Windows.Forms.Button
$y += 55
$ModGUIokButton.Location = New-Object System.Drawing.Point(85, $y)
$ModGUIokButton.Size = New-Object System.Drawing.Size(115, 40)
$ModGUIokButton.Text = "OK"
$ModGUIokButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModGUIokButton.FlatStyle = 'Flat'
$ModGUIokButton.FlatAppearance.BorderSize = 1
$ModGUI.Controls.Add($ModGUIokButton)

# Add Back button
$ModGUIBackButton = New-Object System.Windows.Forms.Button
$y += 55
$ModGUIBackButton.Location = New-Object System.Drawing.Point(85, $y)
$ModGUIBackButton.Size = New-Object System.Drawing.Size(115, 40)
$ModGUIBackButton.Text = "Back"
$ModGUIBackButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModGUIBackButton.FlatStyle = 'Flat'
$ModGUIBackButton.FlatAppearance.BorderSize = 1
$ModGUI.Controls.Add($ModGUIBackButton)

# when clicked, check every checkbox in the hashtable
$SelectAllButton.Add_Click({
    foreach ($cb in $ModGUIcheckboxes.Values) {
        $cb.Checked = $true
    }
})

# Define a function to handle the OK button click
$ModGUIokButton.Add_Click({
    $selectedModules = $ModGUIcheckboxes.GetEnumerator() | Where-Object { $_.Value.Checked } | ForEach-Object { $_.Key }
    $totalModules = $selectedModules.Count
    
    if ($totalModules -eq 0) {
        Log-Message "No modules selected to run." "Skip"
        $ModGUI.Hide()
        return
    }

    # CRITICAL FIX: Wipe ALL module variables back to $false to clear out previous runs
    foreach ($module in $modules) {
        $varName = "Run_" + ($module.Name -replace '\s','')
        Set-Variable -Name $varName -Value $false -Scope Global
    }

    # Now set only the newly selected modules to $true
    foreach ($moduleName in $selectedModules) {
        Set-Variable -Name ("Run_" + ($moduleName -replace '\s','')) -Value $true -Scope Global
    }
    
    # Hide the form and execute the setup script
    $ModGUI.Hide()
    $SetupScriptModPath = Join-Path -Path $PSScriptRoot -ChildPath 'SetupScript.ps1'
    . "$SetupScriptModPath"
})

# Define back button function
$ModGUIBackButton.Add_Click({
	$ModGUI.Hide()
})

# Catch closes to close program properly
$ModGUI.Add_FormClosing({
    param($sender, $e)
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
$ToolsGUI.Font = $font
$ToolsGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$ToolsGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
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
$ToolsInfo = New-Object System.Windows.Forms.Label
$ToolsInfo.Text = "Press a button to launch the relevant tool:"
$ToolsInfo.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ToolsInfo.Location = New-Object System.Drawing.Point(30, $y)
$ToolsInfo.AutoSize = $true
$ToolsInfo.TextAlign = 'TopCenter'
$ToolsGUI.Controls.Add($ToolsInfo)
$y += $labelHeight

# Add User Data Tool button
$UserDataButton = New-Object System.Windows.Forms.Button
$y += 10
$UserDataButton.Location = New-Object System.Drawing.Point(65, $y)
$UserDataButton.Size = New-Object System.Drawing.Size(250, 40)
$UserDataButton.Text = "Hat's User Move Tool"
$UserDataButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$UserDataButton.FlatStyle = 'Flat'
$UserDataButton.FlatAppearance.BorderSize = 1
$UserDataButton.Enabled = $true
$ToolsGUI.Controls.Add($UserDataButton)

# User Data Tool Button Tooltip
$UserDataTooltip = New-Object System.Windows.Forms.ToolTip
$UserDataTooltip.SetToolTip($UserDataButton, "A tool to help collect user and system data for transferring to new machines.")

# CURRENTLY EMPTY BUTTON!
$EButton = New-Object System.Windows.Forms.Button
$y += 0
$EButton.Location = New-Object System.Drawing.Point(380, $y)
$EButton.Size = New-Object System.Drawing.Size(250, 40)
$EButton.Text = "Empty"
$EButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$EButton.FlatStyle = 'Flat'
$EButton.FlatAppearance.BorderSize = 1
$E2Button.Enabled = $false
$ToolsGUI.Controls.Add($EButton)

# Empty Agent Button Tooltip
$ETooltip = New-Object System.Windows.Forms.ToolTip
$ETooltip.SetToolTip($EButton, "Currently Empty Button.")

# Add Ninja Agent Removal button
$NRButton = New-Object System.Windows.Forms.Button
$y += 65
$NRButton.Location = New-Object System.Drawing.Point(65, $y)
$NRButton.Size = New-Object System.Drawing.Size(250, 40)
$NRButton.Text = "Ninja Removal Script"
$NRButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$NRButton.FlatStyle = 'Flat'
$NRButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($NRButton)

# Ninja Agent Removal Button Tooltip
$NRTooltip = New-Object System.Windows.Forms.ToolTip
$NRTooltip.SetToolTip($NRButton, "Launches the Ninja Agent removal script.")

# Add Windows Disk Cleanup button
$DCleanButton = New-Object System.Windows.Forms.Button
$y += 0
$DCleanButton.Location = New-Object System.Drawing.Point(380, $y)
$DCleanButton.Size = New-Object System.Drawing.Size(250, 40)
$DCleanButton.Text = "Windows Disk Cleanup"
$DCleanButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$DCleanButton.FlatStyle = 'Flat'
$DCleanButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($DCleanButton)

# Disk Cleanup Button Tooltip
$DCleanTooltip = New-Object System.Windows.Forms.ToolTip
$DCleanTooltip.SetToolTip($DCleanButton, "Launches the Windows Disk Cleanup GUI.")

# Add Windows Debloat Tool button
$DebloatButton = New-Object System.Windows.Forms.Button
$y += 65
$DebloatButton.Location = New-Object System.Drawing.Point(65, $y)
$DebloatButton.Size = New-Object System.Drawing.Size(250, 40)
$DebloatButton.Text = "Empty"
$DebloatButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$DebloatButton.FlatStyle = 'Flat'
$DebloatButton.FlatAppearance.BorderSize = 1
$DebloatButton.Enabled = $false
$ToolsGUI.Controls.Add($DebloatButton)

# Windows Debloat Button Tooltip
$DebloatTooltip = New-Object System.Windows.Forms.ToolTip
$DebloatTooltip.SetToolTip($DebloatButton, "Empty button.")

# Add Patch Cleaner button
$PatchCButton = New-Object System.Windows.Forms.Button
$y += 0
$PatchCButton.Location = New-Object System.Drawing.Point(380, $y)
$PatchCButton.Size = New-Object System.Drawing.Size(250, 40)
$PatchCButton.Text = "Patch Cleaner"
$PatchCButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$PatchCButton.FlatStyle = 'Flat'
$PatchCButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($PatchCButton)

# PatchCleaner Button Tooltip
$PatchCTooltip = New-Object System.Windows.Forms.ToolTip
$PatchCTooltip.SetToolTip($PatchCButton, "Scans and allows removal of unnecessary driver store files.")

# Add WizTree button
$WizTreeButton = New-Object System.Windows.Forms.Button
$y += 65
$WizTreeButton.Location = New-Object System.Drawing.Point(65, $y)
$WizTreeButton.Size = New-Object System.Drawing.Size(250, 40)
$WizTreeButton.Text = "WizTree"
$WizTreeButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$WizTreeButton.FlatStyle = 'Flat'
$WizTreeButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($WizTreeButton)

# WizTree Button Tooltip
$WizTreeTooltip = New-Object System.Windows.Forms.ToolTip
$WizTreeTooltip.SetToolTip($WizTreeButton, "Scans a selected drive or folder and displays all contents and their relative sizes.")

# Add BleachBit button
$BleachButton = New-Object System.Windows.Forms.Button
$y += 0
$BleachButton.Location = New-Object System.Drawing.Point(380, $y)
$BleachButton.Size = New-Object System.Drawing.Size(250, 40)
$BleachButton.Text = "BleachBit"
$BleachButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$BleachButton.FlatStyle = 'Flat'
$BleachButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($BleachButton)

# BleachBit Button Tooltip
$BleachTooltip = New-Object System.Windows.Forms.ToolTip
$BleachTooltip.SetToolTip($BleachButton, "A system and program temporary data cleaner to help reclaim drive space.")

# Add BlueScreenView button
$BSVButton = New-Object System.Windows.Forms.Button
$y += 65
$BSVButton.Location = New-Object System.Drawing.Point(65, $y)
$BSVButton.Size = New-Object System.Drawing.Size(250, 40)
$BSVButton.Text = "BlueScreenView"
$BSVButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$BSVButton.FlatStyle = 'Flat'
$BSVButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($BSVButton)

# BlueScreenView Button Tooltip
$BSVTooltip = New-Object System.Windows.Forms.ToolTip
$BSVTooltip.SetToolTip($BSVButton, "A memory dump and minidump reader to help identify causes of BSOD events.")

# Add UserProfWiz button
$UPWButton = New-Object System.Windows.Forms.Button
$y += 0
$UPWButton.Location = New-Object System.Drawing.Point(380, $y)
$UPWButton.Size = New-Object System.Drawing.Size(250, 40)
$UPWButton.Text = "User Profile Wizard"
$UPWButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$UPWButton.FlatStyle = 'Flat'
$UPWButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($UPWButton)

# UserProfWiz Button Tooltip
$UPWTooltip = New-Object System.Windows.Forms.ToolTip
$UPWTooltip.SetToolTip($UPWButton, "A tool to migrate user profile data between domains on one computer or between two seperate computers.")

# Add LittleRegCleaner button
$LRCButton = New-Object System.Windows.Forms.Button
$y += 65
$LRCButton.Location = New-Object System.Drawing.Point(65, $y)
$LRCButton.Size = New-Object System.Drawing.Size(250, 40)
$LRCButton.Text = "Little Registry Cleaner"
$LRCButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$LRCButton.FlatStyle = 'Flat'
$LRCButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($LRCButton)

# LittleRegCleaner Button Tooltip
$LRCTooltip = New-Object System.Windows.Forms.ToolTip
$LRCTooltip.SetToolTip($LRCButton, "A simple registry cleaner program.")

# Add DISM++ button
$DISMPPButton = New-Object System.Windows.Forms.Button
$y += 0
$DISMPPButton.Location = New-Object System.Drawing.Point(380, $y)
$DISMPPButton.Size = New-Object System.Drawing.Size(250, 40)
$DISMPPButton.Text = "DISM++"
$DISMPPButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$DISMPPButton.FlatStyle = 'Flat'
$DISMPPButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($DISMPPButton)

# DISM++ Button Tooltip
$DISMPPTooltip = New-Object System.Windows.Forms.ToolTip
$DISMPPTooltip.SetToolTip($DISMPPButton, "An advanced GUI tool based around DISM for Windows image management.")

# EMPTY BUTTON 2!
$E2Button = New-Object System.Windows.Forms.Button
$y += 65
$E2Button.Location = New-Object System.Drawing.Point(65, $y)
$E2Button.Size = New-Object System.Drawing.Size(250, 40)
$E2Button.Text = "Empty"
$E2Button.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$E2Button.FlatStyle = 'Flat'
$E2Button.FlatAppearance.BorderSize = 1
$E2Button.Enabled = $false
$ToolsGUI.Controls.Add($E2Button)

# Empty Button Tooltip
$E2Tooltip = New-Object System.Windows.Forms.ToolTip
$E2Tooltip.SetToolTip($E2Button, "An empty button.")

# Add .NET 3.5 button
$NETButton = New-Object System.Windows.Forms.Button
$y += 0
$NETButton.Location = New-Object System.Drawing.Point(380, $y)
$NETButton.Size = New-Object System.Drawing.Size(250, 40)
$NETButton.Text = ".NET 3.5 (Includes v2 and v3)"
$NETButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$NETButton.FlatStyle = 'Flat'
$NETButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($NETButton)

# NET Button Tooltip
$NETTooltip = New-Object System.Windows.Forms.ToolTip
$NETTooltip.SetToolTip($NETButton, "Installs .NET 3.5, which includes versions 2 and 3.")

# Add DDU Button
$DDUButton = New-Object System.Windows.Forms.Button
$y += 65
$DDUButton.Location = New-Object System.Drawing.Point(65, $y)
$DDUButton.Size = New-Object System.Drawing.Size(250, 40)
$DDUButton.Text = "Display Driver Uninstaller"
$DDUButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$DDUButton.FlatStyle = 'Flat'
$DDUButton.FlatAppearance.BorderSize = 1
$DDUButton.Enabled = $true
$ToolsGUI.Controls.Add($DDUButton)

# DDU Button Tooltip
$DDUTooltip = New-Object System.Windows.Forms.ToolTip
$DDUTooltip.SetToolTip($DDUButton, "Runs the Display Driver Uninstaller tool to clean graphics drivers for fresh installs.")

# Add HDDScan Button
$HDDSButton = New-Object System.Windows.Forms.Button
$y += 0
$HDDSButton.Location = New-Object System.Drawing.Point(380, $y)
$HDDSButton.Size = New-Object System.Drawing.Size(250, 40)
$HDDSButton.Text = "HDDScan"
$HDDSButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$HDDSButton.FlatStyle = 'Flat'
$HDDSButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($HDDSButton)

# Add HDDScan Tooltip
$HDDSTooltip = New-Object System.Windows.Forms.ToolTip
$HDDSTooltip.SetToolTip($HDDSButton, "Runs the HDDScan program to verify the block health and SMART data of a drive.")

# Add Windows 11 Upgrade Assistant Button
$W11AButton = New-Object System.Windows.Forms.Button
$y += 65
$W11AButton.Location = New-Object System.Drawing.Point(65, $y)
$W11AButton.Size = New-Object System.Drawing.Size(250, 40)
$W11AButton.Text = "Win11 Upgrade Assistant"
$W11AButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$W11AButton.FlatStyle = 'Flat'
$W11AButton.FlatAppearance.BorderSize = 1
$W11AButton.Enabled = $true
$ToolsGUI.Controls.Add($W11AButton)

# Add W11A Tooltip
$W11ATooltip = New-Object System.Windows.Forms.ToolTip
$W11ATooltip.SetToolTip($W11AButton, "Runs the Windows 11 Upgrade Assistant program.")

# Add CDM Button
$CDMButton = New-Object System.Windows.Forms.Button
$y += 0
$CDMButton.Location = New-Object System.Drawing.Point(380, $y)
$CDMButton.Size = New-Object System.Drawing.Size(250, 40)
$CDMButton.Text = "Crystal Disk Mark"
$CDMButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$CDMButton.FlatStyle = 'Flat'
$CDMButton.FlatAppearance.BorderSize = 1
$CDMButton.Enabled = $true
$ToolsGUI.Controls.Add($CDMButton)

# Add CDM Tooltop
$CDMTooltip = New-Object System.Windows.Forms.ToolTip
$CDMTooltip.SetToolTip($CDMButton, "Runs Crystal Disk Mark SSD/HDD testing utility.")

# Add CDI Button
$CDIButton = New-Object System.Windows.Forms.Button
$y += 65
$CDIButton.Location = New-Object System.Drawing.Point(65, $y)
$CDIButton.Size = New-Object System.Drawing.Size(250, 40)
$CDIButton.Text = "Crystal Disk Info"
$CDIButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$CDIButton.FlatStyle = 'Flat'
$CDIButton.FlatAppearance.BorderSize = 1
$CDIButton.Enabled = $true
$ToolsGUI.Controls.Add($CDIButton)

# Add CDI Tooltip
$CDITooltip = New-Object System.Windows.Forms.ToolTip
$CDITooltip.SetToolTip($CDIButton, "Runs Crystal Disk Info utility.")

# Add back button
$BackButton = New-Object System.Windows.Forms.Button
$y += 80
$BackButton.Location = New-Object System.Drawing.Point(300, $y)
$BackButton.Size = New-Object System.Drawing.Size(95, 40)
$BackButton.Text = "Back"
$BackButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$BackButton.FlatStyle = 'Flat'
$BackButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($BackButton)

# Define empty button functions
$EButton.Add_Click({
	$EButton.Enabled = $false
	$EButton.Enabled = $true
})

# Define User Data Migration Tool button functions
$UserDataButton.Add_Click({
	$UserDataButton.Enabled = $false
	$MoveToolPath = Join-Path -Path $PSScriptRoot -ChildPath "UserMoveTool.ps1"
	Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$MoveToolPath`""
	$UserDataButton.Enabled = $true
})

# Define Ninja Removal Script button functions
$NRButton.Add_Click({
    $NRButton.Enabled = $false
    if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
    $NRScriptPath = Join-Path -Path $ExtProgramDir -ChildPath "NinjaOneAgentRemoval.ps1"
    Show-DownloadDialog -DisplayName 'Ninja Removal Script' -Url 'https://hatsthings.com/MultitoolFiles/NinjaOneAgentRemoval.ps1' -OutputPath "$NRScriptPath"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$NRScriptPath`""
    $NRButton.Enabled = $true
})

# Define Windows Disk Cleanup button functions
$DCleanButton.Add_Click({
	$DCleanButton.Enabled = $false
	Log-Message "Starting Windows Disk Cleanup diaglog." "logonly"
	Start-Process -FilePath cleanmgr.exe -Verb RunAs
	$DCleanButton.Enabled = $true
})

# Define debloat tool (empty) button functions
$DebloatButton.Add_Click({
	$DebloatButton.Enabled = $false
	$DebloatButton.Enabled = $true
})

# Define Patch Cleaner button functions
$PatchCButton.Add_Click({
	$PatchCButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$PatchCleanerPath = Join-Path -Path $ExtProgramDir -ChildPath "PatchCleanerPortable.zip"
	Show-DownloadDialog -DisplayName 'Patch Cleaner' -Url 'https://phoenixnap.dl.sourceforge.net/project/patchcleaner/PatchCleaner_Portable/v1.4.2.0/PatchCleanerPortable_1_4_2_0.zip?viasf=1' -OutputPath "$PatchCleanerPath"
	Expand-Archive -LiteralPath $PatchCleanerPath -DestinationPath $ExtProgramDir -Force
	$PatchCleanerExePath = Join-Path -Path $ExtProgramDir -ChildPath "PatchCleanerPortable_1_4_2_0\PatchCleaner\PatchCleaner.exe"
	Start-Process $PatchCleanerExePath
	$PatchCButton.Enabled = $true
})

# Define WizTree button functions
$WizTreeButton.Add_Click({
	$WizTreeButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$WizTreeZipPath = Join-Path -Path $ExtProgramDir -ChildPath "WizTree.zip"
	Show-DownloadDialog -DisplayName 'WizTree' -Url 'https://antibodysoftware-17031.kxcdn.com/files/wiztree_4_26_portable.zip' -OutputPath "$WizTreeZipPath"
	Expand-Archive -LiteralPath $WizTreeZipPath -DestinationPath $ExtProgramDir -Force
	$WizTreeExePath = Join-Path -Path $ExtProgramDir -ChildPath "WizTree64.exe"
	Start-Process $WizTreeExePath
	$WizTreeButton.Enabled = $true
})

# Define BleachBit button functions
$BleachButton.Add_Click({
	$BleachButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$BleachZipPath = Join-Path -Path $ExtProgramDir -ChildPath "BleachBit.zip"
	Show-DownloadDialog -DisplayName 'BleachBit' -Url 'https://download.bleachbit.org/BleachBit-5.0.0-portable.zip' -OutputPath "$BleachZipPath"
	Expand-Archive -LiteralPath $BleachZipPath -DestinationPath $ExtProgramDir -Force
	$BleachExePath = Join-Path -Path $ExtProgramDir -ChildPath "BleachBit-Portable\bleachbit.exe"
	Start-Process $BleachExePath
	$BleachButton.Enabled = $true
})

# Define BlueScreenView button functions
$BSVButton.Add_Click({
	$BSVButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$BSVZipPath = Join-Path -Path $ExtProgramDir -ChildPath "BSV.zip"
	Show-DownloadDialog -DisplayName 'BlueScreenView' -Url 'https://www.nirsoft.net/utils/bluescreenview-x64.zip' -OutputPath "$BSVZipPath"
	Expand-Archive -LiteralPath $BSVZipPath -DestinationPath $ExtProgramDir -Force
	$BSVExePath = Join-Path -Path $ExtProgramDir -ChildPath "BlueScreenView.exe"
	Start-Process $BSVExePath
	$BSVButton.Enabled = $true
})

# Define UserProfileWizard button functions
$UPWButton.Add_Click({
	$UPWButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$UPWPath = Join-Path -Path $ExtProgramDir -ChildPath "UserProfileWiz.msi"
	Show-DownloadDialog -DisplayName 'User Profile Wizard' -Url 'https://www.forensit.com/Downloads/Profwiz.msi' -OutputPath "$UPWPath"
	Start-Process $UPWPath
	$UPWButton.Enabled = $true
})

# Define DISM++ button functions
$DISMPPButton.Add_Click({
	$DISMPPButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$DISMPPPath = Join-Path -Path $ExtProgramDir -ChildPath "DISMPP.zip"
	Show-DownloadDialog -DisplayName 'DISM++' -Url 'https://github.com/Chuyu-Team/Dism-Multi-language/releases/download/v10.1.1002.2/Dism++10.1.1002.1B.zip' -OutputPath "$DISMPPPath"
	Expand-Archive -LiteralPath $DISMPPPath -DestinationPath $ExtProgramDir -Force
	$DISMPPEPath = Join-Path -Path $ExtProgramDir -ChildPath "Dism++x64.exe"
    Start-Process $DISMPPEPath
	$DISMPPButton.Enabled = $true
})

# Define LittleRegCleaner button functions
$LRCButton.Add_Click({
	$LRCButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$LRCPath = Join-Path -Path $ExtProgramDir -ChildPath "LRC.zip"
	Show-DownloadDialog -DisplayName 'Little Registry Cleaner' -Url 'https://github.com/little-apps/LittleRegistryCleaner/releases/download/1.6/Little_Registry_Cleaner_Portable_Edition_06_28_2013.zip' -OutputPath "$LRCPath"
	Expand-Archive -LiteralPath $LRCPath -DestinationPath $ExtProgramDir -Force
	$LRCEPath = Join-Path -Path $ExtProgramDir -ChildPath "Little Registry Cleaner.exe"
    Start-Process $LRCEPath
	$LRCButton.Enabled = $true
})

# Define empty2 button functions
$E2Button.Add_Click({
	$E2Button.Enabled = $false
	$E2Button.Enabled = $true
})

# Define .NET button functions
$NETButton.Add_Click({
	$NETButton.Enabled = $false
	Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-Command Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart" -Verb RunAs
	$NETButton.Enabled = $true
})

# Define DDU button functions
$DDUButton.Add_Click({
	$DDUButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$DDUPath = Join-Path -Path $ExtProgramDir -ChildPath "DDU.zip"
	Show-DownloadDialog -DisplayName 'Display Driver Uninstaller' -Url 'https://download-eu2.guru3d.com/ddu/%5BGuru3D%5D-DDU.zip' -OutputPath "$DDUPath"
	Expand-Archive -LiteralPath $DDUPath -DestinationPath $ExtProgramDir -Force
	$DDUEPath = Join-Path -Path $ExtProgramDir -ChildPath "DDU v18.1.1.5.exe"
    Start-Process $DDUEPath
	$DDUButton.Enabled = $true
})

# Define HDDS button functions
$HDDSButton.Add_Click({
	$HDDSButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$HDDSPath = Join-Path -Path $ExtProgramDir -ChildPath "HDDS.zip"
	Show-DownloadDialog -DisplayName 'HDDScan' -Url 'https://hddscan.com/download/HDDScan.zip' -OutputPath "$HDDSPath"
	Expand-Archive -LiteralPath $HDDSPath -DestinationPath $ExtProgramDir -Force
	$HDDSEPath = Join-Path -Path $ExtProgramDir -ChildPath "HDDScan.exe"
    Start-Process $HDDSEPath
	$HDDSButton.Enabled = $true
})

# Define W11A button functions
$W11AButton.Add_Click({
	$W11AButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$W11APath = Join-Path -Path $ExtProgramDir -ChildPath "W11UA.exe"
	Show-DownloadDialog -DisplayName 'Win11 Upgrade Asisstant' -Url 'https://download.microsoft.com/download/6/8/3/683178b7-baac-4b0d-95be-065a945aadee/Windows11InstallationAssistant.exe' -OutputPath "$W11APath"
    Start-Process $W11APath
	$W11AButton.Enabled = $true
})

# Define CDM button functions
$CDMButton.Add_Click({
	$CDMButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$CDMPath = Join-Path -Path $ExtProgramDir -ChildPath "CDM.zip"
	Show-DownloadDialog -DisplayName 'Crystal Disk Mark' -Url 'https://gigenet.dl.sourceforge.net/project/crystaldiskmark/9.0.1/CrystalDiskMark9_0_1.zip?viasf=1' -OutputPath "$CDMPath"
	Expand-Archive -LiteralPath $CDMPath -DestinationPath $ExtProgramDir -Force
	$CDMEPath = Join-Path -Path $ExtProgramDir -ChildPath "DiskMark64.exe"
    Start-Process $CDMEPath
	$CDMButton.Enabled = $true
})

# Define CDI button functions
$CDIButton.Add_Click({
	$CDIButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$CDIPath = Join-Path -Path $ExtProgramDir -ChildPath "CDI.zip"
	Show-DownloadDialog -DisplayName 'Crystal Disk Info' -Url 'https://cytranet-dal.dl.sourceforge.net/project/crystaldiskinfo/9.7.0/CrystalDiskInfo9_7_0.zip?viasf=1' -OutputPath "$CDIPath"
	Expand-Archive -LiteralPath $CDIPath -DestinationPath $ExtProgramDir -Force
	$CDIEPath = Join-Path -Path $ExtProgramDir -ChildPath "DiskInfo64.exe"
    Start-Process $CDIEPath
	$CDIButton.Enabled = $true
})

# Define back button
$BackButton.Add_Click({
	$ToolsGUI.Hide()
})

# Catch closes to close program properly
$ToolsGUI.Add_FormClosing({
    param($sender, $e)
    # $e.CloseReason tells you why it's closing
    # UserClosing covers the “X” or Alt-F4
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and $Global:IntClose -ne $true) {
        # Do your “cleanup” or alternate logic here
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
$TroubleGUI.Font = $font
$TroubleGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$TroubleGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
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
$y += $labelHeight

# Add Check Disk button
$ChkDskButton = New-Object System.Windows.Forms.Button
$y += 10
$ChkDskButton.Location = New-Object System.Drawing.Point(65, $y)
$ChkDskButton.Size = New-Object System.Drawing.Size(250, 40)
$ChkDskButton.Text = "Check Disk (Read Only)"
$ChkDskButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ChkDskButton.FlatStyle = 'Flat'
$ChkDskButton.FlatAppearance.BorderSize = 1
$ChkDskButton.Enabled = $true
$TroubleGUI.Controls.Add($ChkDskButton)

# Check Disk button Tooltip
$ChkDskTooltip = New-Object System.Windows.Forms.ToolTip
$ChkDskTooltip.SetToolTip($ChkDskButton, "Runs Check Disk in read only mode on C: to check for errors in the file system.")

# Add DISM button
$DISMButton = New-Object System.Windows.Forms.Button
$y += 0
$DISMButton.Location = New-Object System.Drawing.Point(380, $y)
$DISMButton.Size = New-Object System.Drawing.Size(250, 40)
$DISMButton.Text = "DISM Repair"
$DISMButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$DISMButton.FlatStyle = 'Flat'
$DISMButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($DISMButton)

# DISM Button Tooltip
$DISMTooltip = New-Object System.Windows.Forms.ToolTip
$DISMTooltip.SetToolTip($DISMButton, "Launches DISM targeting the running image with restore and cleanup options.")

# Add SFC button
$SFCButton = New-Object System.Windows.Forms.Button
$y += 65
$SFCButton.Location = New-Object System.Drawing.Point(65, $y)
$SFCButton.Size = New-Object System.Drawing.Size(250, 40)
$SFCButton.Text = "SFC Repair"
$SFCButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SFCButton.FlatStyle = 'Flat'
$SFCButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($SFCButton)

# SFC Button Tooltip
$SFCTooltip = New-Object System.Windows.Forms.ToolTip
$SFCTooltip.SetToolTip($SFCButton, "Launches standard SFC repair command.")

# Add SafeBoot button
$SafeBootButton = New-Object System.Windows.Forms.Button
$y += 0
$SafeBootButton.Location = New-Object System.Drawing.Point(380, $y)
$SafeBootButton.Size = New-Object System.Drawing.Size(250, 40)
$SafeBootButton.Text = "Enable Safe Boot (with Networking)"
$SafeBootButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SafeBootButton.FlatStyle = 'Flat'
$SafeBootButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($SafeBootButton)

# Safe Boot Button Tooltip
$SafeBootTooltip = New-Object System.Windows.Forms.ToolTip
$SafeBootTooltip.SetToolTip($SafeBootButton, "Sets the BCD file to boot with Safe Boot with networking enabled.")

# Add Battery Report button
$BatteryButton = New-Object System.Windows.Forms.Button
$y += 65
$BatteryButton.Location = New-Object System.Drawing.Point(65, $y)
$BatteryButton.Size = New-Object System.Drawing.Size(250, 40)
$BatteryButton.Text = "Generate Battery Report"
$BatteryButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$BatteryButton.FlatStyle = 'Flat'
$BatteryButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($BatteryButton)

# Battery Report Tooltip
$BatteryTooltip = New-Object System.Windows.Forms.ToolTip
$BatteryTooltip.SetToolTip($BatteryButton, "Generates and opens a detailed HTML report of laptop battery health and cycle history.")

# Add Reliability Monitor button
$RelMonButton = New-Object System.Windows.Forms.Button
$y += 0
$RelMonButton.Location = New-Object System.Drawing.Point(380, $y)
$RelMonButton.Size = New-Object System.Drawing.Size(250, 40)
$RelMonButton.Text = "Reliability Monitor"
$RelMonButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$RelMonButton.FlatStyle = 'Flat'
$RelMonButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($RelMonButton)

# Reliability Monitor Tooltip
$RelMonTooltip = New-Object System.Windows.Forms.ToolTip
$RelMonTooltip.SetToolTip($RelMonButton, "Opens the Windows Reliability Monitor timeline to view crash and software installation history.")

# Add Network Reset button
$NetResetButton = New-Object System.Windows.Forms.Button
$y += 65
$NetResetButton.Location = New-Object System.Drawing.Point(65, $y)
$NetResetButton.Size = New-Object System.Drawing.Size(250, 40)
$NetResetButton.Text = "Flush DNS & Reset IP"
$NetResetButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$NetResetButton.FlatStyle = 'Flat'
$NetResetButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($NetResetButton)

# Network Reset Tooltip
$NetResetTooltip = New-Object System.Windows.Forms.ToolTip
$NetResetTooltip.SetToolTip($NetResetButton, "Releases IP, Renews IP, Flushes DNS, and clears the ARP cache.")

# Add Restart Explorer button
$ExpButton = New-Object System.Windows.Forms.Button
$y += 0
$ExpButton.Location = New-Object System.Drawing.Point(380, $y)
$ExpButton.Size = New-Object System.Drawing.Size(250, 40)
$ExpButton.Text = "Restart Windows Explorer"
$ExpButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ExpButton.FlatStyle = 'Flat'
$ExpButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($ExpButton)

# Restart Explorer Tooltip
$ExpTooltip = New-Object System.Windows.Forms.ToolTip
$ExpTooltip.SetToolTip($ExpButton, "Forcefully kills and restarts the explorer.exe process to resolve frozen taskbars or stuck folders.")

# Add show console button
$ConsoleButton = New-Object System.Windows.Forms.Button
$y += 80
$ConsoleButton.Location = New-Object System.Drawing.Point(200, $y)
$ConsoleButton.Size = New-Object System.Drawing.Size(115, 40)
$ConsoleButton.Text = "Show Console"
$ConsoleButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ConsoleButton.FlatStyle = 'Flat'
$ConsoleButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($ConsoleButton)
$script:ConsoleClicked = 0

# Add back button
$BackButton = New-Object System.Windows.Forms.Button
$BackButton.Location = New-Object System.Drawing.Point(380, $y)
$BackButton.Size = New-Object System.Drawing.Size(115, 40)
$BackButton.Text = "Back"
$BackButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$BackButton.FlatStyle = 'Flat'
$BackButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($BackButton)

# Define check disk button functions
$ChkDskButton.Add_Click({
	$ChkDskButton.Enabled = $false
	Start-Process cmd.exe -ArgumentList '/c chkdsk C: & pause' -Verb RunAs
	$ChkDskButton.Enabled = $true
})

# Define dism button functions
$DISMButton.Add_Click({
	$DISMButton.Enabled = $false
	Start-Process cmd.exe -ArgumentList '/c dism /online /cleanup-image /restorehealth & pause' -Verb RunAs
	$DISMButton.Enabled = $true
})

# Define SFC button functions
$SFCButton.Add_Click({
	$SFCButton.Enabled = $false
	Start-Process cmd.exe -ArgumentList '/c sfc /scannow & pause' -Verb RunAs
	$SFCButton.Enabled = $true
})

# Define Safe Boot button functions
$SafeBootButton.Add_Click({
	$SafeBootButton.Enabled = $false
	Start-Process cmd.exe -ArgumentList '/c bcdedit /set {default} safeboot networking' -Verb RunAs
	$SafeBootButton.Enabled = $true
})

# Define Battery Report button functions
$BatteryButton.Add_Click({
    $BatteryButton.Enabled = $false
    $ReportPath = Join-Path $env:TEMP "battery-report.html"
    Start-Process powercfg.exe -ArgumentList "/batteryreport /output `"$ReportPath`"" -Wait -WindowStyle Hidden
    if (Test-Path $ReportPath) {
        Start-Process $ReportPath
    } else {
        Log-Message "Battery report failed to generate." "Error"
    }
    $BatteryButton.Enabled = $true
})

# Define Reliability Monitor button functions
$RelMonButton.Add_Click({
    $RelMonButton.Enabled = $false
    Start-Process perfmon.exe -ArgumentList "/rel"
    $RelMonButton.Enabled = $true
})

# Define Network Reset button functions
$NetResetButton.Add_Click({
    $NetResetButton.Enabled = $false
    Start-Process cmd.exe -ArgumentList '/c ipconfig /release & ipconfig /renew & ipconfig /flushdns & arp -d * & pause' -Verb RunAs
    $NetResetButton.Enabled = $true
})

# Define Restart Explorer button functions
$ExpButton.Add_Click({
    $ExpButton.Enabled = $false
    # Using taskkill and start ensures it explicitly comes back online
    Start-Process cmd.exe -ArgumentList '/c taskkill /f /im explorer.exe & start explorer.exe' -WindowStyle Hidden
    $ExpButton.Enabled = $true
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

# Catch closes to close program properly
$TroubleGUI.Add_FormClosing({
    param($sender, $e)
    # $e.CloseReason tells you why it's closing
    # UserClosing covers the “X” or Alt-F4
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and $Global:IntClose -ne $true) {
        User-Exit
    }
})
