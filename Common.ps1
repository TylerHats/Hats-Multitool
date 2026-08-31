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
$global:HasErrors = $false
$ProgramExiting = $false

# Log-Message formats and writes structured, color-coded output to the console
function global:Log-Message {
    param(
        [string]$message,
        [string]$level = "Info"  # Options: Info, Success, Error, Warning, Prompt, Skip, Debug, LogOnly
    )
    $timestamp = Get-Date -Format "HH:mm:ss"
    $consoleMessage = "[$timestamp] [$level] - $message"
    
    switch ($level.ToLower()) {
        "error" {
            $global:HasErrors = $true
            Write-Host $consoleMessage -ForegroundColor "Red"
        }
        "warning" {
            Write-Host $consoleMessage -ForegroundColor "Yellow"
        }
        "success" {
            Write-Host $consoleMessage -ForegroundColor "Green"
        }
        "prompt" {
            Write-Host -NoNewLine "$consoleMessage " -ForegroundColor "Yellow"
        }
        "skip" {
            Write-Host $consoleMessage -ForegroundColor "Cyan"
        }
        "debug" {
            Write-Host $consoleMessage -ForegroundColor "DarkGray"
        }
        "logonly" {
            # Silent console output; non-error
        }
        default {
            Write-Host $consoleMessage -ForegroundColor "White"
        }
    }
}

# Trap uncaught script errors globally and record them with line context
trap {
    $errObj = $_
    $errMsg = if ($errObj.Exception -and $errObj.Exception.GetBaseException()) { 
        $errObj.Exception.GetBaseException().Message 
    } else { 
        $errObj.ToString() 
    }
    $invInfo = if ($errObj.InvocationInfo -and $errObj.InvocationInfo.ScriptLineNumber) { 
        " (Line $($errObj.InvocationInfo.ScriptLineNumber))" 
    } else { 
        "" 
    }
    Log-Message "Unhandled Script Exception: $errMsg$invInfo" "Error"
    continue
}

$HMTIconPath = Join-Path -Path $PSScriptRoot -ChildPath "HMTIconSmall.ico"
$HMTIcon = if (Test-Path -LiteralPath $HMTIconPath) { New-Object System.Drawing.Icon($HMTIconPath) } else { $null }

try {
    $g = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero)
    $global:HMTScaleFactor = $g.DpiX / 96.0
    $g.Dispose()
} catch {
    $global:HMTScaleFactor = 1.0
}

function global:Get-HMTFont {
    param(
        [string]$Family = "Segoe UI",
        [float]$Size = 12,
        $Style = [System.Drawing.FontStyle]::Regular
    )
    $fontStyle = [System.Drawing.FontStyle]::Regular
    if ($Style -is [System.Drawing.FontStyle]) {
        $fontStyle = $Style
    } elseif ($Style -is [string] -and -not [string]::IsNullOrWhiteSpace($Style)) {
        $cleanStyle = $Style.Trim() -replace '^\[.*?\]::', ''
        try {
            $fontStyle = [System.Drawing.FontStyle]$cleanStyle
        } catch {
            $fontStyle = [System.Drawing.FontStyle]::Regular
        }
    }
    $scaled = [math]::Max(8, [int][math]::Round($Size * $global:HMTScaleFactor))
    return New-Object System.Drawing.Font($Family, $scaled, $fontStyle, [System.Drawing.GraphicsUnit]::Pixel)
}

$font = Get-HMTFont "Segoe UI" 12

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

function global:Invoke-HMTScale {
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

function global:Show-CustomMessageBox {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [string]$Title = "Hat's Multitool",
        [ValidateSet('Information', 'Warning', 'Error', 'Question', 'None')]
        [string]$Style = 'Information',
        [ValidateSet('OK', 'OKCancel', 'YesNo', 'YesNoCancel')]
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
    elseif ($Buttons -eq 'YesNoCancel') {
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

        $btnCancel = New-Object System.Windows.Forms.Button
        $btnCancel.Text = "Cancel"
        $btnCancel.Size = New-Object System.Drawing.Size(85, 34)
        $btnCancel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $btnCancel.FlatStyle = 'Flat'
        $btnCancel.FlatAppearance.BorderSize = 1
        $btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $btnPanel.Controls.Add($btnCancel)
        $createdButtons += $btnCancel

        $msgForm.AcceptButton = $btnYes
        $msgForm.CancelButton = $btnCancel
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

function global:PopupError {
	param(
		[string]$ErrorMessage,
		[ValidateSet('Information','Warning','Error','None','Question')] [string]$Style = 'Error',
        [ValidateSet('OK', 'OKCancel', 'YesNo', 'YesNoCancel')] [string]$Buttons = 'OK'
	)
    return Show-CustomMessageBox -Message $ErrorMessage -Style $Style -Buttons $Buttons
}

# constants for WM_SETICON
$WM_SETICON = 0x80
$ICON_SMALL = 0
$ICON_BIG   = 1

# grab our icon handle
$hIcon = if ($HMTIcon) { $HMTIcon.Handle } else { [IntPtr]::Zero }

# Apply icon to console window
if ($hIcon -ne [IntPtr]::Zero) {
    $hwnd = [HMT.NativeMethods]::GetConsoleWindow()
    if ($hwnd -ne [IntPtr]::Zero) {
        $wParamSmall = New-Object System.IntPtr($ICON_SMALL)
        $wParamBig   = New-Object System.IntPtr($ICON_BIG)
        [HMT.NativeMethods]::SendMessage($hwnd, [uint32]$WM_SETICON, $wParamSmall, $hIcon) | Out-Null
        [HMT.NativeMethods]::SendMessage($hwnd, [uint32]$WM_SETICON, $wParamBig,   $hIcon) | Out-Null
    }
}

# Set a unique ID for Hat's Multitool
[HMT.NativeMethods]::SetCurrentProcessExplicitAppUserModelID("Hat.Multitool.App") | Out-Null

# Function to hide the console window
function global:Hide-ConsoleWindow {
    $consolePtr = [HMT.NativeMethods]::GetConsoleWindow()
    if ($consolePtr -ne [IntPtr]::Zero) {
        # 0 = Hide
        [HMT.NativeMethods]::ShowWindow($consolePtr, 0) | Out-Null
    }
}

# Function to show the console window
function global:Show-ConsoleWindow {
    $consolePtr = [HMT.NativeMethods]::GetConsoleWindow()
    if ($consolePtr -eq [IntPtr]::Zero) {
        try {
            [HMT.NativeMethods]::AllocConsole() | Out-Null
            $consolePtr = [HMT.NativeMethods]::GetConsoleWindow()
            if ($consolePtr -ne [IntPtr]::Zero) {
                if ($hIcon -ne [IntPtr]::Zero) {
                    $wParamSmall = New-Object System.IntPtr($ICON_SMALL)
                    $wParamBig   = New-Object System.IntPtr($ICON_BIG)
                    [HMT.NativeMethods]::SendMessage($consolePtr, [uint32]$WM_SETICON, $wParamSmall, $hIcon) | Out-Null
                    [HMT.NativeMethods]::SendMessage($consolePtr, [uint32]$WM_SETICON, $wParamBig,   $hIcon) | Out-Null
                }
                $Host.UI.RawUI.WindowTitle = "Hat's Multitool"
            }
        } catch {}
    }
    if ($consolePtr -ne [IntPtr]::Zero) {
        # 5 = Show normally
        [HMT.NativeMethods]::ShowWindow($consolePtr, 5) | Out-Null
        Start-Sleep -Milliseconds 50
        # Pull console window to focus
        [HMT.NativeMethods]::ShowWindow($consolePtr, 9) | Out-Null
        [HMT.NativeMethods]::SetForegroundWindow($consolePtr) | Out-Null
    }
}

# Function to force a WinForms title bar into Dark Mode and rounded corners
function global:Set-DarkTitleBar {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Form]$TargetForm
    )
    $TargetForm.Handle | Out-Null
    $darkMode = 1
    [HMT.NativeMethods]::DwmSetWindowAttribute($TargetForm.Handle, 20, [ref]$darkMode, 4) | Out-Null
    $cornerPref = 2
    [HMT.NativeMethods]::DwmSetWindowAttribute($TargetForm.Handle, 33, [ref]$cornerPref, 4) | Out-Null
    try { [HMT.Tools.DarkThemeHelper]::ApplyDarkTheme($TargetForm.Handle) } catch {}
}

function global:Set-RoundedControl {
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

            $redrawScript = {
                param($sender, $e)
                if ($sender -and $sender.Width -gt 0 -and $sender.Height -gt 0) { $sender.Invalidate() }
            }
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

function global:Show-HMTDialog {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Form]$TargetForm
    )
    try {
        $prop = $TargetForm.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]"Instance, NonPublic")
        if ($null -ne $prop) { $prop.SetValue($TargetForm, $true, $null) }
    } catch {}

    Invoke-HMTScale $TargetForm
    return $TargetForm.ShowDialog()
}

function global:Show-HMTWindow {
    param(
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.Form]$TargetForm,
        [System.Windows.Forms.IWin32Window]$Owner = $null
    )
    try {
        $prop = $TargetForm.GetType().GetProperty("DoubleBuffered", [System.Reflection.BindingFlags]"Instance, NonPublic")
        if ($null -ne $prop) { $prop.SetValue($TargetForm, $true, $null) }
    } catch {}

    Invoke-HMTScale $TargetForm
    if ($Owner) {
        $TargetForm.Show($Owner)
    } elseif ($script:MainForm -and -not $script:MainForm.IsDisposed) {
        $TargetForm.Show($script:MainForm)
    } else {
        $TargetForm.Show()
    }
    $TargetForm.BringToFront()
    $TargetForm.Activate()
}

# Common function for user requested exits
function global:User-Exit {
    if ($script:ProgramExiting -ne $true) {
        $script:ProgramExiting = $true
        
        # Terminate GUI
        [System.Windows.Forms.Application]::OpenForms | ForEach-Object { $_.Hide() }
        [System.Windows.Forms.Application]::DoEvents()
        
        # Prepare cleanup command
        $cleanupCommand = "Wait-Process -Id $PID -ErrorAction SilentlyContinue; while (`$true) { `$lockingProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object { `$_.Path -like '$PSScriptRoot\*' }; if (-not `$lockingProcs) { break }; `$lockingProcs | Wait-Process -ErrorAction SilentlyContinue; Start-Sleep -Seconds 1 }; Start-Sleep -Seconds 1; if (Test-Path -LiteralPath '$PSScriptRoot') { Remove-Item -LiteralPath '$PSScriptRoot' -Recurse -Force }; if ('$($Global:IRMExeTarget)' -ne '' -and (Test-Path -LiteralPath '$($Global:IRMExeTarget)')) { `$retry = 0; while ((Test-Path -LiteralPath '$($Global:IRMExeTarget)') -and `$retry -lt 5) { Remove-Item -LiteralPath '$($Global:IRMExeTarget)' -Force -ErrorAction SilentlyContinue; Start-Sleep -Milliseconds 500; `$retry++ } }"
     
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
function global:Invoke-HMTExtract {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$DestinationPath
    )
    $state = [HMT.Tools.ArchiveExtractor]::StartExtract($Path, $DestinationPath)
    while (-not $state.IsCompleted -and -not $state.Error) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 40
    }
}

# Load GUI Modules (Loaded during splashscreen)
. (Join-Path -Path $PSScriptRoot -ChildPath 'GUI_Diagnostics.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'GUI_Setup.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'GUI_Tools.ps1')
. (Join-Path -Path $PSScriptRoot -ChildPath 'GUI_Main.ps1')

#GUI Functions
function global:Show-MainMenu {
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
                $ToolsGUI.ShowInTaskbar = $true
                $ToolsGUI.MinimizeBox = $true
                [void](Show-HMTDialog $ToolsGUI)
                
                # If they exit the tools GUI without hitting Back, drop back to Main Menu
                if ($ToolsGUI.DialogResult -ne [System.Windows.Forms.DialogResult]::OK -and $Global:NextAction -eq 'Tools') {
                    $Global:NextAction = 'Main'
                }
            }
            
            'Programs' {
                $ProgramsGUI.ShowInTaskbar = $true
                $ProgramsGUI.MinimizeBox = $true
                [void](Show-HMTDialog $ProgramsGUI)
                
                # If they exit the tools GUI without hitting Back, drop back to Main Menu
                if ($ProgramsGUI.DialogResult -ne [System.Windows.Forms.DialogResult]::OK -and $Global:NextAction -eq 'Programs') {
                    $Global:NextAction = 'Main'
                }
            }
            
            'Default' {
                User-Exit
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

# Global Windows Forms unhandled exception trap to display styled error dialogs
try {
    [System.Windows.Forms.Application]::Add_ThreadException({
        param($sender, $e)
        $clean = $e.Exception.Message
        Log-Message "Unhandled UI Exception: $($e.Exception.ToString())" "Error"
        PopupError $clean "Error"
    })
} catch {}

function global:Show-DownloadDialog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DisplayName,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [string]$ExtractTo = ""
    )

    Add-Type -AssemblyName System.Windows.Forms, System.Drawing, System.Net.Http

    $dform = New-Object System.Windows.Forms.Form
    $dform.Text = "Downloading $DisplayName..."
    $dform.ClientSize = New-Object System.Drawing.Size(520, 160)
    $dform.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $dform.MaximizeBox = $false
    $dform.MinimizeBox = $false
    $dform.StartPosition = 'CenterScreen'
    $dform.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    if ($HMTIcon) { $dform.Icon = $HMTIcon }
    $dform.Font = $font
    $dform.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $dform.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $dform

    # Modern Rounded Animated Progress Bar
    $progressBar = New-Object HMT.Tools.SmoothProgressBar
    $progressBar.Size = New-Object System.Drawing.Size(480, 20)
    $progressBar.Location = New-Object System.Drawing.Point(20, 20)
    $progressBar.BorderRadius = 5
    $progressBar.ProgressColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
    $progressBar.ProgressColorEnd = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $progressBar.ShowShimmer = $true
    $dform.Controls.Add($progressBar)

    # Speed label
    $speedLabel = New-Object System.Windows.Forms.Label
    $speedLabel.AutoSize = $true
    $speedLabel.Location = New-Object System.Drawing.Point(20, 52)
    $speedLabel.Text = "Speed: Connecting..."
    $speedLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $dform.Controls.Add($speedLabel)

    # Stats label
    $statsLabel = New-Object System.Windows.Forms.Label
    $statsLabel.AutoSize = $true
    $statsLabel.Location = New-Object System.Drawing.Point(20, 76)
    $statsLabel.Text = "0 MB / 0 MB (0%)"
    $statsLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $dform.Controls.Add($statsLabel)

    # Cancel Button
    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Size = New-Object System.Drawing.Size(100, 32)
    $btnCancel.Location = New-Object System.Drawing.Point(400, 110)
    $btnCancel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnCancel.FlatStyle = 'Flat'
    $btnCancel.FlatAppearance.BorderSize = 1
    $dform.Controls.Add($btnCancel)

    $dform.Add_Load({
        Invoke-HMTScale $dform
        Set-RoundedControl $btnCancel
        $progressBar.Width = $dform.ClientSize.Width - 40
        $btnCancel.Left = $dform.ClientSize.Width - $btnCancel.Width - 20
    })

    # Prepare download parameters
    $downloadUrl = $Url
    if ($downloadUrl -match 'sourceforge\.net/projects/([^/]+)/files/(.+?)(?:/download)?(?:\?.*)?$') {
        $proj = $matches[1]
        $file = $matches[2]
        $downloadUrl = "https://downloads.sourceforge.net/project/$proj/$file"
    }

    $script:dlSuccess = $false
    $script:dlCancelled = $false
    $script:dlIsActive = $true
    $script:isExtracting = $false
    $script:extractState = $null

    # Launch native thread-safe streaming download in C#
    $state = [HMT.Tools.FileDownloader]::StartDownload($downloadUrl, $OutputPath)

    $cancelDownload = {
        if ($script:dlIsActive) {
            $state.IsCancelled = $true
            if ($script:extractState) { $script:extractState.IsCancelled = $true }
            $script:dlCancelled = $true
            $script:dlIsActive = $false
        }
        $dform.Close()
    }

    $btnCancel.Add_Click({ &$cancelDownload })

    $dform.Add_FormClosing({
        param($sender, $e)
        if ($script:dlIsActive) {
            $state.IsCancelled = $true
            if ($script:extractState) { $script:extractState.IsCancelled = $true }
            $script:dlCancelled = $true
            $script:dlIsActive = $false
        }
    })

    # UI Polling Timer
    $uiTimer = New-Object System.Windows.Forms.Timer
    $uiTimer.Interval = 40
    $uiTimer.Add_Tick({
        # Phase 2: Extraction Handling
        if ($script:isExtracting) {
            if ($null -ne $script:extractState) {
                if ($script:extractState.IsCompleted) {
                    $uiTimer.Stop()
                    $script:dlIsActive = $false
                    $script:dlSuccess = $true
                    $progressBar.Value = 100
                    $statsLabel.Text = "Extraction Complete!"
                    $statsLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                    [System.Windows.Forms.Application]::DoEvents()
                    Start-Sleep -Milliseconds 250
                    $dform.Close()
                    return
                }

                if ($script:extractState.Error) {
                    $uiTimer.Stop()
                    $script:dlIsActive = $false
                    Log-Message "Extraction error on $DisplayName : $($script:extractState.Error)" "Warning"
                    PopupError "Failed to extract $DisplayName :`n$($script:extractState.Error)" "Error"
                    $dform.Close()
                    return
                }

                # Update extraction progress UI
                $pctInt = [int]$script:extractState.Percent
                $progressBar.Value = [Math]::Max(0, [Math]::Min(100, $pctInt))
                $statsLabel.Text = "Extracted $($script:extractState.EntriesExtracted) of $($script:extractState.TotalEntries) files ($pctInt%)"
                $entryText = if ($script:extractState.CurrentEntry) { $script:extractState.CurrentEntry } else { "Extracting files..." }
                $speedLabel.Text = "Extracting: $entryText"
            }
            return
        }

        # Phase 1: Download Handling
        if ($state.IsCompleted) {
            if (-not [string]::IsNullOrWhiteSpace($ExtractTo)) {
                # Transition into Extraction Phase in the same UI dialog
                $script:isExtracting = $true
                $dform.Text = "Extracting $DisplayName..."
                $speedLabel.Text = "Starting extraction..."
                $statsLabel.Text = "Reading archive contents..."
                $progressBar.Value = 0
                $progressBar.ProgressColor = [System.Drawing.ColorTranslator]::FromHtml("#206694")
                $progressBar.ProgressColorEnd = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                $script:extractState = [HMT.Tools.ArchiveExtractor]::StartExtract($OutputPath, $ExtractTo)
                return
            }

            $uiTimer.Stop()
            $script:dlIsActive = $false
            $script:dlSuccess = $true
            $progressBar.Value = 100
            $statsLabel.Text = "Download Complete!"
            $statsLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
            $dform.Close()
            return
        }

        if ($state.Error) {
            $uiTimer.Stop()
            $script:dlIsActive = $false
            if (Test-Path -LiteralPath $OutputPath) {
                Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue
            }
            Log-Message "Download error on $DisplayName : $($state.Error)" "Warning"
            PopupError "Failed to download $DisplayName :`n$($state.Error)" "Error"
            $dform.Close()
            return
        }

        if ($script:dlCancelled -or $state.IsCancelled) {
            $uiTimer.Stop()
            $script:dlIsActive = $false
            if (Test-Path -LiteralPath $OutputPath) {
                Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue
            }
            Log-Message "Download cancelled by user: $DisplayName" "Info"
            $dform.Close()
            return
        }

        # Update Download Progress Bar & Labels
        $speedLabel.Text = ('Speed: {0:N2} Mbps' -f $state.SpeedMbps)
        $readMB = $state.BytesRead / 1MB
        $totMB = $state.TotalBytes / 1MB

        if ($state.TotalBytes -gt 0) {
            $pct = [Math]::Max(0.0, [Math]::Min(1.0, ($state.BytesRead / $state.TotalBytes)))
            $pctInt = [int]($pct * 100)
            $progressBar.Value = $pctInt

            if ($totMB -ge 1000) {
                $statsLabel.Text = ('{0:N2} GB / {1:N2} GB ({2}%)' -f ($readMB / 1000), ($totMB / 1000), $pctInt)
            } else {
                $statsLabel.Text = ('{0:N2} MB / {1:N2} MB ({2}%)' -f $readMB, $totMB, $pctInt)
            }
        } else {
            $statsLabel.Text = ('{0:N2} MB downloaded' -f $readMB)
        }
    })

    $uiTimer.Start()
    Show-HMTDialog $dform | Out-Null
    $uiTimer.Stop()
    $uiTimer.Dispose()

    # Unblock file on success
    if ($script:dlSuccess -and (Test-Path -LiteralPath $OutputPath)) {
        try { Unblock-File -LiteralPath $OutputPath -ErrorAction SilentlyContinue } catch {}
        return $true
    } else {
        if (Test-Path -LiteralPath $OutputPath) {
            Remove-Item -LiteralPath $OutputPath -Force -ErrorAction SilentlyContinue
        }
        return $false
    }
}

<#
Example usage:
Show-DownloadDialog -DisplayName 'Sample File' -Url 'https://example.com/file.zip' -OutputPath 'C:\Temp\file.zip'
#>
