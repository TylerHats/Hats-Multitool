# Common File - Tyler Hatfield - v1.27

# Common Variables & packages:
if ($PSVersionTable.PSEdition -eq 'Core') {
    if (-not (Get-Module -ListAvailable -Name WindowsCompatibility)) {
    Install-Module -Name WindowsCompatibility -Scope CurrentUser -Force
    }
    Import-Module WindowsCompatibility
    Import-WinModule -Name 'System.Windows.Forms'
    Import-WinModule -Name 'System.Drawing.Common'
}
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
# $DesktopPath = [Environment]::GetFolderPath('Desktop')
# $DocumentsPath = [Environment]::GetFolderPath('MyDocuments')
# Locate active user Downloads directory
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
$InteractiveUser = (Get-CimInstance Win32_ComputerSystem).UserName
if ($InteractiveUser) {
    $UserAccount = New-Object System.Security.Principal.NTAccount($InteractiveUser)
    $UserSID = $UserAccount.Translate([System.Security.Principal.SecurityIdentifier]).Value
    $ProfilePath = (Get-CimInstance Win32_UserProfile | Where-Object SID -eq $UserSID).LocalPath
    $DownloadsPath = Join-Path -Path $ProfilePath -ChildPath "Downloads"
} else {
    # Fallback for headless environments
    $DownloadsPath = Join-Path -Path $env:USERPROFILE -ChildPath "Downloads"
}
$logPathName = "Hats-Multitool-Log.txt"
$logPath = Join-Path $DownloadsPath $logPathName
$global:TempLogPath = Join-Path $env:TEMP $logPathName
$global:HasErrors = $false
# Check for an IRM launch breadcrumb
$breadcrumbPath = Join-Path $env:PUBLIC "HMT_IRM_Target.txt"
$Global:IRMExeTarget = $null
if (Test-Path -LiteralPath $breadcrumbPath) {
    $Global:IRMExeTarget = Get-Content -LiteralPath $breadcrumbPath
    Remove-Item -LiteralPath $breadcrumbPath -Force -ErrorAction SilentlyContinue
}
$ProgramExiting = $false
$HMTIconPath = Join-Path -Path $PSScriptRoot -ChildPath "HMTIconSmall.ico"
#$HMTIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($HMTIconPath)
$HMTIcon = New-Object System.Drawing.Icon($HMTIconPath)
# $SetupScriptRuns = 0 # Used to prevent multiple runs of the setup script if the GUIs are nested by user
$g = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero)
$global:HMTScaleFactor = $g.DpiX / 96.0
$g.Dispose()

$scaledFontSize = [int](12 * $global:HMTScaleFactor)
$font = New-Object System.Drawing.Font("Segoe UI", $scaledFontSize, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)

try {
    $WindowsEdition = (Get-CimInstance Win32_OperatingSystem).Caption
} catch {
    $WindowsEdition = "Unknown Edition"
}

try {
	$serialNumber = (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
} catch {
	$serialNumber = "Unknown"
}

# Common Functions:

function Invoke-HMTScale {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Form]$TargetForm
    )
    if ($global:HMTScaleFactor -ne 1.0 -and $TargetForm.Tag -ne "Scaled") {
        $TargetForm.Scale((New-Object System.Drawing.SizeF($global:HMTScaleFactor, $global:HMTScaleFactor)))
        $TargetForm.Tag = "Scaled"
    }
    Set-DarkTitleBar -TargetForm $TargetForm
}

# Log-Message writes to log path and console
function Log-Message {
    param(
        [string]$message,
        [string]$level = "Info"  # Options: Info, Success, Error, Prompt, Skip
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$level] - $message"
    $consoleMessage = "[$level] - $message"
    if ($level.ToLower() -eq "info") {
        Write-Host $consoleMessage
    } elseif ($level.ToLower() -eq "prompt") {
        Write-Host -NoNewLine "$consoleMessage " -ForegroundColor "Yellow"
    } elseif ($level.ToLower() -eq "error") {
        Write-Host $consoleMessage -ForegroundColor "Red"
        $global:HasErrors = $true
        $logMessage | Out-File -FilePath $global:TempLogPath -Append
    } elseif ($level.ToLower() -eq "success") {
        Write-Host $consoleMessage -ForegroundColor "Green"
	} elseif ($level.ToLower() -eq "skip") {
		Write-Host $consoleMessage -ForegroundColor "Cyan"
    } elseif ($level.ToLower() -eq "logonly") {
		$logMessage | Out-File -FilePath $global:TempLogPath -Append
	} else {
        Write-Host $consoleMessage
        $logMessage | Out-File -FilePath $global:TempLogPath -Append
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

# constants for WM_SETICON
$WM_SETICON = 0x80
$ICON_SMALL = 0
$ICON_BIG   = 1

# grab our icon handle
$hIcon = $HMTIcon.Handle

# Apply icon to console window
$wParamSmall = New-Object System.IntPtr($ICON_SMALL)
$wParamBig   = New-Object System.IntPtr($ICON_BIG)
$hwnd = [HMT.NativeMethods]::GetConsoleWindow()
[HMT.NativeMethods]::SendMessage($hwnd, [uint32]$WM_SETICON, $wParamSmall, $hIcon) | Out-Null
[HMT.NativeMethods]::SendMessage($hwnd, [uint32]$WM_SETICON, $wParamBig,   $hIcon) | Out-Null

# Set a unique ID for Hat's Multitool
[HMT.NativeMethods]::SetCurrentProcessExplicitAppUserModelID("Hat.Multitool.App") | Out-Null

# Function to hide the console window
function Hide-ConsoleWindow {
    $consolePtr = [HMT.NativeMethods]::GetConsoleWindow()
    # 0 = Hide
    [HMT.NativeMethods]::ShowWindow($consolePtr, 0)
}

# Function to show the console window
function Show-ConsoleWindow {
    $consolePtr = [HMT.NativeMethods]::GetConsoleWindow()
    # 5 = Show normally
    [HMT.NativeMethods]::ShowWindow($consolePtr, 5)
    Start-Sleep -Milliseconds 50
    # Pull console window to focus
    $hwnd = [HMT.NativeMethods]::GetConsoleWindow()
	[HMT.NativeMethods]::ShowWindow($consolePtr, 9) | Out-Null
    [HMT.NativeMethods]::SetForegroundWindow($hwnd) | Out-Null
}

# Function to force a WinForms title bar into Dark Mode
function Set-DarkTitleBar {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Form]$TargetForm
    )
    $TargetForm.Handle | Out-Null
    $darkMode = 1
    [HMT.NativeMethods]::DwmSetWindowAttribute($TargetForm.Handle, 20, [ref]$darkMode, 4) | Out-Null
}

# Common function for user requested exits
function User-Exit {
    if ($script:ProgramExiting -ne $true) {
        $script:ProgramExiting = $true
        
        # Terminate GUI
        [System.Windows.Forms.Application]::OpenForms | ForEach-Object { $_.Hide() }
        [System.Windows.Forms.Application]::DoEvents()
        
        # Process final log output
        if ($global:HasErrors -eq $true) {
            Copy-Item -Path $global:TempLogPath -Destination $logPath -Force -ErrorAction SilentlyContinue
        }

        # Prepare cleanup command
        $cleanupCommand = "Wait-Process -Id $PID -ErrorAction SilentlyContinue; while (`$true) { `$lockingProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object { `$_.Path -like '$PSScriptRoot\*' }; if (-not `$lockingProcs) { break }; `$lockingProcs | Wait-Process -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1 }; Start-Sleep -Seconds 1; if (Test-Path -LiteralPath '$PSScriptRoot') { Remove-Item -LiteralPath '$PSScriptRoot' -Recurse -Force }; if ('$($Global:IRMExeTarget)' -ne '' -and (Test-Path -LiteralPath '$($Global:IRMExeTarget)')) { `$retry = 0; while ((Test-Path -LiteralPath '$($Global:IRMExeTarget)') -and `$retry -lt 5) { Remove-Item -LiteralPath '$($Global:IRMExeTarget)' -Force -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 500; `$retry++ } }; Remove-Item -LiteralPath '$($global:TempLogPath)' -Force -ErrorAction SilentlyContinue"
     
        # Execute async cleanup process
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -NonInteractive -WindowStyle Hidden -Command `"$cleanupCommand`""
        $psi.WorkingDirectory = $env:TEMP
        $psi.CreateNoWindow = $true
        $psi.UseShellExecute = $false
        [System.Diagnostics.Process]::Start($psi) | Out-Null

        # Terminate current process
        [System.Diagnostics.Process]::GetCurrentProcess().Kill()
    }
}

# Load GUI Configs
$GUIPath = Join-Path -Path $PSScriptRoot -ChildPath 'GUIs.ps1'
. "$GUIPath"

#GUI Functions
function Show-MainMenu {
	Hide-ConsoleWindow | Out-Null
    # Run the controller loop as long as the user hasn't explicitly exited
    while ($Global:NextAction -ne 'Exit') {
        
        switch ($Global:NextAction) {
            'Main' {
                [void]$MainMenu.ShowDialog() 
                
                if ($MainMenu.DialogResult -ne [System.Windows.Forms.DialogResult]::OK -and $Global:NextAction -eq 'Main') {
                    $Global:NextAction = 'Exit'
                }
            }
            
            'Setup' {
                [void]$ModGUI.ShowDialog()
                $Global:NextAction = 'Main' 
            }
            
            'Tools' {
                [void]$ToolsGUI.ShowDialog()
                $Global:NextAction = 'Main'
            }
            
            'Troubleshooting' {
                [void]$TroubleGUI.ShowDialog()
                $Global:NextAction = 'Main'
            }
            
            'About' {
                [void]$AboutGUI.ShowDialog()
                $Global:NextAction = 'Main'
            }
        }
    }
}

# Not used? Pending confirmation.
#function Show-RemindersPopup {
#	Hide-ConsoleWindow | Out-Null
#	$ReminderPopup.Show() | Out-Null
#	while ($ReminderPopup.Visible) {[System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50}
#}

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
	$script:dlCompleteClose = $false

    # Create the form
    $dform = New-Object System.Windows.Forms.Form
    $dform.Text = "Downloading $DisplayName..."
    $dform.ClientSize = [System.Drawing.Size]::new(500,120)
    $dform.FormBorderStyle = 'FixedDialog'
    $dform.MaximizeBox = $false
    $dform.MinimizeBox = $true
    $dform.StartPosition = 'CenterScreen'
	$dform.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
	$dform.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
	$dform.Font = $font
	$dform.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
	$dform.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None

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
    $webClient.Proxy = $null
    $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
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
        
        if ($e.Error) {
            # Safely alert user and clean up the corrupted trace file
            PopupError "Download failed: $($e.Error.Message)" "Error"
            if (Test-Path -LiteralPath $OutputPath) { 
                Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue 
            }
        } else {
            $script:dlCompleteClose = $true
        }

        $webClient.Dispose()
        $dform.Close()
    })
	
	$dform.Add_FormClosing({
		param($_sender, $e)
		# $e.CloseReason tells you why it's closing
		# UserClosing covers the “X” or Alt-F4
		if (($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing) -and ($script:dlCompleteClose -ne $true)) {
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
    Invoke-HMTScale $dform
    $dform.ShowDialog() | Out-Null

    # Remove Mark of the Web to bypass execution delays
    if (Test-Path -LiteralPath $OutputPath) {
        Unblock-File -LiteralPath $OutputPath -ErrorAction SilentlyContinue
    }
}

<#
Example usage:
Show-DownloadDialog -DisplayName 'Sample File' -Url 'https://example.com/file.zip' -OutputPath 'C:\Temp\file.zip'
#>
