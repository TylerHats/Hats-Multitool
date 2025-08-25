# Windows Update GUI Module - Tyler Hatfield - v1.6

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

# Load common items
Write-Host "Loading: Windows Update GUI..."
if ($PSVersionTable.PSEdition -eq 'Core') {
    if (-not (Get-Module -ListAvailable WindowsCompatibility)) {Install-Module -Name WindowsCompatibility -Scope CurrentUser -Force}   # only once
    Import-Module WindowsCompatibility
    Import-WinModule -Name 'System.Windows.Forms'
    Import-WinModule -Name 'System.Drawing.Common'
}
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$logPathName = "Hats-Multitool-Log.txt"
$logPath = Join-Path $DesktopPath $logPathName
$UserExit = $false
$WinUpdatesRun = $false
$GUIClosed = $false
$ProgramExiting = $false
$HMTIconPath = Join-Path -Path $PSScriptRoot -ChildPath "HMTIconSmall.ico"
#$HMTIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($HMTIconPath)
$HMTIcon = New-Object System.Drawing.Icon($HMTIconPath)
$SetupScriptRuns = 0 # Used to prevent multiple runs of the setup script if the GUIs are nested by user
$font = New-Object System.Drawing.Font("Segoe UI", 10)
[System.Windows.Forms.Application]::EnableVisualStyles() # Allows use of current Windows Theme/Style
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false) # Allows High-DPI rendering for text and features

# Load C classes for required window management
# Load required functions to interact with Windows
# Used for PowerShell Console window show/hide interactions
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
	[DllImport("user32.dll")]   
	public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
}
"@

# constants for WM_SETICON
$WM_SETICON = 0x80
$ICON_SMALL = 0
$ICON_BIG   = 1

# grab our icon handle
$hIcon = $HMTIcon.Handle

# get the console window and swap in our icon
$wParamSmall = New-Object System.IntPtr($ICON_SMALL)
$wParamBig   = New-Object System.IntPtr($ICON_BIG)
$hwnd = [Win32]::GetConsoleWindow()
[Win32]::SendMessage($hwnd, $WM_SETICON, $wParamSmall, $hIcon) | Out-Null
[Win32]::SendMessage($hwnd, $WM_SETICON, $wParamBig,   $hIcon) | Out-Null

# Used for PowerShell Console window focusing and GUI theming
$code = @"
using System;
using System.Runtime.InteropServices;

namespace ConsoleUtils {
    public static class NativeMethods {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetConsoleWindow();

        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);

        // If you need ShowWindow:
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

        [DllImport("uxtheme.dll", ExactSpelling=true, CharSet=CharSet.Unicode)]
        public static extern int SetWindowTheme(IntPtr hWnd, string pszSubAppName, string pszSubIdList);
    }
}
"@
Add-Type -TypeDefinition $code -Language CSharp

# Used to control DPI rendering of Forms GUIS
$dpiCode = @"
using System;
using System.Runtime.InteropServices;

namespace MyApp.Helpers {
    public static class DPI {
        [DllImport("user32.dll")]
        public static extern bool SetProcessDPIAware();
    }
}
"@
Add-Type -TypeDefinition $dpiCode -Language CSharp
[MyApp.Helpers.DPI]::SetProcessDPIAware() | Out-Null

# Function to hide the console window
function Hide-ConsoleWindow {
    $consolePtr = [Win32]::GetConsoleWindow()
    # 0 = Hide
    [Win32]::ShowWindow($consolePtr, 0)
}

# Function to show the console window
function Show-ConsoleWindow {
    $consolePtr = [Win32]::GetConsoleWindow()
    # 5 = Show normally
    [Win32]::ShowWindow($consolePtr, 5)
    Start-Sleep -Milliseconds 50
    # Pull console window to focus
    $hwnd = [ConsoleUtils.NativeMethods]::GetConsoleWindow()
	[Win32]::ShowWindow($consolePtr, 9) | Out-Null
    [ConsoleUtils.NativeMethods]::SetForegroundWindow($hwnd) | Out-Null
}

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
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font

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
$lv.Size          = [System.Drawing.Size]::new(560,60)
$lv.Columns.Add("Title",360) | Out-Null
$lv.Columns.Add("KB",80)     | Out-Null
$lv.Columns.Add("Size",100)  | Out-Null
$form.Controls.Add($lv)

# --- Status label ---
$lblStatus = [System.Windows.Forms.Label]::new()
$lblStatus.Text      = "Status: Idle"
$lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lblStatus.AutoSize  = $true
$lblStatus.Location  = [System.Drawing.Point]::new(20,165)
$form.Controls.Add($lblStatus)

# --- Install button ---
$btnInstall = [System.Windows.Forms.Button]::new()
$btnInstall.Text      = "Install Updates"
$btnInstall.Size      = [System.Drawing.Size]::new(140,30)
$btnInstall.Location  = [System.Drawing.Point]::new(440,160)
$btnInstall.FlatStyle = 'Flat'
$btnInstall.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$btnInstall.FlatAppearance.BorderSize = 1
$form.Controls.Add($btnInstall)
$form.AcceptButton = $btnInstall

# --- Function to load updates and resize form dynamically ---
function Load-Updates {
    $form.Cursor    = 'WaitCursor'
    $lblStatus.Text = 'Loading updates...'
    [System.Windows.Forms.Application]::DoEvents()

    # Retrieve list via PSWindowsUpdate
    try {
        $list = Get-WindowsUpdate -AcceptAll -IgnoreReboot -Verbose:$false
    } catch {
        $lblStatus.Text = 'Update list failed to load.'
    }
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

# --- Load intial updates after form open ---
$form.Add_Shown({
	Load-Updates
})

# --- Show the GUI ---
[void]$form.ShowDialog()