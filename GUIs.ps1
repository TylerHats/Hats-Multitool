# GUI Setup File - Tyler Hatfield - v2.12

# Setup Global Forms styling
[System.Windows.Forms.Application]::EnableVisualStyles() # Allows use of current Windows Theme/Style
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false) # Allows High-DPI rendering for text and features

# Main Menu GUI ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Prepare form
$MainMenu = New-Object System.Windows.Forms.Form
$MainMenu.Text = "Hat's Multitool"
$MainMenu.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$MainMenu.Size = New-Object System.Drawing.Size(200, 500)
$MainMenu.StartPosition = 'CenterScreen'
$MainMenu.Icon = $HMTIcon
$MainMenu.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$MainMenu.MaximizeBox = $false
$MainMenu.Font = $font
$MainMenu.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font

# Form size variables
$checkboxHeight = 30    # Height of each checkbox
$buttonHeight = 80      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Adjust GUI Height
$MainMenuHeight = ($buttonHeight * 5)
$MainMenu.Size = New-Object System.Drawing.Size(300, $MainMenuHeight)
$MainMenu.StartPosition = 'CenterScreen'

# Add Setup button
$y = 45
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
$y += 60
$MainMenuToolsButton.Location = New-Object System.Drawing.Point(42, $y)
$MainMenuToolsButton.Size = New-Object System.Drawing.Size(200, 40)
$MainMenuToolsButton.Text = 'Tools'
$MainMenuToolsButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuToolsButton.FlatStyle = 'Flat'
$MainMenuToolsButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuToolsButton)

# Add Troubleshooting button
$MainMenuTroubleshootingButton = New-Object System.Windows.Forms.Button
$y += 60
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
$y += 60
$MainMenuAccountButton.Location = New-Object System.Drawing.Point(42, $y)
$MainMenuAccountButton.Size = New-Object System.Drawing.Size(200, 40)
$MainMenuAccountButton.Text = 'Account'
$MainMenuAccountButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuAccountButton.FlatStyle = 'Flat'
$MainMenuAccountButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuAccountButton)
$MainMenuAccountButton.Enabled = $false # Disabled, WIP

# Exit button
$MainMenuExitButton = New-Object System.Windows.Forms.Button
$y += 60
$MainMenuExitButton.Location = New-Object System.Drawing.Point(100, $y)
$MainMenuExitButton.Size = New-Object System.Drawing.Size(85, 40)
$MainMenuExitButton.Text = 'Exit'
$MainMenuExitButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenuExitButton.FlatStyle = 'Flat'
$MainMenuExitButton.FlatAppearance.BorderSize = 1
$MainMenu.Controls.Add($MainMenuExitButton)

# Define a function to handle the Setup button click
$MainMenuSetupButton.Add_Click({
	#$MainMenuSetupButton.Enabled = $false # Menu cannot be opened twice as it causes GUI issues
    # Close and display Setup GUI
    $MainMenu.Hide()
    Show-ModGUI
    $Global:GUIClosed = $true
})

# Define Tools button click
$MainMenuToolsButton.Add_Click({
    $MainMenu.Hide()
    Show-ToolsGUI
    $Global:GUIClosed = $true
})

# Define Troubleshooting button click
$MainMenuTroubleshootingButton.Add_Click({
    $MainMenu.Hide()
    Show-TroubleGUI
    $Global:GUIClosed = $true
})

# Define Account button click
#WIP

# Define Exit button click
$MainMenuExitButton.Add_Click({
    # Set exit flag and close form
    $Global:UserExit = $true
    $Global:GUIClosed = $true
    $MainMenu.Hide()
})

# Catch closes to close program properly
$MainMenu.Add_FormClosing({
    param($sender, $e)
    # $e.CloseReason tells you why it's closing
    # UserClosing covers the “X” or Alt-F4
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and $Global:IntClose -ne $true) {
        # Do your “cleanup” or alternate logic here
        $Global:UserExit = $true
		$Global:GUIClosed = $true
    }
})

# Setup Module Selection GUI ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Prepare form
$ModGUI = New-Object System.Windows.Forms.Form
$ModGUI.Text = "Hat's Multitool"
$ModGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$ModGUI.Size = New-Object System.Drawing.Size(400, 500)
$ModGUI.StartPosition = 'CenterScreen'
$ModGUI.Icon = $HMTIcon
$ModGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$ModGUI.MaximizeBox = $false
$ModGUI.Font = $font
$ModGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font

# Form size variables
$checkboxHeight = 30    # Height of each checkbox
$buttonHeight = 90      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Module List Array
$modules = @(
    @{ Name = 'Time Zone Setting' },
	@{ Name = 'Windows Updates' },
    @{ Name = 'Local Account Setup' },
    @{ Name = 'Bloat Cleanup' },
    @{ Name = 'Program Installation' },
    @{ Name = 'System Management' },
	@{ Name = 'NUM Lock Default' }
)

# Adjust GUI Height
$ModGUIHeight = ($modules.Count * $checkboxHeight) + ($buttonHeight * 2) + ($padding * 3) + $labelHeight
$ModGUI.Size = New-Object System.Drawing.Size(300, $ModGUIHeight)
$ModGUI.StartPosition = 'CenterScreen'

# Prepare Module Checkboxes
$ModGUIcheckboxes = @{ }
$y = 20
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
$y += 10
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
    # Set module enablement variables
    $selectedModules = $ModGUIcheckboxes.GetEnumerator() | Where-Object { $_.Value.Checked } | ForEach-Object { $_.Key }
    $totalModules = $selectedModules.Count
    if ($totalModules -eq 0) {
        Log-Message "No modules selected to run." "Skip"
        $ModGUI.Hide()
        $Global:GUIClosed = $true
        return
    }
    foreach ($moduleName in $selectedModules) {
		Set-Variable -Name ("Run_" + ($moduleName -replace '\s','')) -Value $true -Scope Global
    }
    # Close the form once complete
    $ModGUI.Hide()
    $SetupScriptModPath = Join-Path -Path $PSScriptRoot -ChildPath 'SetupScript.ps1'
	. "$SetupScriptModPath"
    $Global:GUIClosed = $true
})

# Define back button function
$ModGUIBackButton.Add_Click({
	$ModGUI.Hide()
    Show-MainMenu
    $Global:GUIClosed = $true
})

# Catch closes to close program properly
$ModGUI.Add_FormClosing({
    param($sender, $e)
    # $e.CloseReason tells you why it's closing
    # UserClosing covers the “X” or Alt-F4
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and $Global:IntClose -ne $true) {
        # Do your “cleanup” or alternate logic here
        $Global:UserExit = $true
		$Global:GUIClosed = $true
    }
})

# Closing regards/reminders popup ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Prepare form
$ReminderPopup = New-Object System.Windows.Forms.Form
$ReminderPopup.Text = "Hat's Multitool"
$ReminderPopup.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$ReminderPopup.Size = New-Object System.Drawing.Size(400, 500)
$ReminderPopup.StartPosition = 'CenterScreen'
$ReminderPopup.Icon = $HMTIcon
$ReminderPopup.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$ReminderPopup.MaximizeBox = $false
$ReminderPopup.Font = $font
$ReminderPopup.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font

# Form size variables
$buttonHeight = 80      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Adjust GUI Height
$y = 10
$ReminderPopupHeight = $buttonHeight + ($padding * 1) + ($labelHeight * 2)
$ReminderPopup.Size = New-Object System.Drawing.Size(700, $ReminderPopupHeight)
$ReminderPopup.StartPosition = 'CenterScreen'

# Add popup Text
$ReminderPopuplabel = New-Object System.Windows.Forms.Label
$ReminderPopuplabel.Text = "The multitool run has completed! Please check for any background windows`nand reboot if needed to finalize changes. Press OK to exit."
$ReminderPopuplabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ReminderPopupLabel.Size = New-Object System.Drawing.Size(650, 50)
$ReminderPopuplabel.Location = New-Object System.Drawing.Point(18, $y)
$ReminderPopuplabel.AutoSize = $false
$ReminderPopuplabel.TextAlign = 'TopCenter'
$ReminderPopup.Controls.Add($ReminderPopuplabel)
$y += $labelHeight

# Add OK button
$ReminderPopupokButton = New-Object System.Windows.Forms.Button
$y += 30
$ReminderPopupokButton.Location = New-Object System.Drawing.Point(305, $y)
$ReminderPopupokButton.Size = New-Object System.Drawing.Size(75, 30)
$ReminderPopupokButton.Text = "OK"
$ReminderPopupokButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ReminderPopupokButton.FlatStyle = 'Flat'
$ReminderPopupokButton.FlatAppearance.BorderSize = 1
$ReminderPopup.Controls.Add($ReminderPopupokButton)

# Define back button function
$ReminderPopupokButton.Add_Click({
	$ReminderPopup.Hide()
})

# Catch closes to close program properly
$ReminderPopup.Add_FormClosing({
    param($sender, $e)
    # $e.CloseReason tells you why it's closing
    # UserClosing covers the “X” or Alt-F4
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and $Global:IntClose -ne $true) {
        # Do your “cleanup” or alternate logic here
        $Global:UserExit = $true
		$Global:GUIClosed = $true
    }
})

# Tools Menu GUI ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
# Prepare Form
$ToolsGUI = New-Object System.Windows.Forms.Form
$ToolsGUI.Text = "Hat's Multitool"
$ToolsGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$ToolsGUI.Size = New-Object System.Drawing.Size(400, 500)
$ToolsGUI.StartPosition = 'CenterScreen'
$ToolsGUI.Icon = $HMTIcon
$ToolsGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$ToolsGUI.MaximizeBox = $false
$ToolsGUI.Font = $font
$ToolsGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
$ExtProgramDir = Join-Path -Path $PSScriptRoot -ChildPath "ExtPrograms"

# Form size variables
$buttonHeight = 75      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Adjust GUI Height
$y = 20
$ToolsGUIHeight = ($buttonHeight * 11) + ($padding * 0) + ($labelHeight * 1)
$ToolsGUI.Size = New-Object System.Drawing.Size(705, $ToolsGUIHeight)
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
$UserDataButton.Text = "Hat's User Data Tool"
$UserDataButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$UserDataButton.FlatStyle = 'Flat'
$UserDataButton.FlatAppearance.BorderSize = 1
$UserDataButton.Enabled = $false
$ToolsGUI.Controls.Add($UserDataButton)

# User Data Tool Button Tooltip
$UserDataTooltip = New-Object System.Windows.Forms.ToolTip
$UserDataTooltip.SetToolTip($UserDataButton, "A tool to help collect user and system data for transferring to new machines.")

# Add QIP Agent Deployment button
$QIPButton = New-Object System.Windows.Forms.Button
$y += 0
$QIPButton.Location = New-Object System.Drawing.Point(380, $y)
$QIPButton.Size = New-Object System.Drawing.Size(250, 40)
$QIPButton.Text = "QIP Agent Deployment"
$QIPButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$QIPButton.FlatStyle = 'Flat'
$QIPButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($QIPButton)

# QIP Agent Button Tooltip
$QIPTooltip = New-Object System.Windows.Forms.ToolTip
$QIPTooltip.SetToolTip($QIPButton, "Launches the QualityIP Ninja Agent installer.")

# Add QIP Agent Removal button
$QIPRButton = New-Object System.Windows.Forms.Button
$y += 65
$QIPRButton.Location = New-Object System.Drawing.Point(65, $y)
$QIPRButton.Size = New-Object System.Drawing.Size(250, 40)
$QIPRButton.Text = "Ninja Removal Script"
$QIPRButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$QIPRButton.FlatStyle = 'Flat'
$QIPRButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($QIPRButton)

# QIP Agent Removal Button Tooltip
$QIPRTooltip = New-Object System.Windows.Forms.ToolTip
$QIPRTooltip.SetToolTip($QIPRButton, "Launches the Ninja Agent removal script.")

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
$DebloatButton.Text = "Hat's Windows Debloat Tool"
$DebloatButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$DebloatButton.FlatStyle = 'Flat'
$DebloatButton.FlatAppearance.BorderSize = 1
$DebloatButton.Enabled = $false
$ToolsGUI.Controls.Add($DebloatButton)

# Windows Debloat Button Tooltip
$DebloatTooltip = New-Object System.Windows.Forms.ToolTip
$DebloatTooltip.SetToolTip($DebloatButton, "A tool to cleanup system services and data for a smoother, more privacy focused expirience.")

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

# QIP Agent Button Tooltip
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

# Add SDIO button
$SDIOButton = New-Object System.Windows.Forms.Button
$y += 65
$SDIOButton.Location = New-Object System.Drawing.Point(65, $y)
$SDIOButton.Size = New-Object System.Drawing.Size(250, 40)
$SDIOButton.Text = "Snappy Driver Installer Origin"
$SDIOButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SDIOButton.FlatStyle = 'Flat'
$SDIOButton.FlatAppearance.BorderSize = 1
$SDIOButton.Enabled = $false
$ToolsGUI.Controls.Add($SDIOButton)

# SDIO Button Tooltip
$SDIOTooltip = New-Object System.Windows.Forms.ToolTip
$SDIOTooltip.SetToolTip($SDIOButton, "An advanced system driver updating tool.")

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

# Define QIP Agent Deployment button functions
$QIPButton.Add_Click({
	$QIPButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$QIPAgentPath = Join-Path -Path $ExtProgramDir -ChildPath "QIPAgent.exe"
	Show-DownloadDialog -DisplayName 'QIP Agent Installer' -Url 'https://qi-host.nyc3.digitaloceanspaces.com/NinjaOne/Installer/NinjaOne%20-%20Agent%20Deploy.exe' -OutputPath "$QIPAgentPath"
	Start-Process $QIPAgentPath
	$QIPButton.Enabled = $true
})

# Define User Data Migration Tool button functions *************

# Define Ninja Removal Script button functions
$QIPRButton.Add_Click({
    $QIPRButton.Enabled = $false
    if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
    $QIPRScriptPath = Join-Path -Path $ExtProgramDir -ChildPath "NinjaOneAgentRemoval.ps1"
    Show-DownloadDialog -DisplayName 'Ninja Removal Script' -Url 'https://hatsthings.com/MultitoolFiles/NinjaOneAgentRemoval.ps1' -OutputPath "$QIPRScriptPath"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$QIPRScriptPath`""
    $QIPRButton.Enabled = $true
})

# Define Windows Disk Cleanup button functions
$DCleanButton.Add_Click({
	$DCleanButton.Enabled = $false
	Log-Message "Starting Windows Disk Cleanup diaglog." "logonly"
	Start-Process -FilePath cleanmgr.exe -Verb RunAs
	$DCleanButton.Enabled = $true
})

# Define Windows Debloat Tool button functions *************

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

# Define SDIO button functions

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
	Show-DownloadDialog -DisplayName 'HDDScan' -Url 'https://download-eu2.guru3d.com/ddu/%5BGuru3D%5D-DDU.zip' -OutputPath "$HDDSPath"
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
	Show-DownloadDialog -DisplayName 'Crystal Disk Info' -Url 'https://cytranet-dal.dl.sourceforge.net/project/crystaldiskinfo/9.7.0/CrystalDiskInfo9_7_0.zip?viasf=1' -OutputPath "$CDMPath"
	Expand-Archive -LiteralPath $CDIPath -DestinationPath $ExtProgramDir -Force
	$CDIEPath = Join-Path -Path $ExtProgramDir -ChildPath "DiskInfo64.exe"
    Start-Process $CDIEPath
	$CDIButton.Enabled = $true
})

# Define back button
$BackButton.Add_Click({
	$ToolsGUI.Hide()
    Show-MainMenu
    $Global:GUIClosed = $true
})

# Catch closes to close program properly
$ToolsGUI.Add_FormClosing({
    param($sender, $e)
    # $e.CloseReason tells you why it's closing
    # UserClosing covers the “X” or Alt-F4
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and $Global:IntClose -ne $true) {
        # Do your “cleanup” or alternate logic here
        $Global:UserExit = $true
		$Global:GUIClosed = $true
    }
})

#Troubleshooting GUI ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Prepare Form
$ToolsGUI = New-Object System.Windows.Forms.Form
$ToolsGUI.Text = "Hat's Multitool"
$ToolsGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$ToolsGUI.Size = New-Object System.Drawing.Size(400, 500)
$ToolsGUI.StartPosition = 'CenterScreen'
$ToolsGUI.Icon = $HMTIcon
$ToolsGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$ToolsGUI.MaximizeBox = $false
$ToolsGUI.Font = $font
$ToolsGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
$ExtProgramDir = Join-Path -Path $PSScriptRoot -ChildPath "ExtPrograms"

# Form size variables
$buttonHeight = 75      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Adjust GUI Height
$y = 20
$ToolsGUIHeight = ($buttonHeight * 11) + ($padding * 0) + ($labelHeight * 1)
$ToolsGUI.Size = New-Object System.Drawing.Size(705, $ToolsGUIHeight)
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
$UserDataButton.Text = "Hat's User Data Tool"
$UserDataButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$UserDataButton.FlatStyle = 'Flat'
$UserDataButton.FlatAppearance.BorderSize = 1
$UserDataButton.Enabled = $false
$ToolsGUI.Controls.Add($UserDataButton)

# User Data Tool Button Tooltip
$UserDataTooltip = New-Object System.Windows.Forms.ToolTip
$UserDataTooltip.SetToolTip($UserDataButton, "A tool to help collect user and system data for transferring to new machines.")

# Add QIP Agent Deployment button
$QIPButton = New-Object System.Windows.Forms.Button
$y += 0
$QIPButton.Location = New-Object System.Drawing.Point(380, $y)
$QIPButton.Size = New-Object System.Drawing.Size(250, 40)
$QIPButton.Text = "QIP Agent Deployment"
$QIPButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$QIPButton.FlatStyle = 'Flat'
$QIPButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($QIPButton)

# QIP Agent Button Tooltip
$QIPTooltip = New-Object System.Windows.Forms.ToolTip
$QIPTooltip.SetToolTip($QIPButton, "Launches the QualityIP Ninja Agent installer.")

# Add QIP Agent Removal button
$QIPRButton = New-Object System.Windows.Forms.Button
$y += 65
$QIPRButton.Location = New-Object System.Drawing.Point(65, $y)
$QIPRButton.Size = New-Object System.Drawing.Size(250, 40)
$QIPRButton.Text = "Ninja Removal Script"
$QIPRButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$QIPRButton.FlatStyle = 'Flat'
$QIPRButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($QIPRButton)

# QIP Agent Removal Button Tooltip
$QIPRTooltip = New-Object System.Windows.Forms.ToolTip
$QIPRTooltip.SetToolTip($QIPRButton, "Launches the Ninja Agent removal script.")

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

# Define QIP Agent Deployment button functions
$QIPButton.Add_Click({
	$QIPButton.Enabled = $false
	if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
	$QIPAgentPath = Join-Path -Path $ExtProgramDir -ChildPath "QIPAgent.exe"
	Show-DownloadDialog -DisplayName 'QIP Agent Installer' -Url 'https://qi-host.nyc3.digitaloceanspaces.com/NinjaOne/Installer/NinjaOne%20-%20Agent%20Deploy.exe' -OutputPath "$QIPAgentPath"
	Start-Process $QIPAgentPath
	$QIPButton.Enabled = $true
})

# Define User Data Migration Tool button functions *************

# Define Ninja Removal Script button functions
$QIPRButton.Add_Click({
    $QIPRButton.Enabled = $false
    if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir }
    $QIPRScriptPath = Join-Path -Path $ExtProgramDir -ChildPath "NinjaOneAgentRemoval.ps1"
    Show-DownloadDialog -DisplayName 'Ninja Removal Script' -Url 'https://hatsthings.com/MultitoolFiles/NinjaOneAgentRemoval.ps1' -OutputPath "$QIPRScriptPath"
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$QIPRScriptPath`""
    $QIPRButton.Enabled = $true
})

# Define Windows Disk Cleanup button functions
$DCleanButton.Add_Click({
	$DCleanButton.Enabled = $false
	Log-Message "Starting Windows Disk Cleanup diaglog." "logonly"
	Start-Process -FilePath cleanmgr.exe -Verb RunAs
	$DCleanButton.Enabled = $true
})

# Define back button
$BackButton.Add_Click({
	$ToolsGUI.Hide()
    Show-MainMenu
    $Global:GUIClosed = $true
})

# Catch closes to close program properly
$ToolsGUI.Add_FormClosing({
    param($sender, $e)
    # $e.CloseReason tells you why it's closing
    # UserClosing covers the “X” or Alt-F4
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and $Global:IntClose -ne $true) {
        # Do your “cleanup” or alternate logic here
        $Global:UserExit = $true
		$Global:GUIClosed = $true
    }
})