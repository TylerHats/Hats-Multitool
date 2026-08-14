# GUI Tools & Troubleshooting - Tyler Hatfield - v2.20

# Directory for external portable tools
$ExtProgramDir = Join-Path -Path $PSScriptRoot -ChildPath "ExtPrograms"

# ==============================================================================
# Unified Tools & Troubleshooting Window with Tabs
# ==============================================================================

$ToolsGUI = New-Object System.Windows.Forms.Form
$ToolsGUI.Text = "Hat's Multitool - Tools & Troubleshooting"
$ToolsGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$ToolsGUI.ClientSize = New-Object System.Drawing.Size(780, 560)
$ToolsGUI.StartPosition = 'CenterScreen'
$ToolsGUI.Icon = $HMTIcon
$ToolsGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$ToolsGUI.MaximizeBox = $false
$ToolsGUI.MinimizeBox = $true
$ToolsGUI.ShowInTaskbar = $true
$ToolsGUI.Font = $font
$ToolsGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$ToolsGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $ToolsGUI

# Create Dark Tab Control
$ToolsTabControl = New-Object HMT.Tools.DarkTabControl
$ToolsTabControl.Location = New-Object System.Drawing.Point(20, 15)
$ToolsTabControl.Size = New-Object System.Drawing.Size(740, 470)
$ToolsTabControl.Font = $font
$ToolsTabControl.ItemSize = New-Object System.Drawing.Size(142, 32)
$ToolsGUI.Controls.Add($ToolsTabControl)

# Tool Lists by Category
$repairList = @(
    [pscustomobject]@{ Name = "DISM Repair"; Desc = "Launches DISM image health restore with live progress in a styled console." }
    [pscustomobject]@{ Name = "SFC Repair"; Desc = "Executes System File Checker (sfc /scannow) in a styled console window." }
    [pscustomobject]@{ Name = "Check Disk (Read Only)"; Desc = "Runs Check Disk (chkdsk C:) in read-only mode to check for file system errors." }
    [pscustomobject]@{ Name = ".NET 3.5 (Includes v2 and v3)"; Desc = "Installs .NET Framework 3.5/2.0/3.0 via DISM with live status output." }
    [pscustomobject]@{ Name = "Windows Update Reset"; Desc = "Stops update services, clears SoftwareDistribution & catroot2 caches, and resets components." }
    [pscustomobject]@{ Name = "Reset HOSTS File to Default"; Desc = "Resets Windows HOSTS file back to clean Microsoft default (creates a backup .bak)." }
    [pscustomobject]@{ Name = "Reset Settings Page Visibility"; Desc = "Clears SettingsPageVisibility registry policy to unhide blocked Windows Settings pages." }
)

$diskList = @(
    [pscustomobject]@{ Name = "WizTree"; Desc = "Scans a selected drive or folder and displays all contents and relative disk space." }
    [pscustomobject]@{ Name = "BleachBit"; Desc = "System and program temporary data cleaner to reclaim drive space." }
    [pscustomobject]@{ Name = "Patch Cleaner"; Desc = "Scans and allows safe removal of orphaned installer/driver store files." }
    [pscustomobject]@{ Name = "Windows Disk Cleanup"; Desc = "Launches the native Windows Disk Cleanup utility." }
    [pscustomobject]@{ Name = "Storage SMART & Benchmark Dashboard"; Desc = "Hardware health summary, wearout gauge, temperature, and built-in direct sequential & 4K random speed benchmark." }
    [pscustomobject]@{ Name = "Display Driver Uninstaller"; Desc = "Runs Display Driver Uninstaller (DDU) to clean graphics/audio drivers for fresh installs." }
    [pscustomobject]@{ Name = "HDDScan"; Desc = "Runs HDDScan to verify block health and SMART diagnostics." }
    [pscustomobject]@{ Name = "Crystal Disk Mark"; Desc = "SSD/HDD storage benchmark utility." }
    [pscustomobject]@{ Name = "Crystal Disk Info"; Desc = "Drive health and temperature monitoring utility." }
    [pscustomobject]@{ Name = "BitLocker Drive Encryption & Recovery"; Desc = "Inspect status, enable/disable encryption, manage recovery keys, and unlock locked drives." }
)

$netList = @(
    [pscustomobject]@{ Name = "Internet Speed Test"; Desc = "Native, real-time speed test against Cloudflare Anycast measuring Ping, Jitter, Download, and Upload." }
    [pscustomobject]@{ Name = "Packet Loss & Latency Test"; Desc = "High-precision async latency & packet loss tester with real-time jitter, loss metrics, and smooth GDI+ graph." }
    [pscustomobject]@{ Name = "TCP Port & Connection Checker"; Desc = "Tests IP/hostname reachability and open TCP ports with response time." }
    [pscustomobject]@{ Name = "Flush DNS & Reset IP"; Desc = "Releases/renews IP, flushes DNS client cache, and clears ARP entries." }
    [pscustomobject]@{ Name = "Advanced IP Scanner"; Desc = "Fast network scanner for remote subnet discovery and device inventory." }
    [pscustomobject]@{ Name = "PuTTY"; Desc = "SSH and Telnet client for Windows." }
    [pscustomobject]@{ Name = "CurrPorts"; Desc = "Displays all currently opened TCP/IP and UDP ports with process owner details." }
)

$viewerList = @(
    [pscustomobject]@{ Name = "BlueScreenView"; Desc = "Memory dump & minidump reader to identify crash causes and BSOD drivers." }
    [pscustomobject]@{ Name = "USBDeview"; Desc = "Lists all USB devices currently connected or previously used on this system." }
    [pscustomobject]@{ Name = "DriverView"; Desc = "Lists all installed device drivers loaded in the operating system." }
    [pscustomobject]@{ Name = "UninstallView"; Desc = "Fast, comprehensive viewer for installed software with batch uninstall options." }
    [pscustomobject]@{ Name = "DISM++"; Desc = "Advanced GUI based around DISM for Windows image management and optimization." }
    [pscustomobject]@{ Name = "Hat's User Move Tool"; Desc = "Collects user and system data for transferring to new machines." }
    [pscustomobject]@{ Name = "User Profile Wizard"; Desc = "Migrates user profile data between domains or computers (Profwiz)." }
    [pscustomobject]@{ Name = "Generate Battery Report"; Desc = "Generates and opens a detailed HTML report of laptop battery health and cycle history." }
    [pscustomobject]@{ Name = "Startup & Autoruns Manager"; Desc = "Inspect, enable, disable, or remove startup applications and registry autorun entries." }
    [pscustomobject]@{ Name = "Reliability Monitor"; Desc = "Opens Windows Reliability Monitor timeline to view crash and software install history." }
    [pscustomobject]@{ Name = "Read Motherboard OEM Product Key"; Desc = "Reads OEM Windows product key embedded in BIOS/ACPI MSDM table." }
    [pscustomobject]@{ Name = "Enable Safe Boot (w/Network)"; Desc = "Configures BCD to boot into Safe Mode with networking enabled." }
    [pscustomobject]@{ Name = "Restart Windows Explorer"; Desc = "Forcefully kills and restarts explorer.exe to resolve frozen taskbars or stuck folders." }
    [pscustomobject]@{ Name = "McAfee MCPR Tool"; Desc = "Official McAfee Consumer Product Removal tool." }
    [pscustomobject]@{ Name = "Ninja Removal Script"; Desc = "Launches the NinjaOne Agent removal script." }
    [pscustomobject]@{ Name = "Win11 Upgrade Assistant"; Desc = "Runs Microsoft Windows 11 Upgrade Assistant." }
)

$passList = @(
    [pscustomobject]@{ Name = "WebBrowserPassView"; Desc = "Password recovery tool for all major web browsers (Edge, Chrome, Firefox, Opera)." }
    [pscustomobject]@{ Name = "WirelessKeyView"; Desc = "Recovers all wireless network keys (WEP/WPA/WPA2/WPA3) stored in Windows." }
    [pscustomobject]@{ Name = "Dialupass"; Desc = "Recovers passwords for VPN, Dialup, and RAS connections." }
    [pscustomobject]@{ Name = "CredentialFileView"; Desc = "Decrypts and displays credentials stored inside Windows Credentials files." }
    [pscustomobject]@{ Name = "VaultPasswordView"; Desc = "Decrypts and displays passwords stored in Windows Vault and Windows Credentials Manager." }
    [pscustomobject]@{ Name = "BitLocker Recovery Keys & Unlock"; Desc = "Retrieve 48-digit numerical recovery passwords, export keys, and unlock BitLocker volumes." }
)

# Helper function to create a styled ListView for a tab
$createTabListView = {
    param($parentTab, $itemsList)
    $lv = New-Object HMT.Tools.DarkListView
    $lv.Dock = [System.Windows.Forms.DockStyle]::Fill
    $lv.Font = $font
    $lv.Columns.Add("Tool", 210) | Out-Null
    $lv.Columns.Add("Description", 480) | Out-Null

    foreach ($t in $itemsList) {
        $item = New-Object System.Windows.Forms.ListViewItem($t.Name)
        $item.SubItems.Add($t.Desc) | Out-Null
        $lv.Items.Add($item) | Out-Null
    }

    $parentTab.Controls.Add($lv)
    return $lv
}

# 1. Tab: System Repair
$tabRepair = New-Object System.Windows.Forms.TabPage("System Repair")
$tabRepair.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$lvRepair = &$createTabListView $tabRepair $repairList
$ToolsTabControl.TabPages.Add($tabRepair)

# 2. Tab: Disk & Space
$tabDisk = New-Object System.Windows.Forms.TabPage("Disk & Space")
$tabDisk.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$lvDisk = &$createTabListView $tabDisk $diskList
$ToolsTabControl.TabPages.Add($tabDisk)

# 3. Tab: Network & Connectivity
$tabNet = New-Object System.Windows.Forms.TabPage("Network")
$tabNet.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$lvNet = &$createTabListView $tabNet $netList
$ToolsTabControl.TabPages.Add($tabNet)

# 4. Tab: System Viewers & Admin
$tabViewer = New-Object System.Windows.Forms.TabPage("System Viewers")
$tabViewer.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$lvViewer = &$createTabListView $tabViewer $viewerList
$ToolsTabControl.TabPages.Add($tabViewer)

# 5. Tab: Password Recovery
$tabPass = New-Object System.Windows.Forms.TabPage("Passwords")
$tabPass.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$ToolsTabControl.TabPages.Add($tabPass)

# Top warning banner on Password tab
$passHeaderPanel = New-Object System.Windows.Forms.Panel
$passHeaderPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$passHeaderPanel.Height = 100
$passHeaderPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3a2528")
$tabPass.Controls.Add($passHeaderPanel)

$lblPassWarn = New-Object System.Windows.Forms.Label
$lblPassWarn.Text = "[!] Advanced Diagnostic & Recovery Tools: These legitimate NirSoft utilities are frequently flagged as HackTool / RiskTool by Antivirus engines. They are downloaded on-demand only."
$lblPassWarn.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
$lblPassWarn.Location = New-Object System.Drawing.Point(15, 10)
$lblPassWarn.Size = New-Object System.Drawing.Size(700, 32)
$passHeaderPanel.Controls.Add($lblPassWarn)

# AV Query & Defender Deep Link
$avList = @()
try {
    $avProducts = Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
    if ($avProducts) {
        foreach ($av in $avProducts) { $avList += $av.displayName }
    }
} catch {}
$avDisplay = if ($avList.Count -gt 0) { $avList -join ", " } else { "Windows Defender" }

$lblAvDetect = New-Object System.Windows.Forms.Label
$lblAvDetect.Text = "Active AV: $avDisplay | Recommend running in Safe Mode without networking if blocked."
$lblAvDetect.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lblAvDetect.Location = New-Object System.Drawing.Point(15, 46)
$lblAvDetect.Size = New-Object System.Drawing.Size(460, 42)
$passHeaderPanel.Controls.Add($lblAvDetect)

$btnDefender = New-Object System.Windows.Forms.Button
$btnDefender.Text = "Defender Tamper Protection"
$btnDefender.Location = New-Object System.Drawing.Point(485, 48)
$btnDefender.Size = New-Object System.Drawing.Size(230, 34)
$btnDefender.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$btnDefender.FlatStyle = 'Flat'
$btnDefender.FlatAppearance.BorderSize = 1
$btnDefender.Add_Click({
    Start-Process "windowsdefender://threatsettings" -ErrorAction SilentlyContinue
})
$passHeaderPanel.Controls.Add($btnDefender)

$lvPass = &$createTabListView $tabPass $passList

# Bottom Action Buttons
$yBtn = 498
$TLaunchButton = New-Object System.Windows.Forms.Button
$TLaunchButton.Location = New-Object System.Drawing.Point(20, $yBtn)
$TLaunchButton.Size = New-Object System.Drawing.Size(200, 42)
$TLaunchButton.Text = "Launch Selected Tool"
$TLaunchButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TLaunchButton.FlatStyle = 'Flat'
$TLaunchButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($TLaunchButton)

$ConsoleButton = New-Object System.Windows.Forms.Button
$ConsoleButton.Location = New-Object System.Drawing.Point(510, $yBtn)
$ConsoleButton.Size = New-Object System.Drawing.Size(120, 42)
$ConsoleButton.Text = "Show Console"
$ConsoleButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$ConsoleButton.FlatStyle = 'Flat'
$ConsoleButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($ConsoleButton)
$script:ConsoleClicked = 0

$TBackButton = New-Object System.Windows.Forms.Button
$TBackButton.Location = New-Object System.Drawing.Point(640, $yBtn)
$TBackButton.Size = New-Object System.Drawing.Size(120, 42)
$TBackButton.Text = "Back"
$TBackButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$TBackButton.FlatStyle = 'Flat'
$TBackButton.FlatAppearance.BorderSize = 1
$ToolsGUI.Controls.Add($TBackButton)

# Double-click triggers launch across all tab ListViews
$allListViews = @($lvRepair, $lvDisk, $lvNet, $lvViewer, $lvPass)
foreach ($lv in $allListViews) {
    $lv.Add_DoubleClick({
        if ($TLaunchButton.Enabled) { $TLaunchButton.PerformClick() }
    })
}

# Central Tool Execution Router
$TLaunchButton.Add_Click({
    $currentTab = $ToolsTabControl.SelectedTab
    $currentLv = $null
    foreach ($ctrl in $currentTab.Controls) {
        if ($ctrl -is [System.Windows.Forms.ListView]) { $currentLv = $ctrl; break }
    }
    if (-not $currentLv -or $currentLv.SelectedItems.Count -eq 0) { return }

    $selected = $currentLv.SelectedItems[0].Text
    Log-Message "Invoking tool: $selected" "Info"
    $TLaunchButton.Enabled = $false

    try {
        switch ($selected) {
            # --- System Repair ---
            "DISM Repair" {
                Show-CommandRunnerDialog -Title "DISM Repair" -CommandName "dism.exe" -Arguments "/online /cleanup-image /restorehealth" -Description "Restoring system image component store health via DISM"
            }
            "SFC Repair" {
                Show-CommandRunnerDialog -Title "SFC Repair" -CommandName "sfc.exe" -Arguments "/scannow" -Description "Scanning and repairing corrupted system files via SFC"
            }
            "Check Disk (Read Only)" {
                Show-CommandRunnerDialog -Title "Check Disk (Read Only)" -CommandName "chkdsk.exe" -Arguments "C:" -Description "Running Check Disk in read-only mode on C:"
            }
            ".NET 3.5 (Includes v2 and v3)" {
                Show-CommandRunnerDialog -Title ".NET 3.5 Installation" -CommandName "powershell.exe" -Arguments "Enable-WindowsOptionalFeature -Online -FeatureName NetFx3 -All -NoRestart" -Description "Installing .NET Framework 3.5/2.0/3.0 feature" -IsPowerShellScript
            }
            "Windows Update Reset" {
                $confirm = PopupError "Are you sure you want to reset Windows Update components? This will stop update services, clear the cache, and restart services." "Question" "YesNo"
                if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Log-Message "Resetting Windows Update components..." "Info"
                    Stop-Service -Name wuauserv, bits, cryptsvc, msiserver -ErrorAction SilentlyContinue
                    $sdPath = "$env:WINDIR\SoftwareDistribution"
                    $crPath = "$env:WINDIR\System32\catroot2"
                    if (Test-Path $sdPath) { Rename-Item -Path $sdPath -NewName "SoftwareDistribution.old.$((Get-Date).ToString('yyyyMMddHHmmss'))" -ErrorAction SilentlyContinue }
                    if (Test-Path $crPath) { Rename-Item -Path $crPath -NewName "catroot2.old.$((Get-Date).ToString('yyyyMMddHHmmss'))" -ErrorAction SilentlyContinue }
                    Start-Service -Name wuauserv, bits, cryptsvc, msiserver -ErrorAction SilentlyContinue
                    Log-Message "Successfully reset Windows Update services and cleared caches." "Success"
                    PopupError "Windows Update components have been reset and services restarted." "Information"
                }
            }
            "Reset HOSTS File to Default" {
                $confirm = PopupError "Are you sure you want to reset your HOSTS file to clean default? A backup will be created." "Question" "YesNo"
                if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
                    $hostsPath = "$env:WINDIR\System32\drivers\etc\hosts"
                    if (Test-Path $hostsPath) {
                        Copy-Item -Path $hostsPath -Destination "$hostsPath.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))" -Force -ErrorAction SilentlyContinue
                    }
                    $defaultHosts = @"
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# 127.0.0.1       localhost
# ::1             localhost
"@
                    Set-Content -Path $hostsPath -Value $defaultHosts -Encoding UTF8 -Force
                    Log-Message "Reset HOSTS file to default (backup saved to hosts.bak)." "Success"
                    PopupError "HOSTS file has been reset to default.`nA backup of the previous file was created." "Information"
                }
            }
            "Reset Settings Page Visibility" {
                $regKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
                if (-not (Test-Path $regKeyPath)) { New-Item -Path $regKeyPath -Force | Out-Null }
                Set-ItemProperty -Path $regKeyPath -Name "SettingsPageVisibility" -Value "" -Type String -Force
                Log-Message "Cleared SettingsPageVisibility policy registry key." "Success"
                PopupError "Settings Page Visibility policy key has been set to a blank string." "Information"
            }

            # --- Disk & Space ---
            "WizTree" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $WizTreeZipPath = Join-Path -Path $ExtProgramDir -ChildPath "WizTree.zip"
                $wizTreeUrl = 'https://antibodysoftware-17031.kxcdn.com/files/wiztree_4_26_portable.zip'
                try {
                    $wtPage = Invoke-WebRequest -Uri "https://diskanalyzer.com/download" -UseBasicParsing -ErrorAction Stop
                    if ($wtPage.Content -match 'href="(files/wiztree_[^"]+_portable\.zip)"') {
                        $wizTreeUrl = "https://diskanalyzer.com/" + $matches[1]
                    }
                } catch { Write-Warning "Failed to fetch WizTree download URL." }
                Show-DownloadDialog -DisplayName 'WizTree' -Url $wizTreeUrl -OutputPath "$WizTreeZipPath"
                if (Test-Path -LiteralPath $WizTreeZipPath) {
                    Invoke-HMTExtract -Path $WizTreeZipPath -DestinationPath $ExtProgramDir
                    $WizTreeExePath = Get-ChildItem -Path $ExtProgramDir -Filter "WizTree64.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($WizTreeExePath) { Start-Process $WizTreeExePath }
                }
            }
            "BleachBit" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $BleachZipPath = Join-Path -Path $ExtProgramDir -ChildPath "BleachBit.zip"
                $version = "6.0.2"
                try {
                    $ghJson = Invoke-RestMethod -Uri "https://api.github.com/repos/bleachbit/bleachbit/releases/latest" -ErrorAction Stop
                    if ($ghJson.tag_name) { $version = $ghJson.tag_name -replace '^v', '' }
                } catch {}
                $bbUrl = "https://download.bleachbit.org/BleachBit-$version-portable.zip"
                Show-DownloadDialog -DisplayName 'BleachBit' -Url $bbUrl -OutputPath "$BleachZipPath"
                if (Test-Path -LiteralPath $BleachZipPath) {
                    Invoke-HMTExtract -Path $BleachZipPath -DestinationPath $ExtProgramDir
                    $BleachExePath = Get-ChildItem -Path $ExtProgramDir -Filter "bleachbit.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($BleachExePath) { Start-Process $BleachExePath }
                }
            }
            "Patch Cleaner" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $PatchCleanerPath = Join-Path -Path $ExtProgramDir -ChildPath "PatchCleanerPortable.zip"
                Show-DownloadDialog -DisplayName 'Patch Cleaner' -Url 'https://downloads.sourceforge.net/project/patchcleaner/PatchCleaner_Portable/v1.4.2.0/PatchCleanerPortable_1_4_2_0.zip' -OutputPath "$PatchCleanerPath"
                if (Test-Path -LiteralPath $PatchCleanerPath) {
                    Invoke-HMTExtract -Path $PatchCleanerPath -DestinationPath $ExtProgramDir
                    $PatchCleanerExePath = Get-ChildItem -Path $ExtProgramDir -Filter "PatchCleaner.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($PatchCleanerExePath) { Start-Process $PatchCleanerExePath }
                }
            }
            "Windows Disk Cleanup" {
                Start-Process -FilePath cleanmgr.exe -Verb RunAs
            }
            "Storage SMART & Benchmark Dashboard" {
                Show-StorageHealthDialog
            }
            "Storage SMART & Health Summary" {
                Show-StorageHealthDialog
            }
            "Display Driver Uninstaller" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $DDUPath = Join-Path -Path $ExtProgramDir -ChildPath "DDU.exe"
                $dduUrl = "https://download.wagnardsoft.com/DDU/DDU%20v18.1.5.6.exe"
                try {
                    $dduPage = Invoke-WebRequest -Uri "https://www.wagnardsoft.com/display-driver-uninstaller-ddu" -UserAgent "Mozilla/5.0" -UseBasicParsing -ErrorAction Stop
                    if ($dduPage.Content -match 'alt="Download Display Driver Uninstaller \(DDU\) ([0-9\.]+)"') {
                        $dduVer = $matches[1]
                        $dduUrl = "https://download.wagnardsoft.com/DDU/DDU%20v$dduVer.exe"
                    }
                } catch {}
                Show-DownloadDialog -DisplayName 'Display Driver Uninstaller' -Url $dduUrl -OutputPath "$DDUPath"
                if (Test-Path -LiteralPath $DDUPath) {
                    Start-Process $DDUPath -ArgumentList "-y -o`"$ExtProgramDir`"" -Wait
                    $DDUEPath = Get-ChildItem -Path $ExtProgramDir -Filter "Display Driver Uninstaller.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($DDUEPath) { Start-Process $DDUEPath }
                }
            }
            "HDDScan" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $HDDSPath = Join-Path -Path $ExtProgramDir -ChildPath "HDDS.zip"
                Show-DownloadDialog -DisplayName 'HDDScan' -Url 'https://hddscan.com/download/HDDScan.zip' -OutputPath "$HDDSPath"
                if (Test-Path -LiteralPath $HDDSPath) {
                    Invoke-HMTExtract -Path $HDDSPath -DestinationPath $ExtProgramDir
                    $HDDSEPath = Get-ChildItem -Path $ExtProgramDir -Filter "HDDScan.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($HDDSEPath) { Start-Process $HDDSEPath }
                }
            }
            "Crystal Disk Mark" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $CDMPath = Join-Path -Path $ExtProgramDir -ChildPath "CDM.zip"
                $cdmUrl = 'https://downloads.sourceforge.net/project/crystaldiskmark/9.0.3/CrystalDiskMark9_0_3.zip'
                Show-DownloadDialog -DisplayName 'Crystal Disk Mark' -Url $cdmUrl -OutputPath "$CDMPath"
                if (Test-Path -LiteralPath $CDMPath) {
                    Invoke-HMTExtract -Path $CDMPath -DestinationPath $ExtProgramDir
                    $CDMEPath = Get-ChildItem -Path $ExtProgramDir -Filter "DiskMark64.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($CDMEPath) { Start-Process $CDMEPath }
                }
            }
            "Crystal Disk Info" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $CDIPath = Join-Path -Path $ExtProgramDir -ChildPath "CDI.zip"
                $cdiUrl = 'https://downloads.sourceforge.net/project/crystaldiskinfo/9.4.0/CrystalDiskInfo9_4_0.zip'
                Show-DownloadDialog -DisplayName 'Crystal Disk Info' -Url $cdiUrl -OutputPath "$CDIPath"
                if (Test-Path -LiteralPath $CDIPath) {
                    Invoke-HMTExtract -Path $CDIPath -DestinationPath $ExtProgramDir
                    $CDIEPath = Get-ChildItem -Path $ExtProgramDir -Filter "DiskInfo64.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($CDIEPath) { Start-Process $CDIEPath }
                }
            }
            "BitLocker Drive Encryption & Recovery" {
                Show-BitLockerManagerDialog
            }

            # --- Network & Connectivity ---
            "Internet Speed Test" {
                Show-SpeedTestDialog
            }
            "Packet Loss & Latency Test" {
                Show-PacketLossTestDialog
            }
            "Packet Loss Test" {
                Show-PacketLossTestDialog
            }
            "TCP Port & Connection Checker" {
                Show-TcpCheckerDialog
            }
            "Flush DNS & Reset IP" {
                $confirm = PopupError "Are you sure you want to flush DNS and restart network adapters?" "Question" "YesNo"
                if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Clear-DnsClientCache
                    Restart-NetAdapter -Name "*"
                    PopupError "DNS cache flushed and network adapters restarted." "Information"
                }
            }
            "Advanced IP Scanner" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $AIPExePath = Join-Path -Path $ExtProgramDir -ChildPath "Advanced_IP_Scanner.exe"
                $aipUrl = "https://download.advanced-ip-scanner.com/download/files/Advanced_IP_Scanner_2.5.4594.1.exe"
                try {
                    $aipPage = Invoke-WebRequest -Uri "https://www.advanced-ip-scanner.com/download/" -UserAgent "Mozilla/5.0" -UseBasicParsing -ErrorAction Stop
                    if ($aipPage.Content -match '(https://download\.advanced-ip-scanner\.com/download/files/Advanced_IP_Scanner_[0-9\.]+\.exe)') {
                        $aipUrl = $matches[1]
                    }
                } catch {}
                Show-DownloadDialog -DisplayName 'Advanced IP Scanner' -Url $aipUrl -OutputPath "$AIPExePath"
                if (Test-Path -LiteralPath $AIPExePath) { Start-Process $AIPExePath }
            }
            "PuTTY" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $PuttyExePath = Join-Path -Path $ExtProgramDir -ChildPath "putty.exe"
                $puttyUrl = "https://the.earth.li/~sgtatham/putty/latest/w64/putty.exe"
                Show-DownloadDialog -DisplayName 'PuTTY' -Url $puttyUrl -OutputPath "$PuttyExePath"
                if (Test-Path -LiteralPath $PuttyExePath) { Start-Process $PuttyExePath }
            }
            "CurrPorts" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $CPZipPath = Join-Path -Path $ExtProgramDir -ChildPath "cports.zip"
                Show-DownloadDialog -DisplayName 'CurrPorts' -Url 'https://www.nirsoft.net/utils/cports-x64.zip' -OutputPath "$CPZipPath"
                if (Test-Path -LiteralPath $CPZipPath) {
                    Invoke-HMTExtract -Path $CPZipPath -DestinationPath $ExtProgramDir
                    $CPExe = Get-ChildItem -Path $ExtProgramDir -Filter "cports.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($CPExe) { Start-Process $CPExe }
                }
            }

            # --- System Viewers & Admin ---
            "BlueScreenView" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $BSVZipPath = Join-Path -Path $ExtProgramDir -ChildPath "BSV.zip"
                Show-DownloadDialog -DisplayName 'BlueScreenView' -Url 'https://www.nirsoft.net/utils/bluescreenview-x64.zip' -OutputPath "$BSVZipPath"
                if (Test-Path -LiteralPath $BSVZipPath) {
                    Invoke-HMTExtract -Path $BSVZipPath -DestinationPath $ExtProgramDir
                    $BSVExePath = Get-ChildItem -Path $ExtProgramDir -Filter "BlueScreenView.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($BSVExePath) { Start-Process $BSVExePath }
                }
            }
            "USBDeview" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $USBZip = Join-Path -Path $ExtProgramDir -ChildPath "usbdeview.zip"
                Show-DownloadDialog -DisplayName 'USBDeview' -Url 'https://www.nirsoft.net/utils/usbdeview-x64.zip' -OutputPath "$USBZip"
                if (Test-Path -LiteralPath $USBZip) {
                    Invoke-HMTExtract -Path $USBZip -DestinationPath $ExtProgramDir
                    $USBExe = Get-ChildItem -Path $ExtProgramDir -Filter "USBDeview.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($USBExe) { Start-Process $USBExe }
                }
            }
            "DriverView" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $DVZip = Join-Path -Path $ExtProgramDir -ChildPath "driverview.zip"
                Show-DownloadDialog -DisplayName 'DriverView' -Url 'https://www.nirsoft.net/utils/driverview-x64.zip' -OutputPath "$DVZip"
                if (Test-Path -LiteralPath $DVZip) {
                    Invoke-HMTExtract -Path $DVZip -DestinationPath $ExtProgramDir
                    $DVExe = Get-ChildItem -Path $ExtProgramDir -Filter "DriverView.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($DVExe) { Start-Process $DVExe }
                }
            }
            "UninstallView" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $UVZip = Join-Path -Path $ExtProgramDir -ChildPath "uninstallview.zip"
                Show-DownloadDialog -DisplayName 'UninstallView' -Url 'https://www.nirsoft.net/utils/uninstallview-x64.zip' -OutputPath "$UVZip"
                if (Test-Path -LiteralPath $UVZip) {
                    Invoke-HMTExtract -Path $UVZip -DestinationPath $ExtProgramDir
                    $UVExe = Get-ChildItem -Path $ExtProgramDir -Filter "UninstallView.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($UVExe) { Start-Process $UVExe }
                }
            }
            "DISM++" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $DISMPPPath = Join-Path -Path $ExtProgramDir -ChildPath "DISMPP.zip"
                $dismUrl = 'https://github.com/Chuyu-Team/Dism-Multi-language/releases/download/v10.1.1002.2/Dism++10.1.1002.1B.zip'
                try {
                    $ghJson = Invoke-RestMethod -Uri "https://api.github.com/repos/Chuyu-Team/Dism-Multi-language/releases/latest" -ErrorAction Stop
                    $ghAsset = $ghJson.assets | Where-Object { $_.name -match 'Dism.*\.zip' } | Select-Object -First 1
                    if ($ghAsset.browser_download_url) { $dismUrl = $ghAsset.browser_download_url }
                } catch {}
                Show-DownloadDialog -DisplayName 'DISM++' -Url $dismUrl -OutputPath "$DISMPPPath"
                if (Test-Path -LiteralPath $DISMPPPath) {
                    Invoke-HMTExtract -Path $DISMPPPath -DestinationPath $ExtProgramDir
                    $DISMPPEPath = Get-ChildItem -Path $ExtProgramDir -Filter "Dism++x64.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($DISMPPEPath) { Start-Process $DISMPPEPath }
                }
            }
            "Hat's User Move Tool" {
                $MoveToolPath = Join-Path -Path $PSScriptRoot -ChildPath "UserMoveTool.ps1"
                Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy RemoteSigned -WindowStyle Hidden -File `"$MoveToolPath`""
            }
            "User Profile Wizard" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $UPWPath = Join-Path -Path $ExtProgramDir -ChildPath "UserProfileWiz.msi"
                $profWizUrl = "https://www.forensit.com/Downloads/Profwiz.msi"
                try {
                    Show-DownloadDialog -DisplayName 'User Profile Wizard' -Url $profWizUrl -OutputPath "$UPWPath"
                } catch {
                    PopupError "ForensIT direct download is blocked by Cloudflare bot protection.`nOpening the ForensIT downloads page in your browser..." "Warning"
                    Start-Process "https://www.forensit.com/downloads.html"
                }
                if (Test-Path -LiteralPath $UPWPath) { Start-Process $UPWPath }
            }
            "Generate Battery Report" {
                $ReportPath = Join-Path $env:TEMP "battery-report.html"
                Start-Process powercfg.exe -ArgumentList "/batteryreport /output `"$ReportPath`"" -Wait -WindowStyle Hidden
                if (Test-Path $ReportPath) {
                    Start-Process $ReportPath
                } else {
                    PopupError "Battery report failed to generate." "Error"
                }
            }
            "Reliability Monitor" {
                Start-Process perfmon.exe -ArgumentList "/rel"
            }
            "Startup & Autoruns Manager" {
                Show-StartupManagerDialog
            }
            "Read Motherboard OEM Product Key" {
                $oemKey = (Get-CimInstance -ClassName SoftwareLicensingService -ErrorAction SilentlyContinue).OA3xOriginalProductKey
                if (-not [string]::IsNullOrWhiteSpace($oemKey)) {
                    [Windows.Forms.Clipboard]::SetText($oemKey)
                    PopupError "OEM Product Key found:`n`n$oemKey`n`n(Key copied to clipboard!)" "Information"
                } else {
                    PopupError "No OEM Product Key found embedded in the motherboard/BIOS MSDM table." "Warning"
                }
            }
            "Enable Safe Boot (w/Network)" {
                $confirm = PopupError "Are you sure you want to configure this system to boot into Safe Mode with networking?" "Question" "YesNo"
                if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
                    Start-Process "$env:WINDIR\System32\bcdedit.exe" -ArgumentList "/set {default} safeboot networking" -Verb RunAs
                    PopupError "BCD configured for Safe Boot with networking. Restart the PC when ready." "Information"
                }
            }
            "Restart Windows Explorer" {
                Stop-Process -Name explorer -Force
                Start-Process "$env:WINDIR\explorer.exe"
            }
            "McAfee MCPR Tool" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $MCPRPath = Join-Path -Path $ExtProgramDir -ChildPath "MCPR.exe"
                Show-DownloadDialog -DisplayName 'McAfee MCPR Tool' -Url 'https://download.mcafee.com/molbin/iss-loc/SupportTools/MCPR/MCPR.exe' -OutputPath "$MCPRPath"
                if (Test-Path -LiteralPath $MCPRPath) { Start-Process $MCPRPath }
            }
            "Ninja Removal Script" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $NRScriptPath = Join-Path -Path $ExtProgramDir -ChildPath "NinjaOneAgentRemoval.ps1"
                Show-DownloadDialog -DisplayName 'Ninja Removal Script' -Url 'https://hatsthings.com/MultitoolFiles/NinjaOneAgentRemoval.ps1' -OutputPath "$NRScriptPath"
                if (Test-Path -LiteralPath $NRScriptPath) {
                    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy RemoteSigned -File `"$NRScriptPath`""
                }
            }
            "Win11 Upgrade Assistant" {
                if (-Not (Test-Path $ExtProgramDir)) { New-Item -ItemType Directory -Path $ExtProgramDir | Out-Null }
                $W11APath = Join-Path -Path $ExtProgramDir -ChildPath "W11UA.exe"
                Show-DownloadDialog -DisplayName 'Win11 Upgrade Assistant' -Url "https://go.microsoft.com/fwlink/?linkid=2171764" -OutputPath "$W11APath"
                if (Test-Path -LiteralPath $W11APath) { Start-Process $W11APath }
            }

            # --- Password & Recovery (Advanced) ---
            "WebBrowserPassView" {
                $recDir = Join-Path $env:TEMP "HMT_PassRecovery"
                if (-not (Test-Path $recDir)) { New-Item -ItemType Directory -Path $recDir | Out-Null }
                $zip = Join-Path $recDir "webbrowserpassview.zip"
                Show-DownloadDialog -DisplayName 'WebBrowserPassView' -Url 'https://www.nirsoft.net/toolsdownload/webbrowserpassview.zip' -OutputPath "$zip"
                if (Test-Path -LiteralPath $zip) {
                    Invoke-HMTExtract -Path $zip -DestinationPath $recDir
                    $exe = Get-ChildItem -Path $recDir -Filter "WebBrowserPassView.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($exe) { Start-Process $exe }
                }
            }
            "WirelessKeyView" {
                $recDir = Join-Path $env:TEMP "HMT_PassRecovery"
                if (-not (Test-Path $recDir)) { New-Item -ItemType Directory -Path $recDir | Out-Null }
                $zip = Join-Path $recDir "wirelesskeyview.zip"
                Show-DownloadDialog -DisplayName 'WirelessKeyView' -Url 'https://www.nirsoft.net/toolsdownload/wirelesskeyview-x64.zip' -OutputPath "$zip"
                if (Test-Path -LiteralPath $zip) {
                    Invoke-HMTExtract -Path $zip -DestinationPath $recDir
                    $exe = Get-ChildItem -Path $recDir -Filter "WirelessKeyView.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($exe) { Start-Process $exe }
                }
            }
            "Dialupass" {
                $recDir = Join-Path $env:TEMP "HMT_PassRecovery"
                if (-not (Test-Path $recDir)) { New-Item -ItemType Directory -Path $recDir | Out-Null }
                $zip = Join-Path $recDir "dialupass.zip"
                Show-DownloadDialog -DisplayName 'Dialupass' -Url 'https://www.nirsoft.net/toolsdownload/dialupass.zip' -OutputPath "$zip"
                if (Test-Path -LiteralPath $zip) {
                    Invoke-HMTExtract -Path $zip -DestinationPath $recDir
                    $exe = Get-ChildItem -Path $recDir -Filter "dialupass.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($exe) { Start-Process $exe }
                }
            }
            "CredentialFileView" {
                $recDir = Join-Path $env:TEMP "HMT_PassRecovery"
                if (-not (Test-Path $recDir)) { New-Item -ItemType Directory -Path $recDir | Out-Null }
                $zip = Join-Path $recDir "credentialfileview.zip"
                Show-DownloadDialog -DisplayName 'CredentialFileView' -Url 'https://www.nirsoft.net/toolsdownload/credentialsfileview-x64.zip' -OutputPath "$zip"
                if (Test-Path -LiteralPath $zip) {
                    Invoke-HMTExtract -Path $zip -DestinationPath $recDir
                    $exe = Get-ChildItem -Path $recDir -Filter "CredentialFileView.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($exe) { Start-Process $exe }
                }
            }
            "VaultPasswordView" {
                $recDir = Join-Path $env:TEMP "HMT_PassRecovery"
                if (-not (Test-Path $recDir)) { New-Item -ItemType Directory -Path $recDir | Out-Null }
                $zip = Join-Path $recDir "vaultpasswordview.zip"
                Show-DownloadDialog -DisplayName 'VaultPasswordView' -Url 'https://www.nirsoft.net/toolsdownload/vaultpasswordview-x64.zip' -OutputPath "$zip"
                if (Test-Path -LiteralPath $zip) {
                    Invoke-HMTExtract -Path $zip -DestinationPath $recDir
                    $exe = Get-ChildItem -Path $recDir -Filter "VaultPasswordView.exe" -Recurse | Select-Object -ExpandProperty FullName -First 1
                    if ($exe) { Start-Process $exe }
                }
            }
            "BitLocker Recovery Keys & Unlock" {
                Show-BitLockerManagerDialog
            }
        }
    } finally {
        $TLaunchButton.Enabled = $true
    }
})

$ConsoleButton.Add_Click({
	if ($script:ConsoleClicked -eq 0) {
		Show-ConsoleWindow
		$ConsoleButton.Text = "Hide Console"
		$script:ConsoleClicked = 1
	} else {
		Hide-ConsoleWindow
		$ConsoleButton.Text = "Show Console"
		$script:ConsoleClicked = 0
	}
})

$TBackButton.Add_Click({
    $ToolsGUI.Hide()
})

$ToolsGUI.Add_Load({
    Invoke-HMTScale $ToolsGUI
    Set-RoundedControl $TLaunchButton
    Set-RoundedControl $ConsoleButton
    Set-RoundedControl $TBackButton
    Set-RoundedControl $btnDefender
    
    $scaledW = [int](780 * $global:HMTScaleFactor)
    $scaledH = [int](560 * $global:HMTScaleFactor)
    $ToolsGUI.ClientSize = [System.Drawing.Size]::new($scaledW, $scaledH)
    
    $ToolsTabControl.Width = $scaledW - [int](40 * $global:HMTScaleFactor)
    $ToolsTabControl.Height = $scaledH - [int](90 * $global:HMTScaleFactor)
    
    $btnY = $ToolsTabControl.Bottom + [int](15 * $global:HMTScaleFactor)
    $TLaunchButton.Top = $btnY
    $ConsoleButton.Top = $btnY
    $TBackButton.Top = $btnY
    
    $TBackButton.Left = $scaledW - $TBackButton.Width - [int](20 * $global:HMTScaleFactor)
    $ConsoleButton.Left = $TBackButton.Left - $ConsoleButton.Width - [int](10 * $global:HMTScaleFactor)
    
    # Auto-resize ListView columns
    foreach ($lv in $allListViews) {
        $minC0 = [int](210 * $global:HMTScaleFactor)
        $lv.Columns[0].Width = $minC0
        $lv.Columns[1].Width = [math]::Max([int](300 * $global:HMTScaleFactor), ($lv.ClientSize.Width - $minC0 - 20))
    }
})

$ToolsGUI.Add_FormClosing({
    param($_sender, $e)
    [void]$_sender
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing -and $Global:IntClose -ne $true) {
        User-Exit
    }
})
