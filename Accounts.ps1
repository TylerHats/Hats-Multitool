# Accounts Module - Tyler Hatfield - v2.1

# Add C method for placeholder text
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class NativeMethods {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern Int32 SendMessage(IntPtr hWnd, int msg, int wParam, string lParam);
}
"@
$EM_SETCUEBANNER = 0x1501

# Prepare form
$A1GUI = New-Object System.Windows.Forms.Form
$A1GUI.Text = "Hat's Multitool"
$A1GUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$A1GUI.Size = New-Object System.Drawing.Size(315, 240)
$A1GUI.StartPosition = 'CenterScreen'
$A1GUI.Icon = $HMTIcon
$A1GUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$A1GUI.MaximizeBox = $false
$A1GUI.Font = $font
$A1GUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font

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

# Add username input
$y += 30
$UsernameInput = New-Object System.Windows.Forms.TextBox
$UsernameInput.location = New-Object System.Drawing.Point(10, $y)
$UsernameInput.Width = 280
$A1GUI.Controls.Add($UsernameInput)
[NativeMethods]::SendMessage($UsernameInput.Handle, $EM_SETCUEBANNER, 0, "Username")

# Add password input
$y += 35
$PasswordInput = New-Object System.Windows.Forms.TextBox
$PasswordInput.location = New-Object System.Drawing.Point(10, $y)
$PasswordInput.Width = 280
$A1GUI.Controls.Add($PasswordInput)
[NativeMethods]::SendMessage($PasswordInput.Handle, $EM_SETCUEBANNER, 0, "Password")

# Update Password Check
$y += 30
$PWCheckbox = New-Object System.Windows.Forms.CheckBox
$PWCheckbox.Location = New-Object System.Drawing.Point(20, $y)
$PWCheckbox.Text = 'Update Password'
$PWCheckbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$PWCheckbox.AutoSize = $true
$A1GUI.Controls.Add($PWCheckbox)

# Make local admin
$y += 25
$LACheckbox = New-Object System.Windows.Forms.CheckBox
$LACheckbox.Location = New-Object System.Drawing.Point(20, $y)
$LACheckbox.Text = 'Make Local Admin'
$LACheckbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$LACheckbox.AutoSize = $true
$A1GUI.Controls.Add($LACheckbox)

# Add Okay button
$y += 30
$A1OkayButton = New-Object System.Windows.Forms.Button
$A1OkayButton.Location = New-Object System.Drawing.Point(160, $y)
$A1OkayButton.Size = New-Object System.Drawing.Size(75, 30)
$A1OkayButton.Text = 'OK'
$A1OkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$A1OkayButton.FlatStyle = 'Flat'
$A1OkayButton.FlatAppearance.BorderSize = 1
$A1GUI.Controls.Add($A1OkayButton)
$A1GUI.AcceptButton = $A1OkayButton
$A1OkayButton.Enabled = $false

# Add Skip button
$A1Skip = New-Object System.Windows.Forms.Button
$A1Skip.Location = New-Object System.Drawing.Point(60, $y)
$A1Skip.Size = New-Object System.Drawing.Size(75, 30)
$A1Skip.Text = 'Skip'
$A1Skip.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$A1Skip.FlatStyle = 'Flat'
$A1Skip.FlatAppearance.BorderSize = 1
$A1GUI.Controls.Add($A1Skip)
$A1GUI.CancelButton = $A1Skip

# Password masking Code
$script:PasswordMaskApplied = $false
$PasswordInput.Add_Enter({
    if (-not $script:PasswordMaskApplied) {
        # turn on masking; OS bullets:
        $PasswordInput.UseSystemPasswordChar = $true
        $script:PasswordMaskApplied = $true
    }
})

# Do not enable Okay until username is not blank
$UsernameInput.Add_TextChanged({
    $A1OkayButton.Enabled = -not [string]::IsNullOrWhiteSpace($UsernameInput.Text)
})

# Define a function to handle the Okay button click
$A1OkayButton.Add_Click({
	$A1OkayButton.Enabled = $false
	if (-not $PWCheckbox.Checked) {
		$UExists = Get-LocalUser -Name "$($UsernameInput.Text)" -ErrorAction SilentlyContinue
		if ($UExists) {
			Log-Message "User exists, skipping creation" "Skip"
		} else {
			try {
				Net User "$($UsernameInput.Text)" "" /add | Out-File -Append -FilePath $logPath
				if($LASTEXITCODE){ throw "net user exit $LASTEXITCODE" }
			} catch {PopupError "Failed to create user, please check log." "Error"}
		}
	} elseif ($PWCheckbox.Checked) {
		$UExists = Get-LocalUser -Name "$($UsernameInput.Text)" -ErrorAction SilentlyContinue
		if ($UExists) {
			try {
				Net User "$($UsernameInput.Text)" "$($PasswordInput.Text)" | Out-File -Append -FilePath $logPath
				if($LASTEXITCODE){ throw "net user exit $LASTEXITCODE" }
			} catch {PopupError "Failed to update user, please check log." "Error"}
		} else {
			try {
				Net User "$($UsernameInput.Text)" "$($PasswordInput.Text)" /add | Out-File -Append -FilePath $logPath
				if($LASTEXITCODE){ throw "net user exit $LASTEXITCODE" }
			} catch {PopupError "Failed to create user, please check log." "Error"}
		}
	}
	if ($LACheckbox.Checked) {
		$LocalUserCheck = "$env:COMPUTERNAME\$($UsernameInput.Text)"
		$IsAdmin = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LocalUserCheck }
		if (-not $IsAdmin) {
			Log-Message "Setting local user $($UsernameInput.Text) as local admin"
			try {
				Net Localgroup Administrators "$($UsernameInput.Text)" /add | Out-File -Append -FilePath $logPath
				if($LASTEXITCODE){ throw "net user exit $LASTEXITCODE" }
			} catch {PopupError "Failed to elevate user, please check log." "Error"}
		} elseif ($IsAdmin) {
			Log-Message "Skipping account elevation, user account is already a local administrator." "Skip"
		}
	}
	$UsernameInput.Clear()
	$PasswordInput.Clear()
	$PasswordInput.UseSystemPasswordChar = $false
	$script:PasswordMaskApplied = $false
	[NativeMethods]::SendMessage($PasswordInput.Handle, $EM_SETCUEBANNER, 0, "Password")
	$PWCheckbox.Checked = $false
	$LACheckbox.Checked = $false
	$A1Skip.Text = 'Close'
})

# Define Skip closing function
$A1Skip.Add_Click({
	$A1Skip.Enabled = $false
	$A1GUI.Close()
})

# Display First GUI
$A1GUI.ShowDialog() | Out-Null