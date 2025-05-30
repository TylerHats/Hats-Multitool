# Windows Update GUI - Tyler Hatfield
# Provides a WinForms GUI to check for and install Windows Updates using PSWindowsUpdate

# --- Define P/Invoke methods (ignore if already defined) ---
try {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace Native {
    public static class Methods {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
}
"@ -Language CSharpVersion3 -ErrorAction Stop
} catch {
    # ignore if already exists
}

# --- Preload PSWindowsUpdate & WUA COM for fast searches ---
Import-Module PSWindowsUpdate -ErrorAction Stop
$Global:WUASession  = New-Object -ComObject Microsoft.Update.Session
$Global:WUASearcher = $WUASession.CreateUpdateSearcher()

# --- Load WinForms assemblies ---
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- Build main form (fixed width, dynamic height) ---
$form = New-Object System.Windows.Forms.Form
$form.Text            = "Hat's Windows Update"
$form.BackColor       = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$form.StartPosition   = 'CenterScreen'
$form.Font            = [System.Drawing.Font]::new("Segoe UI", 10)
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false
$form.ClientSize      = [System.Drawing.Size]::new(600,200)

# Title label
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text      = "Available Updates"
$lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lblTitle.AutoSize  = $true
$lblTitle.Location  = [System.Drawing.Point]::new(20,20)
$form.Controls.Add($lblTitle)

# Cumulative updates checkbox
$chkCumulative = New-Object System.Windows.Forms.CheckBox
$chkCumulative.Text      = "Include Cumulative Updates"
$chkCumulative.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkCumulative.AutoSize  = $true
$chkCumulative.Location  = [System.Drawing.Point]::new(20,50)
$form.Controls.Add($chkCumulative)

# ListView for updates
$lv = New-Object System.Windows.Forms.ListView
$lv.View          = 'Details'
$lv.CheckBoxes    = $true
$lv.FullRowSelect = $true
$lv.Scrollable    = $true
$lv.BackColor     = [System.Drawing.ColorTranslator]::FromHtml("#3a3c43")
$lv.ForeColor     = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lv.Location      = [System.Drawing.Point]::new(20,80)
$lv.Size          = [System.Drawing.Size]::new(560,200)
$lv.Columns.Add("Title",360) | Out-Null
$lv.Columns.Add("KB",80)    | Out-Null
$lv.Columns.Add("Size",100) | Out-Null
$form.Controls.Add($lv)

# Progress bar container
$panelTrack = New-Object System.Windows.Forms.Panel
$panelTrack.Size        = [System.Drawing.Size]::new(560,20)
$panelTrack.Location    = [System.Drawing.Point]::new(20,300)
$panelTrack.BorderStyle = 'FixedSingle'
$panelTrack.BackColor   = [System.Drawing.ColorTranslator]::FromHtml("#4f4f4f")
$form.Controls.Add($panelTrack)

# Progress fill
$panelFill = New-Object System.Windows.Forms.Panel
$panelFill.Size      = [System.Drawing.Size]::new(0,18)
$panelFill.Location  = [System.Drawing.Point]::new(1,1)
$panelFill.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
$panelTrack.Controls.Add($panelFill)

# Status label
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text      = "Status: Idle"
$lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lblStatus.AutoSize  = $true
$lblStatus.Location  = [System.Drawing.Point]::new(20,330)
$form.Controls.Add($lblStatus)

# Install button
$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text      = "Install Selected"
$btnInstall.Size      = [System.Drawing.Size]::new(140,30)
$btnInstall.Location  = [System.Drawing.Point]::new(440,325)
$btnInstall.FlatStyle = 'Flat'
$btnInstall.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$btnInstall.FlatAppearance.BorderSize = 1
$form.Controls.Add($btnInstall)

# Function to load updates and resize form
function Load-Updates {
    $form.Cursor    = 'WaitCursor'
    $lblStatus.Text = 'Status: Loading updates...'
    [System.Windows.Forms.Application]::DoEvents()

    $updates = $WUASearcher.Search("IsInstalled=0").Updates
    if (-not $chkCumulative.Checked) { $updates = $updates | Where-Object { $_.Title -notmatch 'Cumulative' } }

    $lv.Items.Clear()
    foreach ($u in $updates) {
        $itm = New-Object System.Windows.Forms.ListViewItem($u.Title)
        # Handle possible null KB values
        $kbText = if ($u.KB) { $u.KB } else { '' }
        $itm.SubItems.Add($kbText) | Out-Null
        # Handle size (default 0 MB if null)
        $sizeVal = if ($u.Size) { [math]::Round($u.Size/1MB,1) } else { 0 }
        $itm.SubItems.Add("$sizeVal MB") | Out-Null
        $itm.Tag = $u
        $lv.Items.Add($itm) | Out-Null
    }

    $rowH = 20; $hdrH = 20; $maxRows = 40
    $count = $lv.Items.Count
    $visible = [math]::Min($count, $maxRows)
    $newLvH = $hdrH + ($visible * $rowH)
    $lv.Height = $newLvH

    $yBase = 80 + $newLvH
    $panelTrack.Location   = [System.Drawing.Point]::new(20, $yBase)
    $lblStatus.Location    = [System.Drawing.Point]::new(20, $yBase + 30)
    $btnInstall.Location   = [System.Drawing.Point]::new(440, $yBase + 25)

    $form.ClientSize = [System.Drawing.Size]::new(600, $yBase + 80)

    $form.Cursor    = 'Default'
    $lblStatus.Text = "Status: Ready (Found $count updates)"
}

# Events
$chkCumulative.Add_CheckedChanged({ Load-Updates })
Load-Updates
$btnInstall.Add_Click({
    $btnInstall.Enabled = $false
    $ex = @()
    foreach ($i in $lv.Items) { if (-not $i.Checked) { $ex += $i.SubItems[1].Text } }

    $lblStatus.Text='Hiding unselected updates...'; [System.Windows.Forms.Application]::DoEvents()
    foreach ($kb in $ex) { Hide-WindowsUpdate -KBArticleID $kb -Confirm:$false | Out-Null }

    $lblStatus.Text='Installing updates...'; [System.Windows.Forms.Application]::DoEvents()
    Install-WindowsUpdate -AcceptAll -IgnoreReboot -Confirm:$false | Out-Null

    $lblStatus.Text='Restoring hidden updates...'; [System.Windows.Forms.Application]::DoEvents()
    foreach ($kb in $ex) { Show-WindowsUpdate -KBArticleID $kb -Confirm:$false | Out-Null }

    $lblStatus.Text='All updates installed.'
    Read-Host 'Press Enter to finish...' | Out-Null
    $form.Close()
})

# Show GUI
[void]$form.ShowDialog()