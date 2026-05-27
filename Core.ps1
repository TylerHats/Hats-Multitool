# Core Script - Tyler Hatfield - v1.6

# Elevation check
$IsElevated = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544'
if (-not $IsElevated) {
    Write-Host "This script requires elevation. Please grant Administrator permissions." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -WindowStyle Minimized
    exit
}

# Force PowerShell to be DPI Aware to prevent UI scaling issues
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DpiHelper {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
"@
[DpiHelper]::SetProcessDPIAware() | Out-Null

# Add WinForms Assembly and Setup Global Forms Styling
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles() # Allows use of current Windows Theme/Style
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false) # Allows High-DPI rendering for text and features

# Splashscreen
function Show-ImageSplash {
    param(
        [Parameter(Mandatory)][string]$ImagePath,
        [int]$Margin = 0,
        [switch]$TopMost
    )
    if (-not (Test-Path $ImagePath)) { throw "Splash image not found: $ImagePath" }
    $script:_splashImage = [System.Drawing.Image]::FromFile($ImagePath)
    $w = $script:_splashImage.Width  + (2*$Margin)
    $h = $script:_splashImage.Height + (2*$Margin)
	$key = [System.Drawing.Color]::FromArgb(255, 1, 1, 1)
    $form = New-Object Windows.Forms.Form
    $form.FormBorderStyle = 'None'
    $form.StartPosition   = 'CenterScreen'
    $form.ShowInTaskbar   = $false
    $form.TopMost         = $TopMost.IsPresent
	$form.AutoScaleMode   = 'None'
    $form.Size            = [Drawing.Size]::new(600, 225)
    $keyColor = [Drawing.Color]::Fuchsia
    $form.BackColor      = $key
    $form.TransparencyKey = $key
    $form.BackgroundImage      = $script:_splashImage
    $form.BackgroundImageLayout = 'Stretch'
	$script:_splashMinMs = 1000
	$script:_splashSW    = [Diagnostics.Stopwatch]::StartNew()
    $form.Show() | Out-Null
    [Windows.Forms.Application]::DoEvents()
    $script:_splashForm = $form
}
function Close-ImageSplash {
    if ($script:_splashForm -and -not $script:_splashForm.IsDisposed) {
        $elapsed   = if ($script:_splashSW) { $script:_splashSW.ElapsedMilliseconds } else { 0 }
		$minMillis = ($script:_splashMinMs -as [int])
		$remaining = [Math]::Max(0, $minMillis - $elapsed)
		$deadline = (Get-Date).AddMilliseconds($remaining)
		while ((Get-Date) -lt $deadline) {
            [Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 15
        }
		$script:_splashForm.Close()
        $script:_splashForm.Dispose()
        Remove-Variable -Name _splashForm -Scope Script -ErrorAction SilentlyContinue
    }
    if ($script:_splashImage) {
        $script:_splashImage.Dispose()
        Remove-Variable -Name _splashImage -Scope Script -ErrorAction SilentlyContinue
    }
}
Show-ImageSplash -ImagePath (Join-Path $PSScriptRoot 'Splash.png') -TopMost

# Script setup
Write-Host "Loading: Hat's Multitool..."
$failedResize = 0
$failedColor = 0
try {
	$dWidth = (Get-Host).UI.RawUI.BufferSize.Width
	$dHeight = 50
	$rawUI = $Host.UI.RawUI
	$newSize = New-Object System.Management.Automation.Host.Size ($dWidth, $dHeight)
	$rawUI.WindowSize = $newSize
} catch {
	try {
		$dWidth = (Get-Host).UI.RawUI.BufferSize.Width
		$dHeight = 35
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
$Host.UI.RawUI.WindowTitle = "Hat's Multitool"
$commonPath = Join-Path -Path $PSScriptRoot -ChildPath 'Common.ps1'
. "$commonPath"
if ($failedResize -eq 1) {Log-Message "Failed to resize window." "Error"}
if ($failedColor -eq 1) {Log-Message "Failed to change background color." "Error"}
Hide-ConsoleWindow

# Focus Window and Run Self Update Module
$hwnd = [HMT.NativeMethods]::GetConsoleWindow()
[HMT.NativeMethods]::SetForegroundWindow($hwnd) | Out-Null
$UpdateModPath = Join-Path -Path $PSScriptRoot -ChildPath 'Update.ps1'
. "$UpdateModPath"
if ($ForceExit -eq $true) {exit 0}

# Prompt Hint
Log-Message "Hint: When prompted for input, a capital letter infers a default if the prompt is left blank." "Skip"
Write-Host ""

# Close SplashScreen
Close-ImageSplash

# Display Main Menu GUI
Show-MainMenu

# Post execution cleanup
User-Exit
