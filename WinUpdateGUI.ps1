# Windows Update GUI - Tyler Hatfield
# Provides a WinForms GUI to check for and install Windows Updates using PSWindowsUpdate

# --- Define P/Invoke methods for window control ---
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
"@ -Language CSharpVersion3

# --- Preload PSWindowsUpdate module and WUA COM objects for fast searches ---
Import-Module PSWindowsUpdate -ErrorAction Stop
$Global:WUASession  = New-Object -ComObject Microsoft.Update.Session
$Global:WUASearcher = $WUASession.CreateUpdateSearcher()

# --- Load WinForms assemblies ---
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- Build the main form ---
$form = New-Object System.Windows.Forms.Form
$form.Text            = "Hat's Windows Update"
$form.BackColor       = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$form.Size            = New-Object System.Drawing.Size(600, 500)
$form.StartPosition   = 'CenterScreen'
$form.Font            = New-Object System.Drawing.Font("Segoe UI", 10)
$form.FormBorderStyle = 'Sizable'
$form.MaximizeBox     = $true

# Title label
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text      = "Available Updates"
$lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lblTitle.AutoSize  = $true
$lblTitle.Location  = New-Object System.Drawing.Point(20, 20)
$lblTitle.Anchor    = 'Top,Left'
$form.Controls.Add($lblTitle)

# Include Cumulative checkbox
$chkCumulative = New-Object System.Windows.Forms.CheckBox
$chkCumulative.Text      = "Include Cumulative Updates"
$chkCumulative.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkCumulative.AutoSize  = $true
$chkCumulative.Location  = New-Object System.Drawing.Point(20, 50)
$chkCumulative.Anchor    = 'Top,Left'
$form.Controls.Add($chkCumulative)

# ListView for update items
$lv = New-Object System.Windows.Forms.ListView
$lv.View          = 'Details'
$lv.CheckBoxes    = $true
$lv.FullRowSelect = $true
$lv.BackColor     = [System.Drawing.ColorTranslator]::FromHtml("#3a3c43")
$lv.ForeColor     = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lv.Location      = New-Object System.Drawing.Point(20, 80)
$lv.Size          = New-Object System.Drawing.Size(540, 300)
$lv.Anchor        = 'Top,Bottom,Left,Right'
$lv.Columns.Add("Title", 300) | Out-Null
$lv.Columns.Add("KB", 80)    | Out-Null
$lv.Columns.Add("Size", 100) | Out-Null
$form.Controls.Add($lv)

# Progress bar track panel
$panelTrack = New-Object System.Windows.Forms.Panel
$panelTrack.Size        = New-Object System.Drawing.Size(540, 20)
$panelTrack.Location    = New-Object System.Drawing.Point(20, 400)
$panelTrack.BorderStyle = 'FixedSingle'
$panelTrack.BackColor   = [System.Drawing.ColorTranslator]::FromHtml("#4f4f4f")
$panelTrack.Anchor      = 'Left,Bottom,Right'
$form.Controls.Add($panelTrack)

# Progress bar fill panel
$panelFill = New-Object System.Windows.Forms.Panel
$panelFill.Size      = New-Object System.Drawing.Size(0, 18)
$panelFill.Location  = New-Object System.Drawing.Point(1, 1)
$panelFill.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
$panelTrack.Controls.Add($panelFill)

# Status label
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text      = "Status: Idle"
$lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lblStatus.AutoSize  = $true
$lblStatus.Location  = New-Object System.Drawing.Point(20, 430)
$lblStatus.Anchor    = 'Left,Bottom'
$form.Controls.Add($lblStatus)

# Install button
$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text      = "Install Selected"
$btnInstall.Size      = New-Object System.Drawing.Size(140, 30)
$btnInstall.Location  = New-Object System.Drawing.Point(420, 425)
$btnInstall.FlatStyle = 'Flat'
$btnInstall.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$btnInstall.FlatAppearance.BorderSize = 1
$btnInstall.Anchor    = 'Bottom,Right'
$form.Controls.Add($btnInstall)

# Function to load and list updates with loading indicator
function Load-Updates {
    # Show loading indicator
    $form.Cursor     = 'WaitCursor'
    $lblStatus.Text  = 'Status: Loading updates...'
    [System.Windows.Forms.Application]::DoEvents()

    # Clear and fetch
    $lv.Items.Clear()
    $criteria = "IsInstalled=0"  # include all types (software, drivers, etc.)
    $updates  = $WUASearcher.Search($criteria).Updates
    if (-not $chkCumulative.Checked) {
        $updates = $updates | Where-Object { $_.Title -notmatch 'Cumulative' }
    }

    # Populate list
    foreach ($u in $updates) {
        $item = New-Object System.Windows.Forms.ListViewItem($u.Title)
        $item.SubItems.Add($u.KB) | Out-Null
        $sizeMB = [math]::Round($u.Size/1MB, 1)
        $item.SubItems.Add("$sizeMB MB") | Out-Null
        $item.Tag = $u
        $lv.Items.Add($item) | Out-Null
    }

    # Reset cursor and status
    $form.Cursor    = 'Default'
    $lblStatus.Text = "Status: Ready (Found $($lv.Items.Count) updates)"
}

# Reload list when cumulative toggle changes\```
$chkCumulative.Add_CheckedChanged({ Load-Updates })
# Initial load
Load-Updates

# Handle Install button click with hide/unhide strategy
$btnInstall.Add_Click({
    $btnInstall.Enabled = $false

    # Determine excluded KBs
    $allKBs      = @()
    $excludedKBs = @()
    foreach ($item in $lv.Items) {
        $kb = $item.SubItems[1].Text
        $allKBs += $kb
        if (-not $item.Checked) { $excludedKBs += $kb }
    }

    # Hide unselected
    $lblStatus.Text = 'Status: Hiding unselected updates...'  
    foreach ($kb in $excludedKBs) {
        Hide-WindowsUpdate -KBArticleID $kb -Confirm:$false | Out-Null
    }

    # Install all remaining
    $lblStatus.Text = 'Status: Installing updates...'
    [System.Windows.Forms.Application]::DoEvents()
    Install-WindowsUpdate -AcceptAll -IgnoreReboot -Confirm:$false | Out-Null

    # Restore hidden updates
    $lblStatus.Text = 'Status: Restoring hidden updates...'
    foreach ($kb in $excludedKBs) {
        Show-WindowsUpdate -KBArticleID $kb -Confirm:$false | Out-Null
    }

    # Done
    $lblStatus.Text = 'Status: All updates installed.'
    Read-Host 'Press Enter to finish...' | Out-Null
    $form.Close()
})

# Show the form
[void]$form.ShowDialog()
