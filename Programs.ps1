# Programs Module - Tyler Hatfield - v2.30

# Force TLS 1.2 for reliable WebClient downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor 12288

# Force initialize WinGet source
$global:BGRBaseText = "Updating WinGet Sources"
if ($null -ne $global:BGRlabel -and -not $global:BGRlabel.IsDisposed) { $global:BGRlabel.Text = $global:BGRBaseText }
[System.Windows.Forms.Application]::DoEvents()
Log-Message "Initializing WinGet and updating sources..."

$procReset = Start-Process winget.exe -ArgumentList "source reset --force" -WindowStyle Hidden -PassThru
while (-not $procReset.HasExited) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50 }

$procUpdate = Start-Process winget.exe -ArgumentList "source update" -WindowStyle Hidden -PassThru
while (-not $procUpdate.HasExited) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50 }

$global:BGRBaseText = "Hat's Multitool is running"
if ($null -ne $global:BGRlabel -and -not $global:BGRlabel.IsDisposed) { $global:BGRlabel.Text = $global:BGRBaseText }

# Initialize GUI form
Log-Message "Preparing Software Catalog..."
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Net.Http

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Software & Program Installation Suite'
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$form.StartPosition = 'CenterScreen'
$HMTIconPath = Join-Path -Path $PSScriptRoot -ChildPath "HMTIconSmall.ico"
if (Test-Path $HMTIconPath) {
    $HMTIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($HMTIconPath)
    $form.Icon = $HMTIcon
}
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.ShowInTaskbar = $true
$scaledProgFont = [int](13 * $global:HMTScaleFactor)
$progFont = New-Object System.Drawing.Font("Segoe UI", $scaledProgFont, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$form.Font = $progFont
$form.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
Set-DarkTitleBar -TargetForm $form

$padding = 20

# Categorized Software Catalog
$catalog = @{
    "Browsers & Comms" = @(
        @{ Name = 'Google Chrome'; WingetID = 'Google.Chrome'; Type = 'Winget' },
        @{ Name = 'Mozilla Firefox'; WingetID = 'Mozilla.Firefox'; Type = 'Winget' },
        @{ Name = 'Brave Browser'; WingetID = 'Brave.Brave'; Type = 'Winget' },
        @{ Name = 'Discord'; WingetID = 'Discord.Discord'; Type = 'Winget' },
        @{ Name = 'Microsoft Teams'; WingetID = 'Microsoft.Teams'; Type = 'Winget' },
        @{ Name = 'Zoom'; WingetID = 'Zoom.Zoom'; Type = 'Winget' },
        @{ Name = 'Slack'; WingetID = 'Slack.Slack'; Type = 'Winget' },
        @{ Name = 'Telegram Desktop'; WingetID = 'Telegram.TelegramDesktop'; Type = 'Winget' },
        @{ Name = 'WhatsApp'; WingetID = 'WhatsApp.WhatsApp'; Type = 'Winget' },
        @{ Name = 'Mozilla Thunderbird'; WingetID = 'Mozilla.Thunderbird'; Type = 'Winget' }
    )
    "Productivity" = @(
        @{ Name = '7-Zip'; WingetID = '7zip.7zip'; Type = 'Winget' },
        @{ Name = 'WinRAR'; WingetID = 'RARLab.WinRAR'; Type = 'Winget' },
        @{ Name = 'Notepad++'; WingetID = 'Notepad++.Notepad++'; Type = 'Winget' },
        @{ Name = 'Adobe Acrobat Reader'; WingetID = 'Adobe.Acrobat.Reader.64-bit'; Type = 'Winget' },
        @{ Name = 'Adobe Creative Cloud'; WingetID = 'Adobe.CreativeCloud'; Type = 'Winget' },
        @{ Name = 'Microsoft Office (64-Bit)'; WingetID = ''; Type = 'MSOffice' },
        @{ Name = 'Outlook Classic'; WingetID = ''; Type = 'MSOutlook' },
        @{ Name = 'LibreOffice'; WingetID = 'TheDocumentFoundation.LibreOffice'; Type = 'Winget' },
        @{ Name = 'Microsoft PowerToys'; WingetID = 'Microsoft.PowerToys'; Type = 'Winget' },
        @{ Name = 'Everything Search'; WingetID = 'voidtools.Everything'; Type = 'Winget' },
        @{ Name = 'ShareX'; WingetID = 'ShareX.ShareX'; Type = 'Winget' },
        @{ Name = 'Greenshot'; WingetID = 'Greenshot.Greenshot'; Type = 'Winget' }
    )
    "IT & Dev Tools" = @(
        @{ Name = 'Visual Studio Code'; WingetID = 'Microsoft.VisualStudioCode'; Type = 'Winget' },
        @{ Name = 'Git for Windows'; WingetID = 'Git.Git'; Type = 'Winget' },
        @{ Name = 'Python 3.12'; WingetID = 'Python.Python.3.12'; Type = 'Winget' },
        @{ Name = 'Node.js LTS'; WingetID = 'OpenJS.NodeJS.LTS'; Type = 'Winget' },
        @{ Name = 'Windows Terminal'; WingetID = 'Microsoft.WindowsTerminal'; Type = 'Winget' },
        @{ Name = 'PuTTY'; WingetID = 'PuTTY.PuTTY'; Type = 'Winget' },
        @{ Name = 'WinSCP'; WingetID = 'WinSCP.WinSCP'; Type = 'Winget' },
        @{ Name = 'Wireshark'; WingetID = 'WiresharkFoundation.Wireshark'; Type = 'Winget' },
        @{ Name = 'Twingate Client'; WingetID = 'Twingate.Client'; Type = 'Winget' },
        @{ Name = 'Tailscale'; WingetID = 'Tailscale.Tailscale'; Type = 'Winget' },
        @{ Name = 'RustDesk'; WingetID = 'RustDesk.RustDesk'; Type = 'Winget' },
        @{ Name = 'AnyDesk'; WingetID = 'AnyDeskSoftwareGmbH.AnyDesk'; Type = 'Winget' },
        @{ Name = 'TeamViewer'; WingetID = 'TeamViewer.TeamViewer'; Type = 'Winget' }
    )
    "Media & Design" = @(
        @{ Name = 'VLC Media Player'; WingetID = 'VideoLAN.VLC'; Type = 'Winget' },
        @{ Name = 'Spotify'; WingetID = 'Spotify.Spotify'; Type = 'Winget' },
        @{ Name = 'OBS Studio'; WingetID = 'OBSProject.OBSStudio'; Type = 'Winget' },
        @{ Name = 'Audacity'; WingetID = 'Audacity.Audacity'; Type = 'Winget' },
        @{ Name = 'HandBrake'; WingetID = 'HandBrake.HandBrake'; Type = 'Winget' },
        @{ Name = 'GIMP'; WingetID = 'GIMP.GIMP'; Type = 'Winget' },
        @{ Name = 'Inkscape'; WingetID = 'Inkscape.Inkscape'; Type = 'Winget' },
        @{ Name = 'Blender'; WingetID = 'BlenderFoundation.Blender'; Type = 'Winget' },
        @{ Name = 'K-Lite Codec Pack Mega'; WingetID = 'CodecGuide.K-LiteCodecPack.Mega'; Type = 'Winget' }
    )
    "Cloud & Gaming" = @(
        @{ Name = 'Google Drive'; WingetID = 'Google.Drive'; Type = 'Winget' },
        @{ Name = 'Dropbox'; WingetID = 'Dropbox.Dropbox'; Type = 'Winget' },
        @{ Name = 'Steam'; WingetID = 'Valve.Steam'; Type = 'Winget' },
        @{ Name = 'Epic Games Launcher'; WingetID = 'EpicGames.EpicGamesLauncher'; Type = 'Winget' },
        @{ Name = 'GOG Galaxy'; WingetID = 'GOG.Galaxy'; Type = 'Winget' },
        @{ Name = 'CPUID HWMonitor'; WingetID = 'CPUID.HWMonitor'; Type = 'Winget' },
        @{ Name = 'CPUID CPU-Z'; WingetID = 'CPUID.CPU-Z'; Type = 'Winget' },
        @{ Name = 'TechPowerUp GPU-Z'; WingetID = 'TechPowerUp.GPU-Z'; Type = 'Winget' },
        @{ Name = 'MSI Afterburner'; WingetID = 'Guru3D.Afterburner'; Type = 'Winget' }
    )
}

# Flatten master programs list
$programs = @()
foreach ($cat in $catalog.Keys) {
    $programs += $catalog[$cat]
}

$form.ClientSize = New-Object System.Drawing.Size(580, 560)

# Tab Control for Categories
$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location = New-Object System.Drawing.Point(15, 12)
$tabControl.Size = New-Object System.Drawing.Size(550, 240)
$tabControl.Font = $progFont
$tabControl.DrawMode = [System.Windows.Forms.TabDrawMode]::OwnerDrawFixed
$tabControl.SizeMode = [System.Windows.Forms.TabSizeMode]::Fixed
$tabControl.ItemSize = New-Object System.Drawing.Size(108, 28)
$tabControl.Padding = New-Object System.Drawing.Point(8, 4)

$tabControl.Add_DrawItem({
    param($sender, $e)
    $tc = $sender
    $tab = $tc.TabPages[$e.Index]
    $isSelected = ($e.Index -eq $tc.SelectedIndex)
    $g = $e.Graphics

    $bgBrush = if ($isSelected) {
        New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#36393f"))
    } else {
        New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#202225"))
    }
    $g.FillRectangle($bgBrush, $e.Bounds)
    $bgBrush.Dispose()

    if ($isSelected) {
        $accentPen = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#5865F2"), 3)
        $g.DrawLine($accentPen, $e.Bounds.Left, $e.Bounds.Top + 1, $e.Bounds.Right, $e.Bounds.Top + 1)
        $accentPen.Dispose()
    }

    $textBrush = if ($isSelected) {
        New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#ffffff"))
    } else {
        New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#a0a0a0"))
    }
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
    $tabFont = if ($isSelected) {
        New-Object System.Drawing.Font($tc.Font, [System.Drawing.FontStyle]::Bold)
    } else {
        $tc.Font
    }
    $g.DrawString($tab.Text, $tabFont, $textBrush, [System.Drawing.RectangleF]$e.Bounds, $sf)
    $textBrush.Dispose()
    $sf.Dispose()
    if ($isSelected) { $tabFont.Dispose() }
})

$form.Controls.Add($tabControl)

$checkboxes = @{}
$tabOrder = @("Browsers & Comms", "Productivity", "IT & Dev Tools", "Media & Design", "Cloud & Gaming")

foreach ($tabName in $tabOrder) {
    if (-not $catalog.ContainsKey($tabName)) { continue }
    $tabItems = $catalog[$tabName]

    $tab = New-Object System.Windows.Forms.TabPage($tabName)
    $tab.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $tabControl.TabPages.Add($tab)

    $container = New-Object System.Windows.Forms.Panel
    $container.Dock = [System.Windows.Forms.DockStyle]::Fill
    $container.BackColor = [System.Drawing.Color]::Transparent
    $container.Padding = New-Object System.Windows.Forms.Padding(10)
    $tab.Controls.Add($container)

    $col1 = New-Object System.Windows.Forms.FlowLayoutPanel
    $col1.Location = New-Object System.Drawing.Point(10, 10)
    $col1.Size = New-Object System.Drawing.Size(255, 195)
    $col1.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $col1.WrapContents = $false
    $col1.BackColor = [System.Drawing.Color]::Transparent
    $container.Controls.Add($col1)

    $col2 = New-Object System.Windows.Forms.FlowLayoutPanel
    $col2.Location = New-Object System.Drawing.Point(275, 10)
    $col2.Size = New-Object System.Drawing.Size(255, 195)
    $col2.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
    $col2.WrapContents = $false
    $col2.BackColor = [System.Drawing.Color]::Transparent
    $container.Controls.Add($col2)

    $half = [math]::Ceiling($tabItems.Count / 2)
    for ($i = 0; $i -lt $tabItems.Count; $i++) {
        $prog = $tabItems[$i]
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $prog.Name
        $cb.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $cb.AutoSize = $true
        $cb.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 4)
        if ($i -lt $half) {
            $col1.Controls.Add($cb)
        } else {
            $col2.Controls.Add($cb)
        }
        $checkboxes[$prog.Name] = $cb
    }
}

# User-Exit Checkbox
$userExitCheckbox = New-Object System.Windows.Forms.CheckBox
$userExitCheckbox.Text = "Automatically exit multitool when complete"
$userExitCheckbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$userExitCheckbox.AutoSize = $true
$userExitCheckbox.Location = New-Object System.Drawing.Point(20, ($tabControl.Bottom + 10))
$form.Controls.Add($userExitCheckbox)

# Mutual exclusivity for Office 64-Bit vs Outlook Classic
if ($checkboxes.ContainsKey("Outlook Classic") -and $checkboxes.ContainsKey("Microsoft Office (64-Bit)")) {
    $outlookCheckbox = $checkboxes["Outlook Classic"]
    $officeCheckbox = $checkboxes["Microsoft Office (64-Bit)"]

    $outlookCheckbox.Add_CheckedChanged({
        if ($outlookCheckbox.Checked) {
            $officeCheckbox.Enabled = $false
            $officeCheckbox.Checked = $false
        } else {
            $officeCheckbox.Enabled = $true
        }
    })

    $officeCheckbox.Add_CheckedChanged({
        if ($officeCheckbox.Checked) {
            $outlookCheckbox.Enabled = $false
            $outlookCheckbox.Checked = $false
        } else {
            $outlookCheckbox.Enabled = $true
        }
    })
}

$y = $userExitCheckbox.Bottom + 15
$statuslabel = New-Object System.Windows.Forms.Label
$statuslabel.Text = "Status: Idle"
$statuslabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$statuslabel.Size = New-Object System.Drawing.Size(540, 20)
$statuslabel.Location = New-Object System.Drawing.Point(20, $y)
$statuslabel.AutoSize = $true
$form.Controls.Add($statuslabel)

$detailLabel = New-Object System.Windows.Forms.Label
$detailLabel.Text = ""
$detailLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
$detailLabel.Size = New-Object System.Drawing.Size(540, 20)
$detailLabel.Location = New-Object System.Drawing.Point(20, ($y + 20))
$detailLabel.AutoSize = $true
$form.Controls.Add($detailLabel)

$y += 44
$trackPanel = New-Object System.Windows.Forms.Panel
$trackPanel.Size = New-Object System.Drawing.Size(540, 22)
$trackPanel.Location = New-Object System.Drawing.Point(20, $y)
$trackPanel.BorderStyle = 'FixedSingle'
$trackPanel.BackColor = [System.Drawing.Color]::DarkGray
$form.Controls.Add($trackPanel)

$fillPanel = New-Object System.Windows.Forms.Panel
$fillPanel.Size = New-Object System.Drawing.Size(0, 19)
$fillPanel.Location = New-Object System.Drawing.Point(1, 1)
$fillPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
$trackPanel.Controls.Add($fillPanel)

# Secondary Progress UI Controls for Microsoft Office Payload
$msStatusLabel = New-Object System.Windows.Forms.Label
$msStatusLabel.Text = "Microsoft Office: Starting..."
$msStatusLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$msStatusLabel.Size = New-Object System.Drawing.Size(540, 20)
$msStatusLabel.AutoSize = $true
$msStatusLabel.Visible = $false
$form.Controls.Add($msStatusLabel)

$msDetailLabel = New-Object System.Windows.Forms.Label
$msDetailLabel.Text = ""
$msDetailLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
$msDetailLabel.Size = New-Object System.Drawing.Size(540, 20)
$msDetailLabel.AutoSize = $true
$msDetailLabel.Visible = $false
$form.Controls.Add($msDetailLabel)

$msTrackPanel = New-Object System.Windows.Forms.Panel
$msTrackPanel.Size = New-Object System.Drawing.Size(540, 22)
$msTrackPanel.BorderStyle = 'FixedSingle'
$msTrackPanel.BackColor = [System.Drawing.Color]::DarkGray
$msTrackPanel.Visible = $false
$form.Controls.Add($msTrackPanel)

$msFillPanel = New-Object System.Windows.Forms.Panel
$msFillPanel.Size = New-Object System.Drawing.Size(0, 19)
$msFillPanel.Location = New-Object System.Drawing.Point(1, 1)
$msFillPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
$msTrackPanel.Controls.Add($msFillPanel)

$y += 35
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(170, $y)
$okButton.Size = New-Object System.Drawing.Size(110, 38)
$okButton.Text = "Install Selected"
$okButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
$okButton.FlatStyle = 'Flat'
$okButton.FlatAppearance.BorderSize = 1
$form.Controls.Add($okButton)
$form.AcceptButton = $okButton

$skipButton = New-Object System.Windows.Forms.Button
$skipButton.Location = New-Object System.Drawing.Point(295, $y)
$skipButton.Size = New-Object System.Drawing.Size(110, 38)
$skipButton.Text = "Skip Current"
$skipButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$skipButton.FlatStyle = 'Flat'
$skipButton.FlatAppearance.BorderSize = 1
$skipButton.Enabled = $false
$form.Controls.Add($skipButton)

$script:SkipCurrent = $false
$skipButton.Add_Click({
    $script:SkipCurrent = $true
})

# Dynamic Sizing Trigger
$form.Add_Load({
    Invoke-HMTScale $form
    Set-RoundedControl $okButton
    Set-RoundedControl $skipButton
    $p = [int]($padding * $global:HMTScaleFactor)
    
    $tabControl.Width = $form.ClientSize.Width - ($p * 2)
    $userExitCheckbox.Top = $tabControl.Bottom + [int](8 * $global:HMTScaleFactor)
    $yPos = $userExitCheckbox.Bottom + [int](12 * $global:HMTScaleFactor)
    $statuslabel.Top = $yPos
    $detailLabel.Top = $yPos + [int](20 * $global:HMTScaleFactor)
    
    $yPos += [int](44 * $global:HMTScaleFactor)
    $trackPanel.Top = $yPos
    $trackPanel.Width = $form.ClientSize.Width - ($p * 2)
    
    $yPos += [int](35 * $global:HMTScaleFactor)
    $okButton.Top = $yPos
    $skipButton.Top = $yPos
})

# Progress bar and status updater
$updateMSProgress = {
    if ($null -ne $script:msState) {
        $msStatusLabel.Text = $script:msState.StatusText
        $msDetailLabel.Text = $script:msState.DetailText
        $pct = [math]::Max(0, [math]::Min(100, $script:msState.ProgressPct))
        $maxW = $msTrackPanel.ClientSize.Width - 2
        $msFillPanel.Width = [int](($pct / 100) * $maxW)
    }
}

$updateLocalProgress = {
    param($progIndex, $totPrograms, $segProgressPct, $statusText, $DetailText)

    $pct = [math]::Max(0, [math]::Min(100, $segProgressPct))
    $maxW = $trackPanel.ClientSize.Width - 2
    $fillPanel.Width = [int](($pct / 100) * $maxW)

    if ($null -ne $statusText) {
        $statuslabel.Text = $statusText
        $global:BGRBaseText = $statusText
        if ($null -ne $global:BGRlabel -and -not $global:BGRlabel.IsDisposed) {
            $global:BGRlabel.Text = $statusText
        }
    }

    if ($null -ne $DetailText) {
        $detailLabel.Text = $DetailText
    }

    &$updateMSProgress
}

# Async-Safe Streamed Download Helper
$downloadWithProgress = {
    param(
        [string]$Url, 
        [string]$OutFile, 
        [int]$ProgIndex, 
        [int]$TotPrograms, 
        [string]$AppName,
        [hashtable]$Headers = $null
    )
    
    $global:DlDone = $false
    $script:SkipCurrent = $false

    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor 12288

    $handler = New-Object System.Net.Http.HttpClientHandler
    $client = New-Object System.Net.Http.HttpClient -ArgumentList $handler
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

    if ($null -ne $Headers) {
        foreach ($key in $Headers.Keys) {
            $client.DefaultRequestHeaders.Add($key, $Headers[$key])
        }
    }

    $downloadStream = $null
    $fileStream = $null

    try {
        $responseTask = $client.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead)
        $response = $responseTask.GetAwaiter().GetResult()
        
        if (-not $response.IsSuccessStatusCode) {
            throw "HTTP Error: $($response.StatusCode)"
        }

        $totalBytes = $response.Content.Headers.ContentLength
        $downloadStream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $fileStream = [System.IO.File]::Create($OutFile)

        $buffer = New-Object byte[] 65536
        $bytesRead = 0
        $totalBytesRead = 0
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $lastUiTick = [System.Diagnostics.Stopwatch]::StartNew()

        while (($bytesRead = $downloadStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            if ($script:SkipCurrent) {
                break
            }

            $fileStream.Write($buffer, 0, $bytesRead)
            $totalBytesRead += $bytesRead

            [System.Windows.Forms.Application]::DoEvents()

            if ($lastUiTick.ElapsedMilliseconds -ge 100) {
                $lastUiTick.Restart()
                $elapsedSec = [math]::Max(0.001, $stopwatch.Elapsed.TotalSeconds)
                $speedMbps = (($totalBytesRead * 8) / 1MB) / $elapsedSec
                $dlMB = [math]::Round($totalBytesRead / 1MB, 1)

                if ($totalBytes -and $totalBytes -gt 0) {
                    $totMB = [math]::Round($totalBytes / 1MB, 1)
                    $pct = [math]::Floor(($totalBytesRead / $totalBytes) * 100)
                    &$updateLocalProgress $ProgIndex $TotPrograms ($pct * 0.8) "Installing $($ProgIndex + 1) of $($TotPrograms): $AppName" "Downloading... $pct% ($dlMB MB / $totMB MB @ $([math]::Round($speedMbps, 1)) Mbps)"
                } else {
                    &$updateLocalProgress $ProgIndex $TotPrograms 40 "Installing $($ProgIndex + 1) of $($TotPrograms): $AppName" "Downloading... $dlMB MB @ $([math]::Round($speedMbps, 1)) Mbps"
                }
            }
        }
        $global:DlDone = $true
    }
    catch {
        Log-Message "Download error on $AppName : $_" "Error"
        throw $_
    }
    finally {
        if ($null -ne $fileStream) { $fileStream.Close(); $fileStream.Dispose() }
        if ($null -ne $downloadStream) { $downloadStream.Close(); $downloadStream.Dispose() }
        if ($null -ne $client) { $client.Dispose() }
    }
}

$okButton.Add_Click({
    $okButton.Enabled = $false
    foreach ($cb in $checkboxes.Values) {
        $cb.Enabled = $false
    }
    $userExitCheckbox.Enabled = $true

    $checkedNames = @($checkboxes.GetEnumerator() | Where-Object { $_.Value.Checked } | ForEach-Object { $_.Key })
    $msProgName = $checkedNames | Where-Object { $_ -eq "Microsoft Office (64-Bit)" -or $_ -eq "Outlook Classic" } | Select-Object -First 1

    $selectedPrograms = $checkedNames | Sort-Object { 
        $name = $_
        $prog = $programs | Where-Object { $_.Name -eq $name }
        if ($prog.Type -eq "MSOffice" -or $prog.Type -eq "MSOutlook") { 0 } else { 1 }
    }
    $totalPrograms = $selectedPrograms.Count
    if ($totalPrograms -eq 0) {
        Log-Message "No programs selected for installation." "Skip"
        $form.Close()
        return
    }

    # Start parallel O365 background runspace if selected
    $msRunspace = $null
    $msPowerShell = $null

    if ($msProgName) {
        $isAll = $msProgName -eq "Microsoft Office (64-Bit)"
        $displayName = if ($isAll) { "Microsoft Office (x64)" } else { "Outlook (Classic)" }
        $productID = if ($isAll) { "O365BusinessRetail" } else { "OutlookRetail" }

        $msStatusLabel.Visible = $true
        $msDetailLabel.Visible = $true
        $msTrackPanel.Visible = $true

        $yMS = $trackPanel.Bottom + [int](15 * $global:HMTScaleFactor)
        $msStatusLabel.Location = New-Object System.Drawing.Point(20, $yMS)
        $msDetailLabel.Location = New-Object System.Drawing.Point(20, ($yMS + 18))
        $msTrackPanel.Location = New-Object System.Drawing.Point(20, ($yMS + 38))

        $yBtn = $msTrackPanel.Bottom + [int](20 * $global:HMTScaleFactor)
        $okButton.Top = $yBtn
        $skipButton.Top = $yBtn

        $p = [int]($padding * $global:HMTScaleFactor)
        $form.ClientSize = [System.Drawing.Size]::new($form.ClientSize.Width, ($okButton.Bottom + $p))

        $script:msState = [hashtable]::Synchronized(@{
            ProgressPct = 0
            StatusText  = "Starting $displayName download..."
            DetailText  = "Connecting to CDN..."
            Finished    = $false
            Error       = $null
        })

        $msRunspace = [runspacefactory]::CreateRunspace()
        $msRunspace.Open()
        $msPowerShell = [powershell]::Create()
        $msPowerShell.Runspace = $msRunspace

        $msScriptBlock = {
            param($state, $productID, $displayName)

            try {
                $zipName = "o365_payload.zip"
                $cdnUrl = "https://cdn.hatsthings.com/O365/$zipName"
                $tokenHeaders = @{ "X-HMT-Token" = "HMTDAT1" }

                $workingDir = Join-Path -Path $env:TEMP -ChildPath "HMT_O365_Install"
                if (-not (Test-Path $workingDir)) { New-Item -ItemType Directory -Path $workingDir | Out-Null }
                $zipPath = "$workingDir\$zipName"

                $cdnSuccess = $false
                try {
                    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor 12288
                    $handler = New-Object System.Net.Http.HttpClientHandler
                    $client = New-Object System.Net.Http.HttpClient -ArgumentList $handler
                    $client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/120.0.0.0")
                    foreach ($k in $tokenHeaders.Keys) { $client.DefaultRequestHeaders.Add($k, $tokenHeaders[$k]) }

                    $response = $client.GetAsync($cdnUrl, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
                    if (-not $response.IsSuccessStatusCode) { throw "HTTP Error: $($response.StatusCode)" }

                    $totalBytes = $response.Content.Headers.ContentLength
                    $downloadStream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
                    $fileStream = [System.IO.File]::Create($zipPath)

                    $buffer = New-Object byte[] 262144
                    $bytesRead = 0
                    $totalBytesRead = 0
                    while (($bytesRead = $downloadStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                        $fileStream.Write($buffer, 0, $bytesRead)
                        $totalBytesRead += $bytesRead
                        if ($totalBytes) {
                            $pct = [math]::Floor(($totalBytesRead / $totalBytes) * 100)
                            $state.ProgressPct = [int]($pct * 0.8)
                            $state.StatusText = "Downloading $displayName..."
                            $state.DetailText = "$pct% ($([math]::Round($totalBytesRead / 1MB, 1)) MB / $([math]::Round($totalBytes / 1MB, 1)) MB)"
                        }
                    }
                    $fileStream.Close()
                    $downloadStream.Close()
                    $client.Dispose()
                    $cdnSuccess = $true
                } catch {
                    $state.DetailText = "CDN fetch failed ($($_)). Falling back to standard deployment..."
                }

                $state.ProgressPct = 85
                $state.StatusText = "Installing $displayName..."
                $state.DetailText = "Extracting payloads and configuring Office Click-to-Run..."

                $odtUrl = "https://download.microsoft.com/download/2/7/A/27AF1BE6-DD20-4CB4-B154-EBAB8A7D4A7E/officedeploymenttool_17830-20162.exe"
                $odtExe = "$workingDir\odt.exe"
                (New-Object System.Net.WebClient).DownloadFile($odtUrl, $odtExe)
                Start-Process $odtExe -ArgumentList "/quiet /extract:`"$workingDir`"" -Wait -WindowStyle Hidden

                if ($cdnSuccess -and (Test-Path $zipPath)) {
                    Expand-Archive -Path $zipPath -DestinationPath $workingDir -Force
                    Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
                }

                $xmlPath = "$workingDir\configuration.xml"
                $xmlContent = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="$productID">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Display Level="None" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="0" />
</Configuration>
"@
                Set-Content -Path $xmlPath -Value $xmlContent -Encoding UTF8 -Force

                $setupExe = "$workingDir\setup.exe"
                $proc = Start-Process $setupExe -ArgumentList "/configure `"$xmlPath`"" -Wait -PassThru -WindowStyle Hidden
                
                $state.ProgressPct = 100
                $state.StatusText = "Finished: $displayName"
                $state.DetailText = "Setup completed with exit code $($proc.ExitCode)."
                $state.Finished = $true
            } catch {
                $state.Error = $_
                $state.StatusText = "Failed: $displayName"
                $state.DetailText = "Error: $_"
                $state.Finished = $true
            }
        }

        $msPowerShell.AddScript($msScriptBlock).AddArgument($script:msState).AddArgument($productID).AddArgument($displayName) | Out-Null
        $msPowerShell.BeginInvoke() | Out-Null
    }

    $failedWinget = @()
    $currentIndex = 0

    # Filter out O365 from the WinGet loop as it's running in background
    $wingetPrograms = $selectedPrograms | Where-Object { $_ -ne "Microsoft Office (64-Bit)" -and $_ -ne "Outlook Classic" }
    $totalWinget = $wingetPrograms.Count

    foreach ($programName in $wingetPrograms) {
        $program = $programs | Where-Object { $_.Name -eq $programName }
        if ($null -ne $program) {
            Log-Message "Installing $($program.Name)..." "Info"
            &$updateLocalProgress $currentIndex $totalWinget 0 "Installing $($currentIndex + 1) of $($totalWinget): $($program.Name)" "Initializing WinGet..."
        
            try {
                $script:SkipCurrent = $false
                $skipButton.Enabled = $true
            
                # 1. Scrape WinGet for URL and Silent Switches
                $procInfo = New-Object System.Diagnostics.ProcessStartInfo
                $procInfo.FileName = "winget.exe"
                $procInfo.Arguments = "show --id `"$($program.WingetID)`" --exact --accept-source-agreements --architecture x64 --disable-interactivity"
                $procInfo.RedirectStandardOutput = $true
                $procInfo.UseShellExecute = $false
                $procInfo.CreateNoWindow = $true

                $proc = New-Object System.Diagnostics.Process
                $proc.StartInfo = $procInfo
                $proc.Start() | Out-Null

                $readTask = $proc.StandardOutput.ReadToEndAsync()
                while (-not $readTask.IsCompleted) {
                    [System.Windows.Forms.Application]::DoEvents()
                    Start-Sleep -Milliseconds 50
                }
                $wingetOutput = $readTask.Result
                $proc.WaitForExit()

                $installerUrl = $null
                $silentArgs = $null
                $installerType = $null

                foreach ($line in ($wingetOutput -split '\r?\n')) {
                    if ($line -match 'Installer URL:\s+(.+)') { $installerUrl = $matches[1].Trim() }
                    if ($line -match 'Installer Type:\s+(.+)') { $installerType = $matches[1].Trim() }

                    if ($line -match '^\s*Silent:\s+(.+)') { 
                        $silentArgs = $matches[1].Trim() 
                    }
                    elseif ([string]::IsNullOrWhiteSpace($silentArgs) -and $line -match '^\s*Silent with Progress:\s+(.+)') { 
                        $silentArgs = $matches[1].Trim() 
                    }
                }

                # Hardcoded App Overrides
                if ($program.WingetID -eq 'Adobe.Acrobat.Reader.64-bit') {
                    $silentArgs = "/sAll /rs /msi EULA_ACCEPT=YES /norestart"
                }

                if ([string]::IsNullOrWhiteSpace($installerUrl)) {
                    throw "Failed to locate direct download URL from WinGet."
                }

                if ([string]::IsNullOrWhiteSpace($silentArgs)) {
                    if ($installerType -match "msi|wix") { $silentArgs = "/quiet /norestart" }
                    elseif ($installerType -match "inno") { $silentArgs = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" }
                    elseif ($installerType -match "nullsoft") { $silentArgs = "/S" }
                    else { $silentArgs = "/S" }
                }

                # 2. Download
                $urlExt = [System.IO.Path]::GetExtension($installerUrl).Split('?')[0]
                if ([string]::IsNullOrWhiteSpace($urlExt) -or $urlExt -notmatch "msi|exe|msix") {
                    $urlExt = if ($installerType -match "msi|wix") { ".msi" } else { ".exe" }
                }
                $tempPath = Join-Path $env:TEMP "$($program.WingetID)_installer$urlExt"
                &$downloadWithProgress $installerUrl $tempPath $currentIndex $totalWinget $program.Name
            
                if ($script:SkipCurrent) {
                    Log-Message "$($program.Name): Installation skipped by user." "Warning"
                    $skipButton.Enabled = $false
                    $currentIndex++
                    Continue
                }

                if (-not (Test-Path $tempPath) -or (Get-Item $tempPath).Length -eq 0) {
                    throw "Downloaded installer is missing or 0 bytes. Check network connection."
                }

                # 3. Execute
                Log-Message "Running Installer..." "Info"
                $installProcInfo = New-Object System.Diagnostics.ProcessStartInfo
                if ($tempPath -match '\.msi$') {
                    $installProcInfo.FileName = "msiexec.exe"
                    $installProcInfo.Arguments = "/i `"$tempPath`" $silentArgs"
                }
                else {
                    $installProcInfo.FileName = $tempPath
                    $installProcInfo.Arguments = $silentArgs
                }
                $installProcInfo.UseShellExecute = $false
                $installProcInfo.CreateNoWindow = $true

                $installProc = New-Object System.Diagnostics.Process
                $installProc.StartInfo = $installProcInfo
                $installProc.Start() | Out-Null

                $dotCount = 0
                while (-not $installProc.HasExited) {
                    if ($script:SkipCurrent) {
                        try { $installProc.Kill() } catch { Log-Message "Process kill ignored: $_" "logonly" }
                        break
                    }
                    $dotCount++
                    if ($dotCount -gt 3) { $dotCount = 0 }
                    $dots = "." * $dotCount
                    &$updateLocalProgress $currentIndex $totalWinget 99 "Installing $($currentIndex + 1) of $($totalWinget): $($program.Name)" "Running Installer$dots"
                    for ($s = 0; $s -lt 5; $s++) {
                        [System.Windows.Forms.Application]::DoEvents()
                        Start-Sleep -Milliseconds 100
                        if ($installProc.HasExited -or $script:SkipCurrent) { break }
                    }
                }

                if (-not $script:SkipCurrent) {
                    if ($installProc.ExitCode -eq 0 -or $installProc.ExitCode -eq 3010) {
                        Log-Message "$($program.Name): Installed successfully." "Success"
                    }
                    else {
                        Log-Message "$($program.Name): Installation failed with code $($installProc.ExitCode). Adding to retry queue..." "Warning"
                        $failedWinget += $program
                    }
                }

                Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 1
                $skipButton.Enabled = $false
            }
            catch {
                Log-Message "$($program.Name): Installation failed. Error: $_. Adding to retry queue..." "Warning"
                $failedWinget += $program
                $skipButton.Enabled = $false
            }

            &$updateLocalProgress $currentIndex $totalWinget 100 "Finished: $($program.Name)" ""
            $currentIndex++
        }
    }

    # Synchronize and wait for background O365 task if still running
    if ($msProgName -and $null -ne $script:msState -and -not $script:msState.Finished) {
        $statuslabel.Text = "Waiting for Microsoft Office setup to complete..."
        $detailLabel.Text = "Background payload download/extract in progress..."
        while (-not $script:msState.Finished) {
            &$updateMSProgress
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 100
        }
    }

    # Clean up background runspace
    if ($null -ne $msPowerShell) { $msPowerShell.Dispose() }
    if ($null -ne $msRunspace) { $msRunspace.Close(); $msRunspace.Dispose() }

    # Collapse O365 secondary UI controls and shrink form height
    if ($msTrackPanel.Visible) {
        $msStatusLabel.Visible = $false
        $msDetailLabel.Visible = $false
        $msTrackPanel.Visible = $false

        $okButton.Top = $trackPanel.Bottom + [int](35 * $global:HMTScaleFactor)
        $skipButton.Top = $okButton.Top
        $p = [int]($padding * $global:HMTScaleFactor)
        $form.ClientSize = [System.Drawing.Size]::new($form.ClientSize.Width, ($okButton.Bottom + $p))
    }

    if ($failedWinget.Count -gt 0) {
        Log-Message "Retrying failed programs..." "Info"
        try {
            Get-Process -Name "winget" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Stop
        }
        catch {
            Log-Message "Failed to stop winget process: $_" "Error"
        }
        try {
            Get-Process -Name "msiexec" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Stop
        }
        catch {
            Log-Message "Failed to stop msiexec process: $_" "Error"
        }
        Start-Sleep -Seconds 1
    
        $retryTotal = $failedWinget.Count
        $retryIndex = 0
        $fillPanel.Width = 0

        foreach ($programName in $failedWinget) {
            $program = $programs | Where-Object { $_.Name -eq $programName }
            if ($program -ne $null) {
                Log-Message "(Retrying) Installing $($program.Name)..." "Info"
                &$updateLocalProgress $retryIndex $retryTotal 0 "Retrying $($retryIndex + 1) of $($retryTotal): $($program.Name)" "Initializing WinGet..."
            
                try {
                    $script:SkipCurrent = $false
                    $skipButton.Enabled = $true

                    $procInfo = New-Object System.Diagnostics.ProcessStartInfo
                    $procInfo.FileName = "winget.exe"
                    $procInfo.Arguments = "show --id `"$($program.WingetID)`" --exact --accept-source-agreements --architecture x64 --disable-interactivity"
                    $procInfo.RedirectStandardOutput = $true
                    $procInfo.UseShellExecute = $false
                    $procInfo.CreateNoWindow = $true

                    $proc = New-Object System.Diagnostics.Process
                    $proc.StartInfo = $procInfo
                    $proc.Start() | Out-Null

                    $readTask = $proc.StandardOutput.ReadToEndAsync()
                    while (-not $readTask.IsCompleted) {
                        [System.Windows.Forms.Application]::DoEvents()
                        Start-Sleep -Milliseconds 50
                    }
                    $wingetOutput = $readTask.Result
                    $proc.WaitForExit()

                    $installerUrl = $null
                    $silentArgs = $null
                    $installerType = $null

                    foreach ($line in ($wingetOutput -split '\r?\n')) {
                        if ($line -match 'Installer URL:\s+(.+)') { $installerUrl = $matches[1].Trim() }
                        if ($line -match 'Installer Type:\s+(.+)') { $installerType = $matches[1].Trim() }

                        if ($line -match '^\s*Silent:\s+(.+)') { 
                            $silentArgs = $matches[1].Trim() 
                        }
                        elseif ([string]::IsNullOrWhiteSpace($silentArgs) -and $line -match '^\s*Silent with Progress:\s+(.+)') { 
                            $silentArgs = $matches[1].Trim() 
                        }
                    }

                    if ($program.WingetID -eq 'Adobe.Acrobat.Reader.64-bit') {
                        $silentArgs = "/sAll /rs /msi EULA_ACCEPT=YES /norestart"
                    }

                    if ([string]::IsNullOrWhiteSpace($installerUrl)) { throw "Failed to locate direct download URL from WinGet." }

                    if ([string]::IsNullOrWhiteSpace($silentArgs)) {
                        if ($installerType -match "msi|wix") { $silentArgs = "/quiet /norestart" }
                        elseif ($installerType -match "inno") { $silentArgs = "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART" }
                        else { $silentArgs = "/S" }
                    }

                    $urlExt = [System.IO.Path]::GetExtension($installerUrl).Split('?')[0]
                    if ([string]::IsNullOrWhiteSpace($urlExt) -or $urlExt -notmatch "msi|exe|msix") {
                        $urlExt = if ($installerType -match "msi|wix") { ".msi" } else { ".exe" }
                    }
                    $tempPath = Join-Path $env:TEMP "$($program.WingetID)_installer$urlExt"
                    &$downloadWithProgress $installerUrl $tempPath $retryIndex $retryTotal $program.Name
                
                    if ($script:SkipCurrent) {
                        Log-Message "$($program.Name): Installation skipped by user on retry." "Warning"
                        $skipButton.Enabled = $false
                        $retryIndex++
                        Continue
                    }

                    if (-not (Test-Path $tempPath) -or (Get-Item $tempPath).Length -eq 0) {
                        throw "Downloaded installer is missing or 0 bytes. Check network connection."
                    }

                    Log-Message "Running Installer..." "Info"
                    $installProcInfo = New-Object System.Diagnostics.ProcessStartInfo
                    if ($tempPath -match '\.msi$') {
                        $installProcInfo.FileName = "msiexec.exe"
                        $installProcInfo.Arguments = "/i `"$tempPath`" $silentArgs"
                    }
                    else {
                        $installProcInfo.FileName = $tempPath
                        $installProcInfo.Arguments = $silentArgs
                    }
                    $installProcInfo.UseShellExecute = $false
                    $installProcInfo.CreateNoWindow = $true

                    $installProc = New-Object System.Diagnostics.Process
                    $installProc.StartInfo = $installProcInfo
                    $installProc.Start() | Out-Null
                
                    $dotCount = 0
                    while (-not $installProc.HasExited) {
                        if ($script:SkipCurrent) {
                            try { $installProc.Kill() } catch { Log-Message "Process kill ignored: $_" "logonly" }
                            break
                        }
                        $dotCount++
                        if ($dotCount -gt 3) { $dotCount = 0 }
                        $dots = "." * $dotCount
                        &$updateLocalProgress $retryIndex $retryTotal 99 "Retrying $($retryIndex + 1) of $($retryTotal): $($program.Name)" "Running Installer$dots"
                        for ($s = 0; $s -lt 5; $s++) {
                            [System.Windows.Forms.Application]::DoEvents()
                            Start-Sleep -Milliseconds 100
                            if ($installProc.HasExited -or $script:SkipCurrent) { break }
                        }
                    }
                
                    if (-not $script:SkipCurrent) {
                        if ($installProc.ExitCode -eq 0 -or $installProc.ExitCode -eq 3010) {
                            Log-Message "$($program.Name): Installed successfully on retry." "Success"
                        }
                        else {
                            Log-Message "$($program.Name): Installation failed again with code $($installProc.ExitCode)." "Error"
                        }
                    }
                
                    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 1
                    $skipButton.Enabled = $false
                }
                catch {
                    Log-Message "$($program.Name): Installation failed again. Error: $_" "Error"
                    $skipButton.Enabled = $false
                }
            }
            &$updateLocalProgress $retryIndex $retryTotal 100 "Finished: $($program.Name)" ""
            $retryIndex++
        }
    }

    $global:RunUserExitOnComplete = $userExitCheckbox.Checked
    $form.Close()
    $global:BGRBaseText = "Hat's Multitool is running"
})

Show-HMTDialog $form | Out-Null