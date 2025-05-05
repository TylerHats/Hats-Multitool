# Common File - Tyler Hatfield - v1.5

# Common Variables:
$DesktopPath = [Environment]::GetFolderPath('Desktop')
$logPathName = "Hats-Multitool-Log.txt"
$logPath = Join-Path $DesktopPath $logPathName
$UserExit = $false
$WinUpdatesRun = $false
$GUIClosed = $false

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

# Load required functions to interact with Windows
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
}
"@

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
}

# Common function for user requested exits
function User-Exit {
    $folderToDelete = "$PSScriptRoot"
	$deletionCommand = "Start-Sleep -Seconds 2; Remove-Item -Path '$folderToDelete' -Recurse -Force; Add-Content -Path '$logPath' -Value 'Script self cleanup completed'"
	Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-Command", $deletionCommand
	exit 0
}

# Load GUI Configs as function for reuse
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