# GUI Setup File - Tyler Hatfield - v2.12

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

# Add Account button
$MainMenuAccountButton = New-Object System.Windows.Forms.Button
$y += 65
$MainMenuAccountButton.Location = New-Object System.Drawing.Point(50, $y)
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
    # Temporarily force the window to draw above everything else OS-wide
    $this.TopMost = $true 
    # Grab the foreground focus
    [HMT.NativeMethods]::SetForegroundWindow($this.Handle) | Out-Null
    $this.Activate()
    $this.BringToFront()
    # Relinquish the top-level overlay status so it behaves like a normal window again
    $this.TopMost = $false 
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

$MainMenu.Add_Load({
    $MainMenu.ClientSize = [System.Drawing.Size]::new(300, ($MainMenuExitButton.Bottom + 30))
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
$AboutGUI.ClientSize = New-Object System.Drawing.Size(320, 380)
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
$AboutTitle.Font = New-Object System.Drawing.Font($font.FontFamily, 16, [System.Drawing.FontStyle]::Bold)
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

# Wrap the window height dynamically in case of scaling
$AboutGUI.Add_Load({
    $AboutGUI.ClientSize = [System.Drawing.Size]::new($AboutGUI.ClientSize.Width, ($AboutCloseBtn.Bottom + 20))
})

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

$ModGUI.Add_Load({
    $ModGUI.ClientSize = [System.Drawing.Size]::new(300, ($ModGUIBackButton.Bottom + 20))
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
$ToolsListView.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#36393f")
$ToolsListView.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ToolsListView.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$ToolsListView.Columns.Add("Tool", 180) | Out-Null
$ToolsListView.Columns.Add("Description", 380) | Out-Null
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

$y += 365
$TLaunchButton = New-Object System.Windows.Forms.Button
$TLaunchButton.Location = New-Object System.Drawing.Point(30, $y)
$TLaunchButton.Size = New-Object System.Drawing.Size(200, 40)
$TLaunchButton.Text = "Launch Selected Tool"
$TLaunchButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TLaunchButton.FlatStyle = 'Flat'
$TLaunchButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($TLaunchButton)

$TBackButton = New-Object System.Windows.Forms.Button
$TBackButton.Location = New-Object System.Drawing.Point(505, $y)
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
    
    switch ($selected) {
        "Hat's User Move Tool" {
            $MoveToolPath = Join-Path -Path $PSScriptRoot -ChildPath "UserMoveTool.ps1"
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy RemoteSigned -WindowStyle Hidden -File `"$MoveToolPath`""
        }
        "McAfee MCPR Tool" {
            if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
            $MCPRPath = Join-Path -Path $ExtProgramDir -ChildPath "MCPR.exe"
            Show-DownloadDialog -DisplayName 'McAfee MCPR Tool' -Url 'https://download.mcafee.com/molbin/iss-loc/SupportTools/MCPR/MCPR.exe' -OutputPath "$MCPRPath"
            Start-Process $MCPRPath
        }
        "Ninja Removal Script" {
            if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
            $NRScriptPath = Join-Path -Path $ExtProgramDir -ChildPath "NinjaOneAgentRemoval.ps1"
            Show-DownloadDialog -DisplayName 'Ninja Removal Script' -Url 'https://hatsthings.com/MultitoolFiles/NinjaOneAgentRemoval.ps1' -OutputPath "$NRScriptPath"
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy RemoteSigned -File `"$NRScriptPath`""
        }
        "Windows Disk Cleanup" {
            Log-Message "Starting Windows Disk Cleanup diaglog." "logonly"
            Start-Process -FilePath cleanmgr.exe -Verb RunAs
        }
        "Patch Cleaner" {
            if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
            $PatchCleanerPath = Join-Path -Path $ExtProgramDir -ChildPath "PatchCleanerPortable.zip"
            Show-DownloadDialog -DisplayName 'Patch Cleaner' -Url 'https://phoenixnap.dl.sourceforge.net/project/patchcleaner/PatchCleaner_Portable/v1.4.2.0/PatchCleanerPortable_1_4_2_0.zip?viasf=1' -OutputPath "$PatchCleanerPath"
            Expand-Archive -LiteralPath $PatchCleanerPath -DestinationPath $ExtProgramDir -Force
            $PatchCleanerExePath = Join-Path -Path $ExtProgramDir -ChildPath "PatchCleanerPortable_1_4_2_0\PatchCleaner\PatchCleaner.exe"
            Start-Process $PatchCleanerExePath
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
            } catch { }
            Show-DownloadDialog -DisplayName 'WizTree' -Url $wizTreeUrl -OutputPath "$WizTreeZipPath"
            Expand-Archive -LiteralPath $WizTreeZipPath -DestinationPath $ExtProgramDir -Force
            $WizTreeExePath = Join-Path -Path $ExtProgramDir -ChildPath "WizTree64.exe"
            Start-Process $WizTreeExePath
        }
        "BleachBit" {
            if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
            $BleachZipPath = Join-Path -Path $ExtProgramDir -ChildPath "BleachBit.zip"
            $bbUrl = 'https://download.bleachbit.org/BleachBit-5.0.0-portable.zip'
            try {
                $bbPage = Invoke-WebRequest -Uri "https://www.bleachbit.org/download/windows" -UseBasicParsing -ErrorAction Stop
                if ($bbPage.Content -match 'href="(https://download\.bleachbit\.org/[^"]+portable\.zip)"') {
                    $bbUrl = $matches[1]
                }
            } catch { }
            Show-DownloadDialog -DisplayName 'BleachBit' -Url $bbUrl -OutputPath "$BleachZipPath"
            Expand-Archive -LiteralPath $BleachZipPath -DestinationPath $ExtProgramDir -Force
            $BleachExePath = Join-Path -Path $ExtProgramDir -ChildPath "BleachBit-Portable\bleachbit.exe"
            Start-Process $BleachExePath
        }
        "BlueScreenView" {
            if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
            $BSVZipPath = Join-Path -Path $ExtProgramDir -ChildPath "BSV.zip"
            Show-DownloadDialog -DisplayName 'BlueScreenView' -Url 'https://www.nirsoft.net/utils/bluescreenview-x64.zip' -OutputPath "$BSVZipPath"
            Expand-Archive -LiteralPath $BSVZipPath -DestinationPath $ExtProgramDir -Force
            $BSVExePath = Join-Path -Path $ExtProgramDir -ChildPath "BlueScreenView.exe"
            Start-Process $BSVExePath
        }
        "User Profile Wizard" {
            if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
            $UPWPath = Join-Path -Path $ExtProgramDir -ChildPath "UserProfileWiz.msi"
            Show-DownloadDialog -DisplayName 'User Profile Wizard' -Url 'https://www.forensit.com/Downloads/Profwiz.msi' -OutputPath "$UPWPath"
            Start-Process $UPWPath
        }
        "Little Registry Cleaner" {
            if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
            $LRCPath = Join-Path -Path $ExtProgramDir -ChildPath "LRC.zip"
            Show-DownloadDialog -DisplayName 'Little Registry Cleaner' -Url 'https://github.com/little-apps/LittleRegistryCleaner/releases/download/1.6/Little_Registry_Cleaner_Portable_Edition_06_28_2013.zip' -OutputPath "$LRCPath"
            Expand-Archive -LiteralPath $LRCPath -DestinationPath $ExtProgramDir -Force
            $LRCEPath = Join-Path -Path $ExtProgramDir -ChildPath "Little Registry Cleaner.exe"
            Start-Process $LRCEPath
        }
        "DISM++" {
            if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
            $DISMPPPath = Join-Path -Path $ExtProgramDir -ChildPath "DISMPP.zip"
            $dismUrl = 'https://github.com/Chuyu-Team/Dism-Multi-language/releases/download/v10.1.1002.2/Dism++10.1.1002.1B.zip'
            try {
                $ghJson = Invoke-RestMethod -Uri "https://api.github.com/repos/Chuyu-Team/Dism-Multi-language/releases/latest" -ErrorAction Stop
                $ghAsset = $ghJson.assets | Where-Object { $_.name -match 'Dism.*\.zip' } | Select-Object -First 1
                if ($ghAsset.browser_download_url) { $dismUrl = $ghAsset.browser_download_url }
            } catch { }
            Show-DownloadDialog -DisplayName 'DISM++' -Url $dismUrl -OutputPath "$DISMPPPath"
            Expand-Archive -LiteralPath $DISMPPPath -DestinationPath $ExtProgramDir -Force
            $DISMPPEPath = Join-Path -Path $ExtProgramDir -ChildPath "Dism++x64.exe"
            Start-Process $DISMPPEPath
        }
        ".NET 3.5 (Includes v2 and v3)" {
            Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy RemoteSigned", "-Command Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart" -Verb RunAs
        }
        "Display Driver Uninstaller" {
            if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
            $DDUPath = Join-Path -Path $ExtProgramDir -ChildPath "DDU.zip"
            Show-DownloadDialog -DisplayName 'Display Driver Uninstaller' -Url 'https://download-eu2.guru3d.com/ddu/%5BGuru3D%5D-DDU.zip' -OutputPath "$DDUPath"
            Expand-Archive -LiteralPath $DDUPath -DestinationPath $ExtProgramDir -Force
            $DDUEPath = Join-Path -Path $ExtProgramDir -ChildPath "DDU v18.1.1.5.exe"
            Start-Process $DDUEPath
        }
        "HDDScan" {
            if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
            $HDDSPath = Join-Path -Path $ExtProgramDir -ChildPath "HDDS.zip"
            Show-DownloadDialog -DisplayName 'HDDScan' -Url 'https://hddscan.com/download/HDDScan.zip' -OutputPath "$HDDSPath"
            Expand-Archive -LiteralPath $HDDSPath -DestinationPath $ExtProgramDir -Force
            $HDDSEPath = Join-Path -Path $ExtProgramDir -ChildPath "HDDScan.exe"
            Start-Process $HDDSEPath
        }
        "Win11 Upgrade Assistant" {
            if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
            $W11APath = Join-Path -Path $ExtProgramDir -ChildPath "W11UA.exe"
            Show-DownloadDialog -DisplayName 'Win11 Upgrade Asisstant' -Url 'https://download.microsoft.com/download/6/8/3/683178b7-baac-4b0d-95be-065a945aadee/Windows11InstallationAssistant.exe' -OutputPath "$W11APath"
            Start-Process $W11APath
        }
        "Crystal Disk Mark" {
            if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
            $CDMPath = Join-Path -Path $ExtProgramDir -ChildPath "CDM.zip"
            $cdmUrl = 'https://gigenet.dl.sourceforge.net/project/crystaldiskmark/9.0.1/CrystalDiskMark9_0_1.zip?viasf=1'
            try {
                $sfJson = Invoke-RestMethod -Uri "https://sourceforge.net/projects/crystaldiskmark/best_release.json" -ErrorAction Stop
                if ($sfJson.release.url) { $cdmUrl = $sfJson.release.url }
            } catch { }
            Show-DownloadDialog -DisplayName 'Crystal Disk Mark' -Url $cdmUrl -OutputPath "$CDMPath"
            Expand-Archive -LiteralPath $CDMPath -DestinationPath $ExtProgramDir -Force
            $CDMEPath = Join-Path -Path $ExtProgramDir -ChildPath "DiskMark64.exe"
            Start-Process $CDMEPath
        }
        "Crystal Disk Info" {
            if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
            $CDIPath = Join-Path -Path $ExtProgramDir -ChildPath "CDI.zip"
            $cdiUrl = 'https://cytranet-dal.dl.sourceforge.net/project/crystaldiskinfo/9.7.0/CrystalDiskInfo9_7_0.zip?viasf=1'
            try {
                $sfJson = Invoke-RestMethod -Uri "https://sourceforge.net/projects/crystaldiskinfo/best_release.json" -ErrorAction Stop
                if ($sfJson.release.url) { $cdiUrl = $sfJson.release.url }
            } catch { }
            Show-DownloadDialog -DisplayName 'Crystal Disk Info' -Url $cdiUrl -OutputPath "$CDIPath"
            Expand-Archive -LiteralPath $CDIPath -DestinationPath $ExtProgramDir -Force
            $CDIEPath = Join-Path -Path $ExtProgramDir -ChildPath "DiskInfo64.exe"
            Start-Process $CDIEPath
        }
    }
    
    $TLaunchButton.Enabled = $true
})

$TBackButton.Add_Click({
    $ToolsGUI.Hide()
})

$ToolsGUI.Add_Load({
    $ToolsGUI.ClientSize = [System.Drawing.Size]::new(650, ($TBackButton.Bottom + 20))
})

# Catch closes to close program properly
$ToolsGUI.Add_FormClosing({
    param($sender, $e)
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
$y += 30

# Add ListView
$TrListView = New-Object System.Windows.Forms.ListView
$TrListView.Location = New-Object System.Drawing.Point(30, $y)
$TrListView.Size = New-Object System.Drawing.Size(590, 250)
$TrListView.View = [System.Windows.Forms.View]::Details
$TrListView.FullRowSelect = $true
$TrListView.GridLines = $false
$TrListView.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::Nonclickable
$TrListView.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#36393f")
$TrListView.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TrListView.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$TrListView.Columns.Add("Tool", 180) | Out-Null
$TrListView.Columns.Add("Description", 380) | Out-Null
$TroubleGUI.Controls.Add($TrListView)

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
)

foreach ($t in $troubleList) {
    $item = New-Object System.Windows.Forms.ListViewItem($t.Name)
    $item.SubItems.Add($t.Desc) | Out-Null
    $TrListView.Items.Add($item) | Out-Null
}

$y += 265
$TrLaunchButton = New-Object System.Windows.Forms.Button
$TrLaunchButton.Location = New-Object System.Drawing.Point(30, $y)
$TrLaunchButton.Size = New-Object System.Drawing.Size(200, 40)
$TrLaunchButton.Text = "Launch Selected Tool"
$TrLaunchButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TrLaunchButton.FlatStyle = 'Flat'
$TrLaunchButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($TrLaunchButton)

$ConsoleButton = New-Object System.Windows.Forms.Button
$ConsoleButton.Location = New-Object System.Drawing.Point(375, $y)
$ConsoleButton.Size = New-Object System.Drawing.Size(115, 40)
$ConsoleButton.Text = "Show Console"
$ConsoleButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ConsoleButton.FlatStyle = 'Flat'
$ConsoleButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($ConsoleButton)
$script:ConsoleClicked = 0

$BackButton = New-Object System.Windows.Forms.Button
$BackButton.Location = New-Object System.Drawing.Point(505, $y)
$BackButton.Size = New-Object System.Drawing.Size(115, 40)
$BackButton.Text = "Back"
$BackButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$BackButton.FlatStyle = 'Flat'
$BackButton.FlatAppearance.BorderSize = 1
$TroubleGUI.Controls.Add($BackButton)

$TrListView.Add_DoubleClick({ $TrLaunchButton.PerformClick() })

$TrLaunchButton.Add_Click({
    if ($TrListView.SelectedItems.Count -eq 0) { return }
    $selected = $TrListView.SelectedItems[0].Text
    $TrLaunchButton.Enabled = $false
    
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
    }
    
    $TrLaunchButton.Enabled = $true
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
    $TroubleGUI.ClientSize = [System.Drawing.Size]::new(650, ($BackButton.Bottom + 20))
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
