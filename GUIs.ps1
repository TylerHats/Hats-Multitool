# GUI Setup File - Tyler Hatfield - v2.2

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
$font = New-Object System.Drawing.Font("Segoe UI", 10)
$MainMenu.Font = $font
$MainMenu.AutoScaleMode = [Windows.Forms.AutoScaleMode]::Dpi

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
$MainMenuTroubleshootingButton.Enabled = $false # Disabled, WIP

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
#WIP

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
$ModGUI.AutoScaleMode = [Windows.Forms.AutoScaleMode]::Dpi

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
$ReminderPopup.AutoScaleMode = [Windows.Forms.AutoScaleMode]::Dpi

# Form size variables
$buttonHeight = 80      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Adjust GUI Height
$y = 20
$ReminderPopupHeight = $buttonHeight + ($padding * 1) + ($labelHeight * 2)
$ReminderPopup.Size = New-Object System.Drawing.Size(700, $ReminderPopupHeight)
$ReminderPopup.StartPosition = 'CenterScreen'

# Add popup Text
$ReminderPopuplabel = New-Object System.Windows.Forms.Label
$ReminderPopuplabel.Text = "The multitool run has completed!`nPlease check for any background windows and reboot if needed to finalize changes. Press OK to exit."
$ReminderPopuplabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ReminderPopuplabel.Location = New-Object System.Drawing.Point(30, $y)
$ReminderPopuplabel.AutoSize = $true
$ReminderPopuplabel.TextAlign = 'TopCenter'
$ReminderPopuplabel.Width = 650
$ReminderPopuplabel.Height = 80
$ReminderPopuplabel.MaximumSize = '650,0'
$ReminderPopup.Controls.Add($ReminderPopuplabel)
$y += $labelHeight

# Add OK button
$ReminderPopupokButton = New-Object System.Windows.Forms.Button
$y += 20
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
$ToolsGUI.AutoScaleMode = [Windows.Forms.AutoScaleMode]::Dpi
$ExtProgramDir = Join-Path -Path $PSScriptRoot -ChildPath "ExtPrograms"

# Form size variables
$buttonHeight = 80      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Adjust GUI Height
$y = 20
$ToolsGUIHeight = ($buttonHeight * 3) + ($padding * 0) + ($labelHeight * 1)
$ToolsGUI.Size = New-Object System.Drawing.Size(400, $ToolsGUIHeight)
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
$UserDataButton.Location = New-Object System.Drawing.Point(110, $y)
$UserDataButton.Size = New-Object System.Drawing.Size(170, 40)
$UserDataButton.Text = "User Data Migration"
$UserDataButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$UserDataButton.FlatStyle = 'Flat'
$UserDataButton.FlatAppearance.BorderSize = 1
$UserDataButton.Enabled = $false
$ToolsGUI.Controls.Add($UserDataButton)

# Add QIP Agent Deployment button
$QIPButton = New-Object System.Windows.Forms.Button
$y += 50
$QIPButton.Location = New-Object System.Drawing.Point(110, $y)
$QIPButton.Size = New-Object System.Drawing.Size(170, 40)
$QIPButton.Text = "QIP Agent Deployment"
$QIPButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$QIPButton.FlatStyle = 'Flat'
$QIPButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($QIPButton)

# Add back button
$BackButton = New-Object System.Windows.Forms.Button
$y += 50
$BackButton.Location = New-Object System.Drawing.Point(160, $y)
$BackButton.Size = New-Object System.Drawing.Size(75, 40)
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
	Try {
		Invoke-WebRequest -Uri 'https://qi-host.nyc3.digitaloceanspaces.com/NinjaOne/Installer/NinjaOne%20-%20Agent%20Deploy.exe' -OutFile $QIPAgentPath *>&1
	} catch {
		[System.Windows.Forms.MessageBox]::Show("Download failed, please try again.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
	}
	Start-Process $QIPAgentPath
	$QIPButton.Enabled = $true
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