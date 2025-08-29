# Final Setup Options Module - Tyler Hatfield - v1

# Create Options GUI
# Prepare form
$FOGUI = New-Object System.Windows.Forms.Form
$FOGUI.Text = "Hat's Multitool"
$FOGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$FOGUI.Size = New-Object System.Drawing.Size(200, 500)
$FOGUI.StartPosition = 'CenterScreen'
$FOGUI.Icon = $HMTIcon
$FOGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$FOGUI.MaximizeBox = $false
$FOGUI.Font = $font
$FOGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font

# Form size variables
$checkboxHeight = 30    # Height of each checkbox
$buttonHeight = 80      # Height of the OK button
$labelHeight = 30       # Height of text labels
$padding = 20

# Adjust GUI Height
$FOGUIHeight = ($buttonHeight * 1) + $labelHeight + ($padding * 8)
$FOGUI.Size = New-Object System.Drawing.Size(600, $FOGUIHeight)
$FOGUI.StartPosition = 'CenterScreen'

# Add descriptive label
$y = 10
$FOlabel = New-Object System.Windows.Forms.Label
$FOlabel.Text = "Select setup options:"
$FOlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$FOlabel.Size = New-Object System.Drawing.Size(260, 20)
$FOlabel.Location = New-Object System.Drawing.Point(10, $y)
$FOlabel.AutoSize = $true
$FOlabel.TextAlign = 'TopLeft'
$FOGUI.Controls.Add($FOlabel)

# Add options list
$y += 35
$FOLV = [System.Windows.Forms.ListView]::new()
$FOLV.View          = 'Details'
$FOLV.CheckBoxes    = $true
$FOLV.FullRowSelect = $true
$FOLV.Scrollable    = $false
$FOLV.BackColor     = [System.Drawing.ColorTranslator]::FromHtml("#3a3c43")
$FOLV.ForeColor     = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$FOLV.Location      = [System.Drawing.Point]::new(20, $y)
$FOLV.Size          = [System.Drawing.Size]::new(540,90)
$FOLV.Columns.Add("Option",560) | Out-Null
$FOGUI.Controls.Add($FOLV)

# Populate List
$FOLV.Items.Clear()
$list = @(
    @{ Option = 'NumLock - Default On for Login'; ID = 'numlock' },
	@{ Option = 'Disable Windows Default Printer Management'; ID = 'defprint' }
)
foreach ($u in $list) {
    $item = [System.Windows.Forms.ListViewItem]::new($u.Option)
    $item.Tag = $u.ID
    $FOLV.Items.Add($item)         | Out-Null
}

# Add Okay button
$y += 110
$FOOkayButton = New-Object System.Windows.Forms.Button
$FOOkayButton.Location = New-Object System.Drawing.Point(250, $y)
$FOOkayButton.Size = New-Object System.Drawing.Size(75, 30)
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
                    $regPathNumLock = "Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard"
	                if (Test-Path $regPathNumLock) {
	                	# Set the InitialKeyboardIndicators value to 2147483650 (Enables numlock by default)
	                	New-ItemProperty -PropertyType String -Path $regPathNumLock -Name "InitialKeyboardIndicators" -Value "2147483650"
	                	Log-Message "Enabled NUM Lock at boot by default." "Success"
	                	Write-Host ""
	                } else {
	                	Log-Message "Registry path $regPathNumLock does not exist." "Error"
	                	Write-Host ""
	                }
                    $defHiveMount = 'HKU\DefUser'
                    $defNtUser    = 'C:\Users\Default\NTUSER.DAT'
                    if (Test-Path $defNtUser) {
                        & reg.exe load $defHiveMount "$defNtUser" | Out-Null
                        try {
                            New-Item -Path "Registry::$defHiveMount\Control Panel" -Name 'Keyboard' -Force | Out-Null
                            New-ItemProperty -Path "Registry::$defHiveMount\Control Panel\Keyboard" `
                            -Name 'InitialKeyboardIndicators' -Value '2147483650' -PropertyType String -Force | Out-Null
                        } finally {
                            & reg.exe unload $defHiveMount | Out-Null
                        }
                    }
                }
                'defprint' {
                    # Set "Let Windows manage my default printer" = OFF for NEW users only
                    $defHiveMount = 'HKU\DefUser'
                    $defNtUser    = 'C:\Users\Default\NTUSER.DAT'
                    $prefKeyRel   = 'Software\Microsoft\Windows NT\CurrentVersion\Windows'

                    if (Test-Path $defNtUser) {
                        # Load Default profile hive
                        & reg.exe load $defHiveMount "$defNtUser" | Out-Null
                        try {
                            $prefKey = "Registry::$defHiveMount\$prefKeyRel"
                            if (-not (Test-Path $prefKey)) { New-Item -Path $prefKey -Force | Out-Null }
                            New-ItemProperty -Path $prefKey -Name 'LegacyDefaultPrinterMode' -Value 1 -PropertyType DWord -Force | Out-Null
                            Log-Message "Enabled legacy default print management." "Success"
                        } finally {
                            & reg.exe unload $defHiveMount | Out-Null
                        }
                    } else {
                        Log-Message "Default profile hive not found at $defNtUser" "Error"
                    }
                }
            }
        }
    } finally {
        $FOGUI.Close()
    }
})

# Display GUI
$FOGUI.ShowDialog() | Out-Null