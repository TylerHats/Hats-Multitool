# GUI Diagnostics & Standalone Tools - Tyler Hatfield - v2.20

# Command Runner Dialog (DISM, SFC, ChkDsk, NetFx3)
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
    $runnerForm.ClientSize = New-Object System.Drawing.Size(680, 440)
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
    $lblTitle.Location = New-Object System.Drawing.Point(20, 15)
    $lblTitle.AutoSize = $true
    $runnerForm.Controls.Add($lblTitle)

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text = if ($Description) { "$Description (Starting...)" } else { "Executing command..." }
    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblStatus.Location = New-Object System.Drawing.Point(20, 42)
    $lblStatus.Size = New-Object System.Drawing.Size(640, 20)
    $lblStatus.AutoEllipsis = $true
    $runnerForm.Controls.Add($lblStatus)

    $pBar = New-Object System.Windows.Forms.ProgressBar
    $pBar.Location = New-Object System.Drawing.Point(20, 68)
    $pBar.Size = New-Object System.Drawing.Size(640, 8)
    $pBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
    $pBar.MarqueeAnimationSpeed = 30
    $runnerForm.Controls.Add($pBar)

    $txtOutput = New-Object System.Windows.Forms.TextBox
    $txtOutput.Location = New-Object System.Drawing.Point(20, 86)
    $txtOutput.Size = New-Object System.Drawing.Size(640, 280)
    $txtOutput.Multiline = $true
    $txtOutput.ReadOnly = $true
    $txtOutput.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $txtOutput.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1f22")
    $txtOutput.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtOutput.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $runnerForm.Controls.Add($txtOutput)

    $btnCopy = New-Object System.Windows.Forms.Button
    $btnCopy.Text = "Copy Output"
    $btnCopy.Location = New-Object System.Drawing.Point(20, 385)
    $btnCopy.Size = New-Object System.Drawing.Size(120, 36)
    $btnCopy.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnCopy.FlatStyle = 'Flat'
    $btnCopy.FlatAppearance.BorderSize = 1
    $btnCopy.Enabled = $false
    $runnerForm.Controls.Add($btnCopy)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(430, 385)
    $btnCancel.Size = New-Object System.Drawing.Size(105, 36)
    $btnCancel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnCancel.FlatStyle = 'Flat'
    $btnCancel.FlatAppearance.BorderSize = 1
    $runnerForm.Controls.Add($btnCancel)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Location = New-Object System.Drawing.Point(555, 385)
    $btnClose.Size = New-Object System.Drawing.Size(105, 36)
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $btnClose.Enabled = $false
    $runnerForm.Controls.Add($btnClose)

    $script:runnerProc = $null
    $script:runnerCancelled = $false

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
        $pBar.MarqueeAnimationSpeed = 0
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
        $lblStatus.Text = "Running..."
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
                $pBar.Value = 100
                if ($script:runnerProc.ExitCode -eq 0) {
                    $lblStatus.Text = "Completed successfully (Exit code: 0)."
                    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                } else {
                    $lblStatus.Text = "Finished with exit code $($script:runnerProc.ExitCode)."
                    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
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

# Internet Speed Test Dialog
function Show-SpeedTestDialog {
    $stForm = New-Object System.Windows.Forms.Form
    $stForm.Text = "Internet Speed Test"
    $stForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $stForm.ClientSize = New-Object System.Drawing.Size(650, 480)
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
    $lblServer.Text = "Server: Cloudflare Edge Network (Detecting nearest location...)"
    $lblServer.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblServer.Location = New-Object System.Drawing.Point(20, 15)
    $lblServer.Size = New-Object System.Drawing.Size(610, 20)
    $lblServer.AutoEllipsis = $true
    $stForm.Controls.Add($lblServer)

    # 4 Metric Cards Panel
    $cardPanel = New-Object System.Windows.Forms.Panel
    $cardPanel.Location = New-Object System.Drawing.Point(20, 45)
    $cardPanel.Size = New-Object System.Drawing.Size(610, 85)
    $cardPanel.BackColor = [System.Drawing.Color]::Transparent
    $stForm.Controls.Add($cardPanel)

    $createCard = {
        param($title, $initialVal, $left, $width)
        $p = New-Object System.Windows.Forms.Panel
        $p.Location = New-Object System.Drawing.Point($left, 0)
        $p.Size = New-Object System.Drawing.Size($width, 85)
        $p.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
        $p.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $cardPanel.Controls.Add($p)

        $lTitle = New-Object System.Windows.Forms.Label
        $lTitle.Text = $title
        $lTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
        $lTitle.Location = New-Object System.Drawing.Point(0, 10)
        $lTitle.Size = New-Object System.Drawing.Size($width, 18)
        $lTitle.TextAlign = 'MiddleCenter'
        $p.Controls.Add($lTitle)

        $lVal = New-Object System.Windows.Forms.Label
        $lVal.Text = $initialVal
        $lVal.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $lVal.Font = New-Object System.Drawing.Font($font.FontFamily, 18, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $lVal.Location = New-Object System.Drawing.Point(0, 32)
        $lVal.Size = New-Object System.Drawing.Size($width, 30)
        $lVal.TextAlign = 'MiddleCenter'
        $p.Controls.Add($lVal)

        return $lVal
    }

    $valPing = &$createCard "PING" "-- ms" 0 145
    $valJitter = &$createCard "JITTER" "-- ms" 155 145
    $valDownload = &$createCard "DOWNLOAD" "-- Mbps" 310 145
    $valUpload = &$createCard "UPLOAD" "-- Mbps" 465 145

    # Gauge / Speed Bar Display
    $lblCurrentPhase = New-Object System.Windows.Forms.Label
    $lblCurrentPhase.Text = "Ready to test"
    $lblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblCurrentPhase.Font = New-Object System.Drawing.Font($font.FontFamily, 13, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $lblCurrentPhase.Location = New-Object System.Drawing.Point(20, 145)
    $lblCurrentPhase.Size = New-Object System.Drawing.Size(610, 22)
    $lblCurrentPhase.TextAlign = 'MiddleCenter'
    $stForm.Controls.Add($lblCurrentPhase)

    # Visualizer Progress Track
    $gaugeTrack = New-Object System.Windows.Forms.Panel
    $gaugeTrack.Location = New-Object System.Drawing.Point(20, 175)
    $gaugeTrack.Size = New-Object System.Drawing.Size(610, 26)
    $gaugeTrack.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $gaugeTrack.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $stForm.Controls.Add($gaugeTrack)

    $gaugeFill = New-Object System.Windows.Forms.Panel
    $gaugeFill.Location = New-Object System.Drawing.Point(1, 1)
    $gaugeFill.Size = New-Object System.Drawing.Size(0, 22)
    $gaugeFill.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
    $gaugeTrack.Controls.Add($gaugeFill)

    # Live Graph / Output Area
    $liveChart = New-Object System.Windows.Forms.PictureBox
    $liveChart.Location = New-Object System.Drawing.Point(20, 212)
    $liveChart.Size = New-Object System.Drawing.Size(610, 160)
    $liveChart.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1f22")
    $stForm.Controls.Add($liveChart)

    # Settings Row
    $lblStreams = New-Object System.Windows.Forms.Label
    $lblStreams.Text = "Parallel Streams:"
    $lblStreams.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblStreams.Location = New-Object System.Drawing.Point(20, 390)
    $lblStreams.AutoSize = $true
    $stForm.Controls.Add($lblStreams)

    $cmbStreams = New-Object System.Windows.Forms.ComboBox
    $cmbStreams.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $cmbStreams.Items.AddRange(@("1 Stream", "2 Streams", "4 Streams (Recommended)", "8 Streams"))
    $cmbStreams.SelectedIndex = 2
    $cmbStreams.Location = New-Object System.Drawing.Point(130, 386)
    $cmbStreams.Size = New-Object System.Drawing.Size(180, 26)
    $cmbStreams.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $cmbStreams.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $stForm.Controls.Add($cmbStreams)

    # Buttons
    $btnStart = New-Object System.Windows.Forms.Button
    $btnStart.Text = "Start Test"
    $btnStart.Location = New-Object System.Drawing.Point(395, 385)
    $btnStart.Size = New-Object System.Drawing.Size(115, 36)
    $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnStart.FlatStyle = 'Flat'
    $btnStart.FlatAppearance.BorderSize = 1
    $stForm.Controls.Add($btnStart)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Location = New-Object System.Drawing.Point(520, 385)
    $btnClose.Size = New-Object System.Drawing.Size(110, 36)
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $stForm.Controls.Add($btnClose)

    $script:speedTestRunning = $false
    $script:speedTestCancel = $false
    $speedHistory = [System.Collections.Generic.List[double]]::new()

    $drawChart = {
        $bmp = New-Object System.Drawing.Bitmap($liveChart.Width, $liveChart.Height)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.Clear([System.Drawing.ColorTranslator]::FromHtml("#1e1f22"))

        $penGrid = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#2a2b2f"), 1)
        for ($gy = 30; $gy -lt $liveChart.Height; $gy += 35) {
            $g.DrawLine($penGrid, 0, $gy, $liveChart.Width, $gy)
        }

        if ($speedHistory.Count -gt 1) {
            $maxVal = 100.0
            foreach ($v in $speedHistory) { if ($v -gt $maxVal) { $maxVal = $v } }
            $maxVal = [math]::Ceiling($maxVal * 1.15)

            $penLine = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#6f1fde"), 2)
            $stepX = $liveChart.Width / [math]::Max(1, ($speedHistory.Count - 1))

            for ($i = 0; $i -lt ($speedHistory.Count - 1); $i++) {
                $x1 = $i * $stepX
                $y1 = $liveChart.Height - (($speedHistory[$i] / $maxVal) * ($liveChart.Height - 20)) - 10
                $x2 = ($i + 1) * $stepX
                $y2 = $liveChart.Height - (($speedHistory[$i + 1] / $maxVal) * ($liveChart.Height - 20)) - 10
                $g.DrawLine($penLine, [float]$x1, [float]$y1, [float]$x2, [float]$y2)
            }
            $penLine.Dispose()
        }
        $penGrid.Dispose()
        $g.Dispose()

        $old = $liveChart.Image
        $liveChart.Image = $bmp
        if ($old) { $old.Dispose() }
    }

    $stForm.Add_Load({
        Invoke-HMTScale $stForm
        Set-RoundedControl $btnStart
        Set-RoundedControl $btnClose
        &$drawChart
    })

    $btnClose.Add_Click({
        $script:speedTestCancel = $true
        $stForm.Close()
    })

    $btnStart.Add_Click({
        if ($script:speedTestRunning) {
            $script:speedTestCancel = $true
            $btnStart.Text = "Cancelling..."
            $btnStart.Enabled = $false
            return
        }

        $script:speedTestRunning = $true
        $script:speedTestCancel = $false
        $btnStart.Text = "Cancel"
        $cmbStreams.Enabled = $false
        $speedHistory.Clear()
        &$drawChart

        $streamCount = switch ($cmbStreams.SelectedIndex) {
            0 { 1 }
            1 { 2 }
            3 { 8 }
            Default { 4 }
        }

        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor 12288
        $handler = New-Object System.Net.Http.HttpClientHandler
        $client = New-Object System.Net.Http.HttpClient -ArgumentList $handler
        $client.Timeout = [System.TimeSpan]::FromSeconds(30)
        $client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) HMT-SpeedTest/1.0")

        try {
            # 1. Edge Location & Latency/Jitter test
            $lblCurrentPhase.Text = "Measuring Ping & Jitter..."
            $gaugeFill.Width = 0
            $latencies = @()

            for ($p = 0; $p -lt 8; $p++) {
                if ($script:speedTestCancel) { break }
                $swPing = [System.Diagnostics.Stopwatch]::StartNew()
                try {
                    $resp = $client.GetAsync("https://speed.cloudflare.com/__down?bytes=0").GetAwaiter().GetResult()
                    $swPing.Stop()
                    $lat = $swPing.Elapsed.TotalMilliseconds
                    $latencies += $lat

                    if ($p -eq 0 -and $resp.Headers.Contains("cf-ray")) {
                        $ray = ($resp.Headers.GetValues("cf-ray") | Select-Object -First 1)
                        if ($ray -match '-([A-Z]{3})$') {
                            $colo = $matches[1]
                            $lblServer.Text = "Connected Edge Datacenter: Cloudflare Anycast ($colo)"
                        }
                    }
                } catch { $swPing.Stop() }

                $valPing.Text = "$([math]::Round(($latencies | Measure-Object -Minimum).Minimum, 1)) ms"
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 40
            }

            if ($latencies.Count -gt 1) {
                $diffs = @()
                for ($d = 0; $d -lt ($latencies.Count - 1); $d++) {
                    $diffs += [math]::Abs($latencies[$d + 1] - $latencies[$d])
                }
                $avgJitter = ($diffs | Measure-Object -Average).Average
                $valJitter.Text = "$([math]::Round($avgJitter, 1)) ms"
            }

            if ($script:speedTestCancel) { throw "Cancelled" }

            # 2. Download Speed Test
            $lblCurrentPhase.Text = "Testing Download Speed ($streamCount streams)..."
            $gaugeFill.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
            $speedHistory.Clear()

            $downBytes = 25000000
            $downUrl = "https://speed.cloudflare.com/__down?bytes=$downBytes"
            $swDown = [System.Diagnostics.Stopwatch]::StartNew()
            $lastDownTick = [System.Diagnostics.Stopwatch]::StartNew()

            $tasks = @()
            for ($s = 0; $s -lt $streamCount; $s++) {
                $tasks += $client.GetByteArrayAsync($downUrl)
            }

            while (-not ([System.Threading.Tasks.Task]::WaitAll($tasks, 100))) {
                if ($script:speedTestCancel) { break }
                $elapsed = [math]::Max(0.001, $swDown.Elapsed.TotalSeconds)
                if ($lastDownTick.ElapsedMilliseconds -ge 120) {
                    $lastDownTick.Restart()
                    $curBytes = 0
                    foreach ($t in $tasks) {
                        if ($t.IsCompleted -and -not $t.IsFaulted) { $curBytes += $downBytes }
                        else { $curBytes += [int]($downBytes * 0.45) }
                    }
                    $curMbps = (($curBytes * 8) / 1MB) / $elapsed
                    $speedHistory.Add($curMbps)
                    $valDownload.Text = "$([math]::Round($curMbps, 1)) Mbps"
                    
                    $maxTrackW = $gaugeTrack.ClientSize.Width - 2
                    $pct = [math]::Min(1.0, ($elapsed / 8.0))
                    $gaugeFill.Width = [int]($maxTrackW * $pct)
                    &$drawChart
                }
                [System.Windows.Forms.Application]::DoEvents()
            }

            $swDown.Stop()
            $totalDownBytes = $downBytes * $streamCount
            $finalDownMbps = (($totalDownBytes * 8) / 1MB) / [math]::Max(0.001, $swDown.Elapsed.TotalSeconds)
            $valDownload.Text = "$([math]::Round($finalDownMbps, 1)) Mbps"
            $speedHistory.Add($finalDownMbps)
            &$drawChart

            if ($script:speedTestCancel) { throw "Cancelled" }

            # 3. Upload Speed Test
            $lblCurrentPhase.Text = "Testing Upload Speed ($streamCount streams)..."
            $gaugeFill.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
            $speedHistory.Clear()

            $upPayload = New-Object byte[] (5 * 1024 * 1024)
            [System.Random]::new().NextBytes($upPayload)
            $upUrl = "https://speed.cloudflare.com/__up"
            $swUp = [System.Diagnostics.Stopwatch]::StartNew()
            $lastUpTick = [System.Diagnostics.Stopwatch]::StartNew()

            $upTasks = @()
            for ($s = 0; $s -lt $streamCount; $s++) {
                $content = New-Object System.Net.Http.ByteArrayContent($upPayload, 0, $upPayload.Length)
                $upTasks += $client.PostAsync($upUrl, $content)
            }

            while (-not ([System.Threading.Tasks.Task]::WaitAll($upTasks, 100))) {
                if ($script:speedTestCancel) { break }
                $elapsed = [math]::Max(0.001, $swUp.Elapsed.TotalSeconds)
                if ($lastUpTick.ElapsedMilliseconds -ge 120) {
                    $lastUpTick.Restart()
                    $curBytes = 0
                    foreach ($t in $upTasks) {
                        if ($t.IsCompleted -and -not $t.IsFaulted) { $curBytes += $upPayload.Length }
                        else { $curBytes += [int]($upPayload.Length * 0.45) }
                    }
                    $curUpMbps = (($curBytes * 8) / 1MB) / $elapsed
                    $speedHistory.Add($curUpMbps)
                    $valUpload.Text = "$([math]::Round($curUpMbps, 1)) Mbps"
                    
                    $maxTrackW = $gaugeTrack.ClientSize.Width - 2
                    $pct = [math]::Min(1.0, ($elapsed / 8.0))
                    $gaugeFill.Width = [int]($maxTrackW * $pct)
                    &$drawChart
                }
                [System.Windows.Forms.Application]::DoEvents()
            }

            $swUp.Stop()
            $totalUpBytes = $upPayload.Length * $streamCount
            $finalUpMbps = (($totalUpBytes * 8) / 1MB) / [math]::Max(0.001, $swUp.Elapsed.TotalSeconds)
            $valUpload.Text = "$([math]::Round($finalUpMbps, 1)) Mbps"
            $speedHistory.Add($finalUpMbps)
            &$drawChart

            $lblCurrentPhase.Text = "Speed Test Complete!"
            $gaugeFill.Width = $gaugeTrack.ClientSize.Width - 2
        } catch {
            if ($script:speedTestCancel) {
                $lblCurrentPhase.Text = "Test Cancelled."
            } else {
                $lblCurrentPhase.Text = "Test failed: $_"
            }
        } finally {
            $client.Dispose()
            $btnStart.Text = "Restart Test"
            $btnStart.Enabled = $true
            $cmbStreams.Enabled = $true
            $script:speedTestRunning = $false
        }
    })

    Show-HMTDialog $stForm | Out-Null
}

# TCP Checker Dialog
function Show-TcpCheckerDialog {
    $tcpForm = New-Object System.Windows.Forms.Form
    $tcpForm.Text = "TCP Port & Connection Checker"
    $tcpForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $tcpForm.ClientSize = New-Object System.Drawing.Size(650, 420)
    $tcpForm.StartPosition = 'CenterScreen'
    $tcpForm.Icon = $HMTIcon
    $tcpForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $tcpForm.MaximizeBox = $false
    $tcpForm.MinimizeBox = $true
    $tcpForm.Font = $font
    $tcpForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $tcpForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $tcpForm

    $y = 15
    $lblHost = New-Object System.Windows.Forms.Label
    $lblHost.Text = "Target Hostname / IP:"
    $lblHost.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblHost.Location = New-Object System.Drawing.Point(20, $y)
    $lblHost.AutoSize = $true
    $tcpForm.Controls.Add($lblHost)

    $txtHost = New-Object System.Windows.Forms.TextBox
    $txtHost.Location = New-Object System.Drawing.Point(170, ($y - 3))
    $txtHost.Size = New-Object System.Drawing.Size(200, 25)
    $txtHost.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtHost.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtHost.Text = "8.8.8.8"
    $tcpForm.Controls.Add($txtHost)

    $y += 35
    $lblPort = New-Object System.Windows.Forms.Label
    $lblPort.Text = "TCP Port:"
    $lblPort.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblPort.Location = New-Object System.Drawing.Point(20, $y)
    $lblPort.AutoSize = $true
    $tcpForm.Controls.Add($lblPort)

    $txtPort = New-Object System.Windows.Forms.TextBox
    $txtPort.Location = New-Object System.Drawing.Point(170, ($y - 3))
    $txtPort.Size = New-Object System.Drawing.Size(90, 25)
    $txtPort.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtPort.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtPort.Text = "53"
    $tcpForm.Controls.Add($txtPort)

    $btnCheck = New-Object System.Windows.Forms.Button
    $btnCheck.Location = New-Object System.Drawing.Point(275, ($y - 5))
    $btnCheck.Size = New-Object System.Drawing.Size(95, 30)
    $btnCheck.Text = "Test Port"
    $btnCheck.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnCheck.FlatStyle = 'Flat'
    $btnCheck.FlatAppearance.BorderSize = 1
    $tcpForm.Controls.Add($btnCheck)

    $y += 45
    $lblRes = New-Object System.Windows.Forms.Label
    $lblRes.Text = "Results & History:"
    $lblRes.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblRes.Location = New-Object System.Drawing.Point(20, $y)
    $lblRes.AutoSize = $true
    $tcpForm.Controls.Add($lblRes)

    $y += 25
    $txtLog = New-Object System.Windows.Forms.TextBox
    $txtLog.Location = New-Object System.Drawing.Point(20, $y)
    $txtLog.Size = New-Object System.Drawing.Size(610, 220)
    $txtLog.Multiline = $true
    $txtLog.ReadOnly = $true
    $txtLog.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $txtLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtLog.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $tcpForm.Controls.Add($txtLog)

    $y += 235
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

# Storage SMART & Health Summary Dialog (Fixed Total Writes calculation)
function Show-StorageHealthDialog {
    $shForm = New-Object System.Windows.Forms.Form
    $shForm.Text = "Storage SMART & Health Summary"
    $shForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $shForm.ClientSize = New-Object System.Drawing.Size(825, 360)
    $shForm.StartPosition = 'CenterScreen'
    $shForm.Icon = $HMTIcon
    $shForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $shForm.MaximizeBox = $false
    $shForm.MinimizeBox = $true
    $shForm.Font = $font
    $shForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $shForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $shForm

    $y = 15
    $shLV = New-Object System.Windows.Forms.ListView
    $shLV.Location = New-Object System.Drawing.Point(20, $y)
    $shLV.Size = New-Object System.Drawing.Size(785, 250)
    $shLV.View = [System.Windows.Forms.View]::Details
    $shLV.FullRowSelect = $true
    $shLV.GridLines = $true
    $shLV.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $shLV.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $shLV.Columns.Add("Disk #", 50) | Out-Null
    $shLV.Columns.Add("Model", 220) | Out-Null
    $shLV.Columns.Add("Media Type", 85) | Out-Null
    $shLV.Columns.Add("Size", 80) | Out-Null
    $shLV.Columns.Add("Wearout", 75) | Out-Null
    $shLV.Columns.Add("Total Writes", 95) | Out-Null
    $shLV.Columns.Add("Health Status", 95) | Out-Null
    $shLV.Columns.Add("Status", 80) | Out-Null
    [HMT.NativeMethods]::SetWindowTheme($shLV.Handle, "DarkMode_Explorer", $null) | Out-Null
    $shForm.Controls.Add($shLV)

    $populateDisks = {
        $shLV.Items.Clear()
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
                                if ($attrId -eq 241) { # 0xF1: Total LBAs Written
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
                            $writesStr = "$([math]::Round($bytesWritten / 1TB, 2)) TB"
                        } else {
                            $writesStr = "$([math]::Round($bytesWritten / 1GB, 1)) GB"
                        }
                    }

                    $item = New-Object System.Windows.Forms.ListViewItem([string]$d.DeviceId)
                    $item.SubItems.Add([string]$d.FriendlyName) | Out-Null
                    $item.SubItems.Add([string]$d.MediaType) | Out-Null
                    $sizeGb = [math]::Round($d.Size / 1GB, 1)
                    $item.SubItems.Add("$sizeGb GB") | Out-Null
                    $item.SubItems.Add($wearStr) | Out-Null
                    $item.SubItems.Add($writesStr) | Out-Null
                    $item.SubItems.Add([string]$d.HealthStatus) | Out-Null
                    $item.SubItems.Add(([string]($d.OperationalStatus -join ', '))) | Out-Null
                    $shLV.Items.Add($item) | Out-Null
                }
            } else {
                $item = New-Object System.Windows.Forms.ListViewItem("N/A")
                $item.SubItems.Add("No PhysicalDisks detected via WMI/CIM.") | Out-Null
                $shLV.Items.Add($item) | Out-Null
            }
        } catch {
            $item = New-Object System.Windows.Forms.ListViewItem("Err")
            $item.SubItems.Add("Error querying disk health: $_") | Out-Null
            $shLV.Items.Add($item) | Out-Null
        }
    }

    $y += 265
    $btnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh.Location = New-Object System.Drawing.Point(20, $y)
    $btnRefresh.Size = New-Object System.Drawing.Size(115, 35)
    $btnRefresh.Text = "Refresh"
    $btnRefresh.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnRefresh.FlatStyle = 'Flat'
    $btnRefresh.FlatAppearance.BorderSize = 1
    $shForm.Controls.Add($btnRefresh)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point(690, $y)
    $btnClose.Size = New-Object System.Drawing.Size(115, 35)
    $btnClose.Text = "Close"
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $shForm.Controls.Add($btnClose)

    $btnRefresh.Add_Click({ &$populateDisks })
    $btnClose.Add_Click({ $shForm.Close() })

    $shForm.Add_Load({
        Invoke-HMTScale $shForm
        Set-RoundedControl $btnRefresh
        Set-RoundedControl $btnClose
        &$populateDisks
    })

    Show-HMTDialog $shForm | Out-Null
}

# Packet Loss Test Dialog
function Show-PacketLossTestDialog {
    $pltForm = New-Object System.Windows.Forms.Form
    $pltForm.Text = "Packet Loss Test"
    $pltForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $pltForm.ClientSize = New-Object System.Drawing.Size(700, 480)
    $pltForm.StartPosition = 'CenterScreen'
    $pltForm.Icon = $HMTIcon
    $pltForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $pltForm.MaximizeBox = $false
    $pltForm.MinimizeBox = $true
    $pltForm.Font = $font
    $pltForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $pltForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $pltForm

    $y = 15
    $lblHost = New-Object System.Windows.Forms.Label
    $lblHost.Text = "Host/IP:"
    $lblHost.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblHost.Location = New-Object System.Drawing.Point(20, $y)
    $lblHost.AutoSize = $true
    $pltForm.Controls.Add($lblHost)

    $txtHost = New-Object System.Windows.Forms.TextBox
    $txtHost.Location = New-Object System.Drawing.Point(80, ($y - 3))
    $txtHost.Size = New-Object System.Drawing.Size(120, 25)
    $txtHost.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtHost.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtHost.Text = "8.8.8.8"
    $pltForm.Controls.Add($txtHost)

    $lblPps = New-Object System.Windows.Forms.Label
    $lblPps.Text = "Pings/Sec:"
    $lblPps.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblPps.Location = New-Object System.Drawing.Point(215, $y)
    $lblPps.AutoSize = $true
    $pltForm.Controls.Add($lblPps)

    $txtPps = New-Object System.Windows.Forms.TextBox
    $txtPps.Location = New-Object System.Drawing.Point(285, ($y - 3))
    $txtPps.Size = New-Object System.Drawing.Size(40, 25)
    $txtPps.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtPps.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtPps.Text = "5"
    $pltForm.Controls.Add($txtPps)

    $lblSize = New-Object System.Windows.Forms.Label
    $lblSize.Text = "Bytes:"
    $lblSize.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblSize.Location = New-Object System.Drawing.Point(340, $y)
    $lblSize.AutoSize = $true
    $pltForm.Controls.Add($lblSize)

    $txtSize = New-Object System.Windows.Forms.TextBox
    $txtSize.Location = New-Object System.Drawing.Point(385, ($y - 3))
    $txtSize.Size = New-Object System.Drawing.Size(40, 25)
    $txtSize.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtSize.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtSize.Text = "32"
    $pltForm.Controls.Add($txtSize)

    $lblDuration = New-Object System.Windows.Forms.Label
    $lblDuration.Text = "Duration (s):"
    $lblDuration.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblDuration.Location = New-Object System.Drawing.Point(440, $y)
    $lblDuration.AutoSize = $true
    $pltForm.Controls.Add($lblDuration)

    $txtDuration = New-Object System.Windows.Forms.TextBox
    $txtDuration.Location = New-Object System.Drawing.Point(520, ($y - 3))
    $txtDuration.Size = New-Object System.Drawing.Size(40, 25)
    $txtDuration.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtDuration.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtDuration.Text = "30"
    $pltForm.Controls.Add($txtDuration)

    $btnStart = New-Object System.Windows.Forms.Button
    $btnStart.Location = New-Object System.Drawing.Point(580, ($y - 5))
    $btnStart.Size = New-Object System.Drawing.Size(100, 30)
    $btnStart.Text = "Start Test"
    $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnStart.FlatStyle = 'Flat'
    $btnStart.FlatAppearance.BorderSize = 1
    $pltForm.Controls.Add($btnStart)

    $y += 40
    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text = "Status: Idle | Sent: 0 | Received: 0 | Lost: 0 (0.0%) | Min: 0ms | Avg: 0ms | Max: 0ms"
    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblStatus.Location = New-Object System.Drawing.Point(20, $y)
    $lblStatus.Size = New-Object System.Drawing.Size(660, 20)
    $pltForm.Controls.Add($lblStatus)

    $y += 25
    $graphBox = New-Object System.Windows.Forms.PictureBox
    $graphBox.Location = New-Object System.Drawing.Point(20, $y)
    $graphBox.Size = New-Object System.Drawing.Size(660, 180)
    $graphBox.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $pltForm.Controls.Add($graphBox)

    $y += 190
    $txtLog = New-Object System.Windows.Forms.TextBox
    $txtLog.Location = New-Object System.Drawing.Point(20, $y)
    $txtLog.Size = New-Object System.Drawing.Size(660, 130)
    $txtLog.Multiline = $true
    $txtLog.ReadOnly = $true
    $txtLog.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $txtLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtLog.Font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $pltForm.Controls.Add($txtLog)

    $y += 140
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point(565, $y)
    $btnClose.Size = New-Object System.Drawing.Size(115, 35)
    $btnClose.Text = "Close"
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $pltForm.Controls.Add($btnClose)

    $script:pltRunning = $false
    $script:pingHistory = [System.Collections.Generic.List[int]]::new()
    $script:pingStatusHistory = [System.Collections.Generic.List[string]]::new()
    $script:totalSent = 0
    $script:totalReceived = 0
    $script:totalLost = 0

    $timer = New-Object System.Windows.Forms.Timer

    $drawGraph = {
        $bmp = New-Object System.Drawing.Bitmap($graphBox.Width, $graphBox.Height)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.Clear([System.Drawing.ColorTranslator]::FromHtml("#202225"))

        $penGrid = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml("#3a3c43"), 1)
        for ($gy = 30; $gy -lt $graphBox.Height; $gy += 30) {
            $g.DrawLine($penGrid, 0, $gy, $graphBox.Width, $gy)
        }

        $count = $script:pingHistory.Count
        if ($count -gt 0) {
            $maxVal = 100
            foreach ($v in $script:pingHistory) { if ($v -gt $maxVal) { $maxVal = $v } }

            $stepX = $graphBox.Width / [math]::Max(1, $count)

            for ($i = 0; $i -lt $count; $i++) {
                $val = $script:pingHistory[$i]
                $stat = $script:pingStatusHistory[$i]
                $x = $i * $stepX

                if ($stat -eq "Success") {
                    $barHeight = ($val / $maxVal) * ($graphBox.Height - 20)
                    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#57F287"))
                    $g.FillRectangle($brush, [float]$x, [float]($graphBox.Height - $barHeight), [float]($stepX - 1), [float]$barHeight)
                    $brush.Dispose()
                } else {
                    $brush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml("#ED4245"))
                    $g.FillRectangle($brush, [float]$x, 0, [float]($stepX - 1), [float]$graphBox.Height)
                    $brush.Dispose()
                }
            }
        }
        $penGrid.Dispose()
        $g.Dispose()

        $oldImage = $graphBox.Image
        $graphBox.Image = $bmp
        if ($oldImage) { $oldImage.Dispose() }
    }

    $stopTest = {
        $timer.Stop()
        $script:pltRunning = $false
        $btnStart.Text = "Start Test"
        $txtHost.Enabled = $true
        $txtPps.Enabled = $true
        $txtSize.Enabled = $true
        $txtDuration.Enabled = $true
    }

    $timer.Add_Tick({
        if (-not $script:pltRunning) { return }

        if ($script:pltDurationSec -gt 0 -and $script:pltStopwatch.Elapsed.TotalSeconds -ge $script:pltDurationSec) {
            &$stopTest
            $lblStatus.Text = $lblStatus.Text.Replace("Running", "Finished")
            $txtLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] Test finished.`r`n")
            return
        }

        $pinger = New-Object System.Net.NetworkInformation.Ping
        $buf = New-Object byte[] $script:pltSize
        $script:totalSent++

        try {
            $reply = $pinger.Send($script:pltHost, 1000, $buf)
            if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                $script:totalReceived++
                $rtt = [int]$reply.RoundtripTime
                $script:pingHistory.Add($rtt)
                $script:pingStatusHistory.Add("Success")
                $txtLog.AppendText("Reply from $($reply.Address): bytes=$($reply.Buffer.Length) time=${rtt}ms TTL=$($reply.Options.Ttl)`r`n")
            } else {
                $script:totalLost++
                $script:pingHistory.Add(0)
                $script:pingStatusHistory.Add($reply.Status.ToString())
                $txtLog.AppendText("Request status: $($reply.Status)`r`n")
            }
        } catch {
            $script:totalLost++
            $script:pingHistory.Add(0)
            $script:pingStatusHistory.Add("Error")
            $txtLog.AppendText("Ping exception: $_`r`n")
        } finally {
            $pinger.Dispose()
        }

        $lossPct = if ($script:totalSent -gt 0) { [math]::Round(($script:totalLost / $script:totalSent) * 100, 1) } else { 0 }
        $successes = $script:pingHistory | Where-Object { $_ -gt 0 }
        $minRtt = if ($successes) { ($successes | Measure-Object -Minimum).Minimum } else { 0 }
        $maxRtt = if ($successes) { ($successes | Measure-Object -Maximum).Maximum } else { 0 }
        $avgRtt = if ($successes) { [math]::Round(($successes | Measure-Object -Average).Average, 1) } else { 0 }

        $lblStatus.Text = "Status: Running | Sent: $($script:totalSent) | Recv: $($script:totalReceived) | Lost: $($script:totalLost) ($lossPct%) | Min: ${minRtt}ms | Avg: ${avgRtt}ms | Max: ${maxRtt}ms"

        &$drawGraph
        $txtLog.SelectionStart = $txtLog.Text.Length
        $txtLog.ScrollToCaret()
    })

    $btnStart.Add_Click({
        if ($script:pltRunning) {
            &$stopTest
            $lblStatus.Text = $lblStatus.Text.Replace("Running", "Stopped")
        } else {
            $script:pltHost = $txtHost.Text.Trim()
            if ([string]::IsNullOrWhiteSpace($script:pltHost)) {
                PopupError "Target Host cannot be empty." "Warning"
                return
            }

            $pps = 0
            if (-not [int]::TryParse($txtPps.Text.Trim(), [ref]$pps) -or $pps -lt 1 -or $pps -gt 999) {
                PopupError "Pings / Sec must be an integer between 1 and 999." "Warning"
                return
            }

            $size = 0
            if (-not [int]::TryParse($txtSize.Text.Trim(), [ref]$size) -or $size -lt 1 -or $size -gt 65500) {
                PopupError "Bytes must be between 1 and 65500." "Warning"
                return
            }

            $dur = 0
            if (-not [int]::TryParse($txtDuration.Text.Trim(), [ref]$dur) -or $dur -lt 0) {
                PopupError "Duration must be an integer >= 0 (0 = infinite)." "Warning"
                return
            }

            $script:pltSize = $size
            $script:pltDurationSec = $dur
            $script:pingHistory.Clear()
            $script:pingStatusHistory.Clear()
            $script:totalSent = 0
            $script:totalReceived = 0
            $script:totalLost = 0
            $txtLog.Clear()

            $script:pltRunning = $true
            $btnStart.Text = "Cancel Test"
            $txtHost.Enabled = $false
            $txtPps.Enabled = $false
            $txtSize.Enabled = $false
            $txtDuration.Enabled = $false

            $intervalMs = if ($pps -gt 50) { 15 } else { [math]::Max(15, [int](1000 / $pps)) }
            $timer.Interval = $intervalMs
            $script:pltStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $timer.Start()
        }
    })

    $btnClose.Add_Click({
        &$stopTest
        $pltForm.Close()
    })

    $pltForm.Add_FormClosing({
        &$stopTest
    })

    $pltForm.Add_Load({
        Invoke-HMTScale $pltForm
        Set-RoundedControl $btnStart
        Set-RoundedControl $btnClose
    })

    Show-HMTDialog $pltForm | Out-Null
}
