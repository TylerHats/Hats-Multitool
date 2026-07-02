# Programs Module - Tyler Hatfield - v1.21

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
}

# Async-Safe Streamed Download Helper
$downloadWithProgress = {
    param([string]$Url, [string]$OutFile, [int]$ProgIndex, [int]$TotPrograms, [string]$AppName)
    
    $global:DlDone = $false
    $script:SkipCurrent = $false

    # Enable TLS 1.2 and TLS 1.3 (12288) to unlock faster CDN routing paths
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor 12288

    # Initialize modern HttpClient
    $handler = New-Object System.Net.Http.HttpClientHandler
    $client = New-Object System.Net.Http.HttpClient -ArgumentList $handler
    
    # CRITICAL: Masquerade as a standard web browser to bypass CDN script throttling
    $client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

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
            } else {
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

        $selectedPrograms = @($checkboxes.GetEnumerator() | Where-Object { $_.Value.Checked } | ForEach-Object { $_.Key })
        $totalPrograms = $selectedPrograms.Count
        if ($totalPrograms -eq 0) {
            Log-Message "No programs selected for installation." "Skip"
            $form.Close()
            return
        }

        try {
            Get-Process -Name "winget" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Stop
        }
        catch {
            Log-Message "Failed to stop winget: $_" "Error"
        }

        $failedWinget = @()
        $currentIndex = 0

        foreach ($programName in $selectedPrograms) {
            $program = $programs | Where-Object { $_.Name -eq $programName }
            &$updateLocalProgress $currentIndex $totalPrograms 0 "Starting: $($program.Name)..."

            if ($program.Type -eq "MSOffice" -or $program.Type -eq "MSOutlook") {
                try {
                    $displayName = if ($program.Type -eq "MSOffice") { "Microsoft Office (x64)" } else { "Outlook (Classic)" }
                    $productID = if ($program.Type -eq "MSOffice") { "O365BusinessRetail" } else { "OutlookRetail" }
                
                    Log-Message "Starting Install of $displayName..." "Info"

                    $workingDir = Join-Path -Path "$PSScriptRoot" -ChildPath "OfficeODT"
                    if (-Not (Test-Path $workingDir)) { New-Item -ItemType Directory -Path $workingDir | Out-Null }
                    $odtUrl = "https://download.microsoft.com/download/6c1eeb25-cf8b-41d9-8d0d-cc1dbc032140/officedeploymenttool_18526-20146.exe"
                    $odtExe = "$workingDir\OfficeDeploymentTool.exe"
                
                    if (-Not (Test-Path $odtExe)) {
                        Log-Message "Downloading Office Deployment Tool..." "Info"
                        try {
                            &$downloadWithProgress $odtUrl $odtExe $currentIndex $totalPrograms $displayName
                            try {
                                Unblock-File -Path $odtExe -ErrorAction Stop
                            }
                            catch {
                                Log-Message "Failed to unblock $odtExe : $_" "Error"
                            }
                        }
                        catch {
                            Log-Message "ODT download failed, check internet connection." "Error"
                            $currentIndex++
                            Continue
                        }
                    }
                
                    Log-Message "Extracting Office Deployment Tool..." "Info"
                    &$updateLocalProgress $currentIndex $totalPrograms 80 "Extracting: $displayName (80%)"
                    $extractProc = Start-Process -FilePath "$odtExe" -ArgumentList "/extract:`"$workingDir`" /quiet" -PassThru -WindowStyle Hidden
                    while (-not $extractProc.HasExited) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50 }

                    $configXml = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="Current">
    <Product ID="$productID">
      <Language ID="en-us" />
    </Product>
  </Add>
  <Display Level="Basic" AcceptEULA="TRUE" />
  <Property Name="AUTOACTIVATE" Value="1"/>
</Configuration>
"@
                    $configFile = "$workingDir\configuration.xml"
                    $configXml | Out-File -FilePath $configFile -Encoding ascii

                    Log-Message "Launching Office Setup asynchronously..." "Info"
                    &$updateLocalProgress $currentIndex $totalPrograms 90 "Launching Setup: $displayName (90%)"
                
                    Start-Process -FilePath "$workingDir\setup.exe" -ArgumentList "/configure `"$configFile`"" -WindowStyle Hidden
                    Log-Message "$($displayName): Installer launched in background." "Success"
                }
                catch {
                    Log-Message "$($displayName): Installation failed, please review log." "Error"
                }
            }
            elseif ($program -ne $null) {
                Log-Message "Installing $($program.Name)..." "Info"
                &$updateLocalProgress $currentIndex $totalPrograms 0 "Installing $($currentIndex + 1) of $($totalPrograms): $($program.Name)" "Initializing WinGet..."
            
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

                    # Split cleanly on Windows or Linux newline variants to avoid hidden carriage returns (`\r`)
                    foreach ($line in ($wingetOutput -split '\r?\n')) {
                        if ($line -match 'Installer URL:\s+(.+)') { $installerUrl = $matches[1].Trim() }
                        if ($line -match 'Installer Type:\s+(.+)') { $installerType = $matches[1].Trim() }
    
                        # Strictly isolate the pure hidden silent parameter block
                        if ($line -match '^\s*Silent:\s+(.+)') { 
                            $silentArgs = $matches[1].Trim() 
                        }
                        # Only fall back to 'Silent with Progress' if a completely silent switch hasn't been set
                        elseif ([string]::IsNullOrWhiteSpace($silentArgs) -and $line -match '^\s*Silent with Progress:\s+(.+)') { 
                            $silentArgs = $matches[1].Trim() 
                        }
                    }

                    # HARDCODED APP OVERRIDES
                    # Intercept notoriously broken enterprise manifests before they drop into execution
                    if ($program.WingetID -eq 'Adobe.Acrobat.Reader.64-bit') {
                        # Force absolute silence, auto-accept vendor EULAs, and suppress all reboots/prompts entirely
                        $silentArgs = "/sAll /rs /msi EULA_ACCEPT=YES /norestart"
                    }

                    if ([string]::IsNullOrWhiteSpace($installerUrl)) {
                        throw "Failed to locate direct download URL from WinGet."
                    }

                    if ([string]::IsNullOrWhiteSpace($silentArgs)) {
                        # Fallbacks
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
                    &$downloadWithProgress $installerUrl $tempPath $currentIndex $totalPrograms $program.Name
                
                    if ($script:SkipCurrent) {
                        Log-Message "$($program.Name): Installation skipped by user." "Warning"
                        $skipButton.Enabled = $false
                        $currentIndex++
                        Continue
                    }

                    # 3. Execute
                    if (-not (Test-Path $tempPath) -or (Get-Item $tempPath).Length -eq 0) {
                        throw "Downloaded installer is missing or 0 bytes. Check network connection."
                    }

                    Log-Message "Running Installer..." "Info"
                
                    $installProcInfo = New-Object System.Diagnostics.ProcessStartInfo
                    if ($tempPath -match '\.msi$') {
                        $installProcInfo.FileName = "msiexec.exe"
                        $installProcInfo.Arguments = "/i `"$tempPath`" $silentArgs"
                    } else {
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
                            Log-Message "$($program.Name): Installation aborted by user." "Warning"
                            try { $installProc.Kill() } catch {}
                            break
                        }
                        $dotCount++
                        if ($dotCount -gt 3) { $dotCount = 0 }
                        $dots = "." * $dotCount
                    
                        &$updateLocalProgress $currentIndex $totalPrograms 99 "Installing $($currentIndex + 1) of $($totalPrograms): $($program.Name)" "Running Installer$dots"
                    
                        [System.Windows.Forms.Application]::DoEvents()
                        Start-Sleep -Milliseconds 500
                    }
                
                    if (-not $script:SkipCurrent) {
                        if ($installProc.ExitCode -eq 0 -or $installProc.ExitCode -eq 3010) {
                            Log-Message "$($program.Name): Installed successfully." "Success"
                        }
                        else {
                            Log-Message "$($program.Name): Installation exited with code $($installProc.ExitCode)." "Warning"
                            $failedWinget += $program.Name
                        }
                    }
                
                    # Cleanup
                    Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
                
                    Start-Sleep -Seconds 1
                    $skipButton.Enabled = $false
                }
                catch {
                    Log-Message "$($program.Name): Installation failed. Error: $_" "Error"
                    $failedWinget += $program.Name
                    $skipButton.Enabled = $false
                }
            }
        
            # Finalize segment progress
            &$updateLocalProgress $currentIndex $totalPrograms 100 "Finished: $($program.Name)"
            $currentIndex++
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
                        } else {
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
                                try { $installProc.Kill() } catch {}
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

$form.ShowDialog() | Out-Null