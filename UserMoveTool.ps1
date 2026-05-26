# User Move Tool - Tyler Hatfield - v1.2

# Instantly pop a tiny loading indicator before loading the heavy C# assemblies
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$MicroLoader = New-Object System.Windows.Forms.Form
$MicroLoader.Size = New-Object System.Drawing.Size(220, 40)
$MicroLoader.StartPosition = 'CenterScreen'
$MicroLoader.FormBorderStyle = 'None'
$MicroLoader.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$MicroLoader.ShowInTaskbar = $false
$loadLabel = New-Object System.Windows.Forms.Label
$loadLabel.Text = "Loading Migration Tool..."
$loadLabel.ForeColor = [System.Drawing.Color]::White
$loadLabel.Dock = 'Fill'
$loadLabel.TextAlign = 'MiddleCenter'
$loadLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$MicroLoader.Controls.Add($loadLabel)
$MicroLoader.Show() | Out-Null
[System.Windows.Forms.Application]::DoEvents()

# ---------------------------------------------------------------------------
# Pre-Flight & Standalone Setup
# ---------------------------------------------------------------------------
$OSVersion = [System.Environment]::OSVersion.Version
if ($OSVersion.Build -lt 22000) {
    [System.Windows.Forms.MessageBox]::Show("Warning: This system is not running Windows 11. Some settings migrations (like Taskbar alignment) may not apply correctly.", "OS Compatibility Warning", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
}

# Standalone Logging Function
$logPath = Join-Path [Environment]::GetFolderPath('MyDocuments') "Hats-UserMove-Log.txt"
function Log-Message {
    param( [string]$message, [string]$level = "Info" )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$level] - $message" | Out-File -FilePath $logPath -Append
    Write-Host "[$level] - $message"
}

# Enable Long Path Support in current process
$LongPathKey = "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem"
$LongPathValue = (Get-ItemProperty -Path $LongPathKey -Name LongPathsEnabled -ErrorAction SilentlyContinue).LongPathsEnabled
if ($LongPathValue -ne 1) {
    Log-Message "LongPathsEnabled is not set in the registry. Deeply nested files may fail to extract." "Warning"
}

# Add WinForms & Drawing Assemblies
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# Enable Visual Styles & DPI Awareness for Crisp Scaling
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class UIHelpers {
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();

    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    // Add the Taskbar AppID injection here
    [DllImport("shell32.dll", SetLastError = true)]
    public static extern int SetCurrentProcessExplicitAppUserModelID([MarshalAs(UnmanagedType.LPWStr)] string AppID);
}
"@

# Call all three APIs
[UIHelpers]::SetProcessDPIAware() | Out-Null
[UIHelpers]::SetCurrentProcessExplicitAppUserModelID("Hat.Multitool.UserMove") | Out-Null # Unique ID so it gets its own icon!
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# Standalone Variables
$font = New-Object System.Drawing.Font("Segoe UI", 10)

# Icon Fallback (Uses custom icon if present, otherwise grabs the native PowerShell icon)
$IconPath = Join-Path $PSScriptRoot "HMTIconSmall.ico"
if (Test-Path $IconPath) {
    $HMTIcon = New-Object System.Drawing.Icon($IconPath)
} else {
    $HMTIcon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -Id $PID).Path)
}

# ---------------------------------------------------------------------------
# GUI Setup
# ---------------------------------------------------------------------------
$MoveGUI = New-Object System.Windows.Forms.Form
$MoveGUI.Text = "Hat's User Migration Tool"
$MoveGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$MoveGUI.Size = New-Object System.Drawing.Size(450, 600)
$MoveGUI.StartPosition = 'CenterScreen'
$MoveGUI.Icon = $HMTIcon
$MoveGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$MoveGUI.MaximizeBox = $false
$MoveGUI.Font = $font

# Force Handle Creation so we can apply the Dark Mode Title Bar
$MoveGUI.Handle | Out-Null
$darkMode = 1
# 20 is the DWMWA_USE_IMMERSIVE_DARK_MODE attribute for Windows 11
[UIHelpers]::DwmSetWindowAttribute($MoveGUI.Handle, 20, [ref]$darkMode, 4) | Out-Null

# Mode Selection
$y = 15
$ModeLabel = New-Object System.Windows.Forms.Label
$ModeLabel.Text = "Operation Mode:"
$ModeLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ModeLabel.Location = New-Object System.Drawing.Point(20, $y)
$ModeLabel.AutoSize = $true
$MoveGUI.Controls.Add($ModeLabel)

$BackupRadio = New-Object System.Windows.Forms.RadioButton
$BackupRadio.Text = "Backup (Copy From PC)"
$BackupRadio.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$BackupRadio.Location = New-Object System.Drawing.Point(150, ($y - 2))
$BackupRadio.AutoSize = $true
$BackupRadio.Checked = $true
$MoveGUI.Controls.Add($BackupRadio)

$RestoreRadio = New-Object System.Windows.Forms.RadioButton
$RestoreRadio.Text = "Restore (Copy To PC)"
$RestoreRadio.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$RestoreRadio.Location = New-Object System.Drawing.Point(150, ($y + 20))
$RestoreRadio.AutoSize = $true
$MoveGUI.Controls.Add($RestoreRadio)

# Target Path Selection
$y += 55
$PathLabel = New-Object System.Windows.Forms.Label
$PathLabel.Text = "Destination Folder:"
$PathLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$PathLabel.Location = New-Object System.Drawing.Point(20, $y)
$PathLabel.AutoSize = $true
$MoveGUI.Controls.Add($PathLabel)

$y += 25
$PathTextBox = New-Object System.Windows.Forms.TextBox
$PathTextBox.Location = New-Object System.Drawing.Point(20, $y)
$PathTextBox.Width = 310
$MoveGUI.Controls.Add($PathTextBox)

$BrowseButton = New-Object System.Windows.Forms.Button
$BrowseButton.Text = "Browse"
$BrowseButton.Location = New-Object System.Drawing.Point(340, ($y - 2))
$BrowseButton.Size = New-Object System.Drawing.Size(75, 27)
$BrowseButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$BrowseButton.FlatStyle = 'Flat'
$MoveGUI.Controls.Add($BrowseButton)

# Options Group
$y += 40
$OptionsLabel = New-Object System.Windows.Forms.Label
$OptionsLabel.Text = "Select Data to Migrate:"
$OptionsLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$OptionsLabel.Location = New-Object System.Drawing.Point(20, $y)
$OptionsLabel.AutoSize = $true
$MoveGUI.Controls.Add($OptionsLabel)

$y += 25
$chkRoot = New-Object System.Windows.Forms.CheckBox
$chkRoot.Text = "C:\ Root Data (Excl. Windows/ProgFiles)"
$chkRoot.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkRoot.Location = New-Object System.Drawing.Point(30, $y); $chkRoot.Width = 350; $chkRoot.Checked = $true
$MoveGUI.Controls.Add($chkRoot)

$y += 25
$chkUser = New-Object System.Windows.Forms.CheckBox
$chkUser.Text = "Current User Profile (Excl. Cloud/Temp)"
$chkUser.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkUser.Location = New-Object System.Drawing.Point(30, $y); $chkUser.Width = 350; $chkUser.Checked = $true
$MoveGUI.Controls.Add($chkUser)

$y += 25
$chkBrowsers = New-Object System.Windows.Forms.CheckBox
$chkBrowsers.Text = "Browser Data (Bookmarks, History)"
$chkBrowsers.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkBrowsers.Location = New-Object System.Drawing.Point(30, $y); $chkBrowsers.Width = 350; $chkBrowsers.Checked = $true
$MoveGUI.Controls.Add($chkBrowsers)

$y += 25
$chkSettings = New-Object System.Windows.Forms.CheckBox
$chkSettings.Text = "OS Settings, Printers & Network Drives"
$chkSettings.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkSettings.Location = New-Object System.Drawing.Point(30, $y); $chkSettings.Width = 350; $chkSettings.Checked = $true
$MoveGUI.Controls.Add($chkSettings)

$y += 25
$chkDrivers = New-Object System.Windows.Forms.CheckBox
$chkDrivers.Text = "Export Third-Party Drivers (Backup Only)"
$chkDrivers.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkDrivers.Location = New-Object System.Drawing.Point(30, $y); $chkDrivers.Width = 350; $chkDrivers.Checked = $true
$MoveGUI.Controls.Add($chkDrivers)

$y += 25
$chkZip = New-Object System.Windows.Forms.CheckBox
$chkZip.Text = "Compress Backup into a .ZIP Archive (Slower, saves space)"
$chkZip.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkZip.Location = New-Object System.Drawing.Point(30, $y); $chkZip.Width = 350; $chkZip.Checked = $false
$MoveGUI.Controls.Add($chkZip)

# UI Logic for Mode Switching
$RestoreRadio.Add_CheckedChanged({
    if ($RestoreRadio.Checked) {
        $PathLabel.Text = "Select Migration.json File:"
        $PathTextBox.Clear()
        $chkDrivers.Enabled = $false
        $chkDrivers.Checked = $false
        $chkZip.Enabled = $false
        $chkZip.Checked = $false
    } else {
        $PathLabel.Text = "Destination Folder:"
        $PathTextBox.Clear()
        $chkDrivers.Enabled = $true
        $chkDrivers.Checked = $true
        $chkZip.Enabled = $true
        $chkZip.Checked = $false
    }
})

$BrowseButton.Add_Click({
    if ($BackupRadio.Checked) {
        $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $FolderBrowser.Description = "Select destination to create the backup folder..."
        if ($FolderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $PathTextBox.Text = $FolderBrowser.SelectedPath
        }
    } else {
        $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog
        $FileBrowser.Filter = "Migration Files (*.json, *.zip)|Migration.json;*.zip"
        $FileBrowser.Title = "Select Migration.json OR the Backup .ZIP file..."
        if ($FileBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $PathTextBox.Text = $FileBrowser.FileName
        }
    }
})

# Progress & Status
$y += 40
$StatusLabel = New-Object System.Windows.Forms.Label
$StatusLabel.Text = "Status: Ready"
$StatusLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$StatusLabel.Location = New-Object System.Drawing.Point(20, $y)
$StatusLabel.Size = New-Object System.Drawing.Size(400, 20)
$MoveGUI.Controls.Add($StatusLabel)

$y += 25
$TrackPanel = New-Object System.Windows.Forms.Panel
$TrackPanel.Size = [System.Drawing.Size]::new(395, 22)
$TrackPanel.Location = [System.Drawing.Point]::new(20, $y)
$TrackPanel.BorderStyle = 'FixedSingle'
$TrackPanel.BackColor = [System.Drawing.Color]::DarkGray
$MoveGUI.Controls.Add($TrackPanel)

$FillPanel = New-Object System.Windows.Forms.Panel
$FillPanel.Size = [System.Drawing.Size]::new(0, 19)
$FillPanel.Location = [System.Drawing.Point]::new(1, 1)
$FillPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
$TrackPanel.Controls.Add($FillPanel)

# Action Buttons
$y += 40
$StartButton = New-Object System.Windows.Forms.Button
$StartButton.Text = "Start"
$StartButton.Location = New-Object System.Drawing.Point(120, $y)
$StartButton.Size = New-Object System.Drawing.Size(90, 35)
$StartButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$StartButton.FlatStyle = 'Flat'
$MoveGUI.Controls.Add($StartButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Text = "Cancel"
$CancelButton.Location = New-Object System.Drawing.Point(230, $y)
$CancelButton.Size = New-Object System.Drawing.Size(90, 35)
$CancelButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$CancelButton.FlatStyle = 'Flat'
$CancelButton.Enabled = $false
$MoveGUI.Controls.Add($CancelButton)

$script:CancelOperation = $false

$CancelButton.Add_Click({
    $script:CancelOperation = $true
    $StatusLabel.Text = "Status: Cancelling... Please wait."
    $CancelButton.Enabled = $false
})

# ---------------------------------------------------------------------------
# Core Engine
# ---------------------------------------------------------------------------
$StartButton.Add_Click({
    if ([string]::IsNullOrWhiteSpace($PathTextBox.Text) -or -not (Test-Path $PathTextBox.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid path.", "Error", 0, 16)
        return
    }

    $StartButton.Enabled = $false
    $CancelButton.Enabled = $true
    $script:CancelOperation = $false
    $FillPanel.Width = 0

    if ($BackupRadio.Checked) {
        # --- BACKUP MODE ---
        $DestRoot = Join-Path $PathTextBox.Text "HMT_Migration_$env:USERNAME"
        if (-not (Test-Path $DestRoot)) { New-Item -ItemType Directory -Path $DestRoot | Out-Null }

        $JsonConfig = @{
            OSBuild = $OSVersion.Build
            Username = $env:USERNAME
            Domain = $env:USERDOMAIN
            Printers = @()
            Software = @()
            MappedDrives = @()
            Settings = @{}
        }

        # Pre-Flight: Check for OneDrive KFM and Folder Redirection
        $ShellFoldersKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        $ImportantFolders = @("Desktop", "Personal", "My Pictures")
        $script:HasOneDrive = $false
        $script:HasRedirection = $false

        foreach ($folder in $ImportantFolders) {
            $path = (Get-ItemProperty -Path $ShellFoldersKey -Name $folder -ErrorAction SilentlyContinue).$folder
            if ($path -match "OneDrive") { $script:HasOneDrive = $true }
            if ($path -match "^\\\\") { $script:HasRedirection = $true } # Checks for \\NetworkPath
        }

        # Generate Human-Readable Spec Summary
        $SysInfo = Get-CimInstance Win32_ComputerSystem
        $OSInfo = Get-CimInstance Win32_OperatingSystem
        $SpecSummary = @"
User Migration Backup
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
User: $($env:USERNAME)
Domain: $($env:USERDOMAIN)

Hardware Asset Info:
Hostname: $($SysInfo.Name)
Manufacturer: $($SysInfo.Manufacturer)
Model: $($SysInfo.Model)
RAM: $([math]::Round($SysInfo.TotalPhysicalMemory / 1GB, 2)) GB
OS: $($OSInfo.Caption) ($($OSInfo.OSArchitecture))
"@
        $SpecSummary | Out-File -FilePath (Join-Path $DestRoot "PC_Specs.txt") -Encoding ascii

        # 1. Grab Settings & Metadata
        if ($chkSettings.Checked) {
            $StatusLabel.Text = "Status: Exporting System Settings..."
            [System.Windows.Forms.Application]::DoEvents()

            # Theme Settings
            $ThemeKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
            $JsonConfig.Settings.AppsUseLightTheme = (Get-ItemProperty -Path $ThemeKey -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
            $JsonConfig.Settings.SystemUsesLightTheme = (Get-ItemProperty -Path $ThemeKey -Name SystemUsesLightTheme -ErrorAction SilentlyContinue).SystemUsesLightTheme

            # Taskbar Alignment (Win11)
            $TBKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            $JsonConfig.Settings.TaskbarAl = (Get-ItemProperty -Path $TBKey -Name TaskbarAl -ErrorAction SilentlyContinue).TaskbarAl

            # Printers
            $JsonConfig.Printers = Get-Printer | Select-Object Name, DriverName, PortName, Shared

            # Mapped Drives
            $JsonConfig.MappedDrives = Get-WmiObject Win32_MappedLogicalDisk | Select-Object Name, ProviderName

            # Quick Access / Network Shortcuts
            $QA_Path = "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations"
            if (Test-Path $QA_Path) { Copy-Item -Path $QA_Path -Destination "$DestRoot\SettingsBackup\QuickAccess" -Recurse -Force }
        }

        # 2. Export Drivers
        if ($chkDrivers.Checked) {
            $StatusLabel.Text = "Status: Exporting 3rd Party Drivers (This takes a moment)..."
            [System.Windows.Forms.Application]::DoEvents()
            $DriverDest = Join-Path $DestRoot "ExportedDrivers"
            New-Item -ItemType Directory -Path $DriverDest -Force | Out-Null
            Export-WindowsDriver -Online -Destination $DriverDest -ErrorAction SilentlyContinue | Out-Null
        }

        # 3. File Copy Engine (Build list, then copy)
        $FoldersToScan = @()

        if ($chkRoot.Checked) {
            # Add C:\ folders, exclude Windows, Program Files, PerfLogs, etc.
            Get-ChildItem -Path "C:\" -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -notin @('Windows', 'Program Files', 'Program Files (x86)', 'PerfLogs', '$Recycle.Bin', 'System Volume Information')
            } | ForEach-Object { $FoldersToScan += $_.FullName }
        }

        if ($chkUser.Checked) {
            # Base User Folders
            $UserFolders = @('Desktop', 'Documents', 'Downloads', 'Music', 'Pictures', 'Videos', 'Favorites')
            foreach ($uf in $UserFolders) {
                $p = Join-Path $env:USERPROFILE $uf
                if (Test-Path $p) { $FoldersToScan += $p }
            }
            # Specific AppData grabs (StickyNotes, Signatures)
            $FoldersToScan += "$env:APPDATA\Microsoft\Signatures"
            $FoldersToScan += "$env:LOCALAPPDATA\Packages\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe"
        }

        if ($chkBrowsers.Checked) {
            $FoldersToScan += "$env:LOCALAPPDATA\Google\Chrome\User Data"
            $FoldersToScan += "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
            $FoldersToScan += "$env:APPDATA\Mozilla\Firefox" # Added Firefox Profile Data
        }

        # Scan and Copy Loop
        $TotalFiles = 0
        $TotalBytesRequired = 0
        $FileList = @()

        $StatusLabel.Text = "Status: Scanning folders for sizing..."
        [System.Windows.Forms.Application]::DoEvents()

        foreach ($folder in $FoldersToScan) {
            if (Test-Path $folder) {
                # Scan ONCE
                $found = Get-ChildItem -Path $folder -Recurse -File -Force -ErrorAction SilentlyContinue
                if (-not $found) { continue } # Skip if empty or access denied

                # Calculate size of the array we just grabbed
                $Size = ($found | Measure-Object -Property Length -Sum).Sum

                # 10GB Check
                if ($Size -gt 10GB) {
                    $SizeGB = [math]::Round($Size / 1GB, 2)
                    $msgRes = [System.Windows.Forms.MessageBox]::Show("The folder '$folder' is $SizeGB GB. Do you want to include it in the backup?", "Large Folder Detected", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
                    if ($msgRes -eq 'No') { continue }
                }

                $FileList += $found
                $TotalFiles += $found.Count
                $TotalBytesRequired += $Size
            }
        }

        # Pre-Flight Free Space Check
        $DestDriveLetter = (Split-Path $PathTextBox.Text -Qualifier)
        if ($DestDriveLetter) {
            $DestDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$DestDriveLetter'"
            # Enforce 20% safety margin overhead
            $RequiredSpaceWithBuffer = $TotalBytesRequired * 1.2
            if ($DestDrive.FreeSpace -lt $RequiredSpaceWithBuffer) {
                $NeededGB = [math]::Round($RequiredSpaceWithBuffer / 1GB, 2)
                $AvailableGB = [math]::Round($DestDrive.FreeSpace / 1GB, 2)
                [System.Windows.Forms.MessageBox]::Show("Critical Error: Insufficient destination space.`nRequired (with safety buffer): $NeededGB GB`nAvailable: $AvailableGB GB", "Space Allocation Failure", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                $script:CancelOperation = $true
            }
        }

        # Execute Copy Engine
        $Copied = 0
        $MaxWidth = $TrackPanel.ClientSize.Width - 2

        if (-not $script:CancelOperation) {
            if ($TotalFiles -gt 0) {
                foreach ($file in $FileList) {
                    if ($script:CancelOperation) {
                        Log-Message "Migration Backup Canceled by User." "Warning"
                        break
                    }

                    # Replicate directory layout safely
                    $Relative = $file.FullName.Substring(3) # Strip "C:\"
                    $TargetFile = Join-Path $DestRoot "C_Drive\$Relative"
                    $TargetDir = Split-Path $TargetFile -Parent

                    if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }

                    try {
                        [System.IO.File]::Copy($file.FullName, $TargetFile, $true)
                    } catch {
                        Log-Message "Failed to copy: $($file.FullName)" "Error"
                    }

                    $Copied++
                    if ($Copied % 10 -eq 0 -or $Copied -eq $TotalFiles) {
                        $Percent = [math]::Round(($Copied / $TotalFiles) * 100)
                        $StatusLabel.Text = "Status: Copying... $Percent% ($Copied / $TotalFiles files)"
                        $FillPanel.Width = [int]($MaxWidth * ($Copied / $TotalFiles))
                        [System.Windows.Forms.Application]::DoEvents()
                    }
                }
            } else {
                $StatusLabel.Text = "Status: No files found to copy."
                $FillPanel.Width = $MaxWidth
                [System.Windows.Forms.Application]::DoEvents()
            }
        }

        # Write Metadata Summary Mapping
        $JsonConfig | ConvertTo-Json -Depth 5 | Out-File (Join-Path $DestRoot "Migration.json") -Encoding ascii

        # Post-Processing: Optional ZIP Compactor
        if (-not $script:CancelOperation -and $chkZip.Checked) {
            $StatusLabel.Text = "Status: Compressing Backup to ZIP... (This may take a while)"
            [System.Windows.Forms.Application]::DoEvents()

            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $ZipPath = "$DestRoot.zip"

            if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }

            try {
                [System.IO.Compression.ZipFile]::CreateFromDirectory($DestRoot, $ZipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)
                Log-Message "Backup compressed successfully into a standalone ZIP file." "Success"
                Remove-Item -Path $DestRoot -Recurse -Force -ErrorAction SilentlyContinue
            } catch {
                Log-Message "Failed to compress archive structure. Raw directory structure left intact." "Error"
            }
        }

        # Terminal Completion & Action Requirements Alert
        if (-not $script:CancelOperation) {
            $StatusLabel.Text = "Status: Backup Complete!"
            $FillPanel.Width = $MaxWidth
            Log-Message "User migration backup finished successfully." "Success"

            # Base Technical Warning Prompter
            $WarningText = "The file backup phase has completed successfully.`n`nCRITICAL ACTION ITEMS REMAINING (MANUAL MANDATORY STEPS):`n1. Browser Credentials: Due to App-Bound OS Encryption policies, passwords cannot be automatically extracted. You MUST manually export credentials to a CSV file or verify full profile Cloud Syncing is active.`n2. Authenticator & MFA Profiles: Ensure the user has backup recovery keys or access to MFA configurations before wiping or discarding the host computer."

            # Dynamic Environment Warnings
            $EnvWarnings = @()
            if ($script:HasOneDrive) {
                $EnvWarnings += "- ONEDRIVE KFM DETECTED: Standard user folders (Desktop, Documents, etc.) are currently synced to OneDrive. Ensure the user signs into OneDrive on the new PC to retrieve these files, as they may not be in the local backup."
            }
            if ($script:HasRedirection) {
                $EnvWarnings += "- FOLDER REDIRECTION DETECTED: Standard user folders are pointed to a network share. Ensure the new PC has network access and Group Policy applies correctly to remap these drives."
            }

            if ($EnvWarnings.Count -gt 0) {
                $WarningText += "`n`nENVIRONMENT WARNINGS TRIGGERED:`n" + ($EnvWarnings -join "`n")
            }

            [System.Windows.Forms.MessageBox]::Show($WarningText, "Migration Processing Instructions", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }

    } else {
        # --- RESTORE MODE ---
        $SelectedFile = $PathTextBox.Text

        # Handle ZIP selection automatically
        if ($SelectedFile -match "\.zip$") {
            $StatusLabel.Text = "Status: Extracting ZIP archive..."
            [System.Windows.Forms.Application]::DoEvents()

            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $ExtractDir = $SelectedFile.Substring(0, $SelectedFile.Length - 4) # Remove .zip

            if (-not (Test-Path $ExtractDir)) {
                try {
                    Expand-Archive -Path $SelectedFile -DestinationPath $ExtractDir -Force -ErrorAction Stop
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("Failed to extract ZIP archive. Error: $($_.Exception.Message)", "Error", 0, 16)
                    $StartButton.Enabled = $true; $CancelButton.Enabled = $false
                    return
                }
            }
            # Redirect the script to look at the newly extracted JSON
            $ConfigFile = Join-Path $ExtractDir "Migration.json"
        } else {
            $ConfigFile = $SelectedFile
        }

        $BackupRoot = Split-Path $ConfigFile -Parent
        $DataRoot = Join-Path $BackupRoot "C_Drive"

        if (-not (Test-Path $DataRoot)) {
            [System.Windows.Forms.MessageBox]::Show("Could not find the C_Drive data folder next to the JSON file.", "Error", 0, 16)
            $StartButton.Enabled = $true; $CancelButton.Enabled = $false
            return
        }

        # Read Config
        $JsonConfig = Get-Content $ConfigFile | ConvertFrom-Json

        # Restore Settings
        if ($chkSettings.Checked) {
            $StatusLabel.Text = "Status: Restoring OS Settings..."
            [System.Windows.Forms.Application]::DoEvents()

            if ($JsonConfig.Settings.AppsUseLightTheme -ne $null) {
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -Value $JsonConfig.Settings.AppsUseLightTheme -ErrorAction SilentlyContinue
            }
            if ($JsonConfig.Settings.SystemUsesLightTheme -ne $null) {
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name SystemUsesLightTheme -Value $JsonConfig.Settings.SystemUsesLightTheme -ErrorAction SilentlyContinue
            }
            if ($JsonConfig.Settings.TaskbarAl -ne $null) {
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarAl -Value $JsonConfig.Settings.TaskbarAl -ErrorAction SilentlyContinue
            }

            # Inform about network/printers
            Log-Message "Found $($JsonConfig.Printers.Count) printers and $($JsonConfig.MappedDrives.Count) mapped drives in backup config. Manual configuration may be required." "Info"
        }

        # Restore Files
        $StatusLabel.Text = "Status: Scanning backup files..."
        [System.Windows.Forms.Application]::DoEvents()

        $FileList = Get-ChildItem -Path $DataRoot -Recurse -File -Force -ErrorAction SilentlyContinue
        $TotalFiles = $FileList.Count
        $Copied = 0
        $MaxWidth = $TrackPanel.ClientSize.Width - 2
        $RestoredItemsLog = @() # Track for rollback

        if ($TotalFiles -gt 0) {
            foreach ($file in $FileList) {
                if ($script:CancelOperation) { break }

                # Map from Backup back to C:\
                $Relative = $file.FullName.Substring($DataRoot.Length + 1)

                # Map old username paths to current username
                $OldUserPath = "Users\$($JsonConfig.Username)"
                $CurrentUserPath = "Users\$env:USERNAME"
                if ($Relative.StartsWith($OldUserPath)) {
                    $Relative = $Relative.Replace($OldUserPath, $CurrentUserPath)
                }

                $TargetFile = Join-Path "C:\" $Relative
                $TargetDir = Split-Path $TargetFile -Parent

                if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }

                try {
                    if (-not (Test-Path $TargetFile)) {
                        [System.IO.File]::Copy($file.FullName, $TargetFile, $false)
                        $RestoredItemsLog += $TargetFile
                    }
                } catch {}

                $Copied++
                if ($Copied % 10 -eq 0 -or $Copied -eq $TotalFiles) {
                    $Percent = [math]::Round(($Copied / $TotalFiles) * 100)
                    $StatusLabel.Text = "Status: Restoring... $Percent% ($Copied / $TotalFiles files)"
                    $FillPanel.Width = [int]($MaxWidth * ($Copied / $TotalFiles))
                    [System.Windows.Forms.Application]::DoEvents()
                }
            }
        }

        if ($script:CancelOperation) {
            $rbRes = [System.Windows.Forms.MessageBox]::Show("Restore cancelled. Do you want to rollback (delete) the files that were just copied?", "Rollback", 4, 48)
            if ($rbRes -eq 'Yes') {
                $StatusLabel.Text = "Status: Rolling back files..."
                foreach ($f in $RestoredItemsLog) { Remove-Item $f -Force -ErrorAction SilentlyContinue }
                Log-Message "Restore cancelled and rolled back." "Warning"
            } else {
                Log-Message "Restore cancelled. Files left in place." "Warning"
            }
        } else {
            $StatusLabel.Text = "Status: Restore Complete!"
            $FillPanel.Width = $MaxWidth
            Log-Message "User migration restore finished successfully." "Success"
        }
    }

    $StartButton.Enabled = $true
    $CancelButton.Enabled = $false
})

# Kill the loader and show the real GUI
$MicroLoader.Close()
$MicroLoader.Dispose()
$MoveGUI.ShowDialog() | Out-Null
