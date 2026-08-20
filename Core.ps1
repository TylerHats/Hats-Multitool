# Core Script - Tyler Hatfield - v2.0

# Validate process architecture and elevation
$IsElevated = [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544'
$IsTrappedIn32Bit = ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess)

if (-not $IsElevated -or $IsTrappedIn32Bit) {
    Write-Host "Elevation: $IsElevated - TrappedIn32Bit: $IsTrappedIn32Bit - Relaunching elevated..."
    $currentProc = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    if ($currentProc -and (Test-Path -LiteralPath $currentProc) -and $currentProc -notmatch 'powershell\.exe|pwsh\.exe') {
        Start-Process -FilePath $currentProc -Verb RunAs
        exit
    } else {
        $ExePath = if ($IsTrappedIn32Bit) { 
            "$env:WINDIR\sysnative\WindowsPowerShell\v1.0\powershell.exe" 
        } else { 
            "powershell.exe" 
        }
        $targetScript = if ($PSCommandPath) { $PSCommandPath } else { Join-Path $PSScriptRoot 'Core.ps1' }
        Start-Process -FilePath $ExePath -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$targetScript`"" -Verb RunAs -WindowStyle Hidden
        exit
    }
}

# Initialize WinForms and System assemblies
try {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing, System.IO.Compression -ErrorAction SilentlyContinue
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue
} catch {}

# Initialize Native & Tool assemblies
$nativeDll = Join-Path -Path $PSScriptRoot -ChildPath 'HMTNative.dll'
if (Test-Path $nativeDll) {
    Add-Type -Path $nativeDll
} else {
    $csNative = Join-Path -Path $PSScriptRoot -ChildPath 'HMTNative.cs'
    if (Test-Path $csNative) { Add-Type -TypeDefinition (Get-Content $csNative -Raw) -ReferencedAssemblies System.Windows.Forms, System.Drawing }
}

$toolsDll = Join-Path -Path $PSScriptRoot -ChildPath 'HMTTools.dll'
if (Test-Path $toolsDll) {
    Add-Type -Path $toolsDll
} else {
    $csTools = Join-Path -Path $PSScriptRoot -ChildPath 'HMTTools.cs'
    if (Test-Path $csTools) { 
        Add-Type -TypeDefinition (Get-Content $csTools -Raw) -ReferencedAssemblies System.Windows.Forms, System.Drawing
    }
}

[DpiHelper]::SetProcessDPIAware() | Out-Null

[System.Windows.Forms.Application]::EnableVisualStyles() # Allows use of current Windows Theme/Style
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false) # Allows High-DPI rendering for text and features
try { [System.Windows.Forms.Application]::SetUnhandledExceptionMode([System.Windows.Forms.UnhandledExceptionMode]::CatchException) } catch {}

# Splashscreen
function Show-ImageSplash {
    param(
        [Parameter(Mandatory)][string]$ImagePath,
        [int]$Margin = 0,
        [switch]$TopMost
    )
    if (-not (Test-Path $ImagePath)) { throw "Splash image not found: $ImagePath" }
    
    # Initialize bitmap resource
    $rawImage = [System.Drawing.Bitmap]::new($ImagePath)
    $maxW = 600
    if ($rawImage.Width -gt $maxW) {
        $scale = $maxW / $rawImage.Width
        $newW = $maxW
        $newH = [int]($rawImage.Height * $scale)
        $script:_splashImage = New-Object System.Drawing.Bitmap($rawImage, $newW, $newH)
        $rawImage.Dispose()
    } else {
        $script:_splashImage = $rawImage
    }
    
    $form = [HMT.PerPixelAlphaForm]::new()
    $form.ShowInTaskbar = $false
    $form.TopMost = $TopMost.IsPresent
    
    # Pre-calculate dimensions for CenterScreen positioning
    $form.Size = [System.Drawing.Size]::new($script:_splashImage.Width, $script:_splashImage.Height)
    $form.StartPosition = 'CenterScreen'
    
    # Render layered splash window
    $form.Show() | Out-Null
    $form.SetImage($script:_splashImage)
    
	$script:_splashMinMs = 1000
	$script:_splashSW    = [Diagnostics.Stopwatch]::StartNew()
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
Log-Message "Initialized environment (OS: $WindowsEdition, Scale: $global:HMTScaleFactor)" "Info"
Hide-ConsoleWindow

# Execute Self Update module
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
