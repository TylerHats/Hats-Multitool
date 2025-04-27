# GUI Setup File - Tyler Hatfield - v1.1

# Setup Intro GUI
# Prepare form
Log-Message "Preparing Main Menu..." "Info"
Add-Type -AssemblyName System.Windows.Forms
$MainMenu = New-Object System.Windows.Forms.Form
$MainMenu.Text = "Hat's Multitool"
$MainMenu.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$MainMenu.Size = New-Object System.Drawing.Size(200, 500)
$MainMenu.StartPosition = 'CenterScreen'
$HMTIconPath = Join-Path -Path $PSScriptRoot -ChildPath "HMTIconSmall.ico"
$HMTIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($HMTIconPath)
$MainMenu.Icon = $HMTIcon

# Form size variables
$checkboxHeight = 30    # Height of each checkbox
$buttonHeight = 80      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Adjust GUI Height
$MainMenuHeight = ($buttonHeight * 4) + $padding
$MainMenu.Size = New-Object System.Drawing.Size(300, $MainMenuHeight)
$MainMenu.StartPosition = 'CenterScreen'

# Add Setup button
$y = 45
$MainMenuSetupButton = New-Object System.Windows.Forms.Button
$MainMenuSetupButton.Location = New-Object System.Drawing.Point(80, $y)
$MainMenuSetupButton.Size = New-Object System.Drawing.Size(125, 30)
$MainMenuSetupButton.Text = 'PC Setup and Config'
$MainMenuSetupButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenu.Controls.Add($MainMenuSetupButton)

# Add Tools button
$MainMenuToolsButton = New-Object System.Windows.Forms.Button
$y += 60
$MainMenuToolsButton.Location = New-Object System.Drawing.Point(80, $y)
$MainMenuToolsButton.Size = New-Object System.Drawing.Size(125, 30)
$MainMenuToolsButton.Text = 'Tools'
$MainMenuToolsButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenu.Controls.Add($MainMenuToolsButton)
$MainMenuToolsButton.Enabled = $false # Disabled, WIP
$WIPToolTip = New-Object System.Windows.Forms.ToolTip
$WIPToolTip.SetToolTip($MainMenuToolsButton, "This feature is WIP and will be available in a future update.")

# Add Troubleshooting button
$MainMenuTroubleshootingButton = New-Object System.Windows.Forms.Button
$y += 60
$MainMenuTroubleshootingButton.Location = New-Object System.Drawing.Point(80, $y)
$MainMenuTroubleshootingButton.Size = New-Object System.Drawing.Size(125, 30)
$MainMenuTroubleshootingButton.Text = 'Troubleshooting'
$MainMenuTroubleshootingButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenu.Controls.Add($MainMenuTroubleshootingButton)
$MainMenuTroubleshootingButton.Enabled = $false # Disabled, WIP
$WIPToolTip.SetToolTip($MainMenuTroubleshootingButton, "This feature is WIP and will be available in a future update.")

# Add Account button
$MainMenuAccountButton = New-Object System.Windows.Forms.Button
$y += 60
$MainMenuAccountButton.Location = New-Object System.Drawing.Point(80, $y)
$MainMenuAccountButton.Size = New-Object System.Drawing.Size(125, 30)
$MainMenuAccountButton.Text = 'Account'
$MainMenuAccountButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$MainMenu.Controls.Add($MainMenuAccountButton)
$MainMenuAccountButton.Enabled = $false # Disabled, WIP
$WIPToolTip.SetToolTip($MainMenuAccountButton, "This feature is WIP and will be available in a future update.")

# Define a function to handle the Setup button click
$MainMenuSetupButton.Add_Click({
    # Disable button to prevent further clicks
    $MainMenuSetupButton.Enabled = $false
    # Close and display Setup GUI
	$Global:Show_SetupGUI = $true
    $MainMenu.Close()
})

# Define Tools button click
#WIP

# Define Troubleshooting button click
#WIP

# Define Account button click
#WIP

# Setup Module Selection GUI
# Prepare form
Log-Message "Preparing Module List..." "Info"
$ModGUI = New-Object System.Windows.Forms.Form
$ModGUI.Text = 'Module Selection List'
$ModGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$ModGUI.Size = New-Object System.Drawing.Size(400, 500)
$ModGUI.StartPosition = 'CenterScreen'
$ModGUI.Icon = $HMTIcon

# Form size variables
$checkboxHeight = 30    # Height of each checkbox
$buttonHeight = 80      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Module List Array
$modules = @(
    @{ Name = 'Time Zone Setting' },
	@{ Name = 'Windows Updates' },
    @{ Name = 'Local Account Setup' },
    @{ Name = 'Bloat Cleanup' },
    @{ Name = 'Program Installation' },
    @{ Name = 'System Management' }
)

# Adjust GUI Height
$ModGUIHeight = ($modules.Count * $checkboxHeight) + $buttonHeight + ($padding * 2) + $labelHeight
$ModGUI.Size = New-Object System.Drawing.Size(300, $ModGUIHeight)
$ModGUI.StartPosition = 'CenterScreen'

# Prepare Module Checkboxes
$ModGUIcheckboxes = @{ }
$y = 20
$ModGUIlabel = New-Object System.Windows.Forms.Label
$ModGUIlabel.Text = "Modules:"
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

# Add OK button
$ModGUIokButton = New-Object System.Windows.Forms.Button
$y += 10
$ModGUIokButton.Location = New-Object System.Drawing.Point(100, $y)
$ModGUIokButton.Size = New-Object System.Drawing.Size(75, 30)
$ModGUIokButton.Text = "OK"
$ModGUIokButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModGUI.Controls.Add($ModGUIokButton)

# Define a function to handle the OK button click
$ModGUIokButton.Add_Click({
    # Disable OK button to prevent further clicks
    $ModGUIokButton.Enabled = $false

    # Set module enablement variables
    $selectedModules = $ModGUIcheckboxes.GetEnumerator() | Where-Object { $_.Value.Checked } | ForEach-Object { $_.Key }
    $totalModules = $selectedModules.Count
    if ($totalModules -eq 0) {
        Log-Message "No modules selected to run." "Skip"
        $ModGUI.Close()
        return
    }
    foreach ($moduleName in $selectedModules) {
		Set-Variable -Name ("Run_" + ($moduleName -replace '\s','')) -Value $true -Scope Global
    }
    # Close the form once complete
    $ModGUI.Close()
})