# Final Setup Options Module - Tyler Hatfield - v1.8

# Create Options GUI
# Prepare form
$FOGUI = New-Object System.Windows.Forms.Form
$FOGUI.Text = "Hat's Multitool"
$FOGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$FOGUI.ClientSize = New-Object System.Drawing.Size(600, 300)
$FOGUI.StartPosition = 'CenterScreen'
$FOGUI.Icon = $HMTIcon
$FOGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$FOGUI.MaximizeBox = $false
$FOGUI.MinimizeBox = $true
$FOGUI.ShowInTaskbar = $true
$FOGUI.Font = $font
$FOGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$FOGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $FOGUI

# Form size variables
$padding = 20

# Add descriptive label
$y = 10
$FOlabel = New-Object System.Windows.Forms.Label
$FOlabel.Text = "Select setup options:"
$FOlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$FOlabel.Size = New-Object System.Drawing.Size(260, 20)
$FOlabel.Location = New-Object System.Drawing.Point($padding, $y)
$FOlabel.AutoSize = $true
$FOlabel.TextAlign = 'TopLeft'
$FOGUI.Controls.Add($FOlabel)

# Add options list
$y += 35
$FOLV = [System.Windows.Forms.ListView]::new()
$FOLV.View = 'Details'
$FOLV.CheckBoxes = $true
$FOLV.FullRowSelect = $true
$FOLV.Scrollable = $true
$FOLV.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3a3c43")
$FOLV.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$FOLV.Location = [System.Drawing.Point]::new($padding, $y)
$FOLV.HeaderStyle = 'None'
# Calculate ListView width dynamically: Form Width minus padding on left and right
$lvWidth = $FOGUI.ClientSize.Width - ($padding * 2)
$FOLV.Size = [System.Drawing.Size]::new($lvWidth, 120)
$FOLV.Columns.Add("Option", ($lvWidth - 5)) | Out-Null
$FOGUI.Controls.Add($FOLV)

# Populate List
$FOLV.Items.Clear()
$list = @(
    @{ Option = 'NumLock - Default On for Login and New User Sessions'; ID = 'numlock' },
    @{ Option = 'Disable Windows Default Printer Management'; ID = 'defprint' },
    @{ Option = 'Restore Classic Windows 11 Right-Click Context Menu'; ID = 'classicmenu' },
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
$FOOkayButton.Size = New-Object System.Drawing.Size(95, 40)
$FOOkayButton.Top = $y
$FOOkayButton.Text = 'OK'
$FOOkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$FOOkayButton.FlatStyle = 'Flat'
$FOOkayButton.FlatAppearance.BorderSize = 1
$FOGUI.Controls.Add($FOOkayButton)
$FOGUI.AcceptButton = $FOOkayButton

# Fix Scaling and Layout Dynamically
$FOGUI.Add_Load({
        Invoke-HMTScale $FOGUI
        Set-RoundedControl $FOOkayButton
        $p = [int]($padding * $global:HMTScaleFactor)
        $lvScaledWidth = $FOGUI.ClientSize.Width - ($p * 2)
        $FOLV.Width = $lvScaledWidth
        $FOLV.Columns[0].Width = $lvScaledWidth - 5
        $FOOkayButton.Left = ($FOGUI.ClientSize.Width - $FOOkayButton.Width) / 2
        $FOGUI.ClientSize = [System.Drawing.Size]::new($FOGUI.ClientSize.Width, ($FOOkayButton.Bottom + $p))
    })


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
                    
                        Set-ItemProperty -Path $regPathNumLock -Name "InitialKeyboardIndicators" -Value "2" -Type String -Force
                        Log-Message "Enabled NUM Lock on Login Screen." "Success"

                        # 2. Fix for all NEW Users (Default Profile Hive)
                        $defNtUser = 'C:\Users\Default\NTUSER.DAT'
                    
                        if (Test-Path $defNtUser) {
                            & reg.exe load "HKU\DefUser" "$defNtUser" | Out-Null
                            try {
                                # Using reg.exe natively avoids the .NET file handle locks entirely
                                & reg.exe add "HKU\DefUser\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f | Out-Null
                                Log-Message "Enabled NUM Lock default for new user profiles." "Success"
                            } finally {
                                # Clean unload guaranteed because no PS paths were opened
                                & reg.exe unload "HKU\DefUser" | Out-Null
                            }
                        }
                        else {
                            Log-Message "Default profile hive not found at $defNtUser" "Error"
                        }
                    }
                
                    'defprint' {
                        # 1. Fix System Policy (HKLM - System-wide)
                        $hklmPrintPath = 'Registry::HKLM\SOFTWARE\Policies\Microsoft\Windows NT\Printers'
                        if (-not (Test-Path $hklmPrintPath)) { New-Item -Path $hklmPrintPath -Force | Out-Null }
                        Set-ItemProperty -Path $hklmPrintPath -Name 'LegacyDefaultPrinterMode' -Value 1 -Type DWord -Force

                        # 2. Fix CURRENT User (HKCU)
                        $hkcuPrintPath = 'Registry::HKCU\Software\Microsoft\Windows NT\CurrentVersion\Windows'
                        if (-not (Test-Path $hkcuPrintPath)) { New-Item -Path $hkcuPrintPath -Force | Out-Null }
                        Set-ItemProperty -Path $hkcuPrintPath -Name 'LegacyDefaultPrinterMode' -Value 1 -Type DWord -Force

                        # 3. Fix NEW Users (Default Profile Hive)
                        $defNtUser = 'C:\Users\Default\NTUSER.DAT'
                        if (Test-Path $defNtUser) {
                            & reg.exe load "HKU\DefUser" "$defNtUser" | Out-Null
                            try {
                                & reg.exe add "HKU\DefUser\Software\Microsoft\Windows NT\CurrentVersion\Windows" /v "LegacyDefaultPrinterMode" /t REG_DWORD /d 1 /f | Out-Null
                                Log-Message "Disabled automatic printer management for new user profiles." "Success"
                            } finally {
                                & reg.exe unload "HKU\DefUser" | Out-Null
                            }
                        }
                        else {
                            Log-Message "Default profile hive not found at $defNtUser" "Error"
                        }
                        Log-Message "Disabled automatic Windows default printer management." "Success"
                    }

                    'classicmenu' {
                        # 1. Apply to HKCU
                        $clsidPath = "Registry::HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
                        if (-not (Test-Path $clsidPath)) { New-Item -Path $clsidPath -Force | Out-Null }
                        Set-ItemProperty -Path $clsidPath -Name "(Default)" -Value "" -Type String -Force

                        # 2. Apply to Default Profile Hive (New Users)
                        $defNtUser = 'C:\Users\Default\NTUSER.DAT'
                        if (Test-Path $defNtUser) {
                            & reg.exe load "HKU\DefUser" "$defNtUser" | Out-Null
                            try {
                                & reg.exe add "HKU\DefUser\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f | Out-Null
                                Log-Message "Restored classic context menu for new user profiles." "Success"
                            } finally {
                                & reg.exe unload "HKU\DefUser" | Out-Null
                            }
                        }
                        Log-Message "Restored classic Windows 11 right-click context menu." "Success"
                    }
                
                    'hellopin' {
                        $PassportPath = "Registry::HKLM\SOFTWARE\Policies\Microsoft\PassportForWork"
                    
                        if (-not (Test-Path $PassportPath)) { New-Item -Path $PassportPath -Force | Out-Null }
                    
                        # Set Enabled = 0 to completely disable Windows Hello for Business
                        Set-ItemProperty -Path $PassportPath -Name "Enabled" -Value 0 -Type DWord -Force
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
Show-HMTDialog $FOGUI | Out-Null