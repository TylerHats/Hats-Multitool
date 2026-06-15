# Final Setup Options Module - Tyler Hatfield - v1.6

# Create Options GUI
# Prepare form
$FOGUI = New-Object System.Windows.Forms.Form
$FOGUI.Text = "Hat's Multitool"
$FOGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$FOGUI.ClientSize = New-Object System.Drawing.Size(200, 530)
$FOGUI.StartPosition = 'CenterScreen'
$FOGUI.Icon = $HMTIcon
$FOGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$FOGUI.MaximizeBox = $false
$FOGUI.Font = $font
$FOGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$FOGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
Set-DarkTitleBar -TargetForm $FOGUI

# Form size variables
$checkboxHeight = 30    # Height of each checkbox
$buttonHeight = 90      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Adjust GUI Height
$FOGUIHeight = ($buttonHeight * 1) + $labelHeight + ($padding * 7)
$FOGUI.ClientSize = New-Object System.Drawing.Size(600, $FOGUIHeight)
$FOGUI.StartPosition = 'CenterScreen'

# Add descriptive label
$y = 10
$FOlabel = New-Object System.Windows.Forms.Label
$FOlabel.Text = "Select setup options:"
$FOlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$FOlabel.Size = New-Object System.Drawing.Size(260, 20)
$FOlabel.Location = New-Object System.Drawing.Point(15, $y)
$FOlabel.AutoSize = $true
$FOlabel.TextAlign = 'TopLeft'
$FOGUI.Controls.Add($FOlabel)

# Add options list
$y += 35
$FOLV = [System.Windows.Forms.ListView]::new()
$FOLV.View          = 'Details'
$FOLV.CheckBoxes    = $true
$FOLV.FullRowSelect = $true
$FOLV.Scrollable    = $true
$FOLV.BackColor     = [System.Drawing.ColorTranslator]::FromHtml("#3a3c43")
$FOLV.ForeColor     = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$FOLV.Location      = [System.Drawing.Point]::new(25, $y)
$FOLV.Size          = [System.Drawing.Size]::new(550,120)
$FOLV.Columns.Add("Option",530) | Out-Null
$FOGUI.Controls.Add($FOLV)

# Populate List
$FOLV.Items.Clear()
$list = @(
    @{ Option = 'NumLock - Default On for Login and New User Sessions'; ID = 'numlock' },
	@{ Option = 'Disable Windows Default Printer Management'; ID = 'defprint' },
    @{ Option = 'Prevent Automatic Windows Hello PIN Setup at Azure Login'; ID = 'hellopin' }
)
foreach ($u in $list) {
    $item = [System.Windows.Forms.ListViewItem]::new($u.Option)
    $item.Tag = $u.ID
    $FOLV.Items.Add($item)         | Out-Null
}

# Add Okay button
$y += 140
$FOOkayButton = New-Object System.Windows.Forms.Button
$FOOkayButton.Location = New-Object System.Drawing.Point(252, $y)
$FOOkayButton.Size = New-Object System.Drawing.Size(95, 40)
$FOOkayButton.Text = 'OK'
$FOOkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$FOOkayButton.FlatStyle = 'Flat'
$FOOkayButton.FlatAppearance.BorderSize = 1
$FOGUI.Controls.Add($FOOkayButton)
$FOGUI.AcceptButton = $FOOkayButton

# Define a function to handle the Okay button click
$FOOkayButton.Add_Click({
	$FOOkayButton.Enabled = $false
    try {
        foreach ($li in $FOLV.CheckedItems) {
            switch ($li.Tag) {
                'numlock' {
                    # 1. Fix for the Login Screen (SYSTEM Profile)
                    $regPathNumLock = "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard"
                    if (-not (Test-Path $regPathNumLock)) { New-Item -Path $regPathNumLock -Force | Out-Null }
                    
                    # Use Set-ItemProperty to overwrite existing keys without throwing an error
                    Set-ItemProperty -Path $regPathNumLock -Name "InitialKeyboardIndicators" -Value "2" -Type String -Force
                    Log-Message "Enabled NUM Lock on Login Screen." "Success"

                    # 2. Fix for all NEW Users (Default Profile Hive)
                    $defHiveMount = 'HKU\DefUser'
                    $defNtUser    = 'C:\Users\Default\NTUSER.DAT'
                    
                    if (Test-Path $defNtUser) {
                        & reg.exe load $defHiveMount "$defNtUser" | Out-Null
                        try {
                            $defKey = "Registry::$defHiveMount\Control Panel\Keyboard"
                            if (-not (Test-Path $defKey)) { New-Item -Path $defKey -Force | Out-Null }
                            
                            Set-ItemProperty -Path $defKey -Name 'InitialKeyboardIndicators' -Value "2" -Type String -Force
                            Log-Message "Enabled NUM Lock default for new user profiles." "Success"
                        } finally {
                            # Run garbage collection to release file locks before unloading
                            [gc]::Collect() 
                            & reg.exe unload $defHiveMount | Out-Null
                        }
                    } else {
                        Log-Message "Default profile hive not found at $defNtUser" "Error"
                    }
                }
                
                'defprint' {
                    # Set "Let Windows manage my default printer" = OFF for NEW users only
                    $defHiveMount = 'HKU\DefUser'
                    $defNtUser    = 'C:\Users\Default\NTUSER.DAT'
                    $prefKeyRel   = 'Software\Microsoft\Windows NT\CurrentVersion\Windows'

                    if (Test-Path $defNtUser) {
                        & reg.exe load $defHiveMount "$defNtUser" | Out-Null
                        try {
                            $prefKey = "Registry::$defHiveMount\$prefKeyRel"
                            if (-not (Test-Path $prefKey)) { New-Item -Path $prefKey -Force | Out-Null }
                            
                            Set-ItemProperty -Path $prefKey -Name 'LegacyDefaultPrinterMode' -Value 1 -Type DWord -Force
                            Log-Message "Enabled legacy default print management." "Success"
                        } finally {
                            [gc]::Collect()
                            & reg.exe unload $defHiveMount | Out-Null
                        }
                    } else {
                        Log-Message "Default profile hive not found at $defNtUser" "Error"
                    }
                }
                
                'hellopin' {
                    $PassportPath = "Registry::HKLM\SOFTWARE\Policies\Microsoft\PassportForWork"
                    
                    # Fix: Policies keys rarely exist by default. Create it if it's missing!
                    if (-not (Test-Path $PassportPath)) { 
                        New-Item -Path $PassportPath -Force | Out-Null 
                    }
                    
                    # Native PowerShell cmdlets instead of reg.exe
                    Set-ItemProperty -Path $PassportPath -Name "Enabled" -Value 1 -Type DWord -Force
                    Set-ItemProperty -Path $PassportPath -Name "DisablePostLogonProvisioning" -Value 1 -Type DWord -Force
                    
                    Log-Message "Disabled automatic Windows Hello PIN setup prompt." "Success"
                }
            }
        }
    } finally {
        $FOGUI.Close()
    }
})

# Display GUI
$FOGUI.ShowDialog() | Out-Null