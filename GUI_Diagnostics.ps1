# GUI Diagnostics & Standalone Tools - Tyler Hatfield - v2.30

# ==============================================================================
# 1. Command Runner Dialog (DISM, SFC, ChkDsk, NetFx3)
# ==============================================================================
function Show-CommandRunnerDialog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [Parameter(Mandatory = $true)]
        [string]$CommandName,
        [string]$Arguments = "",
        [string]$Description = "",
        [switch]$IsPowerShellScript
    )

    $runnerForm = New-Object System.Windows.Forms.Form
    $runnerForm.Text = $Title
    $runnerForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $runnerForm.ClientSize = New-Object System.Drawing.Size(700, 480)
    $runnerForm.StartPosition = 'CenterScreen'
    if ($HMTIcon) { $runnerForm.Icon = $HMTIcon }
    $runnerForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $runnerForm.MaximizeBox = $false
    $runnerForm.MinimizeBox = $true
    $runnerForm.ShowInTaskbar = $true
    $runnerForm.Font = $font
    $runnerForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $runnerForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $runnerForm

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = $Title
    $lblTitle.Font = New-Object System.Drawing.Font($font.FontFamily, 14, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblTitle.Location = New-Object System.Drawing.Point(20, 12)
    $lblTitle.AutoSize = $true
    $runnerForm.Controls.Add($lblTitle)

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text = if ($Description) { "$Description (Starting...)" } else { "Executing command..." }
    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $lblStatus.Location = New-Object System.Drawing.Point(20, 36)
    $lblStatus.Size = New-Object System.Drawing.Size(660, 20)
    $lblStatus.AutoEllipsis = $true
    $runnerForm.Controls.Add($lblStatus)

    $lblDetail = New-Object System.Windows.Forms.Label
    $lblDetail.Text = "Initializing diagnostic process..."
    $lblDetail.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblDetail.Font = New-Object System.Drawing.Font($font.FontFamily, 10, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $lblDetail.Location = New-Object System.Drawing.Point(20, 58)
    $lblDetail.Size = New-Object System.Drawing.Size(660, 18)
    $lblDetail.AutoEllipsis = $true
    $runnerForm.Controls.Add($lblDetail)

    $pBar = New-Object System.Windows.Forms.ProgressBar
    $pBar.Location = New-Object System.Drawing.Point(20, 80)
    $pBar.Size = New-Object System.Drawing.Size(660, 10)
    $pBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
    $pBar.MarqueeAnimationSpeed = 30
    $pBar.Minimum = 0
    $pBar.Maximum = 100
    $runnerForm.Controls.Add($pBar)

    $txtOutput = New-Object System.Windows.Forms.TextBox
    $txtOutput.Location = New-Object System.Drawing.Point(20, 98)
    $txtOutput.Size = New-Object System.Drawing.Size(660, 312)
    $txtOutput.Multiline = $true
    $txtOutput.ReadOnly = $true
    $txtOutput.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $txtOutput.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1f22")
    $txtOutput.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtOutput.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $runnerForm.Controls.Add($txtOutput)

    $btnCopy = New-Object System.Windows.Forms.Button
    $btnCopy.Text = "Copy Output"
    $btnCopy.Location = New-Object System.Drawing.Point(20, 424)
    $btnCopy.Size = New-Object System.Drawing.Size(120, 36)
    $btnCopy.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnCopy.FlatStyle = 'Flat'
    $btnCopy.FlatAppearance.BorderSize = 1
    $btnCopy.Enabled = $false
    $runnerForm.Controls.Add($btnCopy)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(445, 424)
    $btnCancel.Size = New-Object System.Drawing.Size(110, 36)
    $btnCancel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnCancel.FlatStyle = 'Flat'
    $btnCancel.FlatAppearance.BorderSize = 1
    $runnerForm.Controls.Add($btnCancel)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Location = New-Object System.Drawing.Point(570, 424)
    $btnClose.Size = New-Object System.Drawing.Size(110, 36)
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $btnClose.Enabled = $false
    $runnerForm.Controls.Add($btnClose)

    $script:runnerProc = $null
    $script:runnerCancelled = $false
    $script:cmdStopwatch = $null
    $script:chkdskStage = 1
    $script:chkdskTotal = 3
    $script:lastProgressPct = 0

    $btnCopy.Add_Click({
        if ($txtOutput.Text) {
            [System.Windows.Forms.Clipboard]::SetText($txtOutput.Text)
            PopupError "Output copied to clipboard." "Information"
        }
    })

    $btnCancel.Add_Click({
        $script:runnerCancelled = $true
        if ($script:runnerProc -and -not $script:runnerProc.HasExited) {
            try { $script:runnerProc.Kill() } catch {}
        }
        $lblStatus.Text = "Cancelled by user."
        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
        $lblDetail.Text = "Execution aborted."
        $pBar.MarqueeAnimationSpeed = 0
        $pBar.Style = [System.Windows.Forms.ProgressBarStyle]::Blocks
        $pBar.Value = 0
        $btnCancel.Enabled = $false
        $btnClose.Enabled = $true
        $btnCopy.Enabled = $true
    })

    $btnClose.Add_Click({ $runnerForm.Close() })

    $runnerForm.Add_Load({
        Invoke-HMTScale $runnerForm
        Set-RoundedControl $btnCopy
        Set-RoundedControl $btnCancel
        Set-RoundedControl $btnClose
    })

    $runnerForm.Add_Shown({
        $script:cmdStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $lblStatus.Text = "Running diagnostic process..."
        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        if ($IsPowerShellScript) {
            $psi.FileName = "powershell.exe"
            $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$Arguments`""
        } else {
            $psi.FileName = $CommandName
            $psi.Arguments = $Arguments
        }
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $true

        $script:runnerProc = New-Object System.Diagnostics.Process
        $script:runnerProc.StartInfo = $psi

        $outputHandler = {
            param($sender, $eventArgs)
            if ($eventArgs.Data) {
                $line = $eventArgs.Data
                $txtOutput.Invoke([action]{
                    $txtOutput.AppendText($line + "`r`n")
                    $txtOutput.SelectionStart = $txtOutput.Text.Length
                    $txtOutput.ScrollToCaret()

                    $elapsed = if ($script:cmdStopwatch) { $script:cmdStopwatch.Elapsed } else { [timespan]::Zero }
                    $elapsedStr = "{0:D2}:{1:D2}" -f [int]$elapsed.TotalMinutes, $elapsed.Seconds

                    # --- 1. SFC Parsing ---
                    if ($line -match 'Verification\s+(\d+)%\s+complete') {
                        $pct = [int]$matches[1]
                        $script:lastProgressPct = $pct
                        $pBar.Style = [System.Windows.Forms.ProgressBarStyle]::Blocks
                        $pBar.Value = [math]::Max(0, [math]::Min(100, $pct))
                        
                        $etaStr = "Estimating..."
                        if ($pct -gt 2 -and $elapsed.TotalSeconds -gt 4) {
                            $rate = $pct / $elapsed.TotalSeconds
                            $remSec = [int]((100 - $pct) / $rate)
                            $etaStr = if ($remSec -ge 60) { "~{0}m {1}s" -f [int]($remSec / 60), ($remSec % 60) } else { "~{0}s" -f $remSec }
                        }
                        $lblStatus.Text = "Scanning and verifying system files ($pct% complete)..."
                        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
                        $lblDetail.Text = "Verification: $pct% | Elapsed: $elapsedStr | Est. Remaining: $etaStr"
                    }
                    elseif ($line -match 'Beginning system scan') {
                        $lblStatus.Text = "Initializing system scan and verification..."
                        $lblDetail.Text = "Elapsed: $elapsedStr | Preparing verification phase"
                    }
                    elseif ($line -match 'Beginning verification phase') {
                        $lblStatus.Text = "Scanning protected Windows system files..."
                        $lblDetail.Text = "Elapsed: $elapsedStr | Verifying component integrity"
                    }
                    elseif ($line -match 'did not find any integrity violations') {
                        $lblStatus.Text = "Verification Complete: No integrity violations found."
                        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                        $lblDetail.Text = "Elapsed: $elapsedStr | System files are healthy."
                    }
                    elseif ($line -match 'found corrupt files and successfully repaired them') {
                        $lblStatus.Text = "Verification Complete: Corrupted files found and successfully repaired."
                        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                        $lblDetail.Text = "Elapsed: $elapsedStr | Repairs applied successfully."
                    }
                    elseif ($line -match 'found corrupt files but was unable to fix some') {
                        $lblStatus.Text = "Corrupted files found that could not all be repaired."
                        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
                        $lblDetail.Text = "Elapsed: $elapsedStr | Check CBS.log for details."
                    }

                    # --- 2. DISM & .NET 3.5 Feature Parsing ---
                    elseif ($line -match '\[\s*={0,}\s*(\d+(?:\.\d+)?)%\s*={0,}\s*\]' -or $line -match '(\d+(?:\.\d+)?)%\s*$') {
                        $pctFloat = [double]$matches[1]
                        $pct = [int]$pctFloat
                        $script:lastProgressPct = $pct
                        $pBar.Style = [System.Windows.Forms.ProgressBarStyle]::Blocks
                        $pBar.Value = [math]::Max(0, [math]::Min(100, $pct))

                        $etaStr = "Estimating..."
                        if ($pct -gt 5 -and $elapsed.TotalSeconds -gt 5) {
                            $rate = $pct / $elapsed.TotalSeconds
                            $remSec = [int]((100 - $pct) / $rate)
                            $etaStr = if ($remSec -ge 60) { "~{0}m {1}s" -f [int]($remSec / 60), ($remSec % 60) } else { "~{0}s" -f $remSec }
                        }

                        $phaseText = "Processing component store..."
                        if ($pctFloat -lt 20.0) {
                            $phaseText = "Phase 1/3: Initializing & scanning component store integrity..."
                        } elseif ($pctFloat -lt 80.0) {
                            $phaseText = "Phase 2/3: Checking corruption & downloading repair payloads from Windows Update..."
                        } elseif ($pctFloat -lt 100.0) {
                            $phaseText = "Phase 3/3: Applying component repairs to Windows image..."
                        } else {
                            $phaseText = "Finalizing component store operations..."
                        }

                        $lblStatus.Text = $phaseText
                        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
                        $lblDetail.Text = "Progress: $pctFloat% | Elapsed: $elapsedStr | Est. Remaining: $etaStr"
                    }
                    elseif ($line -match 'The restore operation completed successfully|The operation completed successfully') {
                        $lblStatus.Text = "Operation completed successfully."
                        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                        $lblDetail.Text = "Elapsed: $elapsedStr | Image health restored."
                    }
                    elseif ($line -match 'No component store corruption detected') {
                        $lblStatus.Text = "No component store corruption detected."
                        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                        $lblDetail.Text = "Elapsed: $elapsedStr | Image is healthy."
                    }

                    # --- 3. CHKDSK Parsing ---
                    elseif ($line -match 'Stage\s+(\d+)\s*(?:of\s*(\d+))?:\s*([^\r\n.]+)') {
                        $stg = $matches[1]
                        $stgTot = if ($matches[2]) { $matches[2] } else { "3" }
                        $stgDesc = $matches[3].Trim()
                        $script:chkdskStage = [int]$stg
                        $script:chkdskTotal = [int]$stgTot
                        $lblStatus.Text = "Stage $stg of $($stgTot): $stgDesc..."
                        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
                        $lblDetail.Text = "Elapsed: $elapsedStr | Analyzing volume structure"
                    }
                    elseif ($line -match '(\d+)\s*(?:percent|%)\s*complete') {
                        $stgPct = [int]$matches[1]
                        $stg = if ($script:chkdskStage) { $script:chkdskStage } else { 1 }
                        $stgTot = if ($script:chkdskTotal) { $script:chkdskTotal } else { 3 }
                        $overallPct = [int]((($stg - 1) * (100 / $stgTot)) + ($stgPct / $stgTot))
                        $pBar.Style = [System.Windows.Forms.ProgressBarStyle]::Blocks
                        $pBar.Value = [math]::Max(0, [math]::Min(100, $overallPct))
                        $lblDetail.Text = "Stage $stg/$($stgTot): $stgPct% (Overall: ~$overallPct%) | Elapsed: $elapsedStr"
                    }
                    elseif ($line -match 'The type of the file system is\s+(\w+)') {
                        $lblDetail.Text = "File System: $($matches[1]) | Initializing scan..."
                    }
                    elseif ($line -match 'Windows has scanned the file system and found no problems') {
                        $lblStatus.Text = "Check Disk Complete: No problems found."
                        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                        $lblDetail.Text = "Elapsed: $elapsedStr | File system is clean."
                    }
                })
            }
        }

        $script:runnerProc.add_OutputDataReceived($outputHandler)
        $script:runnerProc.add_ErrorDataReceived($outputHandler)

        try {
            $script:runnerProc.Start() | Out-Null
            $script:runnerProc.BeginOutputReadLine()
            $script:runnerProc.BeginErrorReadLine()

            while (-not $script:runnerProc.HasExited) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 80
                if ($script:runnerCancelled) { break }
            }

            if (-not $script:runnerCancelled) {
                $script:runnerProc.WaitForExit()
                $pBar.MarqueeAnimationSpeed = 0
                $pBar.Style = [System.Windows.Forms.ProgressBarStyle]::Blocks
                $pBar.Value = 100
                $elapsed = if ($script:cmdStopwatch) { $script:cmdStopwatch.Elapsed } else { [timespan]::Zero }
                $elapsedStr = "{0:D2}:{1:D2}" -f [int]$elapsed.TotalMinutes, $elapsed.Seconds

                if ($script:runnerProc.ExitCode -eq 0) {
                    $lblStatus.Text = "Completed successfully (Exit code: 0)."
                    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                    $lblDetail.Text = "Total Execution Time: $elapsedStr | Success"
                } else {
                    $lblStatus.Text = "Finished with exit code $($script:runnerProc.ExitCode)."
                    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
                    $lblDetail.Text = "Total Execution Time: $elapsedStr | Check log output above."
                }
            }
        } catch {
            $lblStatus.Text = "Execution failed: $_"
            $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
            $txtOutput.AppendText("`r`nError starting process: $_`r`n")
        } finally {
            $btnCancel.Enabled = $false
            $btnClose.Enabled = $true
            $btnCopy.Enabled = $true
            if ($script:runnerProc) { $script:runnerProc.Dispose() }
        }
    })

    Show-HMTDialog $runnerForm | Out-Null
}

# ==============================================================================
# 2. Internet Speed Test Dialog (Cloudflare Anycast + Smooth GDI+ Graph)
# ==============================================================================
function Show-SpeedTestDialog {
    $stForm = New-Object System.Windows.Forms.Form
    $stForm.Text = "Internet Speed Test"
    $stForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $stForm.ClientSize = New-Object System.Drawing.Size(680, 500)
    $stForm.StartPosition = 'CenterScreen'
    if ($HMTIcon) { $stForm.Icon = $HMTIcon }
    $stForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $stForm.MaximizeBox = $false
    $stForm.MinimizeBox = $true
    $stForm.ShowInTaskbar = $true
    $stForm.Font = $font
    $stForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $stForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $stForm

    # Header / Server details
    $lblServer = New-Object System.Windows.Forms.Label
    $lblServer.Text = "Server: Cloudflare Edge Anycast (Detecting nearest datacenter...)"
    $lblServer.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblServer.Location = New-Object System.Drawing.Point(20, 15)
    $lblServer.Size = New-Object System.Drawing.Size(640, 20)
    $lblServer.AutoEllipsis = $true
    $stForm.Controls.Add($lblServer)

    # 4 Metric Cards Panel
    $cardPanel = New-Object System.Windows.Forms.Panel
    $cardPanel.Location = New-Object System.Drawing.Point(20, 42)
    $cardPanel.Size = New-Object System.Drawing.Size(640, 80)
    $cardPanel.BackColor = [System.Drawing.Color]::Transparent
    $stForm.Controls.Add($cardPanel)

    $createCard = {
        param($title, $initialVal, $left, $width)
        $p = New-Object System.Windows.Forms.Panel
        $p.Location = New-Object System.Drawing.Point($left, 0)
        $p.Size = New-Object System.Drawing.Size($width, 80)
        $p.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
        $p.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $cardPanel.Controls.Add($p)

        $lTitle = New-Object System.Windows.Forms.Label
        $lTitle.Text = $title
        $lTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
        $lTitle.Location = New-Object System.Drawing.Point(0, 8)
        $lTitle.Size = New-Object System.Drawing.Size($width, 18)
        $lTitle.TextAlign = 'MiddleCenter'
        $p.Controls.Add($lTitle)

        $lVal = New-Object System.Windows.Forms.Label
        $lVal.Text = $initialVal
        $lVal.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $lVal.Font = New-Object System.Drawing.Font($font.FontFamily, 16, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $lVal.Location = New-Object System.Drawing.Point(0, 30)
        $lVal.Size = New-Object System.Drawing.Size($width, 30)
        $lVal.TextAlign = 'MiddleCenter'
        $p.Controls.Add($lVal)

        return $lVal
    }

    $valPing = &$createCard "PING" "-- ms" 0 152
    $valJitter = &$createCard "JITTER" "-- ms" 162 152
    $valDownload = &$createCard "DOWNLOAD" "-- Mbps" 324 152
    $valUpload = &$createCard "UPLOAD" "-- Mbps" 486 152

    # Status / Phase Indicator
    $lblCurrentPhase = New-Object System.Windows.Forms.Label
    $lblCurrentPhase.Text = "Ready to test"
    $lblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblCurrentPhase.Font = New-Object System.Drawing.Font($font.FontFamily, 12, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $lblCurrentPhase.Location = New-Object System.Drawing.Point(20, 130)
    $lblCurrentPhase.Size = New-Object System.Drawing.Size(640, 20)
    $lblCurrentPhase.TextAlign = 'MiddleCenter'
    $stForm.Controls.Add($lblCurrentPhase)

    # Smooth GDI+ Double-Buffered Graph
    $smoothChart = New-Object HMT.Tools.SmoothGraphControl
    $smoothChart.Location = New-Object System.Drawing.Point(20, 155)
    $smoothChart.Size = New-Object System.Drawing.Size(640, 220)
    $smoothChart.UnitLabel = "Mbps"
    $smoothChart.LineColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $smoothChart.MaxPoints = 80
    $stForm.Controls.Add($smoothChart)

    # Settings Row
    $yBot = 390
    $lblStreams = New-Object System.Windows.Forms.Label
    $lblStreams.Text = "Streams:"
    $lblStreams.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblStreams.Location = New-Object System.Drawing.Point(20, ($yBot + 6))
    $lblStreams.AutoSize = $true
    $stForm.Controls.Add($lblStreams)

    $cmbStreams = New-Object System.Windows.Forms.ComboBox
    $cmbStreams.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbStreams.Items.AddRange(@("2 Streams", "4 Streams (Recommended)", "8 Streams", "16 Streams (Gigabit+)"))
    $cmbStreams.SelectedIndex = 1
    $cmbStreams.Location = New-Object System.Drawing.Point(85, $yBot)
    $cmbStreams.Size = New-Object System.Drawing.Size(200, 26)
    $cmbStreams.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $cmbStreams.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $stForm.Controls.Add($cmbStreams)

    # Buttons
    $btnStart = New-Object System.Windows.Forms.Button
    $btnStart.Text = "Start Test"
    $btnStart.Location = New-Object System.Drawing.Point(415, ($yBot - 2))
    $btnStart.Size = New-Object System.Drawing.Size(120, 36)
    $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnStart.FlatStyle = 'Flat'
    $btnStart.FlatAppearance.BorderSize = 1
    $stForm.Controls.Add($btnStart)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Location = New-Object System.Drawing.Point(545, ($yBot - 2))
    $btnClose.Size = New-Object System.Drawing.Size(115, 36)
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $stForm.Controls.Add($btnClose)

    $script:stRunning = $false
    $script:stEngine = New-Object HMT.Tools.FastSpeedTestEngine

    # Server Location Detection
    $detectServer = {
        try {
            $trace = Invoke-WebRequest -Uri "https://speed.cloudflare.com/meta" -UseBasicParsing -TimeoutSec 4 -ErrorAction Stop
            $json = $trace.Content | ConvertFrom-Json
            if ($json.city -and $json.country) {
                $lblServer.Text = "Server: Cloudflare Edge - $($json.city), $($json.country) (Colo: $($json.colo)) | IP: $($json.clientIp)"
            }
        } catch {
            $lblServer.Text = "Server: Cloudflare Anycast Edge Network (Global CDN)"
        }
    }

    $btnStart.Add_Click({
        if ($script:stRunning) {
            $script:stEngine.Cancel()
            $script:stRunning = $false
            $btnStart.Text = "Start Test"
            $lblCurrentPhase.Text = "Test cancelled."
            $lblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
            $cmbStreams.Enabled = $true
            $btnClose.Enabled = $true
            return
        }

        $script:stRunning = $true
        $btnStart.Text = "Cancel Test"
        $cmbStreams.Enabled = $false
        $btnClose.Enabled = $false
        $smoothChart.Clear()

        $streamCount = switch ($cmbStreams.SelectedIndex) {
            0 { 2 }
            1 { 4 }
            2 { 8 }
            3 { 16 }
            Default { 4 }
        }

        # --- Phase 1: Ping & Jitter ---
        $lblCurrentPhase.Text = "Testing Latency & Jitter (Cloudflare Anycast)..."
        $lblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
        $valPing.Text = "-- ms"
        $valJitter.Text = "-- ms"
        $valDownload.Text = "-- Mbps"
        $valUpload.Text = "-- Mbps"
        [System.Windows.Forms.Application]::DoEvents()

        $pingSender = New-Object System.Net.NetworkInformation.Ping
        $pings = @()
        for ($i = 0; $i -lt 10; $i++) {
            if (-not $script:stRunning) { break }
            try {
                $reply = $pingSender.Send("1.1.1.1", 1000)
                if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                    $pings += $reply.RoundtripTime
                }
            } catch {}
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 60
        }

        if ($pings.Count -gt 0) {
            $avgPing = ($pings | Measure-Object -Average).Average
            $valPing.Text = "$([math]::Round($avgPing, 1)) ms"

            # Jitter calculation
            $jitterSum = 0
            for ($j = 1; $j -lt $pings.Count; $j++) {
                $jitterSum += [math]::Abs($pings[$j] - $pings[$j - 1])
            }
            $avgJitter = $jitterSum / [math]::Max(1, ($pings.Count - 1))
            $valJitter.Text = "$([math]::Round($avgJitter, 1)) ms"
        } else {
            $valPing.Text = "N/A"
            $valJitter.Text = "N/A"
        }

        if (-not $script:stRunning) { return }

        # --- Phase 2: Download Test ---
        $lblCurrentPhase.Text = "Testing Download Speed ($streamCount streams)..."
        $lblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
        $smoothChart.LineColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")

        $dlHandler = {
            param($sample)
            $stForm.Invoke([action]{
                $smoothChart.AddPoint($sample.CurrentMbps)
                $valDownload.Text = "$([math]::Round($sample.AverageMbps, 1)) Mbps"
                $lblCurrentPhase.Text = "Downloading ($([math]::Round($sample.CurrentMbps, 1)) Mbps) | Total: $([math]::Round($sample.TotalBytesTransferred / 1MB, 1)) MB"
            })
        }
        $script:stEngine.add_OnSpeedSample($dlHandler)

        $downUrl = "https://speed.cloudflare.com/__down?bytes=50000000"
        $asyncDl = [System.Threading.Tasks.Task]::Run([Func[HMT.Tools.SpeedSample]]{
            $script:stEngine.RunDownloadTest($downUrl, $streamCount, 9)
        })

        while (-not $asyncDl.IsCompleted) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 50
        }
        $script:stEngine.remove_OnSpeedSample($dlHandler)

        if ($asyncDl.Result) {
            $valDownload.Text = "$([math]::Round($asyncDl.Result.AverageMbps, 1)) Mbps"
        }

        if (-not $script:stRunning) { return }
        Start-Sleep -Milliseconds 400
        $smoothChart.Clear()

        # --- Phase 3: Upload Test ---
        $lblCurrentPhase.Text = "Testing Upload Speed ($streamCount streams)..."
        $lblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
        $smoothChart.LineColor = [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")

        $ulHandler = {
            param($sample)
            $stForm.Invoke([action]{
                $smoothChart.AddPoint($sample.CurrentMbps)
                $valUpload.Text = "$([math]::Round($sample.AverageMbps, 1)) Mbps"
                $lblCurrentPhase.Text = "Uploading ($([math]::Round($sample.CurrentMbps, 1)) Mbps) | Total: $([math]::Round($sample.TotalBytesTransferred / 1MB, 1)) MB"
            })
        }
        $script:stEngine.add_OnSpeedSample($ulHandler)

        $upUrl = "https://speed.cloudflare.com/__up"
        $asyncUl = [System.Threading.Tasks.Task]::Run([Func[HMT.Tools.SpeedSample]]{
            $script:stEngine.RunUploadTest($upUrl, $streamCount, 8)
        })

        while (-not $asyncUl.IsCompleted) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 50
        }
        $script:stEngine.remove_OnSpeedSample($ulHandler)

        if ($asyncUl.Result) {
            $valUpload.Text = "$([math]::Round($asyncUl.Result.AverageMbps, 1)) Mbps"
        }

        # --- Finished ---
        $script:stRunning = $false
        $btnStart.Text = "Test Again"
        $cmbStreams.Enabled = $true
        $btnClose.Enabled = $true
        $lblCurrentPhase.Text = "Speed Test Complete!"
        $lblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    })

    $btnClose.Add_Click({
        if ($script:stRunning) { $script:stEngine.Cancel() }
        $stForm.Close()
    })

    $stForm.Add_FormClosing({
        if ($script:stRunning) { $script:stEngine.Cancel() }
    })

    $stForm.Add_Load({
        Invoke-HMTScale $stForm
        Set-RoundedControl $btnStart
        Set-RoundedControl $btnClose
        [System.Threading.ThreadPool]::QueueUserWorkItem({ &$detectServer }) | Out-Null
    })

    Show-HMTDialog $stForm | Out-Null
}

# ==============================================================================
# 3. TCP Port & Connection Checker Dialog
# ==============================================================================
function Show-TcpCheckerDialog {
    $tcpForm = New-Object System.Windows.Forms.Form
    $tcpForm.Text = "TCP Port & Connection Checker"
    $tcpForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $tcpForm.ClientSize = New-Object System.Drawing.Size(650, 420)
    $tcpForm.StartPosition = 'CenterScreen'
    if ($HMTIcon) { $tcpForm.Icon = $HMTIcon }
    $tcpForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $tcpForm.MaximizeBox = $false
    $tcpForm.MinimizeBox = $true
    $tcpForm.ShowInTaskbar = $true
    $tcpForm.Font = $font
    $tcpForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $tcpForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $tcpForm

    $y = 15
    $lblHost = New-Object System.Windows.Forms.Label
    $lblHost.Text = "Target Host / IP:"
    $lblHost.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblHost.Location = New-Object System.Drawing.Point(20, $y)
    $lblHost.AutoSize = $true
    $tcpForm.Controls.Add($lblHost)

    $txtHost = New-Object System.Windows.Forms.TextBox
    $txtHost.Location = New-Object System.Drawing.Point(140, ($y - 3))
    $txtHost.Size = New-Object System.Drawing.Size(220, 25)
    $txtHost.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtHost.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtHost.Text = "1.1.1.1"
    $tcpForm.Controls.Add($txtHost)

    $lblPort = New-Object System.Windows.Forms.Label
    $lblPort.Text = "Port:"
    $lblPort.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblPort.Location = New-Object System.Drawing.Point(375, $y)
    $lblPort.AutoSize = $true
    $tcpForm.Controls.Add($lblPort)

    $txtPort = New-Object System.Windows.Forms.TextBox
    $txtPort.Location = New-Object System.Drawing.Point(420, ($y - 3))
    $txtPort.Size = New-Object System.Drawing.Size(75, 25)
    $txtPort.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtPort.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtPort.Text = "53"
    $tcpForm.Controls.Add($txtPort)

    $btnCheck = New-Object System.Windows.Forms.Button
    $btnCheck.Location = New-Object System.Drawing.Point(515, ($y - 5))
    $btnCheck.Size = New-Object System.Drawing.Size(115, 30)
    $btnCheck.Text = "Test Port"
    $btnCheck.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnCheck.FlatStyle = 'Flat'
    $btnCheck.FlatAppearance.BorderSize = 1
    $tcpForm.Controls.Add($btnCheck)

    $y += 42
    $lblRes = New-Object System.Windows.Forms.Label
    $lblRes.Text = "Results & Connection Log:"
    $lblRes.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblRes.Location = New-Object System.Drawing.Point(20, $y)
    $lblRes.AutoSize = $true
    $tcpForm.Controls.Add($lblRes)

    $y += 24
    $txtLog = New-Object System.Windows.Forms.TextBox
    $txtLog.Location = New-Object System.Drawing.Point(20, $y)
    $txtLog.Size = New-Object System.Drawing.Size(610, 240)
    $txtLog.Multiline = $true
    $txtLog.ReadOnly = $true
    $txtLog.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $txtLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1f22")
    $txtLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtLog.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $tcpForm.Controls.Add($txtLog)

    $y += 255
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point(515, $y)
    $btnClose.Size = New-Object System.Drawing.Size(115, 35)
    $btnClose.Text = "Close"
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $tcpForm.Controls.Add($btnClose)

    $btnCheck.Add_Click({
        $hostVal = $txtHost.Text.Trim()
        $portVal = 0
        if (-not [int]::TryParse($txtPort.Text.Trim(), [ref]$portVal) -or $portVal -lt 1 -or $portVal -gt 65535) {
            PopupError "Please enter a valid port number between 1 and 65535." "Warning"
            return
        }
        if ([string]::IsNullOrWhiteSpace($hostVal)) {
            PopupError "Please enter a target hostname or IP address." "Warning"
            return
        }

        $btnCheck.Enabled = $false
        $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] Testing $hostVal on TCP port $portVal...`r`n")
        [System.Windows.Forms.Application]::DoEvents()

        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $client = New-Object System.Net.Sockets.TcpClient
        $iar = $client.BeginConnect($hostVal, $portVal, $null, $null)
        $wh = $iar.AsyncWaitHandle
        $connected = $false
        try {
            $success = $wh.WaitOne(3000, $false)
            if ($success) {
                $client.EndConnect($iar)
                $connected = $true
            }
        } catch {}
        finally {
            $sw.Stop()
            $client.Close()
            $wh.Close()
        }

        if ($connected) {
            $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] SUCCESS: Port $portVal is OPEN! (Latency: $($sw.ElapsedMilliseconds) ms)`r`n`r`n")
        } else {
            $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] FAILED: Port $portVal is CLOSED or filtered / unreachable.`r`n`r`n")
        }
        $txtLog.SelectionStart = $txtLog.Text.Length
        $txtLog.ScrollToCaret()
        $btnCheck.Enabled = $true
    })

    $btnClose.Add_Click({ $tcpForm.Close() })

    $tcpForm.Add_Load({
        Invoke-HMTScale $tcpForm
        Set-RoundedControl $btnCheck
        Set-RoundedControl $btnClose
    })

    Show-HMTDialog $tcpForm | Out-Null
}

# ==============================================================================
# 4. Storage SMART Health & Benchmark Dashboard (Revamped)
# ==============================================================================
function Show-StorageHealthDialog {
    $shForm = New-Object System.Windows.Forms.Form
    $shForm.Text = "Storage SMART Health & Benchmark Dashboard"
    $shForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $shForm.ClientSize = New-Object System.Drawing.Size(840, 560)
    $shForm.StartPosition = 'CenterScreen'
    if ($HMTIcon) { $shForm.Icon = $HMTIcon }
    $shForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $shForm.MaximizeBox = $false
    $shForm.MinimizeBox = $true
    $shForm.ShowInTaskbar = $true
    $shForm.Font = $font
    $shForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $shForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $shForm

    # Header / Drive Selector
    $lblSelDrive = New-Object System.Windows.Forms.Label
    $lblSelDrive.Text = "Target Storage Drive:"
    $lblSelDrive.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblSelDrive.Location = New-Object System.Drawing.Point(20, 15)
    $lblSelDrive.AutoSize = $true
    $shForm.Controls.Add($lblSelDrive)

    $cmbDrives = New-Object System.Windows.Forms.ComboBox
    $cmbDrives.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbDrives.Location = New-Object System.Drawing.Point(160, 11)
    $cmbDrives.Size = New-Object System.Drawing.Size(530, 26)
    $cmbDrives.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $cmbDrives.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $shForm.Controls.Add($cmbDrives)

    $btnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh.Text = "Refresh"
    $btnRefresh.Location = New-Object System.Drawing.Point(705, 9)
    $btnRefresh.Size = New-Object System.Drawing.Size(115, 30)
    $btnRefresh.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnRefresh.FlatStyle = 'Flat'
    $btnRefresh.FlatAppearance.BorderSize = 1
    $shForm.Controls.Add($btnRefresh)

    # Tab Control
    $shTabs = New-Object System.Windows.Forms.TabControl
    $shTabs.Location = New-Object System.Drawing.Point(20, 48)
    $shTabs.Size = New-Object System.Drawing.Size(800, 455)
    $shTabs.Font = $font
    $shForm.Controls.Add($shTabs)

    # ---------------- TAB 1: Health & SMART Telemetry ----------------
    $tabHealth = New-Object System.Windows.Forms.TabPage("Health & SMART Telemetry")
    $tabHealth.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $shTabs.TabPages.Add($tabHealth)

    # Top Summary Card
    $cardPanel = New-Object System.Windows.Forms.Panel
    $cardPanel.Location = New-Object System.Drawing.Point(15, 12)
    $cardPanel.Size = New-Object System.Drawing.Size(765, 75)
    $cardPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $cardPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $tabHealth.Controls.Add($cardPanel)

    $lblCardModel = New-Object System.Windows.Forms.Label
    $lblCardModel.Text = "Drive: Selecting..."
    $lblCardModel.Font = New-Object System.Drawing.Font($font.FontFamily, 11, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $lblCardModel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblCardModel.Location = New-Object System.Drawing.Point(15, 10)
    $lblCardModel.Size = New-Object System.Drawing.Size(460, 22)
    $cardPanel.Controls.Add($lblCardModel)

    $lblCardBus = New-Object System.Windows.Forms.Label
    $lblCardBus.Text = "Interface: --"
    $lblCardBus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardBus.Location = New-Object System.Drawing.Point(15, 38)
    $lblCardBus.Size = New-Object System.Drawing.Size(220, 20)
    $cardPanel.Controls.Add($lblCardBus)

    $lblCardHealth = New-Object System.Windows.Forms.Label
    $lblCardHealth.Text = "Health: --"
    $lblCardHealth.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $lblCardHealth.Location = New-Object System.Drawing.Point(245, 38)
    $lblCardHealth.Size = New-Object System.Drawing.Size(220, 20)
    $cardPanel.Controls.Add($lblCardHealth)

    $lblCardWrites = New-Object System.Windows.Forms.Label
    $lblCardWrites.Text = "Total Writes: --"
    $lblCardWrites.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $lblCardWrites.Font = New-Object System.Drawing.Font($font.FontFamily, 11, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $lblCardWrites.Location = New-Object System.Drawing.Point(490, 10)
    $lblCardWrites.Size = New-Object System.Drawing.Size(260, 22)
    $cardPanel.Controls.Add($lblCardWrites)

    $lblCardWear = New-Object System.Windows.Forms.Label
    $lblCardWear.Text = "Wearout: --"
    $lblCardWear.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardWear.Location = New-Object System.Drawing.Point(490, 38)
    $lblCardWear.Size = New-Object System.Drawing.Size(260, 20)
    $cardPanel.Controls.Add($lblCardWear)

    # Physical Disks Table
    $shLV = New-Object System.Windows.Forms.ListView
    $shLV.Location = New-Object System.Drawing.Point(15, 98)
    $shLV.Size = New-Object System.Drawing.Size(765, 310)
    $shLV.View = [System.Windows.Forms.View]::Details
    $shLV.FullRowSelect = $true
    $shLV.GridLines = $true
    $shLV.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $shLV.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $shLV.Columns.Add("Disk #", 55) | Out-Null
    $shLV.Columns.Add("Model", 210) | Out-Null
    $shLV.Columns.Add("Bus / Type", 100) | Out-Null
    $shLV.Columns.Add("Media", 75) | Out-Null
    $shLV.Columns.Add("Size", 75) | Out-Null
    $shLV.Columns.Add("Wearout", 70) | Out-Null
    $shLV.Columns.Add("Total Writes", 95) | Out-Null
    $shLV.Columns.Add("Health", 80) | Out-Null
    [HMT.NativeMethods]::SetWindowTheme($shLV.Handle, "DarkMode_Explorer", $null) | Out-Null
    $tabHealth.Controls.Add($shLV)

    # ---------------- TAB 2: Drive Speed Benchmark ----------------
    $tabBench = New-Object System.Windows.Forms.TabPage("Drive Speed Benchmark")
    $tabBench.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $shTabs.TabPages.Add($tabBench)

    # Benchmark Controls Row
    $lblBenchTarget = New-Object System.Windows.Forms.Label
    $lblBenchTarget.Text = "Target Partition:"
    $lblBenchTarget.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblBenchTarget.Location = New-Object System.Drawing.Point(15, 15)
    $lblBenchTarget.AutoSize = $true
    $tabBench.Controls.Add($lblBenchTarget)

    $cmbBenchTarget = New-Object System.Windows.Forms.ComboBox
    $cmbBenchTarget.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbBenchTarget.Location = New-Object System.Drawing.Point(125, 11)
    $cmbBenchTarget.Size = New-Object System.Drawing.Size(150, 26)
    $cmbBenchTarget.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $cmbBenchTarget.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $tabBench.Controls.Add($cmbBenchTarget)

    $lblBenchSize = New-Object System.Windows.Forms.Label
    $lblBenchSize.Text = "Test Size:"
    $lblBenchSize.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblBenchSize.Location = New-Object System.Drawing.Point(290, 15)
    $lblBenchSize.AutoSize = $true
    $tabBench.Controls.Add($lblBenchSize)

    $cmbBenchSize = New-Object System.Windows.Forms.ComboBox
    $cmbBenchSize.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbBenchSize.Items.AddRange(@("100 MB (Quick)", "250 MB (Standard)", "500 MB (Thorough)", "1 GB (Extended)"))
    $cmbBenchSize.SelectedIndex = 1
    $cmbBenchSize.Location = New-Object System.Drawing.Point(360, 11)
    $cmbBenchSize.Size = New-Object System.Drawing.Size(160, 26)
    $cmbBenchSize.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $cmbBenchSize.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $tabBench.Controls.Add($cmbBenchSize)

    $btnBenchStart = New-Object System.Windows.Forms.Button
    $btnBenchStart.Text = "Start Benchmark"
    $btnBenchStart.Location = New-Object System.Drawing.Point(540, 9)
    $btnBenchStart.Size = New-Object System.Drawing.Size(130, 30)
    $btnBenchStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $btnBenchStart.FlatStyle = 'Flat'
    $btnBenchStart.FlatAppearance.BorderSize = 1
    $tabBench.Controls.Add($btnBenchStart)

    $btnBenchCancel = New-Object System.Windows.Forms.Button
    $btnBenchCancel.Text = "Cancel"
    $btnBenchCancel.Location = New-Object System.Drawing.Point(680, 9)
    $btnBenchCancel.Size = New-Object System.Drawing.Size(100, 30)
    $btnBenchCancel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnBenchCancel.FlatStyle = 'Flat'
    $btnBenchCancel.FlatAppearance.BorderSize = 1
    $btnBenchCancel.Enabled = $false
    $tabBench.Controls.Add($btnBenchCancel)

    # 4 Scorecards
    $scorePanel = New-Object System.Windows.Forms.Panel
    $scorePanel.Location = New-Object System.Drawing.Point(15, 48)
    $scorePanel.Size = New-Object System.Drawing.Size(765, 70)
    $scorePanel.BackColor = [System.Drawing.Color]::Transparent
    $tabBench.Controls.Add($scorePanel)

    $createScoreCard = {
        param($title, $initialVal, $left, $width)
        $p = New-Object System.Windows.Forms.Panel
        $p.Location = New-Object System.Drawing.Point($left, 0)
        $p.Size = New-Object System.Drawing.Size($width, 70)
        $p.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
        $p.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $scorePanel.Controls.Add($p)

        $lTitle = New-Object System.Windows.Forms.Label
        $lTitle.Text = $title
        $lTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
        $lTitle.Location = New-Object System.Drawing.Point(0, 6)
        $lTitle.Size = New-Object System.Drawing.Size($width, 16)
        $lTitle.TextAlign = 'MiddleCenter'
        $p.Controls.Add($lTitle)

        $lVal = New-Object System.Windows.Forms.Label
        $lVal.Text = $initialVal
        $lVal.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $lVal.Font = New-Object System.Drawing.Font($font.FontFamily, 14, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $lVal.Location = New-Object System.Drawing.Point(0, 26)
        $lVal.Size = New-Object System.Drawing.Size($width, 26)
        $lVal.TextAlign = 'MiddleCenter'
        $p.Controls.Add($lVal)

        return $lVal
    }

    $valSeqRead = &$createScoreCard "SEQ READ (128K)" "-- MB/s" 0 185
    $valSeqWrite = &$createScoreCard "SEQ WRITE (128K)" "-- MB/s" 193 185
    $valRandRead = &$createScoreCard "RANDOM 4K READ" "-- IOPS" 386 185
    $valRandWrite = &$createScoreCard "RANDOM 4K WRITE" "-- IOPS" 580 185

    # Benchmark Progress & Real-time Graph
    $lblBenchStatus = New-Object System.Windows.Forms.Label
    $lblBenchStatus.Text = "Ready to benchmark selected drive."
    $lblBenchStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblBenchStatus.Location = New-Object System.Drawing.Point(15, 125)
    $lblBenchStatus.Size = New-Object System.Drawing.Size(765, 18)
    $tabBench.Controls.Add($lblBenchStatus)

    $benchProgressBar = New-Object System.Windows.Forms.ProgressBar
    $benchProgressBar.Location = New-Object System.Drawing.Point(15, 146)
    $benchProgressBar.Size = New-Object System.Drawing.Size(765, 8)
    $benchProgressBar.Minimum = 0
    $benchProgressBar.Maximum = 100
    $benchProgressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Blocks
    $tabBench.Controls.Add($benchProgressBar)

    $benchGraph = New-Object HMT.Tools.SmoothGraphControl
    $benchGraph.Location = New-Object System.Drawing.Point(15, 160)
    $benchGraph.Size = New-Object System.Drawing.Size(765, 245)
    $benchGraph.UnitLabel = "MB/s"
    $benchGraph.LineColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $tabBench.Controls.Add($benchGraph)

    # Bottom Close Button
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point(705, 512)
    $btnClose.Size = New-Object System.Drawing.Size(115, 36)
    $btnClose.Text = "Close"
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $shForm.Controls.Add($btnClose)

    $script:diskListCache = @()
    $script:benchEngine = New-Object HMT.Tools.DiskBenchmarkEngine

    # Drive Population Logic
    $populateDisks = {
        $shLV.Items.Clear()
        $cmbDrives.Items.Clear()
        $cmbBenchTarget.Items.Clear()
        $script:diskListCache = @()

        # Populate logical partition benchmark targets
        $logDrives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -gt 0 }
        foreach ($ld in $logDrives) {
            $freeGb = [math]::Round($ld.Free / 1GB, 1)
            $cmbBenchTarget.Items.Add("$($ld.Name):\ ($freeGb GB Free)") | Out-Null
        }
        if ($cmbBenchTarget.Items.Count -gt 0) { $cmbBenchTarget.SelectedIndex = 0 }

        try {
            $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue

            # Pre-query WMI SMART data for SATA Attribute 241 fallback
            $wmiSmart = @{}
            try {
                $smartObjects = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_ATAPISmartData -ErrorAction SilentlyContinue
                if ($smartObjects) {
                    foreach ($so in $smartObjects) {
                        $instName = $so.InstanceName
                        if ($so.VendorSpecific -and $so.VendorSpecific.Length -ge 362) {
                            for ($idx = 2; $idx -le 350; $idx += 12) {
                                $attrId = $so.VendorSpecific[$idx]
                                if ($attrId -eq 241) {
                                    $rawVal = [BitConverter]::ToUInt32($so.VendorSpecific, ($idx + 5))
                                    if ($rawVal -gt 0) {
                                        $wmiSmart[$instName] = [double]$rawVal * 512.0
                                    }
                                    break
                                }
                            }
                        }
                    }
                }
            } catch {}

            if ($disks) {
                foreach ($d in $disks) {
                    $devId = [int]$d.DeviceId
                    
                    # Direct Native Win32 Descriptor Query via HMT.DriveInterop
                    $nativeDesc = $null
                    try {
                        $nativeDesc = [HMT.DriveInterop]::QueryPhysicalDriveInfo($devId)
                    } catch {}

                    $busType = if ($nativeDesc -and $nativeDesc.Success -and $nativeDesc.BusTypeName -ne "Unknown") {
                        $nativeDesc.BusTypeName
                    } elseif ($d.BusType) {
                        $d.BusType
                    } else {
                        "Disk"
                    }

                    $counter = $d | Get-StorageReliabilityCounter -ErrorAction SilentlyContinue
                    $wearStr = if ($counter -and $null -ne $counter.Wear) { "$($counter.Wear)%" } else { "N/A" }
                    $writesStr = "Unsupported"

                    $bytesWritten = $null
                    if ($counter -and $null -ne $counter.BytesWritten -and $counter.BytesWritten -gt 0) {
                        $bytesWritten = [double]$counter.BytesWritten
                    } elseif ($wmiSmart.Count -gt 0) {
                        foreach ($k in $wmiSmart.Keys) {
                            if ($k -like "*$($d.DeviceId)*" -or $k -like "*$($d.FriendlyName)*") {
                                $bytesWritten = $wmiSmart[$k]
                                break
                            }
                        }
                        if (-not $bytesWritten -and $wmiSmart.Values.Count -eq 1 -and $disks.Count -eq 1) {
                            $bytesWritten = ($wmiSmart.Values | Select-Object -First 1)
                        }
                    }

                    if ($bytesWritten -and $bytesWritten -gt 0) {
                        if ($bytesWritten -ge 1TB) {
                            $writesStr = "$([math]::Round($bytesWritten / 1TB, 1)) TB"
                        } else {
                            $writesStr = "$([math]::Round($bytesWritten / 1GB, 1)) GB"
                        }
                    }

                    $sizeGb = [math]::Round($d.Size / 1GB, 1)

                    $item = New-Object System.Windows.Forms.ListViewItem([string]$d.DeviceId)
                    $item.SubItems.Add([string]$d.FriendlyName) | Out-Null
                    $item.SubItems.Add([string]$busType) | Out-Null
                    $item.SubItems.Add([string]$d.MediaType) | Out-Null
                    $item.SubItems.Add("$sizeGb GB") | Out-Null
                    $item.SubItems.Add($wearStr) | Out-Null
                    $item.SubItems.Add($writesStr) | Out-Null
                    $item.SubItems.Add([string]$d.HealthStatus) | Out-Null
                    $shLV.Items.Add($item) | Out-Null

                    $displayStr = "Disk $($d.DeviceId): $($d.FriendlyName) [$busType $sizeGb GB] - $($d.HealthStatus)"
                    $cmbDrives.Items.Add($displayStr) | Out-Null
                    $script:diskListCache += [pscustomobject]@{
                        Model = $d.FriendlyName
                        BusType = $busType
                        MediaType = $d.MediaType
                        Size = "$sizeGb GB"
                        Wearout = $wearStr
                        Writes = $writesStr
                        Health = $d.HealthStatus
                    }
                }
            }
        } catch {}

        if ($cmbDrives.Items.Count -gt 0) { $cmbDrives.SelectedIndex = 0 }
    }

    $cmbDrives.Add_SelectedIndexChanged({
        $idx = $cmbDrives.SelectedIndex
        if ($idx -ge 0 -and $idx -lt $script:diskListCache.Count) {
            $sel = $script:diskListCache[$idx]
            $lblCardModel.Text = "Drive: $($sel.Model) ($($sel.Size))"
            $lblCardBus.Text = "Interface: $($sel.BusType) ($($sel.MediaType))"
            $lblCardHealth.Text = "Health: $($sel.Health)"
            $lblCardHealth.ForeColor = if ($sel.Health -eq 'Healthy') { [System.Drawing.ColorTranslator]::FromHtml("#57F287") } else { [System.Drawing.ColorTranslator]::FromHtml("#FEE75C") }
            $lblCardWrites.Text = "Total Writes: $($sel.Writes)"
            $lblCardWear.Text = "Wearout: $($sel.Wearout)"
        }
    })

    # Benchmark Execution
    $btnBenchStart.Add_Click({
        if ($cmbBenchTarget.SelectedIndex -lt 0) { return }
        $targetRoot = ($cmbBenchTarget.SelectedItem.ToString() -split ' ')[0]
        
        $sizeMb = switch ($cmbBenchSize.SelectedIndex) {
            0 { 100 }
            1 { 250 }
            2 { 500 }
            3 { 1000 }
            Default { 250 }
        }

        $btnBenchStart.Enabled = $false
        $btnBenchCancel.Enabled = $true
        $cmbBenchTarget.Enabled = $false
        $cmbBenchSize.Enabled = $false
        $benchGraph.Clear()
        $valSeqRead.Text = "-- MB/s"
        $valSeqWrite.Text = "-- MB/s"
        $valRandRead.Text = "-- IOPS"
        $valRandWrite.Text = "-- IOPS"

        $progHandler = {
            param($p)
            $shForm.Invoke([action]{
                $benchProgressBar.Value = [math]::Max(0, [math]::Min(100, [int]$p.ProgressPercent))
                $lblBenchStatus.Text = "$($p.CurrentTest)... $([math]::Round($p.CurrentSpeedMBs, 1)) MB/s"
                if ($p.CurrentSpeedMBs -gt 0) {
                    $benchGraph.AddPoint($p.CurrentSpeedMBs)
                }
            })
        }
        $script:benchEngine.add_OnProgress($progHandler)

        $asyncBench = [System.Threading.Tasks.Task]::Run([Func[HMT.Tools.BenchmarkResult]]{
            $script:benchEngine.RunBenchmark($targetRoot, $sizeMb)
        })

        while (-not $asyncBench.IsCompleted) {
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 50
        }
        $script:benchEngine.remove_OnProgress($progHandler)

        $res = $asyncBench.Result
        if ($res -and $res.Success) {
            $valSeqRead.Text = "$([math]::Round($res.SeqReadMBs, 1)) MB/s"
            $valSeqWrite.Text = "$([math]::Round($res.SeqWriteMBs, 1)) MB/s"
            $valRandRead.Text = "$([int]$res.Rand4KReadIops) IOPS"
            $valRandWrite.Text = "$([int]$res.Rand4KWriteIops) IOPS"
            $lblBenchStatus.Text = "Benchmark completed successfully!"
            $lblBenchStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
            $benchProgressBar.Value = 100
        } else {
            $lblBenchStatus.Text = if ($res.ErrorMessage) { "Benchmark failed: $($res.ErrorMessage)" } else { "Benchmark cancelled." }
            $lblBenchStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
        }

        $btnBenchStart.Enabled = $true
        $btnBenchCancel.Enabled = $false
        $cmbBenchTarget.Enabled = $true
        $cmbBenchSize.Enabled = $true
    })

    $btnBenchCancel.Add_Click({
        $script:benchEngine.Cancel()
        $btnBenchCancel.Enabled = $false
    })

    $btnRefresh.Add_Click({ &$populateDisks })
    $btnClose.Add_Click({
        $script:benchEngine.Cancel()
        $shForm.Close()
    })

    $shForm.Add_FormClosing({
        $script:benchEngine.Cancel()
    })

    $shForm.Add_Load({
        Invoke-HMTScale $shForm
        Set-RoundedControl $btnRefresh
        Set-RoundedControl $btnBenchStart
        Set-RoundedControl $btnBenchCancel
        Set-RoundedControl $btnClose
        &$populateDisks
    })

    Show-HMTDialog $shForm | Out-Null
}

# ==============================================================================
# 5. High-Precision Packet Loss & Latency Tester Dialog (Revamped with C# Engine)
# ==============================================================================
function Show-PacketLossTestDialog {
    $pltForm = New-Object System.Windows.Forms.Form
    $pltForm.Text = "Packet Loss & Latency Precision Tester"
    $pltForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $pltForm.ClientSize = New-Object System.Drawing.Size(780, 560)
    $pltForm.StartPosition = 'CenterScreen'
    if ($HMTIcon) { $pltForm.Icon = $HMTIcon }
    $pltForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $pltForm.MaximizeBox = $false
    $pltForm.MinimizeBox = $true
    $pltForm.ShowInTaskbar = $true
    $pltForm.Font = $font
    $pltForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $pltForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $pltForm

    # Header / Config Bar
    $y = 12
    $lblHost = New-Object System.Windows.Forms.Label
    $lblHost.Text = "Target Host / IP:"
    $lblHost.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblHost.Location = New-Object System.Drawing.Point(20, $y)
    $lblHost.AutoSize = $true
    $pltForm.Controls.Add($lblHost)

    $txtHost = New-Object System.Windows.Forms.TextBox
    $txtHost.Location = New-Object System.Drawing.Point(125, ($y - 3))
    $txtHost.Size = New-Object System.Drawing.Size(140, 25)
    $txtHost.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtHost.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtHost.Text = "1.1.1.1"
    $pltForm.Controls.Add($txtHost)

    $lblPps = New-Object System.Windows.Forms.Label
    $lblPps.Text = "Pings/Sec:"
    $lblPps.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblPps.Location = New-Object System.Drawing.Point(275, $y)
    $lblPps.AutoSize = $true
    $pltForm.Controls.Add($lblPps)

    $txtPps = New-Object System.Windows.Forms.TextBox
    $txtPps.Location = New-Object System.Drawing.Point(345, ($y - 3))
    $txtPps.Size = New-Object System.Drawing.Size(45, 25)
    $txtPps.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtPps.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtPps.Text = "5"
    $pltForm.Controls.Add($txtPps)

    $lblSize = New-Object System.Windows.Forms.Label
    $lblSize.Text = "Bytes:"
    $lblSize.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblSize.Location = New-Object System.Drawing.Point(400, $y)
    $lblSize.AutoSize = $true
    $pltForm.Controls.Add($lblSize)

    $txtSize = New-Object System.Windows.Forms.TextBox
    $txtSize.Location = New-Object System.Drawing.Point(445, ($y - 3))
    $txtSize.Size = New-Object System.Drawing.Size(45, 25)
    $txtSize.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtSize.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtSize.Text = "32"
    $pltForm.Controls.Add($txtSize)

    $lblDuration = New-Object System.Windows.Forms.Label
    $lblDuration.Text = "Duration (s):"
    $lblDuration.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblDuration.Location = New-Object System.Drawing.Point(500, $y)
    $lblDuration.AutoSize = $true
    $pltForm.Controls.Add($lblDuration)

    $txtDuration = New-Object System.Windows.Forms.TextBox
    $txtDuration.Location = New-Object System.Drawing.Point(580, ($y - 3))
    $txtDuration.Size = New-Object System.Drawing.Size(45, 25)
    $txtDuration.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtDuration.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtDuration.Text = "0"
    $pltForm.Controls.Add($txtDuration)

    $btnStart = New-Object System.Windows.Forms.Button
    $btnStart.Location = New-Object System.Drawing.Point(645, ($y - 5))
    $btnStart.Size = New-Object System.Drawing.Size(115, 32)
    $btnStart.Text = "Start Test"
    $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $btnStart.FlatStyle = 'Flat'
    $btnStart.FlatAppearance.BorderSize = 1
    $pltForm.Controls.Add($btnStart)

    # Preset Target Buttons Row
    $y += 38
    $btnP1 = New-Object System.Windows.Forms.Button
    $btnP1.Text = "Cloudflare (1.1.1.1)"
    $btnP1.Location = New-Object System.Drawing.Point(20, $y)
    $btnP1.Size = New-Object System.Drawing.Size(175, 26)
    $btnP1.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $btnP1.FlatStyle = 'Flat'
    $btnP1.FlatAppearance.BorderSize = 1
    $btnP1.Add_Click({ $txtHost.Text = "1.1.1.1" })
    $pltForm.Controls.Add($btnP1)

    $btnP2 = New-Object System.Windows.Forms.Button
    $btnP2.Text = "Google (8.8.8.8)"
    $btnP2.Location = New-Object System.Drawing.Point(205, $y)
    $btnP2.Size = New-Object System.Drawing.Size(175, 26)
    $btnP2.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $btnP2.FlatStyle = 'Flat'
    $btnP2.FlatAppearance.BorderSize = 1
    $btnP2.Add_Click({ $txtHost.Text = "8.8.8.8" })
    $pltForm.Controls.Add($btnP2)

    $btnP3 = New-Object System.Windows.Forms.Button
    $btnP3.Text = "Default Gateway"
    $btnP3.Location = New-Object System.Drawing.Point(390, $y)
    $btnP3.Size = New-Object System.Drawing.Size(175, 26)
    $btnP3.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $btnP3.FlatStyle = 'Flat'
    $btnP3.FlatAppearance.BorderSize = 1
    $btnP3.Add_Click({
        try {
            $gw = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1).NextHop
            if ($gw) { $txtHost.Text = $gw }
        } catch {}
    })
    $pltForm.Controls.Add($btnP3)

    $btnP4 = New-Object System.Windows.Forms.Button
    $btnP4.Text = "Local Host (127.0.0.1)"
    $btnP4.Location = New-Object System.Drawing.Point(575, $y)
    $btnP4.Size = New-Object System.Drawing.Size(185, 26)
    $btnP4.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $btnP4.FlatStyle = 'Flat'
    $btnP4.FlatAppearance.BorderSize = 1
    $btnP4.Add_Click({ $txtHost.Text = "127.0.0.1" })
    $pltForm.Controls.Add($btnP4)

    # 4 Live KPI Cards
    $y += 34
    $kpiPanel = New-Object System.Windows.Forms.Panel
    $kpiPanel.Location = New-Object System.Drawing.Point(20, $y)
    $kpiPanel.Size = New-Object System.Drawing.Size(740, 70)
    $kpiPanel.BackColor = [System.Drawing.Color]::Transparent
    $pltForm.Controls.Add($kpiPanel)

    $createKpiCard = {
        param($title, $initialVal, $left, $width)
        $p = New-Object System.Windows.Forms.Panel
        $p.Location = New-Object System.Drawing.Point($left, 0)
        $p.Size = New-Object System.Drawing.Size($width, 70)
        $p.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
        $p.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $kpiPanel.Controls.Add($p)

        $lTitle = New-Object System.Windows.Forms.Label
        $lTitle.Text = $title
        $lTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
        $lTitle.Location = New-Object System.Drawing.Point(0, 6)
        $lTitle.Size = New-Object System.Drawing.Size($width, 16)
        $lTitle.TextAlign = 'MiddleCenter'
        $p.Controls.Add($lTitle)

        $lVal = New-Object System.Windows.Forms.Label
        $lVal.Text = $initialVal
        $lVal.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $lVal.Font = New-Object System.Drawing.Font($font.FontFamily, 14, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $lVal.Location = New-Object System.Drawing.Point(0, 26)
        $lVal.Size = New-Object System.Drawing.Size($width, 28)
        $lVal.TextAlign = 'MiddleCenter'
        $p.Controls.Add($lVal)

        return $lVal
    }

    $valLatency = &$createKpiCard "LATENCY" "-- ms" 0 178
    $valJitter = &$createKpiCard "JITTER (RFC 3550)" "-- ms" 188 178
    $valLoss = &$createKpiCard "PACKET LOSS" "0.0%" 376 178
    $valPackets = &$createKpiCard "PACKETS (RECV / LOST)" "0 / 0" 564 176

    # Smooth GDI+ Double-Buffered Ping Graph
    $y += 78
    $pingGraph = New-Object HMT.Tools.SmoothGraphControl
    $pingGraph.Location = New-Object System.Drawing.Point(20, $y)
    $pingGraph.Size = New-Object System.Drawing.Size(740, 180)
    $pingGraph.UnitLabel = "ms"
    $pingGraph.LineColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $pingGraph.MaxPoints = 100
    $pltForm.Controls.Add($pingGraph)

    # Real-Time Packet Event Log Box
    $y += 188
    $txtLog = New-Object System.Windows.Forms.TextBox
    $txtLog.Location = New-Object System.Drawing.Point(20, $y)
    $txtLog.Size = New-Object System.Drawing.Size(740, 110)
    $txtLog.Multiline = $true
    $txtLog.ReadOnly = $true
    $txtLog.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $txtLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1f22")
    $txtLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtLog.Font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $pltForm.Controls.Add($txtLog)

    $y += 120
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point(645, $y)
    $btnClose.Size = New-Object System.Drawing.Size(115, 36)
    $btnClose.Text = "Close"
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $pltForm.Controls.Add($btnClose)

    $script:pingEngine = New-Object HMT.Tools.HighPrecisionPingEngine

    $btnStart.Add_Click({
        if ($script:pingEngine.IsRunning) {
            $script:pingEngine.Stop()
            $btnStart.Text = "Start Test"
            $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
            $txtHost.Enabled = $true
            $txtPps.Enabled = $true
            $txtSize.Enabled = $true
            $txtDuration.Enabled = $true
            return
        }

        $hostVal = $txtHost.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($hostVal)) {
            PopupError "Please enter a valid target host or IP address." "Warning"
            return
        }

        $pps = 5
        [int]::TryParse($txtPps.Text.Trim(), [ref]$pps) | Out-Null
        $sz = 32
        [int]::TryParse($txtSize.Text.Trim(), [ref]$sz) | Out-Null
        $dur = 0
        [int]::TryParse($txtDuration.Text.Trim(), [ref]$dur) | Out-Null

        $btnStart.Text = "Stop Test"
        $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
        $txtHost.Enabled = $false
        $txtPps.Enabled = $false
        $txtSize.Enabled = $false
        $txtDuration.Enabled = $false
        $pingGraph.Clear()
        $txtLog.Clear()

        $sampleHandler = {
            param($s)
            $pltForm.Invoke([action]{
                if ($s.Success) {
                    $pingGraph.AddPoint($s.RttMs)
                    $valLatency.Text = "$([math]::Round($s.RttMs, 1)) ms"
                    $valJitter.Text = "$([math]::Round($s.JitterMs, 1)) ms"
                } else {
                    $pingGraph.AddPoint(0)
                    $txtLog.AppendText("[$($s.Timestamp.ToString('HH:mm:ss.fff'))] PACKET DROP #$($s.Sequence): $($s.ErrorMessage)`r`n")
                }
            })
        }

        $summaryHandler = {
            param($sum)
            $pltForm.Invoke([action]{
                $valLoss.Text = "$([math]::Round($sum.LossPercent, 1))%"
                $valLoss.ForeColor = if ($sum.LossPercent -eq 0) {
                    [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                } elseif ($sum.LossPercent -lt 5) {
                    [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
                } else {
                    [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
                }
                $valPackets.Text = "$($sum.TotalReceived) / $($sum.TotalLost)"
            })
        }

        $completeHandler = {
            param($sum)
            $pltForm.Invoke([action]{
                $btnStart.Text = "Start Test"
                $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                $txtHost.Enabled = $true
                $txtPps.Enabled = $true
                $txtSize.Enabled = $true
                $txtDuration.Enabled = $true
                $txtLog.AppendText("`r`n--- Test Complete: $($sum.TotalSent) Sent, $($sum.TotalReceived) Recv, $($sum.TotalLost) Lost ($([math]::Round($sum.LossPercent, 1))% loss) ---`r`n")
            })
        }

        $script:pingEngine.add_OnPingSample($sampleHandler)
        $script:pingEngine.add_OnSummaryUpdate($summaryHandler)
        $script:pingEngine.add_OnCompleted($completeHandler)

        $script:pingEngine.Start($hostVal, $pps, $sz, $dur)
    })

    $btnClose.Add_Click({
        if ($script:pingEngine.IsRunning) { $script:pingEngine.Stop() }
        $pltForm.Close()
    })

    $pltForm.Add_FormClosing({
        if ($script:pingEngine.IsRunning) { $script:pingEngine.Stop() }
    })

    $pltForm.Add_Load({
        Invoke-HMTScale $pltForm
        Set-RoundedControl $btnStart
        Set-RoundedControl $btnP1
        Set-RoundedControl $btnP2
        Set-RoundedControl $btnP3
        Set-RoundedControl $btnP4
        Set-RoundedControl $btnClose
    })

    Show-HMTDialog $pltForm | Out-Null
}

# ==============================================================================
# 6. BitLocker Drive Encryption & Recovery Manager
# ==============================================================================
function Show-BitLockerManagerDialog {
    $blForm = New-Object System.Windows.Forms.Form
    $blForm.Text = "BitLocker Drive Encryption & Recovery Manager"
    $blForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $blForm.ClientSize = New-Object System.Drawing.Size(760, 560)
    $blForm.StartPosition = 'CenterScreen'
    if ($HMTIcon) { $blForm.Icon = $HMTIcon }
    $blForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $blForm.MaximizeBox = $false
    $blForm.MinimizeBox = $true
    $blForm.ShowInTaskbar = $true
    $blForm.Font = $font
    $blForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $blForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $blForm

    # Header / Drive Selector Row
    $lblSelectDrive = New-Object System.Windows.Forms.Label
    $lblSelectDrive.Text = "Target Drive / Volume:"
    $lblSelectDrive.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblSelectDrive.Location = New-Object System.Drawing.Point(20, 18)
    $lblSelectDrive.AutoSize = $true
    $blForm.Controls.Add($lblSelectDrive)

    $cmbDrives = New-Object System.Windows.Forms.ComboBox
    $cmbDrives.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbDrives.Location = New-Object System.Drawing.Point(170, 14)
    $cmbDrives.Size = New-Object System.Drawing.Size(430, 26)
    $cmbDrives.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $cmbDrives.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $blForm.Controls.Add($cmbDrives)

    $btnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh.Text = "Refresh"
    $btnRefresh.Location = New-Object System.Drawing.Point(615, 12)
    $btnRefresh.Size = New-Object System.Drawing.Size(125, 30)
    $btnRefresh.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnRefresh.FlatStyle = 'Flat'
    $btnRefresh.FlatAppearance.BorderSize = 1
    $blForm.Controls.Add($btnRefresh)

    # Drive Status Card Panel
    $statusCard = New-Object System.Windows.Forms.Panel
    $statusCard.Location = New-Object System.Drawing.Point(20, 52)
    $statusCard.Size = New-Object System.Drawing.Size(720, 75)
    $statusCard.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $statusCard.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $blForm.Controls.Add($statusCard)

    $lblCardVol = New-Object System.Windows.Forms.Label
    $lblCardVol.Text = "Volume: --"
    $lblCardVol.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblCardVol.Location = New-Object System.Drawing.Point(15, 10)
    $lblCardVol.Size = New-Object System.Drawing.Size(220, 20)
    $statusCard.Controls.Add($lblCardVol)

    $lblCardStatus = New-Object System.Windows.Forms.Label
    $lblCardStatus.Text = "Status: --"
    $lblCardStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardStatus.Location = New-Object System.Drawing.Point(245, 10)
    $lblCardStatus.Size = New-Object System.Drawing.Size(230, 20)
    $statusCard.Controls.Add($lblCardStatus)

    $lblCardLock = New-Object System.Windows.Forms.Label
    $lblCardLock.Text = "Lock: --"
    $lblCardLock.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardLock.Location = New-Object System.Drawing.Point(485, 10)
    $lblCardLock.Size = New-Object System.Drawing.Size(220, 20)
    $statusCard.Controls.Add($lblCardLock)

    $lblCardProt = New-Object System.Windows.Forms.Label
    $lblCardProt.Text = "Protection: --"
    $lblCardProt.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardProt.Location = New-Object System.Drawing.Point(15, 38)
    $lblCardProt.Size = New-Object System.Drawing.Size(220, 20)
    $statusCard.Controls.Add($lblCardProt)

    $lblCardMethod = New-Object System.Windows.Forms.Label
    $lblCardMethod.Text = "Algorithm: --"
    $lblCardMethod.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardMethod.Location = New-Object System.Drawing.Point(245, 38)
    $lblCardMethod.Size = New-Object System.Drawing.Size(230, 20)
    $statusCard.Controls.Add($lblCardMethod)

    $lblCardPct = New-Object System.Windows.Forms.Label
    $lblCardPct.Text = "Encrypted: --"
    $lblCardPct.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardPct.Location = New-Object System.Drawing.Point(485, 38)
    $lblCardPct.Size = New-Object System.Drawing.Size(220, 20)
    $statusCard.Controls.Add($lblCardPct)

    # Section 1: Protectors & Recovery Password Inspector
    $lblProtTitle = New-Object System.Windows.Forms.Label
    $lblProtTitle.Text = "Key Protectors & Recovery Password:"
    $lblProtTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblProtTitle.Font = New-Object System.Drawing.Font($font.FontFamily, 11, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $lblProtTitle.Location = New-Object System.Drawing.Point(20, 136)
    $lblProtTitle.AutoSize = $true
    $blForm.Controls.Add($lblProtTitle)

    $txtRecoveryKey = New-Object System.Windows.Forms.TextBox
    $txtRecoveryKey.Location = New-Object System.Drawing.Point(20, 158)
    $txtRecoveryKey.Size = New-Object System.Drawing.Size(490, 26)
    $txtRecoveryKey.ReadOnly = $true
    $txtRecoveryKey.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1f22")
    $txtRecoveryKey.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $txtRecoveryKey.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $txtRecoveryKey.Text = "No active Recovery Password selected"
    $blForm.Controls.Add($txtRecoveryKey)

    $btnCopyKey = New-Object System.Windows.Forms.Button
    $btnCopyKey.Text = "Copy Key"
    $btnCopyKey.Location = New-Object System.Drawing.Point(520, 156)
    $btnCopyKey.Size = New-Object System.Drawing.Size(105, 30)
    $btnCopyKey.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnCopyKey.FlatStyle = 'Flat'
    $btnCopyKey.FlatAppearance.BorderSize = 1
    $blForm.Controls.Add($btnCopyKey)

    $btnSaveKey = New-Object System.Windows.Forms.Button
    $btnSaveKey.Text = "Save Key"
    $btnSaveKey.Location = New-Object System.Drawing.Point(635, 156)
    $btnSaveKey.Size = New-Object System.Drawing.Size(105, 30)
    $btnSaveKey.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnSaveKey.FlatStyle = 'Flat'
    $btnSaveKey.FlatAppearance.BorderSize = 1
    $blForm.Controls.Add($btnSaveKey)

    $lvProtectors = New-Object System.Windows.Forms.ListView
    $lvProtectors.Location = New-Object System.Drawing.Point(20, 192)
    $lvProtectors.Size = New-Object System.Drawing.Size(720, 85)
    $lvProtectors.View = [System.Windows.Forms.View]::Details
    $lvProtectors.FullRowSelect = $true
    $lvProtectors.GridLines = $true
    $lvProtectors.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $lvProtectors.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lvProtectors.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $lvProtectors.Columns.Add("Protector Type", 180) | Out-Null
    $lvProtectors.Columns.Add("Key / Details", 410) | Out-Null
    $lvProtectors.Columns.Add("ID", 110) | Out-Null
    [HMT.NativeMethods]::SetWindowTheme($lvProtectors.Handle, "DarkMode_Explorer", $null) | Out-Null
    $blForm.Controls.Add($lvProtectors)

    # Section 2: Unlock Mechanism (Visible/Enabled when drive is locked)
    $unlockPanel = New-Object System.Windows.Forms.Panel
    $unlockPanel.Location = New-Object System.Drawing.Point(20, 288)
    $unlockPanel.Size = New-Object System.Drawing.Size(720, 65)
    $unlockPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $unlockPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $blForm.Controls.Add($unlockPanel)

    $lblUnlockMethod = New-Object System.Windows.Forms.Label
    $lblUnlockMethod.Text = "Unlock Method:"
    $lblUnlockMethod.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblUnlockMethod.Location = New-Object System.Drawing.Point(10, 8)
    $lblUnlockMethod.Size = New-Object System.Drawing.Size(120, 18)
    $unlockPanel.Controls.Add($lblUnlockMethod)

    $cmbUnlockMethod = New-Object System.Windows.Forms.ComboBox
    $cmbUnlockMethod.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbUnlockMethod.Items.AddRange(@("Recovery Password (48-digit)", "Password / Passphrase", "PIN"))
    $cmbUnlockMethod.SelectedIndex = 0
    $cmbUnlockMethod.Location = New-Object System.Drawing.Point(10, 28)
    $cmbUnlockMethod.Size = New-Object System.Drawing.Size(210, 26)
    $cmbUnlockMethod.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $cmbUnlockMethod.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $unlockPanel.Controls.Add($cmbUnlockMethod)

    $lblUnlockInput = New-Object System.Windows.Forms.Label
    $lblUnlockInput.Text = "Password / Recovery Key:"
    $lblUnlockInput.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblUnlockInput.Location = New-Object System.Drawing.Point(235, 8)
    $lblUnlockInput.Size = New-Object System.Drawing.Size(200, 18)
    $unlockPanel.Controls.Add($lblUnlockInput)

    $txtUnlockSecret = New-Object System.Windows.Forms.TextBox
    $txtUnlockSecret.Location = New-Object System.Drawing.Point(235, 28)
    $txtUnlockSecret.Size = New-Object System.Drawing.Size(350, 25)
    $txtUnlockSecret.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $txtUnlockSecret.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $unlockPanel.Controls.Add($txtUnlockSecret)

    $btnUnlock = New-Object System.Windows.Forms.Button
    $btnUnlock.Text = "Unlock Drive"
    $btnUnlock.Location = New-Object System.Drawing.Point(595, 24)
    $btnUnlock.Size = New-Object System.Drawing.Size(110, 32)
    $btnUnlock.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnUnlock.FlatStyle = 'Flat'
    $btnUnlock.FlatAppearance.BorderSize = 1
    $unlockPanel.Controls.Add($btnUnlock)

    # Section 3: Live Progress Tracker & Background Control
    $progPanel = New-Object System.Windows.Forms.Panel
    $progPanel.Location = New-Object System.Drawing.Point(20, 362)
    $progPanel.Size = New-Object System.Drawing.Size(720, 92)
    $progPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $progPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $blForm.Controls.Add($progPanel)

    $lblProgStatus = New-Object System.Windows.Forms.Label
    $lblProgStatus.Text = "Operation Status: Idle"
    $lblProgStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblProgStatus.Location = New-Object System.Drawing.Point(15, 8)
    $lblProgStatus.Size = New-Object System.Drawing.Size(480, 20)
    $progPanel.Controls.Add($lblProgStatus)

    $pBar = New-Object System.Windows.Forms.ProgressBar
    $pBar.Location = New-Object System.Drawing.Point(15, 30)
    $pBar.Size = New-Object System.Drawing.Size(685, 18)
    $pBar.Minimum = 0
    $pBar.Maximum = 100
    $progPanel.Controls.Add($pBar)

    $btnContinueBg = New-Object System.Windows.Forms.Button
    $btnContinueBg.Text = "Continue in Background & Close"
    $btnContinueBg.Location = New-Object System.Drawing.Point(15, 54)
    $btnContinueBg.Size = New-Object System.Drawing.Size(230, 28)
    $btnContinueBg.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnContinueBg.FlatStyle = 'Flat'
    $btnContinueBg.FlatAppearance.BorderSize = 1
    $progPanel.Controls.Add($btnContinueBg)

    $btnPauseResume = New-Object System.Windows.Forms.Button
    $btnPauseResume.Text = "Pause / Resume"
    $btnPauseResume.Location = New-Object System.Drawing.Point(255, 54)
    $btnPauseResume.Size = New-Object System.Drawing.Size(140, 28)
    $btnPauseResume.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnPauseResume.FlatStyle = 'Flat'
    $btnPauseResume.FlatAppearance.BorderSize = 1
    $progPanel.Controls.Add($btnPauseResume)

    # Section 4: Main Action Buttons
    $yActions = 465
    $btnEnable = New-Object System.Windows.Forms.Button
    $btnEnable.Text = "Enable BitLocker (Encrypt)"
    $btnEnable.Location = New-Object System.Drawing.Point(20, $yActions)
    $btnEnable.Size = New-Object System.Drawing.Size(190, 36)
    $btnEnable.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $btnEnable.FlatStyle = 'Flat'
    $btnEnable.FlatAppearance.BorderSize = 1
    $blForm.Controls.Add($btnEnable)

    $btnDisable = New-Object System.Windows.Forms.Button
    $btnDisable.Text = "Disable BitLocker (Decrypt)"
    $btnDisable.Location = New-Object System.Drawing.Point(218, $yActions)
    $btnDisable.Size = New-Object System.Drawing.Size(190, 36)
    $btnDisable.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
    $btnDisable.FlatStyle = 'Flat'
    $btnDisable.FlatAppearance.BorderSize = 1
    $blForm.Controls.Add($btnDisable)

    $btnAddProtector = New-Object System.Windows.Forms.Button
    $btnAddProtector.Text = "Add Recovery Password"
    $btnAddProtector.Location = New-Object System.Drawing.Point(416, $yActions)
    $btnAddProtector.Size = New-Object System.Drawing.Size(190, 36)
    $btnAddProtector.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnAddProtector.FlatStyle = 'Flat'
    $btnAddProtector.FlatAppearance.BorderSize = 1
    $blForm.Controls.Add($btnAddProtector)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Location = New-Object System.Drawing.Point(614, $yActions)
    $btnClose.Size = New-Object System.Drawing.Size(126, 36)
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $blForm.Controls.Add($btnClose)

    # State & Polling Timer
    $script:blVolumes = @{}
    $script:selectedVolume = $null
    $pollTimer = New-Object System.Windows.Forms.Timer
    $pollTimer.Interval = 1000

    # Data Population Logic
    $refreshVolumes = {
        $cmbDrives.Items.Clear()
        $script:blVolumes.Clear()
        
        try {
            $vols = Get-BitLockerVolume -ErrorAction SilentlyContinue
            if ($vols) {
                foreach ($v in $vols) {
                    $mp = $v.MountPoint
                    $label = if ($v.VolumeType) { "$($v.VolumeType)" } else { "Drive" }
                    $lock = if ($v.LockStatus -eq 'Locked') { "LOCKED" } else { "Unlocked" }
                    $prot = if ($v.ProtectionStatus -eq 'On') { "Prot:On" } else { "Prot:Off" }
                    $display = "$mp ($label) - $($v.VolumeStatus) [$lock, $prot]"
                    $script:blVolumes[$display] = $v
                    $cmbDrives.Items.Add($display) | Out-Null
                }
            } else {
                $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -or $_.Free -gt 0 }
                foreach ($d in $drives) {
                    $mp = "$($d.Name):"
                    $display = "$mp [Drive] - Decrypted / Unknown"
                    $dummy = [pscustomobject]@{
                        MountPoint = $mp
                        VolumeType = "Data"
                        VolumeStatus = "FullyDecrypted"
                        LockStatus = "Unlocked"
                        ProtectionStatus = "Off"
                        EncryptionPercentage = 0
                        EncryptionMethod = "None"
                        KeyProtector = @()
                    }
                    $script:blVolumes[$display] = $dummy
                    $cmbDrives.Items.Add($display) | Out-Null
                }
            }
        } catch {
            $display = "Error querying BitLocker: $_"
            $cmbDrives.Items.Add($display) | Out-Null
        }

        if ($cmbDrives.Items.Count -gt 0) {
            $cmbDrives.SelectedIndex = 0
        }
    }

    $updateSelectedDriveUI = {
        if ($cmbDrives.SelectedItem -and $script:blVolumes.ContainsKey($cmbDrives.SelectedItem.ToString())) {
            $v = $script:blVolumes[$cmbDrives.SelectedItem.ToString()]
            $script:selectedVolume = $v
            $mp = $v.MountPoint

            try {
                $latest = Get-BitLockerVolume -MountPoint $mp -ErrorAction SilentlyContinue
                if ($latest) { $v = $latest; $script:selectedVolume = $latest }
            } catch {}

            $lblCardVol.Text = "Volume: $mp ($($v.VolumeType))"
            $lblCardStatus.Text = "Status: $($v.VolumeStatus)"
            $lblCardLock.Text = "Lock: $($v.LockStatus)"
            $lblCardLock.ForeColor = if ($v.LockStatus -eq 'Locked') { [System.Drawing.ColorTranslator]::FromHtml("#ED4245") } else { [System.Drawing.ColorTranslator]::FromHtml("#57F287") }
            $lblCardProt.Text = "Protection: $($v.ProtectionStatus)"
            $lblCardMethod.Text = "Algorithm: $($v.EncryptionMethod)"
            $pct = if ($null -ne $v.EncryptionPercentage) { $v.EncryptionPercentage } else { 0 }
            $lblCardPct.Text = "Encrypted: $pct%"

            # Key Protectors & Recovery Key Extraction
            $lvProtectors.Items.Clear()
            $txtRecoveryKey.Text = "No Recovery Password found"
            $txtRecoveryKey.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")

            if ($v.KeyProtector) {
                foreach ($kp in $v.KeyProtector) {
                    $item = New-Object System.Windows.Forms.ListViewItem([string]$kp.KeyProtectorType)
                    $detail = "Protected"
                    if ($kp.RecoveryPassword) {
                        $detail = $kp.RecoveryPassword
                        $txtRecoveryKey.Text = $kp.RecoveryPassword
                        $txtRecoveryKey.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                    } elseif ($kp.KeyProtectorType -eq 'Tpm') {
                        $detail = "TPM Hardware Security Module"
                    } elseif ($kp.KeyProtectorType -eq 'TpmPin') {
                        $detail = "TPM with Startup PIN"
                    } elseif ($kp.KeyProtectorType -eq 'Password') {
                        $detail = "User Passphrase"
                    }
                    $item.SubItems.Add($detail) | Out-Null
                    $item.SubItems.Add([string]$kp.KeyProtectorId) | Out-Null
                    $lvProtectors.Items.Add($item) | Out-Null
                }
            }

            # Unlock Panel state
            if ($v.LockStatus -eq 'Locked') {
                $unlockPanel.Enabled = $true
                $btnUnlock.Enabled = $true
            } else {
                $unlockPanel.Enabled = $false
                $btnUnlock.Enabled = $false
            }

            # Progress Bar & Actions
            $isInProgress = ($v.VolumeStatus -eq 'EncryptionInProgress' -or $v.VolumeStatus -eq 'DecryptionInProgress')
            if ($isInProgress) {
                $lblProgStatus.Text = "$($v.VolumeStatus) on $mp ($pct% Complete)..."
                $pBar.Value = [math]::Max(0, [math]::Min(100, [int]$pct))
                $pollTimer.Start()
            } else {
                $lblProgStatus.Text = "Operation Status: Idle ($($v.VolumeStatus))"
                $pBar.Value = [math]::Max(0, [math]::Min(100, [int]$pct))
                $pollTimer.Stop()
            }

            # Button states
            $btnEnable.Enabled = ($v.VolumeStatus -eq 'FullyDecrypted' -and $v.LockStatus -ne 'Locked')
            $btnDisable.Enabled = ($v.VolumeStatus -eq 'FullyEncrypted' -or $v.VolumeStatus -eq 'EncryptionInProgress')
        }
    }

    # Timer handler for live progress polling
    $pollTimer.Add_Tick({
        if ($script:selectedVolume) {
            $mp = $script:selectedVolume.MountPoint
            try {
                $latest = Get-BitLockerVolume -MountPoint $mp -ErrorAction SilentlyContinue
                if ($latest) {
                    $pct = if ($null -ne $latest.EncryptionPercentage) { $latest.EncryptionPercentage } else { 0 }
                    $lblProgStatus.Text = "$($latest.VolumeStatus) on $mp ($pct% Complete)..."
                    $pBar.Value = [math]::Max(0, [math]::Min(100, [int]$pct))
                    $lblCardPct.Text = "Encrypted: $pct%"
                    $lblCardStatus.Text = "Status: $($latest.VolumeStatus)"
                    
                    if ($latest.VolumeStatus -ne 'EncryptionInProgress' -and $latest.VolumeStatus -ne 'DecryptionInProgress') {
                        $pollTimer.Stop()
                        &$updateSelectedDriveUI
                    }
                }
            } catch {}
        }
    })

    $cmbDrives.Add_SelectedIndexChanged({ &$updateSelectedDriveUI })
    $btnRefresh.Add_Click({ &$refreshVolumes })

    # Copy Recovery Key
    $btnCopyKey.Add_Click({
        if ($txtRecoveryKey.Text -and $txtRecoveryKey.Text -ne "No active Recovery Password selected" -and $txtRecoveryKey.Text -ne "No Recovery Password found") {
            [System.Windows.Forms.Clipboard]::SetText($txtRecoveryKey.Text)
            PopupError "Recovery Password copied to clipboard!`n`n$($txtRecoveryKey.Text)" "Information"
        } else {
            PopupError "No recovery password available to copy." "Warning"
        }
    })

    # Save Key to File
    $btnSaveKey.Add_Click({
        if ($txtRecoveryKey.Text -and $txtRecoveryKey.Text -ne "No active Recovery Password selected" -and $txtRecoveryKey.Text -ne "No Recovery Password found") {
            $sfd = New-Object System.Windows.Forms.SaveFileDialog
            $sfd.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
            $sfd.FileName = "BitLocker_Recovery_Key_$($script:selectedVolume.MountPoint -replace ':', '').txt"
            if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $content = @"
BitLocker Drive Encryption Recovery Key
========================================
Volume: $($script:selectedVolume.MountPoint)
Generated / Exported: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Recovery Password: $($txtRecoveryKey.Text)
========================================
Store this recovery password in a secure, confidential location.
"@
                Set-Content -Path $sfd.FileName -Value $content -Encoding UTF8 -Force
                PopupError "Recovery Key saved successfully to:`n$($sfd.FileName)" "Information"
            }
        } else {
            PopupError "No recovery password available to save." "Warning"
        }
    })

    # Unlock Drive Action
    $btnUnlock.Add_Click({
        if (-not $script:selectedVolume) { return }
        $mp = $script:selectedVolume.MountPoint
        $secret = $txtUnlockSecret.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($secret)) {
            PopupError "Please enter the password, PIN, or 48-digit recovery key." "Warning"
            return
        }

        $btnUnlock.Enabled = $false
        try {
            $method = $cmbUnlockMethod.SelectedIndex
            if ($method -eq 0) {
                # Recovery Password
                Unlock-BitLocker -MountPoint $mp -RecoveryPassword $secret -ErrorAction Stop
            } elseif ($method -eq 1) {
                # Password
                $secStr = ConvertTo-SecureString $secret -AsPlainText -Force
                Unlock-BitLocker -MountPoint $mp -Password $secStr -ErrorAction Stop
            } elseif ($method -eq 2) {
                # PIN
                Start-Process manage-bde.exe -ArgumentList "-unlock $mp -pin $secret" -Wait -WindowStyle Hidden
            }
            PopupError "Volume $mp unlocked successfully!" "Information"
            $txtUnlockSecret.Clear()
            &$refreshVolumes
        } catch {
            PopupError "Failed to unlock volume $($mp):`n$_" "Error"
        } finally {
            $btnUnlock.Enabled = $true
        }
    })

    # Enable BitLocker Action
    $btnEnable.Add_Click({
        if (-not $script:selectedVolume) { return }
        $mp = $script:selectedVolume.MountPoint
        
        $confirm = PopupError "Are you sure you want to enable BitLocker encryption on volume $mp?`n`nA recovery password protector will be generated automatically." "Question" "YesNo"
        if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

        try {
            $isOs = ($script:selectedVolume.VolumeType -eq 'OperatingSystem')
            if ($isOs) {
                Enable-BitLocker -MountPoint $mp -EncryptionMethod XtsAes128 -UsedSpaceOnly -TpmProtector -RecoveryPasswordProtector -ErrorAction Stop
            } else {
                Enable-BitLocker -MountPoint $mp -EncryptionMethod XtsAes128 -UsedSpaceOnly -RecoveryPasswordProtector -ErrorAction Stop
            }
            PopupError "BitLocker encryption initiated on $mp!`n`nPlease view and save your Recovery Key." "Information"
            &$refreshVolumes
        } catch {
            PopupError "Failed to enable BitLocker on $($mp):`n$_" "Error"
        }
    })

    # Disable BitLocker Action
    $btnDisable.Add_Click({
        if (-not $script:selectedVolume) { return }
        $mp = $script:selectedVolume.MountPoint
        $confirm = PopupError "Are you sure you want to DISABLE BitLocker and DECRYPT volume $mp?`n`nThis will remove encryption and all key protectors." "Question" "YesNo"
        if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

        try {
            Disable-BitLocker -MountPoint $mp -ErrorAction Stop
            PopupError "BitLocker decryption initiated on $mp.`n`nDecryption is progressing in the background." "Information"
            &$refreshVolumes
        } catch {
            PopupError "Failed to disable BitLocker on $($mp):`n$_" "Error"
        }
    })

    # Add Recovery Password Protector
    $btnAddProtector.Add_Click({
        if (-not $script:selectedVolume) { return }
        $mp = $script:selectedVolume.MountPoint
        try {
            Add-BitLockerKeyProtector -MountPoint $mp -RecoveryPasswordProtector -ErrorAction Stop
            PopupError "Recovery Password protector added successfully to $mp!" "Information"
            &$refreshVolumes
        } catch {
            PopupError "Failed to add recovery password protector to $($mp):`n$_" "Error"
        }
    })

    # Pause / Resume Action
    $btnPauseResume.Add_Click({
        if (-not $script:selectedVolume) { return }
        $mp = $script:selectedVolume.MountPoint
        try {
            $v = Get-BitLockerVolume -MountPoint $mp -ErrorAction SilentlyContinue
            if ($v.ProtectionStatus -eq 'On') {
                Suspend-BitLocker -MountPoint $mp -RebootCount 0 -ErrorAction Stop
                PopupError "BitLocker protection suspended / paused on $mp." "Information"
            } else {
                Resume-BitLocker -MountPoint $mp -ErrorAction Stop
                PopupError "BitLocker protection resumed on $mp." "Information"
            }
            &$refreshVolumes
        } catch {
            PopupError "Failed to toggle pause/resume on $($mp):`n$_" "Error"
        }
    })

    # Continue in Background & Close
    $btnContinueBg.Add_Click({
        $pollTimer.Stop()
        $blForm.Close()
    })

    $btnClose.Add_Click({
        $pollTimer.Stop()
        $blForm.Close()
    })

    $blForm.Add_FormClosing({
        $pollTimer.Stop()
        $pollTimer.Dispose()
    })

    $blForm.Add_Load({
        Invoke-HMTScale $blForm
        Set-RoundedControl $btnRefresh
        Set-RoundedControl $btnCopyKey
        Set-RoundedControl $btnSaveKey
        Set-RoundedControl $btnUnlock
        Set-RoundedControl $btnContinueBg
        Set-RoundedControl $btnPauseResume
        Set-RoundedControl $btnEnable
        Set-RoundedControl $btnDisable
        Set-RoundedControl $btnAddProtector
        Set-RoundedControl $btnClose
        &$refreshVolumes
    })

    Show-HMTDialog $blForm | Out-Null
}

# ==============================================================================
# 7. Startup & Autoruns Manager Dialog
# ==============================================================================
function Show-StartupManagerDialog {
    $suForm = New-Object System.Windows.Forms.Form
    $suForm.Text = "Startup & Autoruns Manager"
    $suForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $suForm.ClientSize = New-Object System.Drawing.Size(840, 560)
    $suForm.StartPosition = 'CenterScreen'
    if ($HMTIcon) { $suForm.Icon = $HMTIcon }
    $suForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $suForm.MaximizeBox = $false
    $suForm.MinimizeBox = $true
    $suForm.ShowInTaskbar = $true
    $suForm.Font = $font
    $suForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $suForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $suForm

    # Header / Search Filter
    $lblSearch = New-Object System.Windows.Forms.Label
    $lblSearch.Text = "Filter / Search:"
    $lblSearch.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblSearch.Location = New-Object System.Drawing.Point(20, 15)
    $lblSearch.AutoSize = $true
    $suForm.Controls.Add($lblSearch)

    $txtSearch = New-Object System.Windows.Forms.TextBox
    $txtSearch.Location = New-Object System.Drawing.Point(120, 12)
    $txtSearch.Size = New-Object System.Drawing.Size(260, 25)
    $txtSearch.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtSearch.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $suForm.Controls.Add($txtSearch)

    $lblSummary = New-Object System.Windows.Forms.Label
    $lblSummary.Text = "Total Items: 0 (Enabled: 0, Disabled: 0)"
    $lblSummary.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblSummary.Location = New-Object System.Drawing.Point(400, 15)
    $lblSummary.Size = New-Object System.Drawing.Size(420, 20)
    $lblSummary.TextAlign = 'MiddleRight'
    $suForm.Controls.Add($lblSummary)

    # Startup Items ListView
    $lvStartup = New-Object System.Windows.Forms.ListView
    $lvStartup.Location = New-Object System.Drawing.Point(20, 45)
    $lvStartup.Size = New-Object System.Drawing.Size(800, 445)
    $lvStartup.View = [System.Windows.Forms.View]::Details
    $lvStartup.FullRowSelect = $true
    $lvStartup.GridLines = $true
    $lvStartup.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $lvStartup.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lvStartup.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $lvStartup.Columns.Add("Program Name", 180) | Out-Null
    $lvStartup.Columns.Add("Command Line / Target", 340) | Out-Null
    $lvStartup.Columns.Add("Location", 170) | Out-Null
    $lvStartup.Columns.Add("Status", 90) | Out-Null
    [HMT.NativeMethods]::SetWindowTheme($lvStartup.Handle, "DarkMode_Explorer", $null) | Out-Null
    $suForm.Controls.Add($lvStartup)

    # Buttons Row
    $yBtn = 502
    $btnToggle = New-Object System.Windows.Forms.Button
    $btnToggle.Text = "Toggle Enable / Disable"
    $btnToggle.Location = New-Object System.Drawing.Point(20, $yBtn)
    $btnToggle.Size = New-Object System.Drawing.Size(180, 36)
    $btnToggle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $btnToggle.FlatStyle = 'Flat'
    $btnToggle.FlatAppearance.BorderSize = 1
    $suForm.Controls.Add($btnToggle)

    $btnDelete = New-Object System.Windows.Forms.Button
    $btnDelete.Text = "Delete Entry"
    $btnDelete.Location = New-Object System.Drawing.Point(210, $yBtn)
    $btnDelete.Size = New-Object System.Drawing.Size(130, 36)
    $btnDelete.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
    $btnDelete.FlatStyle = 'Flat'
    $btnDelete.FlatAppearance.BorderSize = 1
    $suForm.Controls.Add($btnDelete)

    $btnOpenLoc = New-Object System.Windows.Forms.Button
    $btnOpenLoc.Text = "Open Location"
    $btnOpenLoc.Location = New-Object System.Drawing.Point(350, $yBtn)
    $btnOpenLoc.Size = New-Object System.Drawing.Size(130, 36)
    $btnOpenLoc.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnOpenLoc.FlatStyle = 'Flat'
    $btnOpenLoc.FlatAppearance.BorderSize = 1
    $suForm.Controls.Add($btnOpenLoc)

    $btnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh.Text = "Refresh"
    $btnRefresh.Location = New-Object System.Drawing.Point(565, $yBtn)
    $btnRefresh.Size = New-Object System.Drawing.Size(115, 36)
    $btnRefresh.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnRefresh.FlatStyle = 'Flat'
    $btnRefresh.FlatAppearance.BorderSize = 1
    $suForm.Controls.Add($btnRefresh)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Location = New-Object System.Drawing.Point(690, $yBtn)
    $btnClose.Size = New-Object System.Drawing.Size(130, 36)
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $suForm.Controls.Add($btnClose)

    $script:startupData = @()

    $loadStartupItems = {
        $script:startupData = @()
        $lvStartup.Items.Clear()

        # Helper to check StartupApproved binary flag
        $checkApproved = {
            param($regPath, $valName)
            try {
                $bytes = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).$valName
                if ($bytes -and $bytes.Length -gt 0) {
                    if ($bytes[0] -eq 0x03 -or $bytes[0] -eq 0x01) { return "Disabled" }
                }
            } catch {}
            return "Enabled"
        }

        # 1. HKCU Run
        $hkcuRunPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $hkcuApprPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
        try {
            $hkcuProps = Get-ItemProperty -Path $hkcuRunPath -ErrorAction SilentlyContinue
            if ($hkcuProps) {
                foreach ($prop in $hkcuProps.PSObject.Properties) {
                    if ($prop.Name -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')) {
                        $st = &$checkApproved $hkcuApprPath $prop.Name
                        $script:startupData += [pscustomobject]@{
                            Name = $prop.Name
                            Command = [string]$prop.Value
                            Location = "HKCU Run"
                            Type = "Registry"
                            RegPath = $hkcuRunPath
                            ApprPath = $hkcuApprPath
                            Status = $st
                        }
                    }
                }
            }
        } catch {}

        # 2. HKLM Run
        $hklmRunPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
        $hklmApprPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run"
        try {
            $hklmProps = Get-ItemProperty -Path $hklmRunPath -ErrorAction SilentlyContinue
            if ($hklmProps) {
                foreach ($prop in $hklmProps.PSObject.Properties) {
                    if ($prop.Name -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')) {
                        $st = &$checkApproved $hklmApprPath $prop.Name
                        $script:startupData += [pscustomobject]@{
                            Name = $prop.Name
                            Command = [string]$prop.Value
                            Location = "HKLM Run"
                            Type = "Registry"
                            RegPath = $hklmRunPath
                            ApprPath = $hklmApprPath
                            Status = $st
                        }
                    }
                }
            }
        } catch {}

        # 3. HKLM WOW6432Node Run
        $hklm32RunPath = "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
        $hklm32ApprPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32"
        try {
            $hklm32Props = Get-ItemProperty -Path $hklm32RunPath -ErrorAction SilentlyContinue
            if ($hklm32Props) {
                foreach ($prop in $hklm32Props.PSObject.Properties) {
                    if ($prop.Name -notin @('PSPath', 'PSParentPath', 'PSChildName', 'PSDrive', 'PSProvider')) {
                        $st = &$checkApproved $hklm32ApprPath $prop.Name
                        $script:startupData += [pscustomobject]@{
                            Name = $prop.Name
                            Command = [string]$prop.Value
                            Location = "HKLM Run (32-bit)"
                            Type = "Registry"
                            RegPath = $hklm32RunPath
                            ApprPath = $hklm32ApprPath
                            Status = $st
                        }
                    }
                }
            }
        } catch {}

        # 4. User Startup Folder
        $userStartupDir = Join-Path -Path $env:APPDATA -ChildPath "Microsoft\Windows\Start Menu\Programs\Startup"
        $userApprFolder = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
        if (Test-Path $userStartupDir) {
            $files = Get-ChildItem -Path $userStartupDir -File -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                $isDisabled = $f.Name.EndsWith(".disabled", [StringComparison]::OrdinalIgnoreCase)
                $st = if ($isDisabled) { "Disabled" } else { &$checkApproved $userApprFolder $f.Name }
                $script:startupData += [pscustomobject]@{
                    Name = $f.Name
                    Command = $f.FullName
                    Location = "User Startup Folder"
                    Type = "File"
                    FilePath = $f.FullName
                    ApprPath = $userApprFolder
                    Status = $st
                }
            }
        }

        # 5. Common Startup Folder
        $commonStartupDir = Join-Path -Path $env:ProgramData -ChildPath "Microsoft\Windows\Start Menu\Programs\Startup"
        $commonApprFolder = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\StartupFolder"
        if (Test-Path $commonStartupDir) {
            $files = Get-ChildItem -Path $commonStartupDir -File -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                $isDisabled = $f.Name.EndsWith(".disabled", [StringComparison]::OrdinalIgnoreCase)
                $st = if ($isDisabled) { "Disabled" } else { &$checkApproved $commonApprFolder $f.Name }
                $script:startupData += [pscustomobject]@{
                    Name = $f.Name
                    Command = $f.FullName
                    Location = "All Users Startup Folder"
                    Type = "File"
                    FilePath = $f.FullName
                    ApprPath = $commonApprFolder
                    Status = $st
                }
            }
        }

        &$renderStartupList
    }

    $renderStartupList = {
        $lvStartup.Items.Clear()
        $filter = $txtSearch.Text.Trim()
        $enabledCount = 0
        $disabledCount = 0

        foreach ($item in $script:startupData) {
            if ($item.Status -eq "Enabled") { $enabledCount++ } else { $disabledCount++ }

            if ($filter) {
                if ($item.Name -notlike "*$filter*" -and $item.Command -notlike "*$filter*" -and $item.Location -notlike "*$filter*") {
                    continue
                }
            }

            $lvi = New-Object System.Windows.Forms.ListViewItem($item.Name)
            $lvi.SubItems.Add($item.Command) | Out-Null
            $lvi.SubItems.Add($item.Location) | Out-Null
            $statusSub = $lvi.SubItems.Add($item.Status)
            $lvi.Tag = $item

            if ($item.Status -eq "Enabled") {
                $lvi.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
            } else {
                $lvi.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
            }
            $lvStartup.Items.Add($lvi) | Out-Null
        }

        $lblSummary.Text = "Total Items: $($script:startupData.Count) (Enabled: $enabledCount, Disabled: $disabledCount)"
    }

    $txtSearch.Add_TextChanged({ &$renderStartupList })
    $btnRefresh.Add_Click({ &$loadStartupItems })
    $btnClose.Add_Click({ $suForm.Close() })

    # Toggle Action
    $btnToggle.Add_Click({
        if ($lvStartup.SelectedItems.Count -eq 0) {
            PopupError "Please select a startup item to toggle." "Warning"
            return
        }

        $selItem = $lvStartup.SelectedItems[0].Tag
        try {
            $newStatus = if ($selItem.Status -eq "Enabled") { "Disabled" } else { "Enabled" }

            if ($selItem.Type -eq "Registry") {
                if (-not (Test-Path $selItem.ApprPath)) {
                    New-Item -Path $selItem.ApprPath -Force | Out-Null
                }
                $byteVal = if ($newStatus -eq "Enabled") { [byte[]]@(0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) } else { [byte[]]@(0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00) }
                Set-ItemProperty -Path $selItem.ApprPath -Name $selItem.Name -Value $byteVal -Type Binary -Force -ErrorAction Stop
            } elseif ($selItem.Type -eq "File") {
                $fPath = $selItem.FilePath
                if ($newStatus -eq "Disabled") {
                    if ($fPath -notmatch '\.disabled$') {
                        Rename-Item -Path $fPath -NewName "$($selItem.Name).disabled" -Force -ErrorAction Stop
                    }
                } else {
                    if ($fPath -match '\.disabled$') {
                        $origName = $selItem.Name -replace '\.disabled$', ''
                        Rename-Item -Path $fPath -NewName $origName -Force -ErrorAction Stop
                    }
                }
            }
            &$loadStartupItems
        } catch {
            PopupError "Failed to toggle startup status:`n$_" "Error"
        }
    })

    # Delete Action
    $btnDelete.Add_Click({
        if ($lvStartup.SelectedItems.Count -eq 0) {
            PopupError "Please select a startup item to delete." "Warning"
            return
        }

        $selItem = $lvStartup.SelectedItems[0].Tag
        $confirm = PopupError "Are you sure you want to permanently DELETE startup item '$($selItem.Name)'?" "Question" "YesNo"
        if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

        try {
            if ($selItem.Type -eq "Registry") {
                Remove-ItemProperty -Path $selItem.RegPath -Name $selItem.Name -Force -ErrorAction Stop
                try { Remove-ItemProperty -Path $selItem.ApprPath -Name $selItem.Name -Force -ErrorAction SilentlyContinue } catch {}
            } elseif ($selItem.Type -eq "File") {
                Remove-Item -Path $selItem.FilePath -Force -ErrorAction Stop
            }
            PopupError "Startup item '$($selItem.Name)' deleted successfully." "Information"
            &$loadStartupItems
        } catch {
            PopupError "Failed to delete startup entry:`n$_" "Error"
        }
    })

    # Open Location Action
    $btnOpenLoc.Add_Click({
        if ($lvStartup.SelectedItems.Count -eq 0) { return }
        $selItem = $lvStartup.SelectedItems[0].Tag

        try {
            if ($selItem.Type -eq "File") {
                Start-Process explorer.exe -ArgumentList "/select,`"$($selItem.FilePath)`""
            } else {
                $cmd = $selItem.Command.Trim()
                $targetPath = $cmd
                if ($cmd.StartsWith('"')) {
                    $targetPath = $cmd.Substring(1, ($cmd.IndexOf('"', 1) - 1))
                } elseif ($cmd -match '^([A-Za-z]:\\[^\s]+\.exe)') {
                    $targetPath = $matches[1]
                }
                if (Test-Path $targetPath) {
                    Start-Process explorer.exe -ArgumentList "/select,`"$targetPath`""
                } else {
                    PopupError "Target file not found at:`n$targetPath" "Information"
                }
            }
        } catch {
            PopupError "Unable to open file location:`n$_" "Error"
        }
    })

    $suForm.Add_Load({
        Invoke-HMTScale $suForm
        Set-RoundedControl $btnToggle
        Set-RoundedControl $btnDelete
        Set-RoundedControl $btnOpenLoc
        Set-RoundedControl $btnRefresh
        Set-RoundedControl $btnClose
        &$loadStartupItems
    })

    Show-HMTDialog $suForm | Out-Null
}

