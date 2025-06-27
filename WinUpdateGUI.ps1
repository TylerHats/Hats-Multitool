# Windows Update GUI Module - Tyler Hatfield - v1.5

# Script Setup
$failedResize = 0
$failedColor = 0
try {
	$dWidth = (Get-Host).UI.RawUI.BufferSize.Width
	$dHeight = 10
	$rawUI = $Host.UI.RawUI
	$newSize = New-Object System.Management.Automation.Host.Size ($dWidth, $dHeight)
	$rawUI.WindowSize = $newSize
} catch {
	try {
		$dWidth = (Get-Host).UI.RawUI.BufferSize.Width
		$dHeight = 20
		$rawUI = $Host.UI.RawUI
		$newSize = New-Object System.Management.Automation.Host.Size ($dWidth, $dHeight)
		$rawUI.WindowSize = $newSize
	} catch {
		$failedResize = 1
	}
}
try {
	$host.UI.RawUI.BackgroundColor = "Black"
} catch {
	$failedColor = 1
}

# Load common file
Write-Host "Loading: Windows Update GUI..."
$commonPath = Join-Path -Path $PSScriptRoot -ChildPath 'Common.ps1'
. "$commonPath"

# Import, or download, PSWindowsUpdate module and set DO Mode
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
    Register-PSRepository -Default
}
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
if (-not (Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -Force | Out-Null
}
try {
	Import-Module PSWindowsUpdate -ErrorAction Stop
} catch {
    Install-Module -Name PSWindowsUpdate -Scope CurrentUser -Force
    Import-Module PSWindowsUpdate
}
Import-Module DeliveryOptimization
Set-DODownloadMode -downloadMode Internet
Restart-Service -Name DoSvc -ErrorAction SilentlyContinue

# Hide console for GUI
Hide-ConsoleWindow | Out-Null

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
$form.AutoScaleMode = [Windows.Forms.AutoScaleMode]::Font

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
$lv.CheckBoxes    = $false
$lv.FullRowSelect = $true
$lv.Scrollable    = $true
$lv.BackColor     = [System.Drawing.ColorTranslator]::FromHtml("#3a3c43")
$lv.ForeColor     = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lv.Location      = [System.Drawing.Point]::new(20,80)
$lv.Size          = [System.Drawing.Size]::new(560,50)
$lv.Columns.Add("Title",360) | Out-Null
$lv.Columns.Add("KB",80)     | Out-Null
$lv.Columns.Add("Size",100)  | Out-Null
$form.Controls.Add($lv)

# --- Status label ---
$lblStatus = [System.Windows.Forms.Label]::new()
$lblStatus.Text      = "Status: Idle"
$lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lblStatus.AutoSize  = $true
$lblStatus.Location  = [System.Drawing.Point]::new(20,170)
$form.Controls.Add($lblStatus)

# --- Install button ---
$btnInstall = [System.Windows.Forms.Button]::new()
$btnInstall.Text      = "Install Updates"
$btnInstall.Size      = [System.Drawing.Size]::new(140,30)
$btnInstall.Location  = [System.Drawing.Point]::new(440,165)
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
    if ($lv.Items.Count -gt 10) {
        $NewLVH = 300
        $lv.Height = $NewLVH
    }elseif ($lv.Items.Count -gt 0) {
        $NewLVH = ($lv.Items.Count * 28)
		$lv.Height = $NewLVH
	} else {
		$NewLVH = 40
		$lv.Height = $NewLVH
	}

    # Reposition and resize form
    $yBase = 80 + $NewLVH
    $lblStatus.Location  = [System.Drawing.Point]::new(20, $yBase + 35)
    $btnInstall.Location = [System.Drawing.Point]::new(440, $yBase + 30)
    $form.ClientSize = [System.Drawing.Size]::new(600, $yBase + 70)

    $form.Cursor    = 'Default'
    $lblStatus.Text = "Status: Ready (Found $($lv.Items.Count) updates)"
}

# --- Wire up toggle and initial load ---
$chkCumulative.Add_CheckedChanged({
    if ($chkCumulative.Checked){
        $env:installCumulativeWU = "y"
    } else {
        $env:installCumulativeWU = "n"
    }
	Load-Updates
})

# --- Install button click: hide/unhide strategy via PSWindowsUpdate ---
$btnInstall.Add_Click({
    $btnInstall.Enabled = $false
	$WindowsUpdateModPath = Join-Path -Path $PSScriptRoot -ChildPath 'WindowsUpdate.ps1'
	Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass", "-File `"$WindowsUpdateModPath`""
    $form.Close()
})

# --- Show the GUI ---
[void]$form.ShowDialog()
Load-Updates