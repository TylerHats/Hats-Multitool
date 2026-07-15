# Accounts Module - Tyler Hatfield - v2.11

# Initialize LocalAccounts module
Import-Module Microsoft.PowerShell.LocalAccounts -ErrorAction SilentlyContinue

$EM_SETCUEBANNER = 0x1501

# Initialize GUI form
$A1GUI = New-Object System.Windows.Forms.Form
$A1GUI.Text = "Hat's Multitool"
$A1GUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$A1GUI.StartPosition = 'CenterScreen'
$A1GUI.Icon = $HMTIcon
$A1GUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$A1GUI.MaximizeBox = $false
$A1GUI.MinimizeBox = $true
$A1GUI.ShowInTaskbar = $true
$A1GUI.Font = $font
$A1GUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$A1GUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $A1GUI

# Add descriptive label
$y = 10
$A1label = New-Object System.Windows.Forms.Label
$A1label.Text = "Enter account information:"
$A1label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$A1label.Size = New-Object System.Drawing.Size(260, 20)
$A1label.Location = New-Object System.Drawing.Point(10, $y)
$A1label.AutoSize = $true
$A1label.TextAlign = 'TopLeft'
$A1GUI.Controls.Add($A1label)

# Parse local password policy
$minPasswordLength = 0
try {
    $netAcc = net accounts
    foreach ($line in $netAcc) {
        if ($line -match "Minimum password length:\s+(\d+)") {
            $minPasswordLength = [int]$matches[1]
        }
    }
} catch {}

$policyText = if ($minPasswordLength -gt 0) { "Local Policy: Minimum Password Length is $minPasswordLength characters." } else { "Local Policy: No password required." }

$y += 20
$PolicyLabel = New-Object System.Windows.Forms.Label
$PolicyLabel.Text = $policyText
$PolicyLabel.ForeColor = if ($minPasswordLength -gt 0) { [System.Drawing.ColorTranslator]::FromHtml("#faa61a") } else { [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0") }
$PolicyLabel.Size = New-Object System.Drawing.Size(260, 20)
$PolicyLabel.Location = New-Object System.Drawing.Point(10, $y)
$PolicyLabel.AutoSize = $true
$PolicyLabel.TextAlign = 'TopLeft'
$A1GUI.Controls.Add($PolicyLabel)

# Add username input 
$y += 35
$UsernameInput = New-Object System.Windows.Forms.TextBox
$UsernameInput.location = New-Object System.Drawing.Point(17, $y)
$UsernameInput.Width = 280
$A1GUI.Controls.Add($UsernameInput)
[HMT.NativeMethods]::SendMessage($UsernameInput.Handle, $EM_SETCUEBANNER, 0, "Username")

# Add password input 
$y += 40
$PasswordInput = New-Object System.Windows.Forms.TextBox
$PasswordInput.location = New-Object System.Drawing.Point(17, $y)
$PasswordInput.Width = 230
$A1GUI.Controls.Add($PasswordInput)
[HMT.NativeMethods]::SendMessage($PasswordInput.Handle, $EM_SETCUEBANNER, 0, "Password")

# Add show password button 
$ShowPWButton = New-Object System.Windows.Forms.Button
$ShowPWButton.Location = New-Object System.Drawing.Point(252, $y)
$ShowPWButton.Size = New-Object System.Drawing.Size(45, 23)
$scaledIconFont = [int](16 * $global:HMTScaleFactor)
$ShowPWButton.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", $scaledIconFont, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$ShowPWButton.Text = [char]0xE052
$ShowPWButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ShowPWButton.FlatStyle = 'Flat'
$ShowPWButton.FlatAppearance.BorderSize = 1
$A1GUI.Controls.Add($ShowPWButton)

# Add password confirm input 
$y += 40
$PasswordConfirmInput = New-Object System.Windows.Forms.TextBox
$PasswordConfirmInput.location = New-Object System.Drawing.Point(17, $y)
$PasswordConfirmInput.Width = 280
$A1GUI.Controls.Add($PasswordConfirmInput)
[HMT.NativeMethods]::SendMessage($PasswordConfirmInput.Handle, $EM_SETCUEBANNER, 0, "Confirm Password")

# Initialize password update CheckBox
$y += 40
$PWCheckbox = New-Object System.Windows.Forms.CheckBox
$PWCheckbox.Location = New-Object System.Drawing.Point(20, $y)
$PWCheckbox.Text = 'Update Password'
$PWCheckbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$PWCheckbox.AutoSize = $true
$A1GUI.Controls.Add($PWCheckbox)

# Make local admin 
$y += 30
$LACheckbox = New-Object System.Windows.Forms.CheckBox
$LACheckbox.Location = New-Object System.Drawing.Point(20, $y)
$LACheckbox.Text = 'Make Local Admin'
$LACheckbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$LACheckbox.AutoSize = $true
$A1GUI.Controls.Add($LACheckbox)

# Add Okay and Skip buttons 
$y += 45
$A1OkayButton = New-Object System.Windows.Forms.Button
$A1OkayButton.Location = New-Object System.Drawing.Point(162, $y)
$A1OkayButton.Size = New-Object System.Drawing.Size(95, 40)
$A1OkayButton.Text = 'OK'
$A1OkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$A1OkayButton.FlatStyle = 'Flat'
$A1OkayButton.FlatAppearance.BorderSize = 1
$A1GUI.Controls.Add($A1OkayButton)
$A1GUI.AcceptButton = $A1OkayButton
$A1OkayButton.Enabled = $false

$A1Skip = New-Object System.Windows.Forms.Button
$A1Skip.Location = New-Object System.Drawing.Point(57, $y)
$A1Skip.Size = New-Object System.Drawing.Size(95, 40)
$A1Skip.Text = 'Skip'
$A1Skip.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$A1Skip.FlatStyle = 'Flat'
$A1Skip.FlatAppearance.BorderSize = 1
$A1GUI.Controls.Add($A1Skip)
$A1GUI.CancelButton = $A1Skip

# Password masking Code
$script:PasswordMaskApplied = $false
$script:ConfirmMaskApplied = $false

$PasswordInput.Add_Enter({
    if (-not $script:PasswordMaskApplied) {
        $PasswordInput.UseSystemPasswordChar = $true
        $script:PasswordMaskApplied = $true
    }
})

$PasswordConfirmInput.Add_Enter({
    if (-not $script:ConfirmMaskApplied) {
        $PasswordConfirmInput.UseSystemPasswordChar = $true
        $script:ConfirmMaskApplied = $true
    }
})

# Show Password Button Logic (Hold to Peek)
$ShowPWButton.Add_MouseDown({
    $PasswordInput.UseSystemPasswordChar = $false
    $PasswordConfirmInput.UseSystemPasswordChar = $false
})

$ShowPWButton.Add_MouseUp({
    if ($script:PasswordMaskApplied) { $PasswordInput.UseSystemPasswordChar = $true }
    if ($script:ConfirmMaskApplied) { $PasswordConfirmInput.UseSystemPasswordChar = $true }
})

$ShowPWButton.Add_MouseLeave({
    if ($script:PasswordMaskApplied) { $PasswordInput.UseSystemPasswordChar = $true }
    if ($script:ConfirmMaskApplied) { $PasswordConfirmInput.UseSystemPasswordChar = $true }
})

# Real-Time Form Validation Scriptblock
$script:ValidateInputs = {
    $userFilled = -not [string]::IsNullOrWhiteSpace($UsernameInput.Text)
    $pwMatch = ($PasswordInput.Text -eq $PasswordConfirmInput.Text)

    if ($userFilled -and $pwMatch) {
        $A1OkayButton.Enabled = $true
    } else {
        $A1OkayButton.Enabled = $false
    }
}

$UsernameInput.Add_TextChanged($script:ValidateInputs)
$PasswordInput.Add_TextChanged($script:ValidateInputs)
$PasswordConfirmInput.Add_TextChanged($script:ValidateInputs)

# Define a function to handle the Okay button click
$A1OkayButton.Add_Click({
    $A1OkayButton.Enabled = $false

    $UExists = Get-LocalUser -Name $UsernameInput.Text -ErrorAction SilentlyContinue

    $SecurePassword = if (-not [string]::IsNullOrEmpty($PasswordInput.Text)) {
        ConvertTo-SecureString $PasswordInput.Text -AsPlainText -Force
    } else {
        $null
    }

    if (-not $UExists) {
        # NEW USER SCENARIO
        try {
            if ($SecurePassword) {
                New-LocalUser -Name $UsernameInput.Text -Password $SecurePassword -ErrorAction Stop | Out-Null
            } else {
                New-LocalUser -Name $UsernameInput.Text -ErrorAction Stop | Out-Null
            }
            Log-Message "Created local user $($UsernameInput.Text)." "Success"
        } catch {
            Log-Message "Exception: $($_.Exception.Message)" "Error"
            PopupError "Failed to create user. Please check log." "Error"
        }
    } else {
        # EXISTING USER SCENARIO
        Log-Message "User $($UsernameInput.Text) already exists." "Skip"

        if ($PWCheckbox.Checked -and $SecurePassword) {
            try {
                Set-LocalUser -Name $UsernameInput.Text -Password $SecurePassword -ErrorAction Stop
                Log-Message "Updated password for user $($UsernameInput.Text)." "Success"
            } catch {
                Log-Message "Exception: $($_.Exception.Message)" "Error"
                PopupError "Failed to update user password. Please check log." "Error"
            }
        } elseif ($PWCheckbox.Checked -and -not $SecurePassword) {
            PopupError "Cannot update password to blank using this method." "Error"
        }
    }

    # Make local admin check
    if ($LACheckbox.Checked) {
        $LocalUserCheck = "$env:COMPUTERNAME\$($UsernameInput.Text)"
        $IsAdmin = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LocalUserCheck }

        if (-not $IsAdmin) {
            Log-Message "Setting local user $($UsernameInput.Text) as local admin." "Info"
            try {
                Add-LocalGroupMember -Group "Administrators" -Member $UsernameInput.Text -ErrorAction Stop
                Log-Message "Successfully elevated $($UsernameInput.Text) to Administrator." "Success"
            } catch {
                Log-Message "Exception: $($_.Exception.Message)" "Error"
                PopupError "Failed to elevate user. Please check log." "Error"
            }
        } else {
            Log-Message "Skipping account elevation, user account is already a local administrator." "Skip"
        }
    }

    # Clean the GUI inputs for the next run
    $UsernameInput.Clear()
    $PasswordInput.Clear()
    $PasswordConfirmInput.Clear()

    $PasswordInput.UseSystemPasswordChar = $false
    $PasswordConfirmInput.UseSystemPasswordChar = $false

    $script:PasswordMaskApplied = $false
    $script:ConfirmMaskApplied = $false

    [HMT.NativeMethods]::SendMessage($UsernameInput.Handle, $EM_SETCUEBANNER, 0, "Username")
    [HMT.NativeMethods]::SendMessage($PasswordInput.Handle, $EM_SETCUEBANNER, 0, "Password")
    [HMT.NativeMethods]::SendMessage($PasswordConfirmInput.Handle, $EM_SETCUEBANNER, 0, "Confirm Password")

    $PWCheckbox.Checked = $false
    $LACheckbox.Checked = $false
    $A1Skip.Text = 'Close'
})

# Define Skip closing function
$A1Skip.Add_Click({
    $A1Skip.Enabled = $false
    $A1GUI.Close()
})

# Set active control to Skip button to preserve cue banners and enable keyboard bypass
$A1GUI.ActiveControl = $A1Skip

# Calculate dynamic layout post-DPI scaling
$A1GUI.Add_Load({
    Invoke-HMTScale $A1GUI
    # Align visibility toggle to password input boundaries
    $ShowPWButton.Height = $PasswordInput.Height
    $ShowPWButton.Top = $PasswordInput.Top
    
    # Calculate dynamic window height
    $w = [int](315 * $global:HMTScaleFactor)
    $p = [int](20 * $global:HMTScaleFactor)
    $A1GUI.ClientSize = [System.Drawing.Size]::new($w, ($A1Skip.Bottom + $p))
})

# Display First GUI
$A1GUI.ShowDialog() | Out-Null