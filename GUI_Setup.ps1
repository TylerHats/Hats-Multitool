# GUI Setup Module Selection - Tyler Hatfield - v2.20

# Setup Module Selection GUI ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
$ModGUI = New-Object System.Windows.Forms.Form
$ModGUI.Text = "Hat's Multitool"
$ModGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$ModGUI.ClientSize = New-Object System.Drawing.Size(400, 500)
$ModGUI.StartPosition = 'CenterScreen'
$ModGUI.Icon = $HMTIcon
$ModGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$ModGUI.MaximizeBox = $false
$ModGUI.MinimizeBox = $true
$ModGUI.ShowInTaskbar = $true
$ModGUI.Font = $font
$ModGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$ModGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $ModGUI

$checkboxHeight = 30
$buttonHeight = 90
$labelHeight = 30
$padding = 20

$modules = @(
    @{ Name = 'Time Zone' },
    @{ Name = 'Local Accounts' },
    @{ Name = 'System Properties' },
    @{ Name = 'Setup Options' },
    @{ Name = 'Bloat Cleanup' },
    @{ Name = 'Programs' }
)

$ModGUIHeight = ($modules.Count * $checkboxHeight) + ($buttonHeight * 2) + ($padding * 3) + $labelHeight
$ModGUI.ClientSize = New-Object System.Drawing.Size(300, $ModGUIHeight)
$ModGUI.StartPosition = 'CenterScreen'

$ModGUIcheckboxes = @{ }
$y = 15
$ModGUIlabel = New-Object System.Windows.Forms.Label
$ModGUIlabel.Text = "Please Select Modules:"
$ModGUIlabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModGUIlabel.Location = New-Object System.Drawing.Point(20, $y)
$ModGUIlabel.AutoSize = $true
$ModGUI.Controls.Add($ModGUIlabel)
$y += 30
$ModCLB = New-Object System.Windows.Forms.CheckedListBox
$ModCLB.Location = New-Object System.Drawing.Point(20, $y)
$ModCLB.Size = New-Object System.Drawing.Size(260, 180)
$ModCLB.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$ModCLB.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModCLB.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$ModCLB.CheckOnClick = $true
$ModGUI.Controls.Add($ModCLB)

foreach ($module in $modules) {
    $ModCLB.Items.Add($module.Name) | Out-Null
}

$y += 180
$SelectAllButton = New-Object System.Windows.Forms.Button
$y += 15
$SelectAllButton.Text = "Select All"
$SelectAllButton.Size = New-Object System.Drawing.Size(115,40)
$SelectAllButton.Location = New-Object System.Drawing.Point(92, $y)
$SelectAllButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$SelectAllButton.FlatStyle = 'Flat'
$SelectAllButton.FlatAppearance.BorderSize = 1
$ModGUI.Controls.Add($SelectAllButton)

$y += 55
$ModOkayButton = New-Object System.Windows.Forms.Button
$ModOkayButton.Location = New-Object System.Drawing.Point(40, $y)
$ModOkayButton.Size = New-Object System.Drawing.Size(95, 40)
$ModOkayButton.Text = "OK"
$ModOkayButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModOkayButton.FlatStyle = 'Flat'
$ModOkayButton.FlatAppearance.BorderSize = 1
$ModGUI.Controls.Add($ModOkayButton)

$ModSkipButton = New-Object System.Windows.Forms.Button
$ModSkipButton.Location = New-Object System.Drawing.Point(165, $y)
$ModSkipButton.Size = New-Object System.Drawing.Size(95, 40)
$ModSkipButton.Text = "Skip"
$ModSkipButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModSkipButton.FlatStyle = 'Flat'
$ModSkipButton.FlatAppearance.BorderSize = 1
$ModGUI.Controls.Add($ModSkipButton)

$SelectAllButton.Add_Click({
    $allChecked = ($ModCLB.CheckedIndices.Count -eq $ModCLB.Items.Count)
    for ($i = 0; $i -lt $ModCLB.Items.Count; $i++) {
        $ModCLB.SetItemChecked($i, (-not $allChecked))
    }
    $SelectAllButton.Text = if ($allChecked) { "Select All" } else { "Deselect All" }
})

$ModOkayButton.Add_Click({
    $checkedCount = $ModCLB.CheckedIndices.Count
    if ($checkedCount -gt 0) {
        $ModGUIcheckboxes.Clear()
        for ($i = 0; $i -lt $ModCLB.Items.Count; $i++) {
            $name = $ModCLB.Items[$i].ToString()
            $isChecked = $ModCLB.GetItemChecked($i)
            $dummyCb = [PSCustomObject]@{ Checked = $isChecked }
            $ModGUIcheckboxes[$name] = $dummyCb
        }
        $Global:NextAction = 'RunSetup'
        $ModGUI.DialogResult = [System.Windows.Forms.DialogResult]::OK
    } else {
        $Global:NextAction = 'Main'
        $ModGUI.Close()
    }
})

$ModSkipButton.Add_Click({
    $Global:NextAction = 'Main'
    $ModGUI.Close()
})

$ModGUI.Add_Load({
    Invoke-HMTScale $ModGUI
    Set-RoundedControl $SelectAllButton
    Set-RoundedControl $ModOkayButton
    Set-RoundedControl $ModSkipButton
    $w = [int](300 * $global:HMTScaleFactor)
    $p = [int](20 * $global:HMTScaleFactor)
    $SelectAllButton.Left = [int](($w - $SelectAllButton.Width) / 2)
    $ModOkayButton.Left = [int]($w / 2) - $ModOkayButton.Width - [int](10 * $global:HMTScaleFactor)
    $ModSkipButton.Left = [int]($w / 2) + [int](10 * $global:HMTScaleFactor)
    $ModGUI.ClientSize = [System.Drawing.Size]::new($w, ($ModSkipButton.Bottom + $p))
})
