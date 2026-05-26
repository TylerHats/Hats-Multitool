# Common File - Tyler Hatfield - v1.17

# Common Variables & packages:
if ($PSVersionTable.PSEdition -eq 'Core') {
    Install-Module -Name WindowsCompatibility -Scope CurrentUser -Force   # only once
    Import-Module WindowsCompatibility
    Import-WinModule -Name 'System.Windows.Forms'
    Import-WinModule -Name 'System.Drawing.Common'
}
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$DocumentsPath = [Environment]::GetFolderPath('MyDocuments')
$logPathName = "Hats-Multitool-Log.txt"
$logPath = Join-Path $DocumentsPath $logPathName
$UserExit = $false
$GUIClosed = $false
$ProgramExiting = $false
$HMTIconPath = Join-Path -Path $PSScriptRoot -ChildPath "HMTIconSmall.ico"
#$HMTIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($HMTIconPath)
$HMTIcon = New-Object System.Drawing.Icon($HMTIconPath)
$SetupScriptRuns = 0 # Used to prevent multiple runs of the setup script if the GUIs are nested by user
$font = New-Object System.Drawing.Font("Segoe UI", 10)

try {
    $WindowsEdition = (Get-CimInstance Win32_OperatingSystem).Caption
} catch {
    try {
        $WindowsEdition = (Get-WmiObject Win32_OperatingSystem).Caption
    } catch {
        $WindowsEdition = "Unknown Edition"
    }
}

try {
	$serialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber
} catch {
	try {
		$serialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
	} catch {
		$serialNumber = "Unknown"
	}
}

# Common Functions:
# Log-Message takes a string or command output and sends it both to the registered $logPath and the PS consol
function Log-Message {
    param(
        [string]$message,
        [string]$level = "Info"  # Options: Info, Success, Error, Prompt, Skip
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$level] - $message"
    $consoleMessage = "[$level] - $message"
    $logMessage | Out-File -FilePath $logPath -Append  # Write to log
    if ($level.ToLower() -eq "info") {
        Write-Host $consoleMessage  # Output to console
    } elseif ($level.ToLower() -eq "prompt") {
        Write-Host -NoNewLine "$consoleMessage " -ForegroundColor "Yellow"
    } elseif ($level.ToLower() -eq "error") {
        Write-Host $consoleMessage -ForegroundColor "Red"
    } elseif ($level.ToLower() -eq "success") {
        Write-Host $consoleMessage -ForegroundColor "Green"
	} elseif ($level.ToLower() -eq "skip") {
		Write-Host $consoleMessage -ForegroundColor "Cyan"
    } elseif ($level.ToLower() -eq "logonly") {
		$null = $null
	} else {
        Write-Host $consoleMessage
    }
}

function PopupError {
	param(
		[string]$ErrorMessage,
		[ValidateSet('Information','Warning','Error','None')] [string]$Style = 'Error'
	)
	$icon = [System.Windows.Forms.MessageBoxIcon]$Style
	[void][System.Windows.Forms.MessageBox]::Show(
		"$ErrorMessage",
		"Hat's Multitool",
		[System.Windows.Forms.MessageBoxButtons]::OK,
		$icon
	)
}

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

<#
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
#>

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

# Common function for user requested exits
function User-Exit {
    # Added $script: scope modifier just in case this is called from a nested context
    if ($script:ProgramExiting -ne $true) {
        $script:ProgramExiting = $true
        
        # Signal Forms to close (optional but good practice)
        [System.Windows.Forms.Application]::Exit()
        
        # Build the exact script we want the background process to run
        # Expanding the variables here before encoding ensures exact paths are used
        $cleanupCommand = @"
Wait-Process -Id $PID -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1 # Brief buffer to ensure Windows fully releases file locks
if (Test-Path -LiteralPath "$PSScriptRoot") {
    Remove-Item -LiteralPath "$PSScriptRoot" -Recurse -Force
}
Add-Content -LiteralPath "$logPath" -Value 'Script self cleanup completed'
"@

        # Encode to Base64 to prevent any quote escaping issues in the command line
        $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($cleanupCommand))
        
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName        = 'powershell.exe'
        $psi.Arguments       = "-NoProfile -WindowStyle Hidden -EncodedCommand $encodedCommand"
        
        # CRITICAL: Change the working directory so the new process doesn't lock $PSScriptRoot
        $psi.WorkingDirectory = $env:TEMP 
        $psi.CreateNoWindow  = $true
        $psi.UseShellExecute = $false
        
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        
        # Immediately terminate the current process
        [System.Environment]::Exit(0)
    }
}

# Load GUI Configs
$GUIPath = Join-Path -Path $PSScriptRoot -ChildPath 'GUIs.ps1'
. "$GUIPath"

#GUI Functions
function Show-MainMenu {
	Hide-ConsoleWindow | Out-Null
	$MainMenu.Show() | Out-null
	while ($MainMenu.Visible -or $GUIClosed -ne $true) {[System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50} 
	$GUIClosed = $false
	if ($UserExit -eq $true) {User-Exit}
}

function Show-ModGUI {
	Hide-ConsoleWindow | Out-Null
	$ModGUI.Show() | Out-null
	while ($ModGUI.Visible -or $GUIClosed -ne $true) {[System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50}
	$GUIClosed = $false
	if ($UserExit -eq $true) {User-Exit}
}

function Show-RemindersPopup {
	Hide-ConsoleWindow | Out-Null
	$ReminderPopup.Show() | Out-Null
	while ($ReminderPopup.Visible -or $GUIClosed -ne $true) {[System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50}
	$GUIClosed = $false
	if ($UserExit -eq $true) {User-Exit}
}

function Show-ToolsGUI {
    Hide-ConsoleWindow | Out-Null
    $ToolsGUI.Show() | Out-Null
    while ($ToolsGUI.Visible -or $GUIClosed -ne $true) {[System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50}
    $GUIClosed = $false
    if ($UserExit -eq $true) {User-Exit}
}

function Show-TroubleGUI {
    Hide-ConsoleWindow | Out-Null
    $TroubleGUI.Show() | Out-Null
    while ($TroubleGUI.Visible -or $GUIClosed -ne $true) {[System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50}
    $GUIClosed = $false
    if ($UserExit -eq $true) {User-Exit}
}

function Show-DownloadDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DisplayName,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Url
    )

	Log-Message "Starting download of file: $DisplayName" "logonly"
    Add-Type -AssemblyName System.Windows.Forms,System.Drawing
	$dlCompleteClose = $false

    # Create the form
    $dform = New-Object System.Windows.Forms.Form
    $dform.Text = "Downloading $DisplayName..."
    $dform.ClientSize = [System.Drawing.Size]::new(500,120)
    $dform.FormBorderStyle = 'FixedDialog'
    $dform.MaximizeBox = $false
    $dform.MinimizeBox = $false
    $dform.StartPosition = 'CenterScreen'
	$dform.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
	$dform.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
	$dform.Font = $font
	$dform.AutoScaleMode = [Windows.Forms.AutoScaleMode]::Font

    # Container panel with border
    $trackPanel = New-Object System.Windows.Forms.Panel
    $trackPanel.Size        = [System.Drawing.Size]::new(462,22)
    $trackPanel.Location    = [System.Drawing.Point]::new(14,19)
    $trackPanel.BorderStyle = 'FixedSingle'
    $trackPanel.BackColor   = [System.Drawing.Color]::DarkGray
    $dform.Controls.Add($trackPanel)

    # Fill panel for progress
    $fillPanel = New-Object System.Windows.Forms.Panel
    $fillPanel.Size      = [System.Drawing.Size]::new(0,19)
    $fillPanel.Location  = [System.Drawing.Point]::new(1,1)
    $fillPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
    $trackPanel.Controls.Add($fillPanel)

    # Speed label
    $speedLabel = New-Object System.Windows.Forms.Label
    $speedLabel.AutoSize = $true
    $speedLabel.Location = [System.Drawing.Point]::new(15,50)
    $speedLabel.Text = "Speed: 0 Mbps"
	$speedLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $dform.Controls.Add($speedLabel)

    # Stats label (downloaded / total)
    $statsLabel = New-Object System.Windows.Forms.Label
    $statsLabel.AutoSize = $true
    $statsLabel.Location = [System.Drawing.Point]::new(15,75)
    $statsLabel.Text = "0 MB / 0 MB"
	$statsLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $dform.Controls.Add($statsLabel)

    # Timer to keep UI responsive
    $uiTimer = New-Object System.Windows.Forms.Timer
    $uiTimer.Interval = 100     # reduce interval for snappier UI
    $uiTimer.add_Tick({ [System.Windows.Forms.Application]::DoEvents() })
    $uiTimer.Start()

    # WebClient and stopwatch
    $webClient = New-Object System.Net.WebClient
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Progress event updates fill panel width and labels
    $webClient.add_DownloadProgressChanged({ param($s,$e)
        # Calculate fill width
        $percent = $e.ProgressPercentage / 100
        $maxWidth = $trackPanel.ClientSize.Width - 2  # account for border
        $fillPanel.Width = [int]($maxWidth * $percent)
        # Update speed label
        $speedMbps = (($e.BytesReceived * 8) / 1MB) / $stopwatch.Elapsed.TotalSeconds
        $speedLabel.Text = ('Speed: {0:N2} Mbps' -f $speedMbps)
        # Update stats label
        $downloadedMB = $e.BytesReceived / 1MB
        $totalMB      = $e.TotalBytesToReceive / 1MB
		if ($totalMB -lt 1000) {
			$statsLabel.Text = ('{0:N2} MB / {1:N2} MB' -f $downloadedMB, $totalMB)
		} else {
			$totalGB = $totalMB / 1000
			$downloadedGB = $downloadedMB / 1000
			$statsLabel.Text = ('{0:N2} GB / {1:N2} GB' -f $downloadedGB, $totalGB)
		}
    })

    # Completion event stops timer and closes form
    $webClient.add_DownloadFileCompleted({ param($s,$e)
        $uiTimer.Stop()
        $webClient.Dispose()
		$dlCompleteClose = $true
        $dform.Close()
    })
	
	$dform.Add_FormClosing({
		param($sender, $e)
		# $e.CloseReason tells you why it's closing
		# UserClosing covers the “X” or Alt-F4
		if (($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing) -and ($dlCompleteClose -ne $true)) {
			# Do your “cleanup” or alternate logic here
			if ($webClient.IsBusy) {
				$e.Cancel = $true             # prevent immediate close; wait for Completed event
				$uiTimer.Stop()
				$webClient.CancelAsync()
				return
			}
			# Not busy: allow close; dispose safely
			try { $uiTimer.Stop() } catch {}
			try { $webClient.Dispose() } catch {}
		}
	})

    # Start async download
    try { $webClient.DownloadFileAsync([Uri]$Url, $OutputPath) }
    catch { [System.Windows.Forms.MessageBox]::Show("Failed to start download: $_", "Error", 'OK', 'Error') | Out-Null; $uiTimer.Stop(); Log-Message "Failed to download file: $DisplayName" "logonly"; return }

    # Show dialog until done
    $dform.ShowDialog() | Out-Null
}

<#
Example usage:
Show-DownloadDialog -DisplayName 'Sample File' -Url 'https://example.com/file.zip' -OutputPath 'C:\Temp\file.zip'
#>
