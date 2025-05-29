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
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox     = $false

# Title label
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text      = "Available Updates"
$lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lblTitle.AutoSize  = $true
$lblTitle.Location  = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($lblTitle)

# Cumulative updates checkbox
$chkCumulative = New-Object System.Windows.Forms.CheckBox
$chkCumulative.Text      = "Include Cumulative Updates"
$chkCumulative.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkCumulative.AutoSize  = $true
$chkCumulative.Location  = New-Object System.Drawing.Point(20, 50)
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
$form.Controls.Add($lblStatus)

# Install button
$btnInstall = New-Object System.Windows.Forms.Button
$btnInstall.Text      = "Install Selected"
$btnInstall.Size      = New-Object System.Drawing.Size(140, 30)
# Use System.Drawing.Point instead of System.Windows.Forms.Point
$btnInstall.Location  = New-Object System.Drawing.Point(420, 425)
$btnInstall.FlatStyle = 'Flat'
$btnInstall.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$btnInstall.FlatAppearance.BorderSize = 1
$form.Controls.Add($btnInstall)

# Function to load and list updates
function Load-Updates {
    $lv.Items.Clear()
    $criteria = "IsInstalled=0 and Type='Software'"
    $updates = $WUASearcher.Search($criteria).Updates
    if (-not $chkCumulative.Checked) {
        $updates = $updates | Where-Object { $_.Title -notmatch 'Cumulative' }
    }
    foreach ($u in $updates) {
        $item = New-Object System.Windows.Forms.ListViewItem($u.Title)
        $item.SubItems.Add($u.KB) | Out-Null
        $sizeMB = [math]::Round($u.Size/1MB, 1)
        $item.SubItems.Add("$sizeMB MB") | Out-Null
        $item.Tag = $u
        $lv.Items.Add($item) | Out-Null
    }
    $lblStatus.Text = "Status: Ready (Found $($lv.Items.Count) updates)"
}

# Reload list when cumulative toggle changes
$chkCumulative.Add_CheckedChanged({ Load-Updates })
# Initial load
Load-Updates

# Handle Install button click
$btnInstall.Add_Click({
    $btnInstall.Enabled = $false
    $selected = $lv.CheckedItems
    $count    = $selected.Count
    if ($count -eq 0) {
        $lblStatus.Text = 'Status: No updates selected'
        return
    }

    $i = 0
    foreach ($item in $selected) {
        $i++
        $update  = $item.Tag
        $percent = [int]($i / $count * 100)
        $panelFill.Width = [int]($panelTrack.ClientSize.Width * $percent / 100)
        $lblStatus.Text  = "Installing: $($update.Title)"
        # Perform the install
        Install-WindowsUpdate -Updates $update -AcceptAll -IgnoreReboot -Confirm:$false | Out-Null
    }

    $lblStatus.Text = 'Status: All updates installed.'
    Read-Host 'Press Enter to finish...' | Out-Null
    $form.Close()
})

# Show the form
[void]$form.ShowDialog()