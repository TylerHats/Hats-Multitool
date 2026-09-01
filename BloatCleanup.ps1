# Bloat Cleanup Module - Tyler Hatfield - v3.0

# Initialize Bloat Cleanup GUI Dialog
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$BloatGUI = New-Object System.Windows.Forms.Form
$titlePrefix = if ($global:HMTSetupTotalSteps -gt 1) { "Setup (Step $($global:HMTSetupCurrentStepIndex) of $($global:HMTSetupTotalSteps)): Bloat Cleanup" } else { "Bloat Cleanup & System Debloat" }
$BloatGUI.Text = "Hat's Multitool - $titlePrefix"
$BloatGUI.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$BloatGUI.ClientSize = New-Object System.Drawing.Size(480, 160)
$BloatGUI.StartPosition = 'CenterScreen'
if ($HMTIcon) { $BloatGUI.Icon = $HMTIcon }
$BloatGUI.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$BloatGUI.MaximizeBox = $false
$BloatGUI.MinimizeBox = $true
$BloatGUI.ShowInTaskbar = $true
$BloatGUI.Font = $font
$BloatGUI.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$BloatGUI.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $BloatGUI

$padding = 20
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Preparing Bloat Cleanup..."
$lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$lblStatus.Location = New-Object System.Drawing.Point($padding, 18)
$lblStatus.Size = New-Object System.Drawing.Size(440, 22)
$lblStatus.AutoSize = $false
$BloatGUI.Controls.Add($lblStatus)

$lblDetail = New-Object System.Windows.Forms.Label
$lblDetail.Text = "Scanning installed AppX packages..."
$lblDetail.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
$lblDetail.Location = New-Object System.Drawing.Point($padding, 42)
$lblDetail.Size = New-Object System.Drawing.Size(440, 20)
$lblDetail.AutoSize = $false
$BloatGUI.Controls.Add($lblDetail)

$pBar = New-Object HMT.Tools.SmoothProgressBar
$pBar.Location = New-Object System.Drawing.Point($padding, 70)
$pBar.Size = New-Object System.Drawing.Size(440, 20)
$pBar.BorderRadius = 5
$pBar.ProgressColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
$pBar.ProgressColorEnd = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
$pBar.ShowShimmer = $true
$BloatGUI.Controls.Add($pBar)

$BloatGUI.Add_Load({
    Invoke-HMTScale $BloatGUI
    $p = [int]($padding * $global:HMTScaleFactor)
    $lblStatus.Location = New-Object System.Drawing.Point($p, [int](18 * $global:HMTScaleFactor))
    $lblStatus.Size = New-Object System.Drawing.Size(($BloatGUI.ClientSize.Width - ($p * 2)), [int](22 * $global:HMTScaleFactor))
    $lblDetail.Location = New-Object System.Drawing.Point($p, [int](42 * $global:HMTScaleFactor))
    $lblDetail.Size = New-Object System.Drawing.Size(($BloatGUI.ClientSize.Width - ($p * 2)), [int](20 * $global:HMTScaleFactor))
    $pBar.Location = New-Object System.Drawing.Point($p, [int](70 * $global:HMTScaleFactor))
    $pBar.Size = New-Object System.Drawing.Size(($BloatGUI.ClientSize.Width - ($p * 2)), [int](20 * $global:HMTScaleFactor))
    $BloatGUI.ClientSize = New-Object System.Drawing.Size($BloatGUI.ClientSize.Width, ($pBar.Bottom + $p))
})

# Show form non-blocking and execute debloat
$BloatGUI.Show()
[System.Windows.Forms.Application]::DoEvents()

<#
List of common Windows 11 OEM and Consumer bloatware.
Wildcards (*) are used to catch varying version names.
#>
$bloatApps = @(
    "*TikTok*",
    "*Instagram*",
    "*Facebook*",
    "*Spotify*",
    "*Disney*",
    "*Netflix*",
    "*PrimeVideo*",
    "*WhatsApp*",
    "*LinkedIn*",
    "*LinkedInForWindows*",
    "*Clipchamp*",
    "*McAfee*",
    "*Norton*",
    "*BingNews*",
    "*BingWeather*",
    "*WindowsMaps*",
    "*ZuneVideo*",
    "*ZuneMusic*",
    "*Cortana*",
    "*MicrosoftSolitaireCollection*",
    "*GetHelp*",
    "*Getstarted*",
    "*YourPhone*",
    "*windowscommunicationsapps*"
)

$totalBloat = $bloatApps.Count
$removedCount = 0
$idx = 0

foreach ($app in $bloatApps) {
    $idx++
    $cleanName = $app.Trim('*')
    $lblStatus.Text = "Removing Bloatware: $cleanName ($idx of $totalBloat)"
    $lblDetail.Text = "Checking AppX user and provisioned package registrations..."
    $pBar.Value = [int](($idx / ($totalBloat + 3)) * 100)
    [System.Windows.Forms.Application]::DoEvents()

    Log-Message "Attempting to remove $app..." "Info"

    try {
        # 1. Remove from all existing user profiles
        $installed = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
        if ($installed) {
            $installed | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        }

        # 2. Remove the provisioned package so it doesn't install for new users
        $provisioned = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like $app -or $_.PackageName -like $app }
        if ($provisioned) {
            foreach ($prov in $provisioned) {
                Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction SilentlyContinue | Out-Null
            }
        }

        $removedCount++
    }
    catch {
        Log-Message "Failed to completely remove $app. Error: $_" "Error"
    }

    [System.Windows.Forms.Application]::DoEvents()
}

Log-Message "Appx Debloat complete. Processed $removedCount package targets." "Success"

# Phase 2: Telemetry & Services
$lblStatus.Text = "Optimizing System: Disabling Telemetry & Diagnostic Services..."
$lblDetail.Text = "Configuring DiagTrack and dmwappushservice policies..."
$pBar.Value = 85
[System.Windows.Forms.Application]::DoEvents()

Log-Message "Disabling Telemetry and Tracking services..." "Info"
Stop-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name "dmwappushservice" -ErrorAction SilentlyContinue
Set-Service -Name "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue

# Disable Telemetry System-wide in Registry Policy
$telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (-not (Test-Path $telemetryPath)) { New-Item -Path $telemetryPath -Force | Out-Null }
Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# Disable Windows Consumer Features & Suggested Apps System-wide
$cloudPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
if (-not (Test-Path $cloudPath)) { New-Item -Path $cloudPath -Force | Out-Null }
Set-ItemProperty -Path $cloudPath -Name "DisableWindowsConsumerFeatures" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $cloudPath -Name "DisableCloudOptimizedContent" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

# Phase 3: Bing Search & Ads Policies
$lblStatus.Text = "Optimizing System: Disabling Bing Search & Web Ads..."
$lblDetail.Text = "Applying explorer and search policies..."
$pBar.Value = 95
[System.Windows.Forms.Application]::DoEvents()

Log-Message "Applying registry tweaks for Bing Search, Consumer Pins, and Advertising..." "Info"

# 1. HKLM System-wide Policies
$hklmExplorerPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
if (-not (Test-Path $hklmExplorerPath)) { New-Item -Path $hklmExplorerPath -Force | Out-Null }
Set-ItemProperty -Path $hklmExplorerPath -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue

$hklmSearchPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
if (-not (Test-Path $hklmSearchPath)) { New-Item -Path $hklmSearchPath -Force | Out-Null }
Set-ItemProperty -Path $hklmSearchPath -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $hklmSearchPath -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $hklmSearchPath -Name "AllowCortana" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# 2. HKCU Current User Settings
if (-not (Test-Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer")) { New-Item -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force | Out-Null }
Set-ItemProperty -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0 -Force -ErrorAction SilentlyContinue

$cdmPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $cdmPath)) { New-Item -Path $cdmPath -Force | Out-Null }
Set-ItemProperty -Path $cdmPath -Name "ContentDeliveryAllowed" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $cdmPath -Name "OemPreInstalledAppsEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $cdmPath -Name "PreInstalledAppsEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $cdmPath -Name "SilentInstalledAppsEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-338388Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path $cdmPath -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

# 3. Default User Profile Hive (New Users)
$defNtUser = 'C:\Users\Default\NTUSER.DAT'
if (Test-Path $defNtUser) {
    & reg.exe load "HKU\DefUser" "$defNtUser" | Out-Null
    try {
        & reg.exe add "HKU\DefUser\Software\Policies\Microsoft\Windows\Explorer" /v "DisableSearchBoxSuggestions" /t REG_DWORD /d 1 /f | Out-Null
        & reg.exe add "HKU\DefUser\Software\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\DefUser\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\DefUser\Software\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f | Out-Null
        
        & reg.exe add "HKU\DefUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\DefUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\DefUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\DefUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\DefUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f | Out-Null
        & reg.exe add "HKU\DefUser\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f | Out-Null
        Log-Message "Applied Search, Telemetry, and Consumer Feature policies to Default User profile template." "Success"
    } finally {
        & reg.exe unload "HKU\DefUser" | Out-Null
    }
}

$lblStatus.Text = "Bloat Cleanup Complete"
$lblDetail.Text = "Finished removing bloatware and optimizing policies."
$pBar.Value = 100
[System.Windows.Forms.Application]::DoEvents()
Start-Sleep -Milliseconds 400

$BloatGUI.Close()
$BloatGUI.Dispose()