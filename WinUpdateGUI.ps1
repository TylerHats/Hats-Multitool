# Windows Update GUI - Tyler Hatfield
# Provides a WinForms GUI to check for and install Windows Updates using PSWindowsUpdate

# --- Define P/Invoke methods (ignore if already exists) ---
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
"@ -Language CSharp -CompilerVersion v4.0 -ErrorAction Stop
} catch {
    # ignore if already defined
}

# --- Preload PSWindowsUpdate & WUA COM objects ---
Import-Module PSWindowsUpdate -ErrorAction Stop
$Global:WUASession  = New-Object -ComObject Microsoft.Update.Session
$Global:WUASearcher = $WUASession.CreateUpdateSearcher()

# --- Load WinForms assemblies ---
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- Build the main form (fixed width, dynamic height) ---
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

# Include cumulative updates checkbox
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

# Progress fill panel
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

# Function to fetch COM updates, wrap into PSObjects, populate ListView, resize form
function Load-Updates {
    $form.Cursor    = 'WaitCursor'
    $lblStatus.Text = 'Status: Loading updates...'
    [System.Windows.Forms.Application]::DoEvents()

    # COM search
    $comUpdates = $WUASearcher.Search("IsInstalled=0").Updates
    if (-not $chkCumulative.Checked) { $comUpdates = $comUpdates | Where-Object { $_.Title -notmatch 'Cumulative' } }

    # Wrap into PSCustomObjects for KB and Size
    $updates = @()
    foreach ($cu in $comUpdates) {
        $kbList = @()
        try { foreach ($id in $cu.KBArticleIDs) { $kbList += $id } } catch {}
        $kbText = $kbList -join ', '
        $sizeVal = if ($cu.Size) { [math]::Round($cu.Size/1MB,1) } else { 0 }
        $updates += [pscustomobject]@{
            Title     = $cu.Title
            KB        = $kbText
            Size      = "$sizeVal MB"
            UpdateObj = $cu
        }
    }

    # Populate ListView
    $lv.Items.Clear()
    foreach ($u in $updates) {
        $item = [System.Windows.Forms.ListViewItem]::new($u.Title)
        $item.SubItems.Add($u.KB)   | Out-Null
        $item.SubItems.Add($u.Size) | Out-Null
        $item.Tag = $u.UpdateObj
        $lv.Items.Add($item)        | Out-Null
    }

    # Resize ListView height (cap at 40 rows)
    $rowH = 20; $hdrH = 20; $maxRows = 40
    $count = $lv.Items.Count
    $visible = [math]::Min($count, $maxRows)
    $newLvH = $hdrH + ($visible * $rowH)
    $lv.Height = $newLvH

    # Reposition and resize form
    $yBase = 80 + $newLvH
    $panelTrack.Location   = [System.Drawing.Point]::new(20, $yBase)
    $lblStatus.Location    = [System.Drawing.Point]::new(20, $yBase + 30)
    $btnInstall.Location   = [System.Drawing.Point]::new(440, $yBase + 25)
    $form.ClientSize = [System.Drawing.Size]::new(600, $yBase + 80)

    $form.Cursor    = 'Default'
    $lblStatus.Text = "Status: Ready (Found $count updates)"
}

# Event wiring
$chkCumulative.Add_CheckedChanged({ Load-Updates })
Load-Updates

# Install button: hide selected logic using KBArticleIDs array
$btnInstall.Add_Click({
    $btnInstall.Enabled = $false
    # Build list of KB IDs to hide
    $hideList = @()
    foreach ($item in $lv.Items) {
        if (-not $item.Checked) {
            foreach ($id in $item.Tag.KBArticleIDs) {
                if ($id) { $hideList += $id }
            }
        }
    }
    $hideList = $hideList | Sort-Object -Unique

    $lblStatus.Text = 'Hiding unselected updates...'; [System.Windows.Forms.Application]::DoEvents()
    foreach ($kb in $hideList) { Hide-WindowsUpdate -KBArticleID $kb -Confirm:$false | Out-Null }

    $lblStatus.Text = 'Installing updates...'; [System.Windows.Forms.Application]::DoEvents()
    Install-WindowsUpdate -AcceptAll -IgnoreReboot -Confirm:$false | Out-Null

    $lblStatus.Text = 'Restoring hidden updates...'; [System.Windows.Forms.Application]::DoEvents()
    foreach ($kb in $hideList) { Show-WindowsUpdate -KBArticleID $kb -Confirm:$false | Out-Null }

    $lblStatus.Text = 'All updates installed.'
    Read-Host 'Press Enter to finish...' | Out-Null
    $form.Close()
})

# Show the GUI
[void]$form.ShowDialog()