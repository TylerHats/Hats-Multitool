# Windows Update GUI - Tyler Hatfield
# Provides a WinForms GUI to list and install Windows Updates using PSWindowsUpdate

# --- Preload PSWindowsUpdate module ---
Import-Module PSWindowsUpdate -ErrorAction Stop

# --- Load WinForms assemblies ---
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- Build the main form ---
$form = [System.Windows.Forms.Form]::new()
$form.Text            = "Hat's Windows Update"
$form.BackColor       = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$form.StartPosition   = 'CenterScreen'
$form.Font            = [System.Drawing.Font]::new("Segoe UI", 10)
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false
$form.ClientSize      = [System.Drawing.Size]::new(600,200)

# Title label
$lblTitle = [System.Windows.Forms.Label]::new()
$lblTitle.Text      = "Available Updates"
$lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lblTitle.AutoSize  = $true
$lblTitle.Location  = [System.Drawing.Point]::new(20,20)
$form.Controls.Add($lblTitle)

# Cumulative updates toggle
$chkCumulative = [System.Windows.Forms.CheckBox]::new()
$chkCumulative.Text      = "Include Cumulative Updates"
$chkCumulative.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkCumulative.AutoSize  = $true
$chkCumulative.Location  = [System.Drawing.Point]::new(20,50)
$form.Controls.Add($chkCumulative)

# ListView for updates
$lv = [System.Windows.Forms.ListView]::new()
$lv.View          = 'Details'
$lv.CheckBoxes    = $true
$lv.FullRowSelect = $true
$lv.Scrollable    = $true
$lv.BackColor     = [System.Drawing.ColorTranslator]::FromHtml("#3a3c43")
$lv.ForeColor     = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lv.Location      = [System.Drawing.Point]::new(20,80)
$lv.Size          = [System.Drawing.Size]::new(560,200)
$lv.Columns.Add("Title",360)  | Out-Null
$lv.Columns.Add("KB",80)      | Out-Null
$lv.Columns.Add("Size",100)   | Out-Null
$form.Controls.Add($lv)

# Progress bar container
$panelTrack = [System.Windows.Forms.Panel]::new()
$panelTrack.Size        = [System.Drawing.Size]::new(560,20)
$panelTrack.Location    = [System.Drawing.Point]::new(20,300)
$panelTrack.BorderStyle = 'FixedSingle'
$panelTrack.BackColor   = [System.Drawing.ColorTranslator]::FromHtml("#4f4f4f")
$form.Controls.Add($panelTrack)

# Progress fill
$panelFill = [System.Windows.Forms.Panel]::new()
$panelFill.Size      = [System.Drawing.Size]::new(0,18)
$panelFill.Location  = [System.Drawing.Point]::new(1,1)
$panelFill.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
$panelTrack.Controls.Add($panelFill)

# Status label
$lblStatus = [System.Windows.Forms.Label]::new()
$lblStatus.Text      = "Status: Idle"
$lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lblStatus.AutoSize  = $true
$lblStatus.Location  = [System.Drawing.Point]::new(20,330)
$form.Controls.Add($lblStatus)

# Install button
$btnInstall = [System.Windows.Forms.Button]::new()
$btnInstall.Text      = "Install Selected"
$btnInstall.Size      = [System.Drawing.Size]::new(140,30)
$btnInstall.Location  = [System.Drawing.Point]::new(440,325)
$btnInstall.FlatStyle = 'Flat'
$btnInstall.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$btnInstall.FlatAppearance.BorderSize = 1
$form.Controls.Add($btnInstall)

# Function to load updates from PSWindowsUpdate and resize form
function Load-Updates {
    $form.Cursor    = 'WaitCursor'
    $lblStatus.Text = 'Loading updates...'
    [System.Windows.Forms.Application]::DoEvents()

    # Retrieve updates via PSWindowsUpdate
    $list = Get-WindowsUpdate -AcceptAll -IgnoreReboot -Verbose:$false
    if (-not $chkCumulative.Checked) { $list = $list | Where-Object { $_.Title -notmatch 'Cumulative' } }

    # Populate ListView
    $lv.Items.Clear()
    foreach ($u in $list) {
        $item = [System.Windows.Forms.ListViewItem]::new($u.Title)
        $item.SubItems.Add($u.KB) | Out-Null
        $item.SubItems.Add($u.Size) | Out-Null
        $item.Tag = $u
        $lv.Items.Add($item) | Out-Null
    }

    # Resize ListView height (cap at 40 rows)
    $rowH = 20; $hdrH = 20; $maxRows = 40
    $count = $lv.Items.Count
    $visible = [math]::Min($count, $maxRows)
    $newLvH = $hdrH + ($visible * $rowH)
    $lv.Height = $newLvH

    # Reposition lower controls and resize form
    $yBase = 80 + $newLvH
    $panelTrack.Location = [System.Drawing.Point]::new(20, $yBase)
    $lblStatus.Location  = [System.Drawing.Point]::new(20, $yBase + 30)
    $btnInstall.Location = [System.Drawing.Point]::new(440, $yBase + 25)
    $form.ClientSize     = [System.Drawing.Size]::new(600, $yBase + 80)

    $form.Cursor    = 'Default'
    $lblStatus.Text = "Status: Ready (Found $count updates)"
}

# Wire up toggle and initial load
$chkCumulative.Add_CheckedChanged({ Load-Updates })
Load-Updates

# Install button click: install exactly the selected PSWUUpdate objects
$btnInstall.Add_Click({
    $btnInstall.Enabled = $false
    $selected = @()
    foreach ($item in $lv.CheckedItems) { $selected += $item.Tag }

    $total = $selected.Count
    if ($total -eq 0) {
        $lblStatus.Text = 'Status: No updates selected'
        return
    }

    $i = 0
    foreach ($upd in $selected) {
        $i++
        $lblStatus.Text = "Installing: $($upd.Title)"
        $percent = [int]($i / $total * 100)
        $panelFill.Width = [int]($panelTrack.ClientSize.Width * $percent / 100)
        [System.Windows.Forms.Application]::DoEvents()

        # Install this update
        Install-WindowsUpdate -Updates $upd -AcceptAll -IgnoreReboot -Confirm:$false | Out-Null
    }

    $lblStatus.Text = 'All selected updates installed.'
    Read-Host 'Press Enter to finish...' | Out-Null
    $form.Close()
})

# Show the form
[void]$form.ShowDialog()