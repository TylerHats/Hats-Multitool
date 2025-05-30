# Windows Update GUI Module - Tyler Hatfield - v1.1

# Load common file
$commonPath = Join-Path -Path $PSScriptRoot -ChildPath 'Common.ps1'
. "$commonPath"

# Import, or download, PSWindowsUpdate module and set DO Mode
try {
	Import-Module PSWindowsUpdate -ErrorAction Stop
} catch {
	Log-Message "PSWindowsUpdate module not found. Installing now..." "LogOnly"
    Install-Module -Name PSWindowsUpdate -Scope CurrentUser -Force
    Import-Module PSWindowsUpdate
}
#Add-Type -AssemblyName System.Windows.Forms, System.Drawing # Already done in common file
try {
	Set-DODownloadMode -DownloadMode 3 -ErrorAction Stop *>&1 | Out-File -Append -FilePath $logPath
} catch {
	Log-Message "Delivery Optimization mode setting failed, continuing with defaults..." "LogOnly"
}

# --- Build the main form ---
$form = [System.Windows.Forms.Form]::new()
$form.Text            = "Hat's Windows Update"
$form.BackColor       = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$form.StartPosition   = 'CenterScreen'
$form.ClientSize      = [System.Drawing.Size]::new(600,200)
$form.Icon = $HMTIcon
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.Font = $font

# --- Title label ---
$lblTitle = [System.Windows.Forms.Label]::new()
$lblTitle.Text      = "Available Updates"
$lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lblTitle.AutoSize  = $true
$lblTitle.Location  = [System.Drawing.Point]::new(20,20)
$form.Controls.Add($lblTitle)

# --- Cumulative updates toggle ---
$chkCumulative = [System.Windows.Forms.CheckBox]::new()
$chkCumulative.Text      = "Include Cumulative Updates"
$chkCumulative.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkCumulative.AutoSize  = $true
$chkCumulative.Location  = [System.Drawing.Point]::new(20,50)
$form.Controls.Add($chkCumulative)

# --- ListView for updates ---
$lv = [System.Windows.Forms.ListView]::new()
$lv.View          = 'Details'
$lv.CheckBoxes    = $true
$lv.FullRowSelect = $true
$lv.Scrollable    = $true
$lv.BackColor     = [System.Drawing.ColorTranslator]::FromHtml("#3a3c43")
$lv.ForeColor     = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lv.Location      = [System.Drawing.Point]::new(20,80)
$lv.Size          = [System.Drawing.Size]::new(560,200)
$lv.Columns.Add("Title",360) | Out-Null
$lv.Columns.Add("KB",80)     | Out-Null
$lv.Columns.Add("Size",100)  | Out-Null
$form.Controls.Add($lv)

# --- Progress bar ---
$panelTrack = [System.Windows.Forms.Panel]::new()
$panelTrack.Size        = [System.Drawing.Size]::new(560,20)
$panelTrack.Location    = [System.Drawing.Point]::new(20,300)
$panelTrack.BorderStyle = 'FixedSingle'
$panelTrack.BackColor   = [System.Drawing.ColorTranslator]::FromHtml("#4f4f4f")
$form.Controls.Add($panelTrack)
$panelFill = [System.Windows.Forms.Panel]::new()
$panelFill.Size      = [System.Drawing.Size]::new(0,18)
$panelFill.Location  = [System.Drawing.Point]::new(1,1)
$panelFill.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
$panelTrack.Controls.Add($panelFill)

# --- Status label ---
$lblStatus = [System.Windows.Forms.Label]::new()
$lblStatus.Text      = "Status: Idle"
$lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lblStatus.AutoSize  = $true
$lblStatus.Location  = [System.Drawing.Point]::new(20,330)
$form.Controls.Add($lblStatus)

# --- Install button ---
$btnInstall = [System.Windows.Forms.Button]::new()
$btnInstall.Text      = "Install Selected"
$btnInstall.Size      = [System.Drawing.Size]::new(140,30)
$btnInstall.Location  = [System.Drawing.Point]::new(440,325)
$btnInstall.FlatStyle = 'Flat'
$btnInstall.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$btnInstall.FlatAppearance.BorderSize = 1
$form.Controls.Add($btnInstall)

# --- Function to load updates and resize form dynamically ---
function Load-Updates {
    $form.Cursor    = 'WaitCursor'
    $lblStatus.Text = 'Loading updates...'
    [System.Windows.Forms.Application]::DoEvents()

    # Retrieve list via PSWindowsUpdate
    $list = Get-WindowsUpdate -AcceptAll -IgnoreReboot -Verbose:$false
    if (-not $chkCumulative.Checked) {
        $list = $list | Where-Object { $_.Title -notmatch 'Cumulative' }
    }

    # Populate ListView
    $lv.Items.Clear()
    foreach ($u in $list) {
        $item = [System.Windows.Forms.ListViewItem]::new($u.Title)
        $item.SubItems.Add($u.KB)    | Out-Null
        $item.SubItems.Add($u.Size)  | Out-Null
        $lv.Items.Add($item)         | Out-Null
    }

    # Calculate row height dynamically
    if ($lv.Items.Count -gt 0) {
        $rowH = $lv.GetItemRect(0).Height
    } else {
        $rowH = 20
    }
    $hdrH   = 20
    $maxRows= 40
    $visible= [math]::Min($lv.Items.Count, $maxRows)
    $newLvH = $hdrH + ($visible * $rowH)
    $lv.Height = $newLvH

    # Reposition and resize form
    $yBase = 80 + $newLvH
    $panelTrack.Location = [System.Drawing.Point]::new(20, $yBase + 5)
    $lblStatus.Location  = [System.Drawing.Point]::new(20, $yBase + 35)
    $btnInstall.Location = [System.Drawing.Point]::new(440, $yBase + 30)
    $form.ClientSize = [System.Drawing.Size]::new(600, $yBase + 70)

    $form.Cursor    = 'Default'
    $lblStatus.Text = "Status: Ready (Found $($lv.Items.Count) updates)"
}

# --- Wire up toggle and initial load ---
$chkCumulative.Add_CheckedChanged({ Load-Updates })
Load-Updates

# --- Install button click: hide/unhide strategy via PSWindowsUpdate ---
$btnInstall.Add_Click({
    $btnInstall.Enabled = $false

    # Hide unselected
    $lblStatus.Text = 'Hiding unselected updates...'
    [System.Windows.Forms.Application]::DoEvents()
	$unselectedTitles = $lv.Items | Where-Object { -not $_.Checked } | ForEach-Object { $_.Text }
	Write-Host "Start of unTitles"
	Write-Host $unselectedTitles
	Write-Host "Endof unTitles"
	if ($unselectedTitles) {
		foreach ($ExTitle in $unselectedTitles) {
			Hide-WindowsUpdate -Title "$ExTitle" -Confirm:$false# | Out-Null
		}
	}

    # Install remaining
    $lblStatus.Text = 'Installing updates...'
    [System.Windows.Forms.Application]::DoEvents()
    Install-WindowsUpdate -AcceptAll -IgnoreReboot -Confirm:$false | Out-Null

    # Restore hidden
    $lblStatus.Text = 'Restoring hidden updates...'
    [System.Windows.Forms.Application]::DoEvents()
    if ($unselectedTitles) {
		foreach ($ExTitle in $unselectedTitles) {
			Show-WindowsUpdate -Title "$ExTitle" -Confirm:$false -IgnoreReboot | Out-Null
		}
	}

    $lblStatus.Text = 'All selected updates installed.'
    Read-Host 'Press Enter to finish...' | Out-Null
    $form.Close()
})

# --- Show the GUI ---
[void]$form.ShowDialog()