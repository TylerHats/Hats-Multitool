# User Move Tool - Tyler Hatfield - v1.10

# Instantly pop a tiny loading indicator before loading the heavy C# assemblies
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
$MicroLoader = New-Object System.Windows.Forms.Form
$MicroLoader.ClientSize = New-Object System.Drawing.Size(220, 40)
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

    [DllImport("shell32.dll", SetLastError = true)]
    public static extern int SetCurrentProcessExplicitAppUserModelID([MarshalAs(UnmanagedType.LPWStr)] string AppID);
}
"@

# Call all three APIs
[UIHelpers]::SetProcessDPIAware() | Out-Null
[UIHelpers]::SetCurrentProcessExplicitAppUserModelID("Hat.Multitool.UserMove") | Out-Null
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# Standalone Variables
$font = New-Object System.Drawing.Font("Segoe UI", 10)

# Icon Fallback
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
$MoveGUI.ClientSize = New-Object System.Drawing.Size(450, 750)
$MoveGUI.StartPosition = 'CenterScreen'
$MoveGUI.Icon = $HMTIcon
$MoveGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$MoveGUI.MaximizeBox = $false
$MoveGUI.Font = $font
$MoveGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$MoveGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi

# Force Handle Creation so we can apply the Dark Mode Title Bar
$MoveGUI.Handle | Out-Null
$darkMode = 1
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

# User Selection Group
$y += 40
$UserListLabel = New-Object System.Windows.Forms.Label
$UserListLabel.Text = "Select Users to Backup:"
$UserListLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$UserListLabel.Location = New-Object System.Drawing.Point(20, $y)
$UserListLabel.AutoSize = $true
$MoveGUI.Controls.Add($UserListLabel)

$y += 25
# The Backup Mode User List
$UserListBox = New-Object System.Windows.Forms.CheckedListBox
$UserListBox.Location = New-Object System.Drawing.Point(30, $y)
$UserListBox.Size = New-Object System.Drawing.Size(380, 75)
$UserListBox.CheckOnClick = $true
$UserListBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#40444b")
$UserListBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$UserListBox.BorderStyle = 'FixedSingle'
$MoveGUI.Controls.Add($UserListBox)

# The Restore Mode User List (Hidden by Default)
$RestoreUserListBox = New-Object System.Windows.Forms.CheckedListBox
$RestoreUserListBox.Location = New-Object System.Drawing.Point(30, $y)
$RestoreUserListBox.Size = New-Object System.Drawing.Size(380, 75)
$RestoreUserListBox.CheckOnClick = $true
$RestoreUserListBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#40444b")
$RestoreUserListBox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$RestoreUserListBox.BorderStyle = 'FixedSingle'
$RestoreUserListBox.Visible = $false
$MoveGUI.Controls.Add($RestoreUserListBox)

# Populate Local Users for Backup
$LocalUsers = Get-ChildItem -Path "C:\Users" -Directory -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin @('Public', 'Default', 'Default User', 'All Users') }
foreach ($u in $LocalUsers) {
    $idx = $UserListBox.Items.Add($u.Name)
    if ($u.Name -eq $env:USERNAME) {
        $UserListBox.SetItemChecked($idx, $true)
    }
}

# Options Group
$y += 85
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
$chkUser.Text = "Selected User Profiles (Excl. Cloud/Temp)"
$chkUser.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkUser.Location = New-Object System.Drawing.Point(30, $y); $chkUser.Width = 350; $chkUser.Checked = $true
$MoveGUI.Controls.Add($chkUser)

# Master Browser Checkbox
$y += 25
$chkBrowsers = New-Object System.Windows.Forms.CheckBox
$chkBrowsers.Text = "Browser Data (Bookmarks, History, etc.)"
$chkBrowsers.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkBrowsers.Location = New-Object System.Drawing.Point(30, $y); $chkBrowsers.Width = 350; $chkBrowsers.Checked = $true
$MoveGUI.Controls.Add($chkBrowsers)

# Indented Browser Sub-Options
$y += 25
$chkChrome = New-Object System.Windows.Forms.CheckBox
$chkChrome.Text = "Google Chrome"
$chkChrome.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
$chkChrome.Location = New-Object System.Drawing.Point(60, $y); $chkChrome.Width = 150; $chkChrome.Checked = $true
$MoveGUI.Controls.Add($chkChrome)

$chkEdge = New-Object System.Windows.Forms.CheckBox
$chkEdge.Text = "Microsoft Edge"
$chkEdge.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
$chkEdge.Location = New-Object System.Drawing.Point(220, $y); $chkEdge.Width = 150; $chkEdge.Checked = $true
$MoveGUI.Controls.Add($chkEdge)

$y += 25
$chkFirefox = New-Object System.Windows.Forms.CheckBox
$chkFirefox.Text = "Mozilla Firefox"
$chkFirefox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
$chkFirefox.Location = New-Object System.Drawing.Point(60, $y); $chkFirefox.Width = 150; $chkFirefox.Checked = $true
$MoveGUI.Controls.Add($chkFirefox)

$y += 25
$chkSettings = New-Object System.Windows.Forms.CheckBox
$chkSettings.Text = 'OS Settings, Printers, Network Drives, etc.'
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
$chkZip.Text = "Compress Backup into a .ZIP Archive (Slower)"
$chkZip.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$chkZip.Location = New-Object System.Drawing.Point(30, $y); $chkZip.Width = 350; $chkZip.Checked = $false
$MoveGUI.Controls.Add($chkZip)

# UI Logic for Browser Sub-menus
$chkBrowsers.Add_CheckedChanged({
    $chkChrome.Enabled = $chkBrowsers.Checked
    $chkEdge.Enabled = $chkBrowsers.Checked
    $chkFirefox.Enabled = $chkBrowsers.Checked
})

# UI Logic for Mode Switching
$RestoreRadio.Add_CheckedChanged({
    if ($RestoreRadio.Checked) {
        $PathLabel.Text = "Select Migration.json File:"
        $PathTextBox.Clear()
        $UserListLabel.Text = "Select Users to Restore:"
        $UserListBox.Visible = $false
        $RestoreUserListBox.Visible = $true
        $chkDrivers.Enabled = $false
        $chkDrivers.Checked = $false
        $chkZip.Enabled = $false
        $chkZip.Checked = $false
    } else {
        $PathLabel.Text = "Destination Folder:"
        $PathTextBox.Clear()
        $UserListLabel.Text = "Select Users to Backup:"
        $UserListBox.Visible = $true
        $RestoreUserListBox.Visible = $false
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

            try {
                $TempConfigPath = $FileBrowser.FileName
                if ($TempConfigPath -match "\.zip$") {
                    $RestoreUserListBox.Items.Clear()
                    $RestoreUserListBox.Items.Add("Users will be extracted from ZIP on start.")
                } else {
                    $TempJSON = Get-Content $TempConfigPath -Raw | ConvertFrom-Json
                    $RestoreUserListBox.Items.Clear()
                    foreach ($u in $TempJSON.UsersBackedUp) {
                        $idx = $RestoreUserListBox.Items.Add($u)
                        $RestoreUserListBox.SetItemChecked($idx, $true)
                    }
                }
            } catch {}
        }
    }
})

# Progress & Status
$y += 45
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
        $ActiveUsers = @()
        foreach ($item in $UserListBox.CheckedItems) { $ActiveUsers += $item }

        if ($ActiveUsers.Count -eq 0 -and ($chkUser.Checked -or $chkBrowsers.Checked)) {
            [System.Windows.Forms.MessageBox]::Show("Please select at least one user to backup.", "Error", 0, 16)
            $StartButton.Enabled = $true; $CancelButton.Enabled = $false
            return
        }

        $DestRoot = Join-Path $PathTextBox.Text "HMT_Migration_$(Get-Date -Format 'yyyyMMdd_HHmm')"
        if (-not (Test-Path $DestRoot)) { New-Item -ItemType Directory -Path $DestRoot | Out-Null }

        $JsonConfig = @{
            OSBuild = $OSVersion.Build
            UsersBackedUp = $ActiveUsers
            Domain = $env:USERDOMAIN
            Printers = @()
            Software = @()
            MappedDrives = @()
            Settings = @{}
        }

        $ShellFoldersKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        $ImportantFolders = @("Desktop", "Personal", "My Pictures")
        $script:HasOneDrive = $false
        $script:HasRedirection = $false

        foreach ($folder in $ImportantFolders) {
            $path = (Get-ItemProperty -Path $ShellFoldersKey -Name $folder -ErrorAction SilentlyContinue).$folder
            if ($path -match "OneDrive") { $script:HasOneDrive = $true }
            if ($path -match "^\\\\") { $script:HasRedirection = $true }
        }

        $SysInfo = Get-CimInstance Win32_ComputerSystem
        $OSInfo = Get-CimInstance Win32_OperatingSystem
        $UserString = $ActiveUsers -join ", "
        $SpecSummary = @"
User Migration Backup
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Backed Up Users: $UserString
Domain: $($env:USERDOMAIN)

Hardware Asset Info:
Hostname: $($SysInfo.Name)
Manufacturer: $($SysInfo.Manufacturer)
Model: $($SysInfo.Model)
RAM: $([math]::Round($SysInfo.TotalPhysicalMemory / 1GB, 2)) GB
OS: $($OSInfo.Caption) ($($OSInfo.OSArchitecture))
"@
        $SpecSummary | Out-File -FilePath (Join-Path $DestRoot "PC_Specs.txt") -Encoding ascii

        if ($chkSettings.Checked) {
            $StatusLabel.Text = "Status: Exporting System Settings..."
            [System.Windows.Forms.Application]::DoEvents()

            $JsonConfig.Printers = Get-Printer -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch "Microsoft|OneNote|PDF|XPS|Root" } | Select-Object Name, DriverName, PortName, Shared

            foreach ($u in $ActiveUsers) {
                $JsonConfig.Settings.$u = @{}
                $UserRoot = "C:\Users\$u"

                try {
                    $objUser = New-Object System.Security.Principal.NTAccount($u)
                    $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier]).Value
                    $RegLoadedHere = $false

                    if (-not (Test-Path "Registry::HKEY_USERS\$strSID")) {
                        Start-Process cmd.exe -ArgumentList "/c reg load `"HKU\TempHive_$u`" `"$UserRoot\NTUSER.DAT`"" -NoNewWindow -Wait
                        $TargetHive = "Registry::HKEY_USERS\TempHive_$u"
                        $RegLoadedHere = $true
                    } else {
                        $TargetHive = "Registry::HKEY_USERS\$strSID"
                    }

                    $ThemeKey = "$TargetHive\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
                    $JsonConfig.Settings.$u.AppsUseLightTheme = (Get-ItemProperty -Path $ThemeKey -Name AppsUseLightTheme -ErrorAction SilentlyContinue).AppsUseLightTheme
                    $JsonConfig.Settings.$u.SystemUsesLightTheme = (Get-ItemProperty -Path $ThemeKey -Name SystemUsesLightTheme -ErrorAction SilentlyContinue).SystemUsesLightTheme

                    $TBKey = "$TargetHive\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
                    $JsonConfig.Settings.$u.TaskbarAl = (Get-ItemProperty -Path $TBKey -Name TaskbarAl -ErrorAction SilentlyContinue).TaskbarAl

                    $NetworkKey = "$TargetHive\Network"
                    $Drives = @()
                    if (Test-Path $NetworkKey) {
                        $DriveLetters = Get-ChildItem -Path $NetworkKey -ErrorAction SilentlyContinue
                        foreach ($dl in $DriveLetters) {
                            $RemotePath = (Get-ItemProperty -Path $dl.PSPath -Name RemotePath -ErrorAction SilentlyContinue).RemotePath
                            $Drives += @{ Drive = $dl.PSChildName; Path = $RemotePath }
                        }
                    }
                    $JsonConfig.Settings.$u.MappedDrives = $Drives

                    if ($RegLoadedHere) {
                        [gc]::Collect(); [gc]::WaitForPendingFinalizers()
                        Start-Process cmd.exe -ArgumentList "/c reg unload `"HKU\TempHive_$u`"" -NoNewWindow -Wait
                    }
                } catch {
                    Log-Message "Failed to read registry settings for user: $u" "Warning"
                }
            }
        }

        if ($chkDrivers.Checked) {
            $StatusLabel.Text = "Status: Exporting 3rd Party Drivers (This takes a moment)..."
            [System.Windows.Forms.Application]::DoEvents()
            $DriverDest = Join-Path $DestRoot "ExportedDrivers"
            New-Item -ItemType Directory -Path $DriverDest -Force | Out-Null
            Export-WindowsDriver -Online -Destination $DriverDest -ErrorAction SilentlyContinue | Out-Null
        }

        $FoldersToScan = @()

        if ($chkRoot.Checked) {
            Get-ChildItem -Path "C:\" -Directory -Force -ErrorAction SilentlyContinue | Where-Object {
                $_.Name -notin @('Windows', 'Program Files', 'Program Files (x86)', 'PerfLogs', '$Recycle.Bin', 'System Volume Information')
            } | ForEach-Object { $FoldersToScan += $_.FullName }
        }

        foreach ($u in $ActiveUsers) {
            $UserRoot = "C:\Users\$u"
            if ($chkUser.Checked) {
                $UserFolders = @('Desktop', 'Documents', 'Downloads', 'Music', 'Pictures', 'Videos', 'Favorites')
                foreach ($uf in $UserFolders) {
                    $p = Join-Path $UserRoot $uf
                    if (Test-Path $p) { $FoldersToScan += $p }
                }

                # Core AppData Injections
                $FoldersToScan += "$UserRoot\AppData\Roaming\Microsoft\Signatures"
                $FoldersToScan += "$UserRoot\AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe"

                # OS Settings & UI Injections (Quick Access, Pinned Taskbar Icons)
                $FoldersToScan += "$UserRoot\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations"
                $FoldersToScan += "$UserRoot\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
            }
            if ($chkBrowsers.Checked) {
                if ($chkChrome.Checked) { $FoldersToScan += "$UserRoot\AppData\Local\Google\Chrome\User Data" }
                if ($chkEdge.Checked) { $FoldersToScan += "$UserRoot\AppData\Local\Microsoft\Edge\User Data" }
                if ($chkFirefox.Checked) { $FoldersToScan += "$UserRoot\AppData\Roaming\Mozilla\Firefox" }
            }
        }

        $TotalFiles = 0
        $TotalBytesRequired = 0
        $FileList = @()

        $StatusLabel.Text = "Status: Scanning folders for sizing..."
        [System.Windows.Forms.Application]::DoEvents()

        foreach ($folder in $FoldersToScan) {
            if (Test-Path $folder) {
                $found = Get-ChildItem -Path $folder -Recurse -File -Force -ErrorAction SilentlyContinue
                if (-not $found) { continue }
                $Size = ($found | Measure-Object -Property Length -Sum).Sum

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

        $DestDriveLetter = (Split-Path $PathTextBox.Text -Qualifier)
        if ($DestDriveLetter) {
            $DestDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$DestDriveLetter'"
            $RequiredSpaceWithBuffer = $TotalBytesRequired * 1.2
            if ($DestDrive.FreeSpace -lt $RequiredSpaceWithBuffer) {
                $NeededGB = [math]::Round($RequiredSpaceWithBuffer / 1GB, 2)
                $AvailableGB = [math]::Round($DestDrive.FreeSpace / 1GB, 2)
                [System.Windows.Forms.MessageBox]::Show("Critical Error: Insufficient destination space.`nRequired: $NeededGB GB`nAvailable: $AvailableGB GB", "Space Allocation Failure", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                $script:CancelOperation = $true
            }
        }

        $Copied = 0
        $MaxWidth = $TrackPanel.ClientSize.Width - 2

        if (-not $script:CancelOperation) {
            if ($TotalFiles -gt 0) {
                foreach ($file in $FileList) {
                    if ($script:CancelOperation) {
                        Log-Message "Migration Backup Canceled by User." "Warning"
                        break
                    }
                    $Relative = $file.FullName.Substring(3)
                    $TargetFile = Join-Path $DestRoot "C_Drive\$Relative"
                    $TargetDir = Split-Path $TargetFile -Parent

                    if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }
                    try { [System.IO.File]::Copy($file.FullName, $TargetFile, $true) } catch {}

                    $Copied++
                    if ($Copied % 20 -eq 0 -or $Copied -eq $TotalFiles) {
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

        $JsonConfig | ConvertTo-Json -Depth 5 | Out-File (Join-Path $DestRoot "Migration.json") -Encoding ascii

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
                Log-Message "Failed to compress archive structure." "Error"
            }
        }

        if (-not $script:CancelOperation) {
            $StatusLabel.Text = "Status: Backup Complete!"
            $FillPanel.Width = $MaxWidth
            Log-Message "User migration backup finished successfully." "Success"

            $WarningText = "CRITICAL ACTION ITEMS REMAINING:`n1. Browser Credentials must be manually exported/synced.`n2. Authenticator & MFA Profiles must be backed up."
            $EnvWarnings = @()
            if ($script:HasOneDrive) { $EnvWarnings += "- ONEDRIVE KFM DETECTED." }
            if ($script:HasRedirection) { $EnvWarnings += "- FOLDER REDIRECTION DETECTED." }
            if ($EnvWarnings.Count -gt 0) { $WarningText += "`n`nENVIRONMENT WARNINGS:`n" + ($EnvWarnings -join "`n") }

            [System.Windows.Forms.MessageBox]::Show($WarningText, "Migration Instructions", 0, [System.Windows.Forms.MessageBoxIcon]::Information)
        }

    } else {
        # --- RESTORE MODE (OOBE GHOST AGENT) ---
        $SelectedFile = $PathTextBox.Text

        if ($SelectedFile -match "\.zip$") {
            $StatusLabel.Text = "Status: Extracting ZIP archive..."
            [System.Windows.Forms.Application]::DoEvents()
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $ExtractDir = $SelectedFile.Substring(0, $SelectedFile.Length - 4)

            if (-not (Test-Path $ExtractDir)) {
                try { Expand-Archive -Path $SelectedFile -DestinationPath $ExtractDir -Force -ErrorAction Stop }
                catch {
                    [System.Windows.Forms.MessageBox]::Show("Failed to extract ZIP archive.", "Error", 0, 16)
                    $StartButton.Enabled = $true; $CancelButton.Enabled = $false
                    return
                }
            }
            $ConfigFile = Join-Path $ExtractDir "Migration.json"
        } else {
            $ConfigFile = $SelectedFile
        }

        $BackupRoot = Split-Path $ConfigFile -Parent
        $DataRoot = Join-Path $BackupRoot "C_Drive"

        if (-not (Test-Path $DataRoot)) {
            [System.Windows.Forms.MessageBox]::Show("Could not find the C_Drive data folder.", "Error", 0, 16)
            $StartButton.Enabled = $true; $CancelButton.Enabled = $false
            return
        }

        $JsonConfig = Get-Content $ConfigFile -Raw | ConvertFrom-Json
        $ActiveRestoreUsers = @()
        foreach ($item in $RestoreUserListBox.CheckedItems) { $ActiveRestoreUsers += ($item -replace " \(Current User.*","").Trim() }

        if ($ActiveRestoreUsers.Count -eq 0) {
            if ($JsonConfig.UsersBackedUp) { $ActiveRestoreUsers = $JsonConfig.UsersBackedUp }
            else {
                [System.Windows.Forms.MessageBox]::Show("Could not identify users to restore.", "Error", 0, 16)
                $StartButton.Enabled = $true; $CancelButton.Enabled = $false
                return
            }
        }

        # 1. Prepare Staging Environment (Generic Naming)
        $PublicStaging = "C:\Users\Public\System_Profile_Migration"
        $FilesStaging = Join-Path $PublicStaging "StagedFiles"
        if (-not (Test-Path $FilesStaging)) { New-Item -ItemType Directory -Path $FilesStaging -Force | Out-Null }

        Start-Process cmd.exe -ArgumentList "/c icacls `"$PublicStaging`" /grant `"Everyone:(OI)(CI)M`" /T /C /Q" -WindowStyle Hidden -Wait

        $StatusLabel.Text = "Status: Scanning backup files..."
        [System.Windows.Forms.Application]::DoEvents()

        $FileList = Get-ChildItem -Path $DataRoot -Recurse -File -Force -ErrorAction SilentlyContinue
        $FilteredFileList = @()
        foreach ($file in $FileList) {
            $Relative = $file.FullName.Substring($DataRoot.Length + 1)
            if ($Relative -match "^Users\\") {
                $uName = ($Relative -split "\\")[1]
                if ($ActiveRestoreUsers -contains $uName) { $FilteredFileList += $file }
            } else {
                if ($chkRoot.Checked) { $FilteredFileList += $file }
            }
        }

        $TotalFiles = $FilteredFileList.Count
        $Copied = 0
        $MaxWidth = $TrackPanel.ClientSize.Width - 2

        if ($TotalFiles -gt 0) {
            foreach ($file in $FilteredFileList) {
                if ($script:CancelOperation) { break }

                $Relative = $file.FullName.Substring($DataRoot.Length + 1)

                if ($Relative -match "^Users\\") {
                    $uName = ($Relative -split "\\")[1]
                    $UserSubPath = $Relative.Substring("Users\$uName\".Length)
                    $TargetFile = Join-Path "$FilesStaging\$uName" $UserSubPath
                } else {
                    $TargetFile = Join-Path "C:\" $Relative
                }

                $TargetDir = Split-Path $TargetFile -Parent
                if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }
                try { if (-not (Test-Path $TargetFile)) { [System.IO.File]::Copy($file.FullName, $TargetFile, $false) } } catch {}

                $Copied++
                if ($Copied % 20 -eq 0 -or $Copied -eq $TotalFiles) {
                    $Percent = [math]::Round(($Copied / $TotalFiles) * 100)
                    $StatusLabel.Text = "Status: Staging... $Percent% ($Copied / $TotalFiles files)"
                    $FillPanel.Width = [int]($MaxWidth * ($Copied / $TotalFiles))
                    [System.Windows.Forms.Application]::DoEvents()
                }
            }
        }

        if ($script:CancelOperation) {
            $StatusLabel.Text = "Status: Rolling back staging data..."
            Remove-Item $PublicStaging -Recurse -Force -ErrorAction SilentlyContinue
            $StartButton.Enabled = $true; $CancelButton.Enabled = $false
            return
        }

        # 2. Build the Mandatory OOBE Ghost Agent
        $StatusLabel.Text = "Status: Arming OOBE Agent for first login..."
        [System.Windows.Forms.Application]::DoEvents()

        $PendingSettings = @{}
        foreach ($u in $ActiveRestoreUsers) { $PendingSettings[$u] = $JsonConfig.Settings.$u }
        $PendingSettings | ConvertTo-Json -Depth 5 | Out-File (Join-Path $PublicStaging "PendingSettings.json") -Encoding ascii

        $GhostScriptPath = Join-Path $PublicStaging "ProfileOOBE.ps1"
        $GhostCode = @"
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

`$SettingsFile = "C:\Users\Public\System_Profile_Migration\PendingSettings.json"
if (-not (Test-Path `$SettingsFile)) { exit }

`$Pending = Get-Content `$SettingsFile -Raw | ConvertFrom-Json
`$StagedUsers = Get-ChildItem "C:\Users\Public\System_Profile_Migration\StagedFiles" -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name

`$MatchFound = `$false
`$MatchedOldUser = ""

foreach (`$oldUser in `$StagedUsers) {
    # Loose Auto-Matching (e.g. jsmith matches john.smith, or jsmith.DOMAIN)
    if (`$env:USERNAME -match `$oldUser -or `$oldUser -match `$env:USERNAME) {
        `$MatchFound = `$true
        `$MatchedOldUser = `$oldUser
        break
    }
}

if (`$MatchFound) {
    # 1. Spawn Mandatory Blocking Screen
    `$Blocker = New-Object System.Windows.Forms.Form
    `$Blocker.FormBorderStyle = 'None'
    `$Blocker.WindowState = 'Maximized'
    `$Blocker.TopMost = `$true
    `$Blocker.BackColor = [System.Drawing.Color]::Black
    `$Blocker.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    `$Label = New-Object System.Windows.Forms.Label
    `$Label.Text = "Finalizing User Profile Integration... Please wait."
    `$Label.ForeColor = [System.Drawing.Color]::White
    `$Label.Font = New-Object System.Drawing.Font("Segoe UI", 16)
    `$Label.AutoSize = `$false
    `$Label.Dock = 'Fill'
    `$Label.TextAlign = 'MiddleCenter'
    `$Blocker.Controls.Add(`$Label)

    `$Blocker.Show()
    [System.Windows.Forms.Application]::DoEvents()

    # 2. Run Robocopy to instantly move files into active profile
    `$Src = "C:\Users\Public\System_Profile_Migration\StagedFiles\`$MatchedOldUser"
    Start-Process cmd.exe -ArgumentList "/c robocopy `"`$Src`" `"`$env:USERPROFILE`" /E /MOVE /IS /IT" -WindowStyle Hidden -Wait

    # 3. Apply Registry Themes
    `$uSettings = `$Pending.`$MatchedOldUser
    if (`$uSettings.AppsUseLightTheme -ne `$null) { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -Value `$uSettings.AppsUseLightTheme -ErrorAction SilentlyContinue }
    if (`$uSettings.SystemUsesLightTheme -ne `$null) { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name SystemUsesLightTheme -Value `$uSettings.SystemUsesLightTheme -ErrorAction SilentlyContinue }
    if (`$uSettings.TaskbarAl -ne `$null) { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarAl -Value `$uSettings.TaskbarAl -ErrorAction SilentlyContinue }

    # 4. Map Network Drives
    if (`$uSettings.MappedDrives) {
        foreach (`$drive in `$uSettings.MappedDrives) {
            Start-Process cmd.exe -ArgumentList "/c net use `$(`$drive.Drive): `"`$(`$drive.Path)`" /persistent:yes" -WindowStyle Hidden
        }
    }

    # Remove user from pending list and cleanup staging folder
    Remove-Item "C:\Users\Public\System_Profile_Migration\StagedFiles\`$MatchedOldUser" -Recurse -Force -ErrorAction SilentlyContinue

    # Update UI to notify forced sign out
    `$Label.Text = "Integration Complete.`nSigning out to apply deep system themes..."
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Seconds 10

    # Force Logoff to cleanly reload cached HKCU settings
    Start-Process cmd.exe -ArgumentList "/c logoff" -WindowStyle Hidden
}

# Cleanup Agent if Empty
`$Remaining = Get-ChildItem "C:\Users\Public\System_Profile_Migration\StagedFiles" -Directory -ErrorAction SilentlyContinue
if (-not `$Remaining) {
    Remove-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\ProfileOOBE.lnk" -Force -ErrorAction SilentlyContinue
    Start-Process cmd.exe -ArgumentList "/c rmdir /s /q `"C:\Users\Public\System_Profile_Migration`"" -WindowStyle Hidden
}
"@
        $GhostCode | Out-File $GhostScriptPath -Encoding ascii

        # Create the All-Users Startup Shortcut via COM Object
        $WshShell = New-Object -ComObject WScript.Shell
        $ShortcutPath = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\ProfileOOBE.lnk"
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$GhostScriptPath`""
        $Shortcut.Save()

        $StatusLabel.Text = "Status: Restore Staging Complete!"
        $FillPanel.Width = $MaxWidth

        [System.Windows.Forms.MessageBox]::Show("Staging complete! The OOBE Agent is armed.`n`nHave the user(s) log into this PC. The screen will lock momentarily to finalize their profile, and they will be automatically signed out once complete.", "Restore Armed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }

    $StartButton.Enabled = $true
    $CancelButton.Enabled = $false
})

# Kill the loader and show the real GUI
$MicroLoader.Close()
$MicroLoader.Dispose()
$MoveGUI.ShowDialog() | Out-Null
