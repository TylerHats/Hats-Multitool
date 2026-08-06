# Programs Module - Tyler Hatfield - v2.0

# Force TLS 1.2 for reliable WebClient downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# # Force initialize WinGet source
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
Log-Message "Preparing Software List..."
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Net.Http
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Program Selection List'
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$form.StartPosition = 'CenterScreen'
$HMTIconPath = Join-Path -Path $PSScriptRoot -ChildPath "HMTIconSmall.ico"
$HMTIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($HMTIconPath)
$form.Icon = $HMTIcon
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

# Component sizing variables
# $checkboxHeight = 30
$labelHeight = 30
$padding = 20

$programs = @(
    @{ Name = '7-Zip'; WingetID = '7zip.7zip'; Type = 'Winget' },
    @{ Name = 'Acrobat Reader'; WingetID = 'Adobe.Acrobat.Reader.64-bit'; Type = 'Winget' },
    @{ Name = 'Creative Cloud'; WingetID = 'Adobe.CreativeCloud'; Type = 'Winget' },
    @{ Name = 'Dropbox'; WingetID = 'Dropbox.Dropbox'; Type = 'Winget' },
    @{ Name = 'Firefox'; WingetID = 'Mozilla.Firefox'; Type = 'Winget' },
    @{ Name = 'Google Chrome'; WingetID = 'Google.Chrome'; Type = 'Winget' },
    @{ Name = 'Google Drive'; WingetID = 'Google.Drive'; Type = 'Winget' },
    @{ Name = 'Notepad++'; WingetID = 'Notepad++.Notepad++'; Type = 'Winget' },
    @{ Name = 'Twingate Client'; WingetID = 'Twingate.Client'; Type = 'Winget' },
    @{ Name = 'VLC Media Player'; WingetID = 'VideoLAN.VLC'; Type = 'Winget' },
    @{ Name = 'Zoom'; WingetID = 'Zoom.Zoom'; Type = 'Winget' },
    @{ Name = 'Microsoft Office (64-Bit)'; WingetID = ''; Type = 'MSOffice' },
    @{ Name = 'Outlook Classic'; WingetID = ''; Type = 'MSOutlook' }
)

$form.ClientSize = New-Object System.Drawing.Size(400, 500)

# Prepare Program Checkboxes
$checkboxes = @{ }
$y = 20
$label = New-Object System.Windows.Forms.Label
$label.Text = "Programs:"
$label.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$label.Location = New-Object System.Drawing.Point(20, $y)
$label.AutoSize = $true
$form.Controls.Add($label)
$y += $labelHeight

$programFlow = New-Object System.Windows.Forms.FlowLayoutPanel
$programFlow.Location = New-Object System.Drawing.Point(20, $y)
$programFlow.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
$programFlow.WrapContents = $false
$programFlow.AutoSize = $true
$programFlow.AutoSizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
$form.Controls.Add($programFlow)

foreach ($program in $programs) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Text = $program.Name
    $checkbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $checkbox.AutoSize = $true
    $checkbox.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 5)
    $programFlow.Controls.Add($checkbox)
    $checkboxes[$program.Name] = $checkbox
}

# Add User-Exit Checkbox
$userExitCheckbox = New-Object System.Windows.Forms.CheckBox
$userExitCheckbox.Text = "Automatically exit multitool when complete"
$userExitCheckbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$userExitCheckbox.AutoSize = $true
$userExitCheckbox.Margin = New-Object System.Windows.Forms.Padding(0, 10, 0, 5)
$programFlow.Controls.Add($userExitCheckbox)

$y = $programFlow.Bottom + 15

$outlookCheckbox = $checkboxes["Outlook Classic"]
$officeCheckbox = $checkboxes["Microsoft Office (64-Bit)"]

$outlookCheckbox.Add_CheckedChanged({
        if ($outlookCheckbox.Checked) {
            $officeCheckbox.Enabled = $false
            $officeCheckbox.Checked = $false
        }
        else {
            $officeCheckbox.Enabled = $true
        }
    })

$officeCheckbox.Add_CheckedChanged({
        if ($officeCheckbox.Checked) {
            $outlookCheckbox.Enabled = $false
            $outlookCheckbox.Checked = $false
        }
        else {
            $outlookCheckbox.Enabled = $true
        }
    })

$y += 15
$statuslabel = New-Object System.Windows.Forms.Label
$statuslabel.Text = "Status: Idle"
$statuslabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$statuslabel.Size = New-Object System.Drawing.Size(340, 20)
$statuslabel.Location = New-Object System.Drawing.Point(20, ($y - 10))
$statuslabel.AutoSize = $true
$statuslabel.TextAlign = 'TopLeft'
$form.Controls.Add($statuslabel)

$detailLabel = New-Object System.Windows.Forms.Label
$detailLabel.Text = ""
$detailLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0") # Dimmer grey for sub-text
$detailLabel.Size = New-Object System.Drawing.Size(340, 20)
$detailLabel.Location = New-Object System.Drawing.Point(20, ($y + 10))
$detailLabel.AutoSize = $true
$detailLabel.TextAlign = 'TopLeft'
$form.Controls.Add($detailLabel)

$y += 35
$trackPanel = New-Object System.Windows.Forms.Panel
$trackPanel.Size = [System.Drawing.Size]::new(340, 22)
$trackPanel.Location = [System.Drawing.Point]::new(20, $y)
$trackPanel.BorderStyle = 'FixedSingle'
$trackPanel.BackColor = [System.Drawing.Color]::DarkGray
$form.Controls.Add($trackPanel)

$fillPanel = New-Object System.Windows.Forms.Panel
$fillPanel.Size = [System.Drawing.Size]::new(0, 19)
$fillPanel.Location = [System.Drawing.Point]::new(1, 1)
$fillPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
$trackPanel.Controls.Add($fillPanel)

# Secondary Progress UI Controls for Microsoft Office Payload
$msStatusLabel = New-Object System.Windows.Forms.Label
$msStatusLabel.Text = "Microsoft Office: Starting..."
$msStatusLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$msStatusLabel.Size = New-Object System.Drawing.Size(340, 20)
$msStatusLabel.AutoSize = $true
$msStatusLabel.Visible = $false
$form.Controls.Add($msStatusLabel)

$msDetailLabel = New-Object System.Windows.Forms.Label
$msDetailLabel.Text = ""
$msDetailLabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
$msDetailLabel.Size = New-Object System.Drawing.Size(340, 20)
$msDetailLabel.AutoSize = $true
$msDetailLabel.Visible = $false
$form.Controls.Add($msDetailLabel)

$msTrackPanel = New-Object System.Windows.Forms.Panel
$msTrackPanel.Size = [System.Drawing.Size]::new(340, 22)
$msTrackPanel.BorderStyle = 'FixedSingle'
$msTrackPanel.BackColor = [System.Drawing.Color]::DarkGray
$msTrackPanel.Visible = $false
$form.Controls.Add($msTrackPanel)

$msFillPanel = New-Object System.Windows.Forms.Panel
$msFillPanel.Size = [System.Drawing.Size]::new(0, 19)
$msFillPanel.Location = [System.Drawing.Point]::new(1, 1)
$msFillPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
$msTrackPanel.Controls.Add($msFillPanel)

$okButton = New-Object System.Windows.Forms.Button
$y += 40
$okButton.Location = New-Object System.Drawing.Point(95, $y)
$okButton.Size = New-Object System.Drawing.Size(95, 40)
$okButton.Text = "OK"
$okButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$okButton.FlatStyle = 'Flat'
$okButton.FlatAppearance.BorderSize = 1
$form.Controls.Add($okButton)
$form.AcceptButton = $okButton

$skipButton = New-Object System.Windows.Forms.Button
$skipButton.Location = New-Object System.Drawing.Point(210, $y)
$skipButton.Size = New-Object System.Drawing.Size(95, 40)
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
        
        $y = $programFlow.Bottom + [int](30 * $global:HMTScaleFactor)
        $statuslabel.Top = $y - [int](10 * $global:HMTScaleFactor)
        $detailLabel.Top = $y + [int](10 * $global:HMTScaleFactor)
        
        $y += [int](35 * $global:HMTScaleFactor)
        $trackPanel.Top = $y
        
        $y += [int](40 * $global:HMTScaleFactor)
        $okButton.Top = $y
        $skipButton.Top = $y
        
        $form.ClientSize = [System.Drawing.Size]::new($form.ClientSize.Width, ($okButton.Bottom + $p))
    })

$updateMSProgress = {
    if ($msTrackPanel.Visible -and $null -ne $script:msState) {
        $msMaxW = $msTrackPanel.ClientSize.Width - 2
        $pct = [math]::Max(0, [math]::Min([double]$script:msState.ProgressPct, 100))
        $msFillPanel.Width = [int]($msMaxW * ($pct / 100.0))
        if ($script:msState.StatusText) { $msStatusLabel.Text = $script:msState.StatusText }
        if ($null -ne $script:msState.DetailText) { $msDetailLabel.Text = $script:msState.DetailText }
    }
}

# Progress & UI Logic Helper
$updateLocalProgress = {
    param([int]$Index, [int]$Total, [double]$LocalPct, [string]$StatusText, [string]$DetailText)
    
    # Cap bounds to prevent visual tearing
    if ($LocalPct -lt 0) { $LocalPct = 0 }
    if ($LocalPct -gt 100) { $LocalPct = 100 }

    $maxWidth = $trackPanel.ClientSize.Width - 2
    $baseWidth = ($Index / $Total) * $maxWidth
    $chunkWidth = ($LocalPct / 100) * ($maxWidth / $Total)
    
    $newWidth = [math]::Min([int]($baseWidth + $chunkWidth), $maxWidth)
    
    # Direct assignment allows the bar to reflect true state, even if a download restarts
    $fillPanel.Width = $newWidth
    
    if (-not [string]::IsNullOrEmpty($StatusText)) {
        $statuslabel.Text = $StatusText
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

    # Enable TLS 1.2 and TLS 1.3
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor 12288

    # Initialize modern HttpClient
    $handler = New-Object System.Net.Http.HttpClientHandler
    $client = New-Object System.Net.Http.HttpClient -ArgumentList $handler
    
    # Masquerade as a standard web browser
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

    # ONLY apply headers if explicitly passed into this function call
    if ($null -ne $Headers) {
        foreach ($key in $Headers.Keys) {
            $client.DefaultRequestHeaders.Add($key, $Headers[$key])
        }
    }

    $downloadStream = $null
    $fileStream = $null

    try {
        # Request headers first to get file size safely
        $responseTask = $client.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead)
        $response = $responseTask.GetAwaiter().GetResult()
        
        if (-not $response.IsSuccessStatusCode) {
            throw "HTTP Error: $($response.StatusCode)"
        }

        # Extract total content length if provided by server
        $totalBytes = $response.Content.Headers.ContentLength
        
        # Open streams
        $downloadStream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $fileStream = [System.IO.File]::Create($OutFile)

        # 256 KB buffer chunk sizing
        $buffer = New-Object byte[] 262144
        $bytesRead = 0
        $totalBytesRead = 0
        $lastPct = -1

        # Stream reading loop
        while (($bytesRead = $downloadStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
            if ($script:SkipCurrent) {
                break
            }

            $fileStream.Write($buffer, 0, $bytesRead)
            $totalBytesRead += $bytesRead

            if ($totalBytes) {
                $pct = [math]::Floor(($totalBytesRead / $totalBytes) * 100)
                
                # Only update UI when the whole percentage changes
                if ($pct -ne $lastPct) {
                    $lastPct = $pct
                    &$updateLocalProgress $ProgIndex $TotPrograms ($pct * 0.8) "Installing $($ProgIndex + 1) of $($TotPrograms): $AppName" "Downloading... ($pct%)"
                    [System.Windows.Forms.Application]::DoEvents()
                }
            }
            else {
                &$updateLocalProgress $ProgIndex $TotPrograms 40 "Installing $($ProgIndex + 1) of $($TotPrograms): $AppName" "Downloading... (Size Unknown)"
                [System.Windows.Forms.Application]::DoEvents()
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
        $global:RunUserExitOnComplete = $userExitCheckbox.Checked

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

        # Start parallel O365 download/extract background runspace if selected
        $msRunspace = $null
        $msPowerShell = $null

        if ($msProgName) {
            $isAll = $msProgName -eq "Microsoft Office (64-Bit)"
            $displayName = if ($isAll) { "Microsoft Office (x64)" } else { "Outlook (Classic)" }
            $productID = if ($isAll) { "O365BusinessRetail" } else { "OutlookRetail" }

            # Dynamically expand form for O365 secondary progress bar
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
                                $state.DetailText = "Downloading payload ($pct%)..."
                            } else {
                                $state.ProgressPct = 40
                                $state.StatusText = "Downloading $displayName..."
                                $state.DetailText = "Downloading payload..."
                            }
                        }
                        $fileStream.Close(); $fileStream.Dispose()
                        $downloadStream.Close(); $downloadStream.Dispose()
                        $client.Dispose()

                        # Non-blocking async extraction in background worker
                        $state.ProgressPct = 85
                        $state.StatusText = "Extracting $displayName..."
                        $state.DetailText = "Unpacking payload archive..."
                        if ($zipPath -match '\.7z$' -and (Get-Command tar.exe -ErrorAction SilentlyContinue)) {
                            $pExt = Start-Process -FilePath "tar.exe" -ArgumentList "-xf `"$zipPath`" -C `"$workingDir`"" -PassThru -WindowStyle Hidden
                            while (-not $pExt.HasExited) { Start-Sleep -Milliseconds 100 }
                        } else {
                            $pExt = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Expand-Archive -Path '$zipPath' -DestinationPath '$workingDir' -Force`"" -PassThru -WindowStyle Hidden
                            while (-not $pExt.HasExited) { Start-Sleep -Milliseconds 100 }
                        }
                        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue

                        # Generate XML with Full display level
                        $state.ProgressPct = 95
                        $state.StatusText = "Launching $displayName..."
                        $state.DetailText = "Starting setup.exe..."
                        $configXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="$productID">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Display Level="Full" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="1"/>
</Configuration>
"@
                        $configXmlPath = "$workingDir\configuration.xml"
                        $configXml | Out-File -FilePath $configXmlPath -Encoding ascii

                        Start-Process -FilePath "$workingDir\setup.exe" -ArgumentList "/configure `"$configXmlPath`""
                        $cdnSuccess = $true
                    } catch {
                        # Fallback to official Microsoft online streaming installer
                        $state.StatusText = "Falling back to Microsoft CDN..."
                        $state.DetailText = "Downloading official ODT..."
                        $odtUrl = "https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_18526-20146.exe"
                        $odtExe = "$workingDir\OfficeDeploymentTool.exe"

                        (New-Object System.Net.WebClient).DownloadFile($odtUrl, $odtExe)
                        try { Unblock-File -Path $odtExe -ErrorAction Stop } catch {}

                        $state.ProgressPct = 85
                        $state.StatusText = "Extracting ODT..."
                        $extractProc = Start-Process -FilePath "$odtExe" -ArgumentList "/extract:`"$workingDir`" /quiet" -PassThru -WindowStyle Hidden
                        while (-not $extractProc.HasExited) { Start-Sleep -Milliseconds 100 }

                        $configXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="$productID">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Display Level="Full" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="1"/>
</Configuration>
"@
                        $configXmlPath = "$workingDir\configuration.xml"
                        $configXml | Out-File -FilePath $configXmlPath -Encoding ascii

                        Start-Process -FilePath "$workingDir\setup.exe" -ArgumentList "/configure `"$configXmlPath`""
                    }

                    $state.ProgressPct = 100
                    $state.StatusText = "Finished $displayName setup launch"
                    $state.DetailText = "Installer running"
                } catch {
                    $state.Error = $_.ToString()
                } finally {
                    $state.Finished = $true
                }
            }

            [void]$msPowerShell.AddScript($msScriptBlock).AddArgument($script:msState).AddArgument($productID).AddArgument($displayName)
            [void]$msPowerShell.BeginInvoke()
        }

        try {
            Get-Process -Name "winget" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Stop
        }
        catch {
            Log-Message "Failed to stop winget: $_" "Error"
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

                    $wingetOutput = $proc.StandardOutput.ReadToEnd()
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

                    # HARDCODED APP OVERRIDES
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
                        [System.Windows.Forms.Application]::DoEvents()
                        Start-Sleep -Milliseconds 500
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

            $okButton.Top = $trackPanel.Bottom + [int](40 * $global:HMTScaleFactor)
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

                        $wingetOutput = $proc.StandardOutput.ReadToEnd()
                        $proc.WaitForExit()

                        $installerUrl = $null
                        $silentArgs = $null
                        $installerType = $null

                        # Modern newline split to protect parameters
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

                        # Adobe Override (Keeps the retry attempt silent too)
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
                            [System.Windows.Forms.Application]::DoEvents()
                            Start-Sleep -Milliseconds 500
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
                # Finalize segment progress
                &$updateLocalProgress $retryIndex $retryTotal 100 "Finished: $($program.Name)" ""
                $retryIndex++
            }
        }

        $form.Close()
        $global:BGRBaseText = "Hat's Multitool is running"
    })

Show-HMTDialog $form | Out-Null