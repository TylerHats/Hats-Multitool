# Programs Module - Tyler Hatfield - v1.16

# Force TLS 1.2 for reliable WebClient downloads
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Force initialize WinGet source
Log-Message "Initializing WinGet and updating sources..."
winget source reset --force | Out-Null
winget source update | Out-Null

# Install programs based on selections, prepare Windows "Form"
Log-Message "Preparing Software List..."
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Program Selection List'
$form.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
$form.StartPosition = 'CenterScreen'
$HMTIconPath = Join-Path -Path $PSScriptRoot -ChildPath "HMTIconSmall.ico"
$HMTIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($HMTIconPath)
$form.Icon = $HMTIcon
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$font = New-Object System.Drawing.Font("Segoe UI", 10)
$form.Font = $font
$form.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
Set-DarkTitleBar -TargetForm $form

# Component sizing variables
$checkboxHeight = 30
$labelHeight = 30
$padding = 20

$programs = @(
    @{ Name = 'Acrobat Reader'; WingetID = 'Adobe.Acrobat.Reader.64-bit'; Type = 'Winget' },
    @{ Name = 'Creative Cloud'; WingetID = 'Adobe.CreativeCloud'; Type = 'Winget' },
    @{ Name = 'Google Chrome'; WingetID = 'Google.Chrome'; Type = 'Winget' },
    @{ Name = 'Firefox'; WingetID = 'Mozilla.Firefox'; Type = 'Winget' },
    @{ Name = '7-Zip'; WingetID = '7zip.7zip'; Type = 'Winget' },
    @{ Name = 'Google Drive'; WingetID = 'Google.Drive'; Type = 'Winget' },
    @{ Name = 'Dropbox'; WingetID = 'Dropbox.Dropbox'; Type = 'Winget' },
    @{ Name = 'VLC Media Player'; WingetID = 'VideoLAN.VLC'; Type = 'Winget' },
    @{ Name = 'Zoom'; WingetID = 'Zoom.Zoom'; Type = 'Winget' },
    @{ Name = 'Outlook Classic'; WingetID = ''; Type = 'MSOutlook' },
    @{ Name = 'Microsoft Office (64-Bit)'; WingetID = ''; Type = 'MSOffice' }
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

foreach ($program in $programs) {
    $checkbox = New-Object System.Windows.Forms.CheckBox
    $checkbox.Location = New-Object System.Drawing.Point(20, $y)
    $checkbox.Text = $program.Name
    $checkbox.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $checkbox.AutoSize = $true
    $form.Controls.Add($checkbox)
    $checkboxes[$program.Name] = $checkbox
    $y += $checkboxHeight
}

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

$y += 15
$statuslabel = New-Object System.Windows.Forms.Label
$statuslabel.Text = "Status: Idle"
$statuslabel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$statuslabel.Size = New-Object System.Drawing.Size(340, 20)
$statuslabel.Location = New-Object System.Drawing.Point(20, ($y-10))
$statuslabel.AutoSize = $true
$statuslabel.TextAlign = 'TopLeft'
$form.Controls.Add($statuslabel)

$y += 20
$trackPanel = New-Object System.Windows.Forms.Panel
$trackPanel.Size        = [System.Drawing.Size]::new(340,22)
$trackPanel.Location    = [System.Drawing.Point]::new(20,$y)
$trackPanel.BorderStyle = 'FixedSingle'
$trackPanel.BackColor   = [System.Drawing.Color]::DarkGray
$form.Controls.Add($trackPanel)

$fillPanel = New-Object System.Windows.Forms.Panel
$fillPanel.Size      = [System.Drawing.Size]::new(0,19)
$fillPanel.Location  = [System.Drawing.Point]::new(1,1)
$fillPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
$trackPanel.Controls.Add($fillPanel)

$okButton = New-Object System.Windows.Forms.Button
$y += 40
$okButton.Location = New-Object System.Drawing.Point(152, $y)
$okButton.Size = New-Object System.Drawing.Size(95, 40)
$okButton.Text = "OK"
$okButton.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
$okButton.FlatStyle = 'Flat'
$okButton.FlatAppearance.BorderSize = 1
$form.Controls.Add($okButton)
$form.AcceptButton = $okButton

# Dynamic Sizing Trigger
$form.Add_Load({
    $form.ClientSize = [System.Drawing.Size]::new($form.ClientSize.Width, ($okButton.Bottom + $padding))
})

# Progress & UI Logic Helper
$updateLocalProgress = {
    param([int]$Index, [int]$Total, [double]$LocalPct, [string]$StatusText)
    $maxWidth = $trackPanel.ClientSize.Width - 2
    $baseWidth = ($Index / $Total) * $maxWidth
    $chunkWidth = (1 / $Total) * ($LocalPct / 100) * $maxWidth
    
    $newWidth = [math]::Min([int]($baseWidth + $chunkWidth), $maxWidth)
    if ($fillPanel.Width -lt $newWidth) {
        $fillPanel.Width = $newWidth
    }
    if (-not [string]::IsNullOrEmpty($StatusText)) {
        $statuslabel.Text = $StatusText
    }
}

# Async Download Helper 
$downloadWithProgress = {
    param([string]$Url, [string]$OutFile, [int]$ProgIndex, [int]$TotPrograms, [string]$AppName)
    $global:DlProgress = 0
    $global:DlDone = $false
    $webClient = New-Object System.Net.WebClient
    
    $onProg = Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action { $global:DlProgress = $EventArgs.ProgressPercentage }
    $onComp = Register-ObjectEvent -InputObject $webClient -EventName DownloadFileCompleted -Action { $global:DlDone = $true }
    
    $webClient.DownloadFileAsync([System.Uri]$Url, $OutFile)
    while (-not $global:DlDone) {
        $pct = $global:DlProgress
        # Scale download up to 80% of local segment
        &$updateLocalProgress $ProgIndex $TotPrograms ($pct * 0.8) "Downloading: $AppName ($pct%)"
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 50
    }
    
    Unregister-Event -SourceIdentifier $onProg.Name
    Unregister-Event -SourceIdentifier $onComp.Name
    $webClient.Dispose()
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

    Get-Process -Name "winget" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue *>&1 | Out-File -Append -FilePath $logPath

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
                        Unblock-File -Path $odtExe *>&1 | Out-File -Append -FilePath $logPath
                    } catch {
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
                Log-Message "$displayName: Installer launched in background." "Success"
            } catch {
                Log-Message "$displayName: Installation failed, please review log." "Error"
            }
        } elseif ($program.Type -eq "Teams") {
            try {
                Log-Message "Starting Install of Microsoft Teams..." "Info"
                $workingDir = Join-Path -Path "$PSScriptRoot" -ChildPath "Teams"
                if (-Not (Test-Path $workingDir)) { New-Item -ItemType Directory -Path $workingDir | Out-Null }
                
                $bootstrapperURL = "https://statics.teams.cdn.office.net/production-teamsprovision/lkg/teamsbootstrapper.exe"
                $teamsEXE = "$workingDir\teamsbootstrapper.exe"
                
                Log-Message "Downloading Teams Bootstrapper..." "Info"
                &$downloadWithProgress $bootstrapperURL $teamsEXE $currentIndex $totalPrograms "Microsoft Teams"
                Unblock-File -Path $teamsEXE *>&1 | Out-File -Append -FilePath $logPath
                
                &$updateLocalProgress $currentIndex $totalPrograms 80 "Installing: Microsoft Teams (80%)"
                $teamsProc = Start-Process -FilePath "$teamsEXE" -ArgumentList "-p" -PassThru -WindowStyle Hidden
                while (-not $teamsProc.HasExited) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 50 }

                Log-Message "Microsoft Teams: Install completed." "Success"
            } catch {
                Log-Message "Microsoft Teams installation failed." "Error"
            }
        } elseif ($program -ne $null) {
            Log-Message "Installing $($program.Name)..." "Info"
            &$updateLocalProgress $currentIndex $totalPrograms 0 "Installing: $($program.Name)..."
            
            try {
                $procInfo = New-Object System.Diagnostics.ProcessStartInfo
                $procInfo.FileName = "winget.exe"
                $procInfo.Arguments = "install -e --id `"$($program.WingetID)`" --disable-interactivity --scope machine --accept-package-agreements --accept-source-agreements --source winget"
                $procInfo.RedirectStandardOutput = $true
                $procInfo.UseShellExecute = $false
                $procInfo.CreateNoWindow = $true
                $procInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8

                $proc = New-Object System.Diagnostics.Process
                $proc.StartInfo = $procInfo
                $proc.Start() | Out-Null

                $buffer = ""
                while (-not $proc.HasExited) {
                    while ($proc.StandardOutput.Peek() -gt -1) {
                        $char = [char]$proc.StandardOutput.Read()
                        $buffer += $char
                        if ($char -eq "`r" -or $char -eq "`n" -or $char -eq "%") {
                            if ($buffer -match "(\d{1,3})\s*%") {
                                $pct = [int]$matches[1]
                                if ($pct -le 100) { 
                                    &$updateLocalProgress $currentIndex $totalPrograms $pct "Installing: $($program.Name) ($pct%)" 
                                }
                            }
                            if ($char -ne "%") { $buffer = "" }
                        }
                    }
                    [System.Windows.Forms.Application]::DoEvents()
                    Start-Sleep -Milliseconds 30
                }
                
                while ($proc.StandardOutput.Peek() -gt -1) { $null = $proc.StandardOutput.Read() }
                $proc.WaitForExit()
                
                if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
                    Log-Message "$($program.Name): Installed successfully." "Success"
                    Start-Sleep -Seconds 1
                } else {
                    Log-Message "$($program.Name): Installation failed with exit code $($proc.ExitCode)." "Error"
                    $failedWinget += $program.Name
                    Get-Process -Name "msiexec" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue *>&1 | Out-File -Append -FilePath $logPath
                }
            } catch {
                Log-Message "$($program.Name): Installation failed. Error: $_" "Error"
            }
        }
        
        # Advance segment mapping to force it to 100% completion before moving index
        &$updateLocalProgress $currentIndex $totalPrograms 100 "Finished: $($program.Name)"
        $currentIndex++
    }

    if ($failedWinget.Count -gt 0) {
        Log-Message "Retrying failed programs..." "Info"
        Get-Process -Name "winget" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue *>&1 | Out-File -Append -FilePath $logPath
        Get-Process -Name "msiexec" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue *>&1 | Out-File -Append -FilePath $logPath
        Start-Sleep -Seconds 1
        
        $retryTotal = $failedWinget.Count
        $retryIndex = 0
        $fillPanel.Width = 0

        foreach ($programName in $failedWinget) {
            $program = $programs | Where-Object { $_.Name -eq $programName }
            if ($program -ne $null) {
                Log-Message "(Retrying) Installing $($program.Name)..." "Info"
                &$updateLocalProgress $retryIndex $retryTotal 0 "(Retrying) Installing: $($program.Name)..."
                
                try {
                    $procInfo = New-Object System.Diagnostics.ProcessStartInfo
                    $procInfo.FileName = "winget.exe"
                    $procInfo.Arguments = "install -e --id `"$($program.WingetID)`" --disable-interactivity --scope machine --accept-package-agreements --accept-source-agreements"
                    $procInfo.RedirectStandardOutput = $true
                    $procInfo.UseShellExecute = $false
                    $procInfo.CreateNoWindow = $true

                    $proc = New-Object System.Diagnostics.Process
                    $proc.StartInfo = $procInfo
                    $proc.Start() | Out-Null

                    $buffer = ""
                    while (-not $proc.HasExited) {
                        while ($proc.StandardOutput.Peek() -gt -1) {
                            $char = [char]$proc.StandardOutput.Read()
                            $buffer += $char
                            if ($char -eq "`r" -or $char -eq "`n" -or $char -eq "%") {
                                if ($buffer -match "(\d{1,3})\s*%") {
                                    $pct = [int]$matches[1]
                                    if ($pct -le 100) { 
                                        &$updateLocalProgress $retryIndex $retryTotal $pct "(Retrying) $($program.Name) ($pct%)"
                                    }
                                }
                                if ($char -ne "%") { $buffer = "" }
                            }
                        }
                        [System.Windows.Forms.Application]::DoEvents()
                        Start-Sleep -Milliseconds 30
                    }
                    $proc.WaitForExit()

                    if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010) {
                        Log-Message "$($program.Name): Installed successfully." "Success"
                    } else {
                        Log-Message "$($program.Name): Installation failed again with exit code $($proc.ExitCode)." "Error"
                    }
                } catch {
                    Log-Message "$($program.Name): Installation failed. Error: $_" "Error"
                }
            }
            &$updateLocalProgress $retryIndex $retryTotal 100 "Finished: $($program.Name)"
            $retryIndex++
        }
    }

    $form.Close()
})

$form.ShowDialog() | Out-Null