# System Management Module - Tyler Hatfield - v2.8

$EM_SETCUEBANNER = 0x1501

# Determine if Windows edition is domain/EntraID joinable
$IsPro = if ($WindowsEdition -match 'Pro|Enterprise') { 1 } else { 0 }

# Prepare form
$SMGUI = New-Object System.Windows.Forms.Form
$SMGUI.Text = "Hat's Multitool"
$SMGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$SMGUI.ClientSize = New-Object System.Drawing.Size(315, 265)
$SMGUI.StartPosition = 'CenterScreen'
$SMGUI.Icon = $HMTIcon
$SMGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$SMGUI.MaximizeBox = $false
$SMGUI.Font = $font
$SMGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$SMGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
Set-DarkTitleBar -TargetForm $SMGUI

# Add descriptive label
$y = 10
$SMlabel = New-Object System.Windows.Forms.Label
$SMlabel.Text = "Enter new device name:"
$SMlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SMlabel.Size = New-Object System.Drawing.Size(300, 20)
$SMlabel.Location = New-Object System.Drawing.Point(10, $y)
$SMlabel.AutoSize = $true
$SMlabel.TextAlign = 'TopLeft'
$SMGUI.Controls.Add($SMlabel)

# Add descriptive label 2nd line
$y = 30
$SMlabel = New-Object System.Windows.Forms.Label
$SMlabel.Text = "(Currently: $env:computername)"
$SMlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SMlabel.Size = New-Object System.Drawing.Size(300, 20)
$SMlabel.Location = New-Object System.Drawing.Point(10, $y)
$SMlabel.AutoSize = $true
$SMlabel.TextAlign = 'TopLeft'
$SMGUI.Controls.Add($SMlabel)

# Add serial number label
$y += 20
$SerialLabel = New-Object System.Windows.Forms.Label
$SerialLabel.Text = "Serial Number: $serialNumber"
$SerialLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SerialLabel.Size = New-Object System.Drawing.Size(300, 20)
$SerialLabel.Location = New-Object System.Drawing.Point(10, $y)
$SerialLabel.AutoSize = $true
$SerialLabel.TextAlign = 'TopLeft'
$SerialLabel.Cursor = [Windows.Forms.Cursors]::Hand
$SMGUI.Controls.Add($SerialLabel)

# Add PC name input
$y += 30
$PCNameInput = New-Object System.Windows.Forms.TextBox
$PCNameInput.location = New-Object System.Drawing.Point(10, $y)
$PCNameInput.Width = 280
$PCNameInput.MaxLength = 15
$SMGUI.Controls.Add($PCNameInput)
[HMT.NativeMethods]::SendMessage($PCNameInput.Handle, $EM_SETCUEBANNER, 1, "Computer Name")

# Add domain Check
$y += 30
$DomainCheckbox = New-Object System.Windows.Forms.CheckBox
$DomainCheckbox.Location = New-Object System.Drawing.Point(20, $y)
$DomainCheckbox.Text = 'Join to Domain'
$DomainCheckbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$DomainCheckbox.AutoSize = $true
if ($IsPro -eq 1) {
	$DomainCheckbox.Enabled = $true
} else {
	$DomainCheckbox.Enabled = $false
}
$SMGUI.Controls.Add($DomainCheckbox)

# Make Entra check
$y += 25
$EntraCheckbox = New-Object System.Windows.Forms.CheckBox
$EntraCheckbox.Location = New-Object System.Drawing.Point(20, $y)
$EntraCheckbox.Text = 'Join to EntraID'
$EntraCheckbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$EntraCheckbox.AutoSize = $true
if ($IsPro -eq 1) {
	$EntraCheckbox.Enabled = $true
} else {
	$EntraCheckbox.Enabled = $false
}
$SMGUI.Controls.Add($EntraCheckbox)

# Add domain name input
$y += 30
$DomainNameInput = New-Object System.Windows.Forms.TextBox
$DomainNameInput.location = New-Object System.Drawing.Point(10, $y)
$DomainNameInput.Width = 280
$DomainNameInput.Enabled = $false
$SMGUI.Controls.Add($DomainNameInput)
[HMT.NativeMethods]::SendMessage($DomainNameInput.Handle, $EM_SETCUEBANNER, 1, "Domain Name")

# Add Okay button
$y += 40
$SMOkayButton = New-Object System.Windows.Forms.Button
$SMOkayButton.Location = New-Object System.Drawing.Point(162, $y)
$SMOkayButton.Size = New-Object System.Drawing.Size(95, 40)
$SMOkayButton.Text = 'OK'
$SMOkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SMOkayButton.FlatStyle = 'Flat'
$SMOkayButton.FlatAppearance.BorderSize = 1
$SMOkayButton.Enabled = $false
$SMGUI.Controls.Add($SMOkayButton)
$SMGUI.AcceptButton = $SMOkayButton

# Add Skip button
$SMSkip = New-Object System.Windows.Forms.Button
$SMSkip.Location = New-Object System.Drawing.Point(57, $y)
$SMSkip.Size = New-Object System.Drawing.Size(95, 40)
$SMSkip.Text = 'Skip'
$SMSkip.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SMSkip.FlatStyle = 'Flat'
$SMSkip.FlatAppearance.BorderSize = 1
$SMGUI.Controls.Add($SMSkip)
$SMGUI.CancelButton = $SMSkip

# Make serial number click to copy
$SerialLabel.Add_Click({
    [Windows.Forms.Clipboard]::SetText($serialNumber)
    $tip = New-Object Windows.Forms.ToolTip
    $tip.Show('Copied!', $SerialLabel, 0, -20, 1200)
})

# Limit PC names to acceptable Windows NetBIOS names
$PCNameInput.Add_KeyPress({
    param($s,$e)
    $ch = $e.KeyChar
    # Allow all control keys (Enter, Backspace, Ctrl+C/V/X/A, etc.)
    if ([char]::IsControl($ch)) { return }
    # Allow only A–Z, a–z, 0–9, hyphen
    if ($ch -notmatch '[A-Za-z0-9-]') { $e.Handled = $true }
})
function Test-ComputerName([string]$name) {
    if ([string]::IsNullOrEmpty($name)) { return $false }
    # 1–15 chars; start & end alnum; middle alnum or '-'; not all digits
    return ($name -match '^(?!\d+$)[A-Za-z0-9](?:[A-Za-z0-9-]{0,13}[A-Za-z0-9])?$')
}

# Add an event handler for the domain checkbox:
$DomainCheckbox.Add_CheckedChanged({
    if ($DomainCheckbox.Checked) {
		$DomainNameInput.Enabled = $true
        $EntraCheckbox.Enabled = $false
        $EntraCheckbox.Checked = $false
    }
    else {
		$DomainNameInput.Enabled = $false
        if ($IsPro -eq 1) {
			$EntraCheckbox.Enabled = $true
		} else {
			$EntraCheckbox.Enabled = $false
		}
    }
})

# Add an event handler for the entra checkbox:
$EntraCheckbox.Add_CheckedChanged({
    if ($EntraCheckbox.Checked) {
		$DomainNameInput.Clear()
		$DomainNameInput.Enabled = $false
        $DomainCheckbox.Enabled = $false
        $DomainCheckbox.Checked = $false
    }
    else {
        if ($IsPro -eq 1) {
			$DomainCheckbox.Enabled = $true
		} else {
			$DomainCheckbox.Enabled = $false
		}
    }
})

# Do not enable Okay until a condition is met
$PCNameInput.Add_TextChanged({
    if ($PCNameInput.Text -match '[^A-Za-z0-9-]') {
        $pos   = $PCNameInput.SelectionStart
        $clean = [regex]::Replace($PCNameInput.Text, '[^A-Za-z0-9-]', '')
        $PCNameInput.Text = $clean
        # restore caret position safely
        $PCNameInput.SelectionStart = [Math]::Min($pos, $PCNameInput.Text.Length)
    }
	$SMOkayButton.Enabled = ((-not [string]::IsNullOrWhiteSpace($PCNameInput.Text) -and (Test-ComputerName $PCNameInput.Text)) -or (($DomainCheckbox.Checked) -and (-not [string]::IsNullOrWhiteSpace($DomainNameInput.Text))) -or ($EntraCheckbox.Checked))
})
$DomainNameInput.Add_TextChanged({
    $SMOkayButton.Enabled = ((-not [string]::IsNullOrWhiteSpace($PCNameInput.Text) -and (Test-ComputerName $PCNameInput.Text)) -or (($DomainCheckbox.Checked) -and (-not [string]::IsNullOrWhiteSpace($DomainNameInput.Text))) -or ($EntraCheckbox.Checked))
})
$EntraCheckbox.Add_CheckedChanged({
	$SMOkayButton.Enabled = ((-not [string]::IsNullOrWhiteSpace($PCNameInput.Text) -and (Test-ComputerName $PCNameInput.Text)) -or (($DomainCheckbox.Checked) -and (-not [string]::IsNullOrWhiteSpace($DomainNameInput.Text))) -or ($EntraCheckbox.Checked))
})
$DomainCheckbox.Add_CheckedChanged({
	$SMOkayButton.Enabled = ((-not [string]::IsNullOrWhiteSpace($PCNameInput.Text) -and (Test-ComputerName $PCNameInput.Text)) -or (($DomainCheckbox.Checked) -and (-not [string]::IsNullOrWhiteSpace($DomainNameInput.Text))) -or ($EntraCheckbox.Checked))
})

# Define a function to handle the Okay button click
$SMOkayButton.Add_Click({
	$SMOkayButton.Enabled = $false
	try {
		if ($DomainCheckbox.Checked -and (-not [string]::IsNullOrWhiteSpace($PCNameInput.Text))) {
			if (-not (Test-ComputerName $PCNameInput.Text)) {throw "Bad PC Name"}
			$DomainCredential = Get-Credential -Message "Enter credentials with permission to add this device to $($DomainNameInput.Text):"
			Add-Computer -DomainName $DomainNameInput.Text -NewName $PCNameInput.Text -Credential $DomainCredential -ErrorAction Stop *>&1 | Out-File -Append -FilePath $logPath
		} elseif ($DomainCheckbox.Checked -and ([string]::IsNullOrWhiteSpace($PCNameInput.Text))) {
			$DomainCredential = Get-Credential -Message "Enter credentials with permission to add this device to $($DomainNameInput.Text):"
			Add-Computer -DomainName $DomainNameInput.Text -Credential $DomainCredential -ErrorAction Stop *>&1 | Out-File -Append -FilePath $logPath
		} elseif ((-not $DomainCheckbox.Checked) -and ($PCNameInput.Text -ne "")) {
			if (-not (Test-ComputerName $PCNameInput.Text)) {throw "Bad PC Name"}
			Rename-Computer -NewName $PCNameInput.Text -Force -ErrorAction Stop *>&1 | Out-File -Append -FilePath $logPath
		} elseif (($EntraCheckbox.Checked) -and (-not [string]::IsNullOrWhiteSpace($PCNameInput.Text))) {
			if (-not (Test-ComputerName $PCNameInput.Text)) {throw "Bad PC Name"}
			Rename-Computer -NewName $PCNameInput.Text -Force -ErrorAction Stop *>&1 | Out-File -Append -FilePath $logPath
			Start-Process 'ms-settings:workplace'
		} elseif (($EntraCheckbox.Checked) -and ([string]::IsNullOrWhiteSpace($PCNameInput.Text))) {
			Start-Process 'ms-settings:workplace'
		} else {
			throw "Unexpected error"
		}
		$SMGUI.Close()
	} catch {
		$PCNameInput.Clear()
		$DomainNameInput.Clear()
		$DomainCheckbox.Checked = $false
		$EntraCheckbox.Checked = $false
		PopupError "PC Naming and/or Domain Joining failed." "Error"
	}
})

# Define Skip closing function
$SMSkip.Add_Click({
	$SMSkip.Enabled = $false
	$SMGUI.Close()
})

# Display First GUI
$SMGUI.ShowDialog() | Out-Null