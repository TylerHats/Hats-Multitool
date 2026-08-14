# Common File - Tyler Hatfield - v2.0

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

# Check for an IRM launch breadcrumb
$breadcrumbPath = Join-Path $env:PUBLIC "HMT_IRM_Target.txt"
$Global:IRMExeTarget = $null
if (Test-Path -LiteralPath $breadcrumbPath) {
    $Global:IRMExeTarget = Get-Content -LiteralPath $breadcrumbPath
    Remove-Item -LiteralPath $breadcrumbPath -Force -ErrorAction SilentlyContinue
}

$global:ExeDir = if ($Global:IRMExeTarget -and (Test-Path -LiteralPath (Split-Path -Parent $Global:IRMExeTarget))) {
    Split-Path -Parent $Global:IRMExeTarget
} elseif ($PSScriptRoot) {
    $PSScriptRoot
} else {
    [System.AppDomain]::CurrentDomain.BaseDirectory
}
$global:logPath = Join-Path $global:ExeDir $logPathName
$global:TempLogPath = Join-Path $env:TEMP $logPathName
$global:HasErrors = $false

$ProgramExiting = $false
$HMTIconPath = Join-Path -Path $PSScriptRoot -ChildPath "HMTIconSmall.ico"
#$HMTIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($HMTIconPath)
$HMTIcon = New-Object System.Drawing.Icon($HMTIconPath)
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
        [string]$level = "Info"  # Options: Info, Success, Error, Prompt, Skip, LogOnly
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$level] - $message"
    $consoleMessage = "[$level] - $message"
    
    $isError = ($level.ToLower() -eq "error")
    if ($isError) {
        $global:HasErrors = $true
        try {
            $logMessage | Out-File -FilePath $global:logPath -Append -ErrorAction SilentlyContinue
        } catch {}
    }

    if ($level.ToLower() -eq "info") {
        Write-Host $consoleMessage
    } elseif ($level.ToLower() -eq "prompt") {
        Write-Host -NoNewLine "$consoleMessage " -ForegroundColor "Yellow"
    } elseif ($level.ToLower() -eq "error") {
        Write-Host $consoleMessage -ForegroundColor "Red"
    } elseif ($level.ToLower() -eq "success") {
        Write-Host $consoleMessage -ForegroundColor "Green"
    } elseif ($level.ToLower() -eq "skip") {
        Write-Host $consoleMessage -ForegroundColor "Cyan"
    } elseif ($level.ToLower() -eq "logonly") {
        # Silent console output; non-error
    } else {
        Write-Host $consoleMessage
    }
}

# Trap uncaught script errors globally and record them
trap {
    $errObj = $_
    $errMsg = if ($errObj.Exception -and $errObj.Exception.GetBaseException()) { $errObj.Exception.GetBaseException().Message } else { $errObj.ToString() }
    Log-Message "Unhandled Exception: $errMsg" "Error"
    continue
}

function Show-CustomMessageBox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Title = "Hat's Multitool",
        [ValidateSet('Information', 'Warning', 'Error', 'Question', 'None')]
        [string]$Style = 'Information',
        [ValidateSet('OK', 'OKCancel', 'YesNo')]
        [string]$Buttons = 'OK'
    )

    Add-Type -AssemblyName System.Windows.Forms, System.Drawing

    $msgForm = New-Object System.Windows.Forms.Form
    $msgForm.Text = $Title
    $msgForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $msgForm.StartPosition = 'CenterScreen'
    if ($HMTIcon) { $msgForm.Icon = $HMTIcon }
    $msgForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $msgForm.MaximizeBox = $false
    $msgForm.MinimizeBox = $false
    $msgForm.ShowInTaskbar = $true
    $msgForm.Font = $font
    $msgForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $msgForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $msgForm

    $accentColor = switch ($Style) {
        'Error'       { [System.Drawing.ColorTranslator]::FromHtml("#ED4245") }
        'Warning'     { [System.Drawing.ColorTranslator]::FromHtml("#FEE75C") }
        'Question'    { [System.Drawing.ColorTranslator]::FromHtml("#5865F2") }
        'Information' { [System.Drawing.ColorTranslator]::FromHtml("#6f1fde") }
        Default       { [System.Drawing.ColorTranslator]::FromHtml("#6f1fde") }
    }

    # Left decorative accent bar
    $accentBar = New-Object System.Windows.Forms.Panel
    $accentBar.Location = New-Object System.Drawing.Point(0, 0)
    $accentBar.Size = New-Object System.Drawing.Size(6, 400)
    $accentBar.BackColor = $accentColor
    $msgForm.Controls.Add($accentBar)

    $msgLabel = New-Object System.Windows.Forms.Label
    $msgLabel.Text = $Message
    $msgLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $msgLabel.Location = New-Object System.Drawing.Point(25, 25)
    $msgLabel.MaximumSize = New-Object System.Drawing.Size(430, 0)
    $msgLabel.AutoSize = $true
    $msgForm.Controls.Add($msgLabel)

    $btnPanel = New-Object System.Windows.Forms.Panel
    $btnPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $btnPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
    $btnPanel.Height = 60
    $msgForm.Controls.Add($btnPanel)

    $createdButtons = @()
    if ($Buttons -eq 'YesNo') {
        $btnYes = New-Object System.Windows.Forms.Button
        $btnYes.Text = "Yes"
        $btnYes.Size = New-Object System.Drawing.Size(85, 34)
        $btnYes.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $btnYes.FlatStyle = 'Flat'
        $btnYes.FlatAppearance.BorderSize = 1
        $btnYes.DialogResult = [System.Windows.Forms.DialogResult]::Yes
        $btnPanel.Controls.Add($btnYes)
        $createdButtons += $btnYes

        $btnNo = New-Object System.Windows.Forms.Button
        $btnNo.Text = "No"
        $btnNo.Size = New-Object System.Drawing.Size(85, 34)
        $btnNo.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $btnNo.FlatStyle = 'Flat'
        $btnNo.FlatAppearance.BorderSize = 1
        $btnNo.DialogResult = [System.Windows.Forms.DialogResult]::No
        $btnPanel.Controls.Add($btnNo)
        $createdButtons += $btnNo

        $msgForm.AcceptButton = $btnYes
        $msgForm.CancelButton = $btnNo
    }
    elseif ($Buttons -eq 'OKCancel') {
        $btnOK = New-Object System.Windows.Forms.Button
        $btnOK.Text = "OK"
        $btnOK.Size = New-Object System.Drawing.Size(85, 34)
        $btnOK.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $btnOK.FlatStyle = 'Flat'
        $btnOK.FlatAppearance.BorderSize = 1
        $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $btnPanel.Controls.Add($btnOK)
        $createdButtons += $btnOK

        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Text = "Cancel"
        $btnCancel.Size = New-Object System.Drawing.Size(85, 34)
        $btnCancel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $btnCancel.FlatStyle = 'Flat'
        $btnCancel.FlatAppearance.BorderSize = 1
        $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $btnPanel.Controls.Add($btnCancel)
        $createdButtons += $btnCancel

        $msgForm.AcceptButton = $btnOK
        $msgForm.CancelButton = $btnCancel
    }
    else {
        $btnOK = New-Object System.Windows.Forms.Button
        $btnOK.Text = "OK"
        $btnOK.Size = New-Object System.Drawing.Size(85, 34)
        $btnOK.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $btnOK.FlatStyle = 'Flat'
        $btnOK.FlatAppearance.BorderSize = 1
        $btnOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $btnPanel.Controls.Add($btnOK)
        $createdButtons += $btnOK

        $msgForm.AcceptButton = $btnOK
        $msgForm.CancelButton = $btnOK
    }

    $msgForm.Add_Load({
        Invoke-HMTScale $msgForm
        foreach ($b in $createdButtons) {
            Set-RoundedControl $b
        }
        $scaledPadding = [int](30 * $global:HMTScaleFactor)
        $minW = [int](360 * $global:HMTScaleFactor)
        $calcW = [math]::Max($minW, ($msgLabel.Right + $scaledPadding))
        $calcH = $msgLabel.Bottom + [int](85 * $global:HMTScaleFactor)
        $msgForm.ClientSize = New-Object System.Drawing.Size($calcW, $calcH)

        # Right-align buttons inside bottom panel
        $btnY = ($btnPanel.ClientSize.Height - $createdButtons[0].Height) / 2
        $currX = $btnPanel.ClientSize.Width - [int](20 * $global:HMTScaleFactor)
        for ($i = $createdButtons.Count - 1; $i -ge 0; $i--) {
            $currX -= $createdButtons[$i].Width
            $createdButtons[$i].Location = New-Object System.Drawing.Point($currX, $btnY)
            $currX -= [int](10 * $global:HMTScaleFactor)
        }
    })

    return (Show-HMTDialog $msgForm)
}

function Format-HMTError {
    param(
        [Parameter(Mandatory = $true)]
        $ErrorRecord,
        [string]$Context = ""
    )

    $rawMsg = if ($ErrorRecord -is [string]) { 
        $ErrorRecord 
    } elseif ($ErrorRecord.Exception -and $ErrorRecord.Exception.GetBaseException()) { 
        $ErrorRecord.Exception.GetBaseException().Message 
    } else { 
        $ErrorRecord.ToString() 
    }

    $cleanMsg = $rawMsg
    if ($rawMsg -match "1326|0x8007052E|Logon failure|unknown user name or bad password|user name or password is incorrect") {
        $cleanMsg = "Authentication Failed: The username or password provided was incorrect."
    }
    elseif ($rawMsg -match "1355|0x8007054B|domain.*could not be contacted|specified domain either does not exist") {
        $cleanMsg = "Domain Not Found: Could not contact a domain controller. Please verify your network connection and DNS settings."
    }
    elseif ($rawMsg -match "5|0x80070005|Access is denied|General access denied") {
        $cleanMsg = "Access Denied: The specified credentials do not have administrative permission to complete this action."
    }
    elseif ($rawMsg -match "2224|0x80070524|account already exists|object already exists") {
        $cleanMsg = "Account Conflict: An account with this computer name already exists on the domain."
    }
    elseif ($rawMsg -match "53|0x80070035|network path was not found") {
        $cleanMsg = "Network Error: The network path could not be found. Check connectivity to the remote server."
    }
    elseif ($rawMsg -match "Exception calling|FullyQualifiedErrorId|System.Management.Automation") {
        $cleanMsg = ($rawMsg -split ':\s*', 2)[-1].Trim()
    }

    if (-not [string]::IsNullOrWhiteSpace($Context)) {
        return "$Context`n`n$cleanMsg"
    }
    return $cleanMsg
}

function PopupError {
	param(
		[string]$ErrorMessage,
		[ValidateSet('Information','Warning','Error','None','Question')] [string]$Style = 'Error',
        [ValidateSet('OK', 'OKCancel', 'YesNo')] [string]$Buttons = 'OK'
	)
    return Show-CustomMessageBox -Message $ErrorMessage -Style $Style -Buttons $Buttons
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

# Function to force a WinForms title bar into Dark Mode and rounded corners
function Set-DarkTitleBar {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Form]$TargetForm
    )
    $TargetForm.Handle | Out-Null
    $darkMode = 1
    [HMT.NativeMethods]::DwmSetWindowAttribute($TargetForm.Handle, 20, [ref]$darkMode, 4) | Out-Null
    $cornerPref = 2
    [HMT.NativeMethods]::DwmSetWindowAttribute($TargetForm.Handle, 33, [ref]$cornerPref, 4) | Out-Null
}

function Set-RoundedControl {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Control]$Control,
        [int]$Radius = 5
    )
    if ($null -eq $Control) { return }

    if ($Control -is [System.Windows.Forms.Button]) {
        $Control.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
        $Control.FlatAppearance.BorderSize = 0
        $Control.TabStop = $false

        if ($Control.Tag -ne "RoundedButtonBound") {
            $Control.Tag = "RoundedButtonBound"

            $redrawScript = { if ($this.Width -gt 0 -and $this.Height -gt 0) { $this.Invalidate() } }
            $Control.Add_MouseEnter($redrawScript)
            $Control.Add_MouseLeave($redrawScript)
            $Control.Add_MouseDown($redrawScript)
            $Control.Add_MouseUp($redrawScript)
            $Control.Add_EnabledChanged($redrawScript)

            $Control.Add_Paint({
                param($s, $pevent)
                if ($s.Width -le 0 -or $s.Height -le 0) { return }

                $g = $pevent.Graphics
                $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
                $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

                $isHovered = $s.ClientRectangle.Contains($s.PointToClient([System.Windows.Forms.Cursor]::Position))
                $isPressed = ($isHovered -and ([System.Windows.Forms.Control]::MouseButtons -band [System.Windows.Forms.MouseButtons]::Left))

                if (-not $s.Enabled) {
                    $bgHex = "#35383f"
                    $fgHex = "#6c7078"
                } elseif ($isPressed) {
                    $bgHex = "#34373d"
                    $fgHex = "#ffffff"
                } elseif ($isHovered) {
                    $bgHex = "#565b64"
                    $fgHex = "#ffffff"
                } else {
                    $bgHex = "#484c54"
                    $fgHex = "#ffffff"
                }

                $parentColor = if ($null -ne $s.Parent) { $s.Parent.BackColor } else { [System.Drawing.ColorTranslator]::FromHtml("#2f3136") }
                $g.Clear($parentColor)

                $r = [float]($Radius * $global:HMTScaleFactor)
                if ($r -lt 1.0) { $r = 1.0 }
                $d = $r * 2.0
                $w = [float]($s.Width - 1.0)
                $h = [float]($s.Height - 1.0)
                if ($d -gt $w) { $d = $w }
                if ($d -gt $h) { $d = $h }

                $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                $arcRect = [System.Drawing.RectangleF]::new(0.0, 0.0, $d, $d)
                $path.AddArc($arcRect, 180, 90)
                $arcRect.X = $w - $d
                $path.AddArc($arcRect, 270, 90)
                $arcRect.Y = $h - $d
                $path.AddArc($arcRect, 0, 90)
                $arcRect.X = 0.0
                $path.AddArc($arcRect, 90, 90)
                $path.CloseFigure()

                $bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($bgHex))
                $g.FillPath($bgBrush, $path)
                $bgBrush.Dispose()
                $path.Dispose()

                if (-not [string]::IsNullOrEmpty($s.Text)) {
                    $textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($fgHex))
                    $sf = New-Object System.Drawing.StringFormat
                    $sf.Alignment = [System.Drawing.StringAlignment]::Center
                    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
                    $g.DrawString($s.Text, $s.Font, $textBrush, [System.Drawing.RectangleF]::new(0, 0, $s.Width, $s.Height), $sf)
                    $textBrush.Dispose()
                    $sf.Dispose()
                }
            })
        }
    } else {
        $applyControlRegion = {
            param($sender, $e)
            if ($sender.Width -gt 0 -and $sender.Height -gt 0) {
                $r = [float]($Radius * $global:HMTScaleFactor)
                if ($r -lt 1.0) { $r = 1.0 }
                $d = $r * 2.0
                $w = [float]$sender.Width
                $h = [float]$sender.Height
                if ($d -gt $w) { $d = $w }
                if ($d -gt $h) { $d = $h }
                if ($d -le 0) { return }

                $path = New-Object System.Drawing.Drawing2D.GraphicsPath
                $arcRect = [System.Drawing.RectangleF]::new(0.0, 0.0, $d, $d)
                $path.AddArc($arcRect, 180, 90)
                $arcRect.X = $w - $d
                $path.AddArc($arcRect, 270, 90)
                $arcRect.Y = $h - $d
                $path.AddArc($arcRect, 0, 90)
                $arcRect.X = 0.0
                $path.AddArc($arcRect, 90, 90)
                $path.CloseFigure()
                $sender.Region = New-Object System.Drawing.Region($path)
            }
        }

        if ($Control.Tag -ne "RoundedControlBound") {
            $Control.Tag = "RoundedControlBound"
            $Control.Add_SizeChanged($applyControlRegion)
        }
        &$applyControlRegion $Control $null
    }
}

function Show-HMTDialog {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Form]$TargetForm
    )
    try {
        $prop = $TargetForm.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]"Instance, NonPublic")
        if ($null -ne $prop) { $prop.SetValue($TargetForm, $true, $null) }
    } catch {}

    Invoke-HMTScale $TargetForm
    $TargetForm.Opacity = 0
    $shownScript = {
        param($s, $e)
        $s.Opacity = 1
        $s.Refresh()
    }
    $TargetForm.Add_Shown($shownScript)
    try {
        return $TargetForm.ShowDialog()
    } finally {
        $TargetForm.Opacity = 1
    }
}

# Common function for user requested exits
function User-Exit {
    if ($script:ProgramExiting -ne $true) {
        $script:ProgramExiting = $true
        
        # Terminate GUI
        [System.Windows.Forms.Application]::OpenForms | ForEach-Object { $_.Hide() }
        [System.Windows.Forms.Application]::DoEvents()
        
        # Errors are appended directly to $global:logPath as they occur during execution

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

# Non-blocking async extraction helper to keep WinForms UI responsive
function Invoke-HMTExtract {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath
    )
    if (Get-Command tar.exe -ErrorAction SilentlyContinue) {
        $proc = Start-Process -FilePath "tar.exe" -ArgumentList "-xf `"$Path`" -C `"$DestinationPath`"" -PassThru -WindowStyle Hidden
    } else {
        $proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Expand-Archive -LiteralPath '$Path' -DestinationPath '$DestinationPath' -Force`"" -PassThru -WindowStyle Hidden
    }
    while (-not $proc.HasExited) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 50
    }
}

# Load GUI Modules (Loaded during splashscreen)
. (Join-Path -Path $PSScriptRoot -ChildPath 'GUI_Diagnostics.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'GUI_Setup.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'GUI_Tools.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'GUI_Main.ps1')

#GUI Functions
function Show-MainMenu {
    Hide-ConsoleWindow | Out-Null
    
    while ($Global:NextAction -ne 'Exit') {
        
        switch ($Global:NextAction) {
            'Main' {
                [void](Show-HMTDialog $MainMenu)
                if ($MainMenu.DialogResult -ne [System.Windows.Forms.DialogResult]::OK -and $Global:NextAction -eq 'Main') {
                    $Global:NextAction = 'Exit'
                }
            }
            
            'Setup' {
                $ModGUI.ShowInTaskbar = $true
                $ModGUI.MinimizeBox = $true
                [void](Show-HMTDialog $ModGUI)
                
                # If they exit the setup GUI without hitting OK, drop back to Main Menu
                if ($ModGUI.DialogResult -ne [System.Windows.Forms.DialogResult]::OK -and $Global:NextAction -eq 'Setup') {
                    $Global:NextAction = 'Main'
                }
            }

            'RunSetup' {
                # This runs on a completely fresh stack frame out here!
                $SetupScriptModPath = Join-Path -Path $PSScriptRoot -ChildPath 'SetupScript.ps1'
                . "$SetupScriptModPath"
                
                # Once the script ripples through all checked modules, return to the Main Menu
                $Global:NextAction = 'Main'
            }
            
            'Tools' {
                [void](Show-HMTDialog $ToolsGUI)
                $Global:NextAction = 'Main'
            }
            
            'Troubleshooting' {
                [void](Show-HMTDialog $ToolsGUI)
                $Global:NextAction = 'Main'
            }
            
            'About' {
                [void](Show-HMTDialog $AboutGUI)
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
    $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36")
    $webClient.Headers.Add("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8")
    $webClient.Headers.Add("Accept-Language", "en-US,en;q=0.5")
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor 12288
    try {
        $uri = [Uri]$Url
        if ($uri.Host -like "*forensit.com*") {
            $webClient.Headers.Add("Referer", "https://www.forensit.com/downloads.html")
        } elseif ($uri.Host -like "*sourceforge.net*") {
            $webClient.Headers["User-Agent"] = "curl/8.5.0"
        } else {
            $webClient.Headers.Add("Referer", "$($uri.Scheme)://$($uri.Host)/")
        }
    } catch {}
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

    $script:dlError = $null
    # Completion event stops timer and closes form
    $webClient.add_DownloadFileCompleted({ param($s,$e)
        $uiTimer.Stop()
        
        if ($e.Error) {
            $script:dlError = $e.Error
            Log-Message "Download failed for ${DisplayName}: $($e.Error.Message)" "Warning"
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
    catch { [System.Windows.Forms.MessageBox]::Show("Failed to start download: $_", "Error", 'OK', 'Error') | Out-Null; $uiTimer.Stop(); Log-Message "Failed to download file: $DisplayName" "Error"; throw $_ }

    # Show dialog until done
    Show-HMTDialog $dform | Out-Null

    # Remove Mark of the Web to bypass execution delays
    if (Test-Path -LiteralPath $OutputPath) {
        Unblock-File -LiteralPath $OutputPath -ErrorAction SilentlyContinue
    }

    if ($script:dlError) {
        $errObj = $script:dlError
        $script:dlError = $null
        throw $errObj
    }
}

<#
Example usage:
Show-DownloadDialog -DisplayName 'Sample File' -Url 'https://example.com/file.zip' -OutputPath 'C:\Temp\file.zip'
#>
