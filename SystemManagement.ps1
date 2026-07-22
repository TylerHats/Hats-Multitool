# System Management Module - Tyler Hatfield - v2.11

$EM_SETCUEBANNER = 0x1501

# Validate OS domain join compatibility
$IsPro = if ($WindowsEdition -match 'Pro|Enterprise') { 1 } else { 0 }

# Detect existing domain membership
$sysInfo = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
$IsAlreadyJoined = if ($sysInfo -and $sysInfo.PartOfDomain) { $true } else { $false }
$CurrentDomain = if ($sysInfo -and $sysInfo.PartOfDomain) { $sysInfo.Domain } else { "" }

# Initialize GUI form
$SMGUI = New-Object System.Windows.Forms.Form
$SMGUI.Text = "Hat's Multitool"
$SMGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$SMGUI.ClientSize = New-Object System.Drawing.Size(315, 265)
$SMGUI.StartPosition = 'CenterScreen'
$SMGUI.Icon = $HMTIcon
$SMGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$SMGUI.MaximizeBox = $false
$SMGUI.MinimizeBox = $true
$SMGUI.ShowInTaskbar = $true
$SMGUI.Font = $font
$SMGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$SMGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $SMGUI

# Add descriptive label
$y = 10
$SMlabel = New-Object System.Windows.Forms.Label
$SMlabel.Text = "Enter new device name:"
$SMlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SMlabel.Size = New-Object System.Drawing.Size(300, 20)
$SMlabel.Location = New-Object System.Drawing.Point(17, $y)
$SMlabel.AutoSize = $true
$SMlabel.TextAlign = 'TopLeft'
$SMGUI.Controls.Add($SMlabel)

# Add descriptive label 2nd line
$y = 30
$SMlabel = New-Object System.Windows.Forms.Label
$SMlabel.Text = "(Currently: $env:computername)"
$SMlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SMlabel.Size = New-Object System.Drawing.Size(300, 20)
$SMlabel.Location = New-Object System.Drawing.Point(17, $y)
$SMlabel.AutoSize = $true
$SMlabel.TextAlign = 'TopLeft'
$SMGUI.Controls.Add($SMlabel)

# Add serial number label
$y += 20
$SerialLabel = New-Object System.Windows.Forms.Label
$SerialLabel.Text = "Serial Number: $serialNumber"
$SerialLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SerialLabel.Size = New-Object System.Drawing.Size(300, 20)
$SerialLabel.Location = New-Object System.Drawing.Point(17, $y)
$SerialLabel.AutoSize = $true
$SerialLabel.TextAlign = 'TopLeft'
$SerialLabel.Cursor = [Windows.Forms.Cursors]::Hand
$SMGUI.Controls.Add($SerialLabel)

# Add PC name input
$y += 30
$PCNameInput = New-Object System.Windows.Forms.TextBox
$PCNameInput.location = New-Object System.Drawing.Point(17, $y)
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
if ($IsAlreadyJoined) {
    $DomainCheckbox.Checked = $true
    $DomainCheckbox.Enabled = $false
} elseif ($IsPro -eq 1) {
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
if ($IsAlreadyJoined) {
    $EntraCheckbox.Enabled = $false
} elseif ($IsPro -eq 1) {
    $EntraCheckbox.Enabled = $true
} else {
    $EntraCheckbox.Enabled = $false
}
$SMGUI.Controls.Add($EntraCheckbox)

# Add domain name input
$y += 30
$DomainNameInput = New-Object System.Windows.Forms.TextBox
$DomainNameInput.location = New-Object System.Drawing.Point(17, $y)
$DomainNameInput.Width = 280
if ($IsAlreadyJoined) {
    $DomainNameInput.Text = $CurrentDomain
    $DomainNameInput.Enabled = $false
} else {
    $DomainNameInput.Enabled = $false
}
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

# Configure clipboard copy event
$SerialLabel.Add_Click({
    try {
        if (-not [string]::IsNullOrWhiteSpace($serialNumber)) {
            [Windows.Forms.Clipboard]::SetText($serialNumber)
        } else {
            [Windows.Forms.Clipboard]::SetText("N/A")
        }
        $tip = New-Object Windows.Forms.ToolTip
        $tip.Show('Copied!', $SerialLabel, 0, -20, 1200)
    } catch {
        Log-Message "Clipboard copy failed: $_" "logonly"
    }
})

# Enforce NetBIOS naming constraints
$PCNameInput.Add_KeyPress({
    param($_sender, $e)
    [void]$_sender
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

# Configure domain CheckBox event
$DomainCheckbox.Add_CheckedChanged({
    if (-not $IsAlreadyJoined) {
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
    }
})

# Add an event handler for the entra checkbox:
$EntraCheckbox.Add_CheckedChanged({
    if (-not $IsAlreadyJoined) {
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
    }
})

# Validate form state for Okay button
$script:UpdateSMOKButtonState = {
    if ($PCNameInput.Text -match '[^A-Za-z0-9-]') {
        $pos   = $PCNameInput.SelectionStart
        $clean = [regex]::Replace($PCNameInput.Text, '[^A-Za-z0-9-]', '')
        $PCNameInput.Text = $clean
        $PCNameInput.SelectionStart = [Math]::Min($pos, $PCNameInput.Text.Length)
    }
    $hasValidName = (-not [string]::IsNullOrWhiteSpace($PCNameInput.Text) -and (Test-ComputerName $PCNameInput.Text))
    $hasValidDomain = (($DomainCheckbox.Checked) -and (-not [string]::IsNullOrWhiteSpace($DomainNameInput.Text)))
    $isEntra = $EntraCheckbox.Checked

    if ($IsAlreadyJoined) {
        $SMOkayButton.Enabled = $hasValidName
    } else {
        $SMOkayButton.Enabled = ($hasValidName -or $hasValidDomain -or $isEntra)
    }
}

$PCNameInput.Add_TextChanged($script:UpdateSMOKButtonState)
$DomainNameInput.Add_TextChanged($script:UpdateSMOKButtonState)
$EntraCheckbox.Add_CheckedChanged($script:UpdateSMOKButtonState)
$DomainCheckbox.Add_CheckedChanged($script:UpdateSMOKButtonState)

# Define a function to handle the Okay button click
$SMOkayButton.Add_Click({
	$SMOkayButton.Enabled = $false
	$SMOkayButton.Text = "Processing..."
	
	$isDomain = $DomainCheckbox.Checked
	$isEntra = $EntraCheckbox.Checked
	$pcName = $PCNameInput.Text
	$domainName = $DomainNameInput.Text
	$cred = $null

	if (-not [string]::IsNullOrWhiteSpace($pcName) -and (-not (Test-ComputerName $pcName))) {
		$SMOkayButton.Text = "OK"
		$SMOkayButton.Enabled = $true
		PopupError "Invalid PC Name. Must be 1-15 characters, alphanumeric/hyphens only." "Error"
		return
	}

	try {
		if ($IsAlreadyJoined) {
			$cred = Get-Credential -Message "Enter domain credentials to approve renaming device to ${pcName} in ${domainName}:"
		} elseif ($isDomain) {
			$cred = Get-Credential -Message "Enter credentials with permission to add this device to ${domainName}:"
		}
		
		$scriptBlock = {
			param([bool]$IsAlreadyJoined, [bool]$isDomain, [bool]$isEntra, [string]$pcName, [string]$domainName, [pscredential]$cred)
			
			if ($IsAlreadyJoined) {
				if (-not [string]::IsNullOrWhiteSpace($pcName)) {
					Rename-Computer -NewName $pcName -DomainCredential $cred -Force -ErrorAction Stop
					return "Successfully renamed domain-joined computer to $pcName."
				} else {
					return "No computer name specified."
				}
			} elseif ($isDomain -and (-not [string]::IsNullOrWhiteSpace($pcName))) {
				Add-Computer -DomainName $domainName -NewName $pcName -Credential $cred -ErrorAction Stop
				return "Successfully added computer to domain $domainName and renamed to $pcName."
			} elseif ($isDomain -and ([string]::IsNullOrWhiteSpace($pcName))) {
				Add-Computer -DomainName $domainName -Credential $cred -ErrorAction Stop
				return "Successfully added computer to domain $domainName."
			} elseif ((-not $isDomain) -and ($pcName -ne "")) {
				Rename-Computer -NewName $pcName -Force -ErrorAction Stop
				return "Successfully renamed computer to $pcName."
			} elseif (($isEntra) -and (-not [string]::IsNullOrWhiteSpace($pcName))) {
				Rename-Computer -NewName $pcName -Force -ErrorAction Stop
				return "Successfully renamed computer to $pcName. Opening workplace settings..."
			} elseif (($isEntra) -and ([string]::IsNullOrWhiteSpace($pcName))) {
				return "Opening workplace settings..."
			} else {
				throw "Unexpected error"
			}
		}

		$runspace = [runspacefactory]::CreateRunspace()
		$runspace.Open()
		$ps = [powershell]::Create()
		$ps.Runspace = $runspace
		$ps.AddScript($scriptBlock) | Out-Null
		$ps.AddParameter("IsAlreadyJoined", $IsAlreadyJoined) | Out-Null
		$ps.AddParameter("isDomain", $isDomain) | Out-Null
		$ps.AddParameter("isEntra", $isEntra) | Out-Null
		$ps.AddParameter("pcName", $pcName) | Out-Null
		$ps.AddParameter("domainName", $domainName) | Out-Null
		$ps.AddParameter("cred", $cred) | Out-Null
		
		$asyncResult = $ps.BeginInvoke()
		
		while (-not $asyncResult.IsCompleted) {
			[System.Windows.Forms.Application]::DoEvents()
			Start-Sleep -Milliseconds 50
		}
		
		$result = $ps.EndInvoke($asyncResult)
		$ps.Dispose()
		$runspace.Close()
		$runspace.Dispose()
		
		Log-Message $result "Success"
		if ($isEntra) {
			Start-Process "ms-settings:workplace" -ErrorAction SilentlyContinue
		}
		$SMGUI.Close()
	} catch {
		if (-not $IsAlreadyJoined) {
			$PCNameInput.Clear()
			$DomainNameInput.Clear()
			$DomainCheckbox.Checked = $false
			$EntraCheckbox.Checked = $false
		}
		$SMOkayButton.Text = "OK"
		$SMOkayButton.Enabled = $true
		PopupError "PC Naming and/or Domain operation failed.`nError: $_" "Error"
	}
})

# Define Skip closing function
$SMSkip.Add_Click({
	$SMSkip.Enabled = $false
	$SMGUI.Close()
})

# Calculate dynamic layout post-DPI scaling
$SMGUI.Add_Load({
    Invoke-HMTScale $SMGUI
    Set-RoundedControl $SMOkayButton
    Set-RoundedControl $SMSkip
    $w = [int](315 * $global:HMTScaleFactor)
    $p = [int](20 * $global:HMTScaleFactor)
    $SMGUI.ClientSize = [System.Drawing.Size]::new($w, ($SMSkip.Bottom + $p))
})

# Display First GUI
Show-HMTDialog $SMGUI | Out-Null