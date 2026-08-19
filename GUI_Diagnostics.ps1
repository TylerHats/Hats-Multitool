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

    $script:crRunnerForm = New-Object System.Windows.Forms.Form
    $runnerForm = $script:crRunnerForm
    $runnerForm.Text = $Title
    $runnerForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $runnerForm.ClientSize = New-Object System.Drawing.Size(740, 510)
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

    $script:crLblTitle = New-Object System.Windows.Forms.Label
    $lblTitle = $script:crLblTitle
    $lblTitle.Text = $Title
    $lblTitle.Font = New-Object System.Drawing.Font($font.FontFamily, 14, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblTitle.Location = New-Object System.Drawing.Point(20, 12)
    $lblTitle.AutoSize = $true
    $runnerForm.Controls.Add($lblTitle)

    $script:crLblStatus = New-Object System.Windows.Forms.Label
    $lblStatus = $script:crLblStatus
    $lblStatus.Text = if ($Description) { "$Description (Starting...)" } else { "Executing command..." }
    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $lblStatus.Location = New-Object System.Drawing.Point(20, 36)
    $lblStatus.Size = New-Object System.Drawing.Size(700, 20)
    $lblStatus.AutoEllipsis = $true
    $runnerForm.Controls.Add($lblStatus)

    $script:crLblDetail = New-Object System.Windows.Forms.Label
    $lblDetail = $script:crLblDetail
    $lblDetail.Text = "Initializing diagnostic process..."
    $lblDetail.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblDetail.Font = New-Object System.Drawing.Font($font.FontFamily, 10, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $lblDetail.Location = New-Object System.Drawing.Point(20, 58)
    $lblDetail.Size = New-Object System.Drawing.Size(700, 18)
    $lblDetail.AutoEllipsis = $true
    $runnerForm.Controls.Add($lblDetail)

    $script:crPBar = New-Object HMT.Tools.SmoothProgressBar
    $pBar = $script:crPBar
    $pBar.Location = New-Object System.Drawing.Point(20, 80)
    $pBar.Size = New-Object System.Drawing.Size(700, 12)
    $pBar.BorderRadius = 4
    $pBar.ProgressColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
    $pBar.ProgressColorEnd = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $pBar.IsMarquee = $true
    $pBar.ShowShimmer = $true
    $pBar.Minimum = 0
    $pBar.Maximum = 100
    $runnerForm.Controls.Add($pBar)

    $script:crTxtOutput = New-Object System.Windows.Forms.TextBox
    $txtOutput = $script:crTxtOutput
    $txtOutput.Location = New-Object System.Drawing.Point(20, 100)
    $txtOutput.Size = New-Object System.Drawing.Size(700, 338)
    $txtOutput.Multiline = $true
    $txtOutput.ReadOnly = $true
    $txtOutput.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $txtOutput.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1f22")
    $txtOutput.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtOutput.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $runnerForm.Controls.Add($txtOutput)

    $yBtn = 455
    $script:crBtnCopy = New-Object System.Windows.Forms.Button
    $btnCopy = $script:crBtnCopy
    $btnCopy.Text = "Copy Output"
    $btnCopy.Location = New-Object System.Drawing.Point(20, $yBtn)
    $btnCopy.Size = New-Object System.Drawing.Size(110, 36)
    $btnCopy.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnCopy.FlatStyle = 'Flat'
    $btnCopy.FlatAppearance.BorderSize = 1
    $runnerForm.Controls.Add($btnCopy)

    $script:crBtnContinueBg = New-Object System.Windows.Forms.Button
    $btnContinueBg = $script:crBtnContinueBg
    $btnContinueBg.Text = "Continue in Background & Close"
    $btnContinueBg.Location = New-Object System.Drawing.Point(140, $yBtn)
    $btnContinueBg.Size = New-Object System.Drawing.Size(230, 36)
    $btnContinueBg.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnContinueBg.FlatStyle = 'Flat'
    $btnContinueBg.FlatAppearance.BorderSize = 1
    $runnerForm.Controls.Add($btnContinueBg)

    $script:crBtnCancel = New-Object System.Windows.Forms.Button
    $btnCancel = $script:crBtnCancel
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(485, $yBtn)
    $btnCancel.Size = New-Object System.Drawing.Size(110, 36)
    $btnCancel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
    $btnCancel.FlatStyle = 'Flat'
    $btnCancel.FlatAppearance.BorderSize = 1
    $runnerForm.Controls.Add($btnCancel)

    $script:crBtnClose = New-Object System.Windows.Forms.Button
    $btnClose = $script:crBtnClose
    $btnClose.Text = "Close"
    $btnClose.Location = New-Object System.Drawing.Point(605, $yBtn)
    $btnClose.Size = New-Object System.Drawing.Size(115, 36)
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $runnerForm.Controls.Add($btnClose)

    $script:runnerProc = $null
    $script:runnerCancelled = $false
    $script:runInBackground = $false
    $script:cmdStopwatch = $null
    $script:chkdskStage = 1
    $script:chkdskTotal = 3
    $script:lastProgressPct = 0
    $script:lastLoggedProgress = -1

    $calculateEta = {
        param([double]$currentPct)
        if ($currentPct -le 2 -or -not $script:cmdStopwatch -or $script:cmdStopwatch.Elapsed.TotalSeconds -lt 4) {
            return "Calculating..."
        }
        $sec = $script:cmdStopwatch.Elapsed.TotalSeconds
        $rate = $currentPct / $sec
        if ($rate -le 0) { return "Estimating..." }
        $remSec = [int]((100 - $currentPct) / $rate)
        if ($remSec -le 0) { return "Finishing..." }
        if ($remSec -ge 3600) {
            return "~{0}h {1}m" -f [int]($remSec / 3600), [int](($remSec % 3600) / 60)
        } elseif ($remSec -ge 60) {
            return "~{0}m {1}s" -f [int]($remSec / 60), ($remSec % 60)
        } else {
            return "~{0}s" -f $remSec
        }
    }

    $btnCopy.Add_Click({
        if ($script:crTxtOutput.Text) {
            [System.Windows.Forms.Clipboard]::SetText($script:crTxtOutput.Text)
            PopupError "Output copied to clipboard." "Information"
        }
    }.GetNewClosure())

    $btnCancel.Add_Click({
        $confirm = PopupError "Are you sure you want to cancel and terminate this process ($Title)?" "Question" "YesNo"
        if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

        $script:runnerCancelled = $true
        if ($script:runnerProc -and -not $script:runnerProc.HasExited) {
            try { $script:runnerProc.Kill() } catch {}
        }
        $script:crLblStatus.Text = "Cancelled by user."
        $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
        $script:crLblDetail.Text = "Execution aborted."
        $script:crPBar.IsMarquee = $false
        $script:crPBar.Value = 0
        $script:crBtnCancel.Enabled = $false
        $script:crBtnContinueBg.Enabled = $false
        $script:crBtnClose.Enabled = $true
        $script:crBtnCopy.Enabled = $true
    }.GetNewClosure())

    $btnContinueBg.Add_Click({
        $script:runInBackground = $true
        if ($script:crPollTimer) { $script:crPollTimer.Stop() }
        $script:crRunnerForm.Close()
    }.GetNewClosure())

    $btnClose.Add_Click({
        if ($script:runnerProc -and -not $script:runnerProc.HasExited) {
            $choice = PopupError "This process ($Title) is still running.`n`nClick 'Yes' to continue running in the background and close this window.`nClick 'No' to abort and terminate the process.`nClick 'Cancel' to keep this window open." "Question" "YesNoCancel"
            if ($choice -eq [System.Windows.Forms.DialogResult]::Cancel) { return }
            if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
                $script:runInBackground = $true
                if ($script:crPollTimer) { $script:crPollTimer.Stop() }
                $script:crRunnerForm.Close()
                return
            } else {
                $script:runnerCancelled = $true
                try { $script:runnerProc.Kill() } catch {}
            }
        }
        if ($script:crPollTimer) { $script:crPollTimer.Stop() }
        $script:crRunnerForm.Close()
    }.GetNewClosure())

    $runnerForm.Add_Load({
        Invoke-HMTScale $script:crRunnerForm
        Set-RoundedControl $script:crBtnCopy
        Set-RoundedControl $script:crBtnContinueBg
        Set-RoundedControl $script:crBtnCancel
        Set-RoundedControl $script:crBtnClose
    }.GetNewClosure())

    $processLine = {
        param([string]$line)
        if ([string]::IsNullOrWhiteSpace($line)) { return }
        
        $lineClean = $line.Trim()
        $elapsed = if ($script:cmdStopwatch) { $script:cmdStopwatch.Elapsed } else { [timespan]::Zero }
        $elapsedStr = "{0:D2}:{1:D2}" -f [int]$elapsed.TotalMinutes, $elapsed.Seconds

        # --- 1. SFC Parsing ---
        if ($lineClean -match '^Verification\s+(\d+)%\s+complete') {
            $pct = [int]$matches[1]
            $script:lastProgressPct = $pct
            $script:crPBar.IsMarquee = $false
            $script:crPBar.Value = [math]::Max(0, [math]::Min(100, $pct))
            
            $etaStr = &$calculateEta $pct
            $script:crLblStatus.Text = "Scanning and verifying protected system files ($pct% complete)..."
            $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
            $script:crLblDetail.Text = "Stage: Verification ($pct%) | Elapsed: $elapsedStr | Est. Remaining: $etaStr"

            # Filter repetitive % lines and only log milestones to keep the log clean
            if ($pct -eq 100 -or ($pct % 20 -eq 0 -and $pct -ne $script:lastLoggedProgress)) {
                $script:lastLoggedProgress = $pct
                $script:crTxtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] Verification $pct% complete`r`n")
            }
        }
        elseif ($lineClean -match 'Beginning system scan') {
            $script:crPBar.IsMarquee = $true
            $script:crLblStatus.Text = "Stage 1/2: Initializing system file scan..."
            $script:crLblDetail.Text = "Elapsed: $elapsedStr | Preparing Windows Resource Protection"
            $script:crTxtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'Beginning verification phase') {
            $script:crPBar.IsMarquee = $false
            $script:crPBar.Value = 0
            $script:crLblStatus.Text = "Stage 2/2: Verifying Windows system files..."
            $script:crLblDetail.Text = "Elapsed: $elapsedStr | Verifying component integrity"
            $script:crTxtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'did not find any integrity violations') {
            $script:crPBar.IsMarquee = $false
            $script:crPBar.Value = 100
            $script:crLblStatus.Text = "Verification Complete: No integrity violations found."
            $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
            $script:crLblDetail.Text = "Elapsed: $elapsedStr | All system files are intact."
            $script:crTxtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'found corrupt files and successfully repaired them') {
            $script:crPBar.IsMarquee = $false
            $script:crPBar.Value = 100
            $script:crLblStatus.Text = "Verification Complete: Corrupted files found and successfully repaired."
            $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
            $script:crLblDetail.Text = "Elapsed: $elapsedStr | Repairs successfully applied to system."
            $script:crTxtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'found corrupt files but was unable to fix some') {
            $script:crLblStatus.Text = "Corrupted files found that could not all be repaired."
            $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
            $script:crLblDetail.Text = "Elapsed: $elapsedStr | Check CBS.log for detailed repair errors."
            $script:crTxtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }

        # --- 2. DISM & .NET 3.5 Feature Parsing ---
        elseif ($lineClean -match '\[\s*={0,}\s*(\d+(?:\.\d+)?)%\s*={0,}\s*\]' -or $lineClean -match '^(\d+(?:\.\d+)?)%\s*$') {
            $pctFloat = [double]$matches[1]
            $pct = [int]$pctFloat
            $script:lastProgressPct = $pct
            $script:crPBar.IsMarquee = $false
            $script:crPBar.Value = [math]::Max(0, [math]::Min(100, $pct))

            $etaStr = &$calculateEta $pctFloat

            $phaseText = "Processing component store..."
            if ($pctFloat -lt 20.0) {
                $phaseText = "Stage 1/3: Checking component store corruption & hash integrity..."
            } elseif ($pctFloat -lt 80.0) {
                $phaseText = "Stage 2/3: Restoring store & downloading repair payloads from Windows Update..."
            } elseif ($pctFloat -lt 100.0) {
                $phaseText = "Stage 3/3: Applying component repairs to Windows system image..."
            } else {
                $phaseText = "Finalizing component store operations..."
            }

            $script:crLblStatus.Text = $phaseText
            $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
            $script:crLblDetail.Text = "Progress: $pctFloat% | Elapsed: $elapsedStr | Est. Remaining: $etaStr"

            # Log clean milestone entries rather than 100+ console progress lines
            if ($pct -eq 100 -or ($pct % 20 -eq 0 -and $pct -ne $script:lastLoggedProgress)) {
                $script:lastLoggedProgress = $pct
                $script:crTxtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] Progress: $pctFloat% complete`r`n")
            }
        }
        elseif ($lineClean -match 'The restore operation completed successfully|The operation completed successfully') {
            $script:crPBar.IsMarquee = $false
            $script:crPBar.Value = 100
            $script:crLblStatus.Text = "Operation completed successfully."
            $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
            $script:crLblDetail.Text = "Elapsed: $elapsedStr | Image health restored successfully."
            $script:crTxtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'No component store corruption detected') {
            $script:crPBar.IsMarquee = $false
            $script:crPBar.Value = 100
            $script:crLblStatus.Text = "No component store corruption detected."
            $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
            $script:crLblDetail.Text = "Elapsed: $elapsedStr | Component store is clean and healthy."
            $script:crTxtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }

        # --- 3. CHKDSK Parsing ---
        elseif ($lineClean -match 'Stage\s+(\d+)\s*(?:of\s*(\d+))?:\s*([^\r\n.]+)') {
            $stg = [int]$matches[1]
            $stgTot = if ($matches[2]) { [int]$matches[2] } else { 3 }
            $stgDesc = $matches[3].Trim()
            $script:chkdskStage = $stg
            $script:chkdskTotal = $stgTot
            $script:crPBar.IsMarquee = $false
            $stageBase = [int](($stg - 1) * (100 / $stgTot))
            $script:crPBar.Value = $stageBase
            $script:crLblStatus.Text = "Stage $stg of $($stgTot): $stgDesc..."
            $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
            $script:crLblDetail.Text = "Stage $stg/$stgTot | Elapsed: $elapsedStr | Analyzing file system structure"
            $script:crTxtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] Stage $stg of $($stgTot): $stgDesc`r`n")
        }
        elseif ($lineClean -match '(\d+)\s*(?:percent|%)\s*complete') {
            $stgPct = [int]$matches[1]
            $stg = if ($script:chkdskStage) { $script:chkdskStage } else { 1 }
            $stgTot = if ($script:chkdskTotal) { $script:chkdskTotal } else { 3 }
            $overallPct = [int]((($stg - 1) * (100 / $stgTot)) + ($stgPct / $stgTot))
            $script:crPBar.IsMarquee = $false
            $script:crPBar.Value = [math]::Max(0, [math]::Min(100, $overallPct))
            $etaStr = &$calculateEta $overallPct
            $script:crLblDetail.Text = "Stage $stg/$stgTot ($stgPct%) | Overall: ~$overallPct% | Elapsed: $elapsedStr | Est. Remaining: $etaStr"

            if ($stgPct % 25 -eq 0 -and $stgPct -ne $script:lastLoggedProgress) {
                $script:lastLoggedProgress = $stgPct
                $script:crTxtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] Stage $($stg): $stgPct% complete (Overall: ~$overallPct%)`r`n")
            }
        }
        elseif ($lineClean -match 'The type of the file system is\s+(\w+)') {
            $script:crLblDetail.Text = "File System: $($matches[1]) | Initializing volume check..."
            $script:crTxtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'Windows has scanned the file system and found no problems') {
            $script:crPBar.IsMarquee = $false
            $script:crPBar.Value = 100
            $script:crLblStatus.Text = "Check Disk Complete: No file system problems found."
            $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
            $script:crLblDetail.Text = "Elapsed: $elapsedStr | Volume is clean and consistent."
            $script:crTxtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        else {
            # Standard diagnostic log line
            $script:crTxtOutput.AppendText($line + "`r`n")
        }

        $script:crTxtOutput.SelectionStart = $script:crTxtOutput.Text.Length
        $script:crTxtOutput.ScrollToCaret()
    }

    $script:cmdOutputQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()

    $script:crPollTimer = New-Object System.Windows.Forms.Timer
    $pollTimer = $script:crPollTimer
    $pollTimer.Interval = 40
    $pollTimer.Add_Tick({
        if ($null -ne $script:cmdOutputQueue) {
            $line = $null
            while ($script:cmdOutputQueue.TryDequeue([ref]$line)) {
                if ($null -ne $line) {
                    &$processLine $line
                }
            }
        }

        if ($null -ne $script:runnerProc) {
            if ($script:runnerProc.HasExited -or $script:runnerCancelled) {
                # Drain any remaining output lines
                if ($null -ne $script:cmdOutputQueue) {
                    $remLine = $null
                    while ($script:cmdOutputQueue.TryDequeue([ref]$remLine)) {
                        if ($null -ne $remLine) { &$processLine $remLine }
                    }
                }

                if ($script:crPollTimer) { $script:crPollTimer.Stop() }
                $script:crPBar.IsMarquee = $false
                $script:crPBar.Value = 100
                $elapsed = if ($script:cmdStopwatch) { $script:cmdStopwatch.Elapsed } else { [timespan]::Zero }
                $elapsedStr = "{0:D2}:{1:D2}" -f [int]$elapsed.TotalMinutes, $elapsed.Seconds

                if ($script:runnerCancelled) {
                    $script:crLblStatus.Text = "Execution cancelled."
                    $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
                } elseif ($script:runnerProc.ExitCode -eq 0) {
                    $script:crLblStatus.Text = "Completed successfully (Exit code: 0)."
                    $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                    $script:crLblDetail.Text = "Total Execution Time: $elapsedStr | Success"
                } else {
                    $script:crLblStatus.Text = "Finished with exit code $($script:runnerProc.ExitCode)."
                    $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
                    $script:crLblDetail.Text = "Total Execution Time: $elapsedStr | Check log output above."
                }

                $script:crBtnCancel.Enabled = $false
                $script:crBtnContinueBg.Enabled = $false
                $script:crBtnClose.Enabled = $true
                $script:crBtnCopy.Enabled = $true
            }
        }
    }.GetNewClosure())

    $runnerForm.Add_Shown({
        $script:cmdStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $script:crLblStatus.Text = "Running diagnostic process..."
        $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")

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
        $script:runnerProc.EnableRaisingEvents = $true

        $outHandler = [System.Diagnostics.DataReceivedEventHandler]{
            param($s, $e)
            if ($null -ne $e.Data -and $null -ne $script:cmdOutputQueue) {
                $script:cmdOutputQueue.Enqueue($e.Data)
            }
        }
        $script:runnerProc.add_OutputDataReceived($outHandler)
        $script:runnerProc.add_ErrorDataReceived($outHandler)

        try {
            $script:runnerProc.Start() | Out-Null
            $script:runnerProc.BeginOutputReadLine()
            $script:runnerProc.BeginErrorReadLine()
            if ($script:crPollTimer) { $script:crPollTimer.Start() }
        } catch {
            $script:crLblStatus.Text = "Execution failed: $_"
            $script:crLblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
            $script:crTxtOutput.AppendText("`r`nError starting process: $_`r`n")
            $script:crBtnCancel.Enabled = $false
            $script:crBtnContinueBg.Enabled = $false
            $script:crBtnClose.Enabled = $true
            $script:crBtnCopy.Enabled = $true
        }
    }.GetNewClosure())

    $runnerForm.Add_FormClosing({
        if ($script:crPollTimer) {
            $script:crPollTimer.Stop()
            $script:crPollTimer.Dispose()
        }
        if (-not $script:runInBackground -and $script:runnerProc -and -not $script:runnerProc.HasExited) {
            try { $script:runnerProc.Kill() } catch {}
        }
    }.GetNewClosure())

    Show-HMTWindow $script:crRunnerForm | Out-Null
}

# ==============================================================================
# 2. Internet Speed Test Dialog (Cloudflare Anycast + Smooth GDI+ Graph)
# ==============================================================================
function Show-SpeedTestDialog {
    $script:stForm = New-Object System.Windows.Forms.Form
    $stForm = $script:stForm
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
    $script:stLblServer = New-Object System.Windows.Forms.Label
    $lblServer = $script:stLblServer
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

    $script:stValPing = &$createCard "PING" "-- ms" 0 152
    $valPing = $script:stValPing
    $script:stValJitter = &$createCard "JITTER" "-- ms" 162 152
    $valJitter = $script:stValJitter
    $script:stValDownload = &$createCard "DOWNLOAD" "-- Mbps" 324 152
    $valDownload = $script:stValDownload
    $script:stValUpload = &$createCard "UPLOAD" "-- Mbps" 486 152
    $valUpload = $script:stValUpload
    $valDownload.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#00A8FC")
    $valUpload.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#BD00FF")

    # Status / Phase Indicator
    $script:stLblCurrentPhase = New-Object System.Windows.Forms.Label
    $lblCurrentPhase = $script:stLblCurrentPhase
    $lblCurrentPhase.Text = "Ready to test"
    $lblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblCurrentPhase.Font = New-Object System.Drawing.Font($font.FontFamily, 12, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $lblCurrentPhase.Location = New-Object System.Drawing.Point(20, 130)
    $lblCurrentPhase.Size = New-Object System.Drawing.Size(640, 20)
    $lblCurrentPhase.TextAlign = 'MiddleCenter'
    $stForm.Controls.Add($lblCurrentPhase)

    # Smooth GDI+ Double-Buffered Graph
    $script:stSmoothChart = New-Object HMT.Tools.SmoothGraphControl
    $smoothChart = $script:stSmoothChart
    $smoothChart.Location = New-Object System.Drawing.Point(20, 155)
    $smoothChart.Size = New-Object System.Drawing.Size(640, 220)
    $smoothChart.UnitLabel = "Mbps"
    $smoothChart.LineColor = [System.Drawing.ColorTranslator]::FromHtml("#00A8FC")
    $smoothChart.MaxPoints = 250
    $stForm.Controls.Add($smoothChart)

    # Settings Row
    $yBot = 390
    $lblStreams = New-Object System.Windows.Forms.Label
    $lblStreams.Text = "Streams:"
    $lblStreams.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblStreams.Location = New-Object System.Drawing.Point(20, ($yBot + 6))
    $lblStreams.AutoSize = $true
    $stForm.Controls.Add($lblStreams)

    $script:stCmbStreams = New-Object HMT.Tools.DarkComboBox
    $cmbStreams = $script:stCmbStreams
    $cmbStreams.Items.AddRange(@("2 Streams", "4 Streams (Recommended)", "8 Streams", "16 Streams (Gigabit+)"))
    $cmbStreams.SelectedIndex = 1
    $cmbStreams.Location = New-Object System.Drawing.Point(85, $yBot)
    $cmbStreams.Size = New-Object System.Drawing.Size(200, 26)
    $stForm.Controls.Add($cmbStreams)

    # Buttons
    $script:stBtnStart = New-Object System.Windows.Forms.Button
    $btnStart = $script:stBtnStart
    $btnStart.Text = "Start Test"
    $btnStart.Location = New-Object System.Drawing.Point(415, ($yBot - 2))
    $btnStart.Size = New-Object System.Drawing.Size(120, 36)
    $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnStart.FlatStyle = 'Flat'
    $btnStart.FlatAppearance.BorderSize = 1
    $stForm.Controls.Add($btnStart)

    $script:stBtnClose = New-Object System.Windows.Forms.Button
    $btnClose = $script:stBtnClose
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
                $script:stLblServer.Text = "Server: Cloudflare Edge - $($json.city), $($json.country) (Colo: $($json.colo)) | IP: $($json.clientIp)"
            }
        } catch {
            $script:stLblServer.Text = "Server: Cloudflare Anycast Edge Network (Global CDN)"
        }
    }

    $btnStart.Add_Click({
        if ($script:stRunning) {
            if ($script:stEngine) { $script:stEngine.Cancel() }
            $script:stRunning = $false
            $script:stBtnStart.Text = "Start Test"
            $script:stLblCurrentPhase.Text = "Test cancelled."
            $script:stLblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
            $script:stCmbStreams.Enabled = $true
            $script:stBtnClose.Enabled = $true
            return
        }

        try {
            $script:stRunning = $true
            $script:stBtnStart.Text = "Cancel Test"
            $script:stCmbStreams.Enabled = $false
            $script:stBtnClose.Enabled = $false
            $script:stSmoothChart.Clear()

            $streamCount = switch ($script:stCmbStreams.SelectedIndex) {
                0 { 2 }
                1 { 4 }
                2 { 8 }
                3 { 16 }
                Default { 4 }
            }

            # --- Phase 1: Ping & Jitter ---
            $script:stLblCurrentPhase.Text = "Testing Latency & Jitter (Cloudflare Anycast)..."
            $script:stLblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
            $script:stValPing.Text = "-- ms"
            $script:stValJitter.Text = "-- ms"
            $script:stValDownload.Text = "-- Mbps"
            $script:stValUpload.Text = "-- Mbps"
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
                $script:stValPing.Text = "$([math]::Round($avgPing, 1)) ms"

                # Jitter calculation
                $jitterSum = 0
                for ($j = 1; $j -lt $pings.Count; $j++) {
                    $jitterSum += [math]::Abs($pings[$j] - $pings[$j - 1])
                }
                $avgJitter = $jitterSum / [math]::Max(1, ($pings.Count - 1))
                $script:stValJitter.Text = "$([math]::Round($avgJitter, 1)) ms"
            } else {
                $script:stValPing.Text = "N/A"
                $script:stValJitter.Text = "N/A"
            }

            if (-not $script:stRunning) { return }

            # --- Phase 2: Download Test (Blue #00A8FC) ---
            $colorBlue = [System.Drawing.ColorTranslator]::FromHtml("#00A8FC")
            $script:stLblCurrentPhase.Text = "Testing Download Speed ($streamCount streams)..."
            $script:stLblCurrentPhase.ForeColor = $colorBlue

            $downUrl = "https://speed.cloudflare.com/__down"
            $script:stEngine.StartDownloadTest($downUrl, $streamCount, 6, 14)

            while (-not $script:stEngine.IsFinished) {
                $sample = $script:stEngine.CurrentSample
                if ($null -ne $sample) {
                    $script:stSmoothChart.AddPoint($sample.CurrentMbps, $colorBlue)
                    $script:stValDownload.Text = "$([math]::Round($sample.AverageMbps, 1)) Mbps"
                    $script:stLblCurrentPhase.Text = "Downloading ($([math]::Round($sample.CurrentMbps, 1)) Mbps) | Total: $([math]::Round($sample.TotalBytesTransferred / 1MB, 1)) MB"
                }
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 40
                if (-not $script:stRunning) { break }
            }

            $finalDownMbps = 0
            if ($script:stEngine.Result) {
                $finalDownMbps = $script:stEngine.Result.AverageMbps
                $script:stValDownload.Text = "$([math]::Round($finalDownMbps, 1)) Mbps"
            }

            if (-not $script:stRunning) { return }
            Start-Sleep -Milliseconds 300

            # --- Phase 3: Upload Test (Purple #BD00FF) ---
            $colorPurple = [System.Drawing.ColorTranslator]::FromHtml("#BD00FF")
            $script:stLblCurrentPhase.Text = "Testing Upload Speed ($streamCount streams)..."
            $script:stLblCurrentPhase.ForeColor = $colorPurple

            $upUrl = "https://speed.cloudflare.com/__up"
            $script:stEngine.StartUploadTest($upUrl, $streamCount, 6, 14)

            while (-not $script:stEngine.IsFinished) {
                $sample = $script:stEngine.CurrentSample
                if ($null -ne $sample) {
                    $script:stSmoothChart.AddPoint($sample.CurrentMbps, $colorPurple)
                    $script:stValUpload.Text = "$([math]::Round($sample.AverageMbps, 1)) Mbps"
                    $script:stLblCurrentPhase.Text = "Uploading ($([math]::Round($sample.CurrentMbps, 1)) Mbps) | Total: $([math]::Round($sample.TotalBytesTransferred / 1MB, 1)) MB"
                }
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 40
                if (-not $script:stRunning) { break }
            }

            $finalUpMbps = 0
            if ($script:stEngine.Result) {
                $finalUpMbps = $script:stEngine.Result.AverageMbps
                $script:stValUpload.Text = "$([math]::Round($finalUpMbps, 1)) Mbps"
            }

            # --- Finished ---
            $script:stRunning = $false
            $script:stBtnStart.Text = "Test Again"
            $script:stCmbStreams.Enabled = $true
            $script:stBtnClose.Enabled = $true
            $script:stLblCurrentPhase.Text = "Speed Test Complete!"
            $script:stLblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
        } catch {
            $script:stRunning = $false
            $script:stBtnStart.Text = "Start Test"
            $script:stCmbStreams.Enabled = $true
            $script:stBtnClose.Enabled = $true
            $script:stLblCurrentPhase.Text = "Speed test error: $_"
            $script:stLblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
        } finally {
            $script:stRunning = $false
            $script:stCmbStreams.Enabled = $true
            $script:stBtnClose.Enabled = $true
        }
    }.GetNewClosure())

    $btnClose.Add_Click({
        if ($script:stRunning -and $script:stEngine) { $script:stEngine.Cancel() }
        if ($script:stForm) { $script:stForm.Close() }
    }.GetNewClosure())

    $stForm.Add_FormClosing({
        if ($script:stRunning -and $script:stEngine) { $script:stEngine.Cancel() }
    }.GetNewClosure())

    $stForm.Add_Load({
        Invoke-HMTScale $script:stForm
        Set-RoundedControl $script:stBtnStart
        Set-RoundedControl $script:stBtnClose
    }.GetNewClosure())

    $stForm.Add_Shown({
        &$detectServer
    }.GetNewClosure())

    Show-HMTWindow $script:stForm | Out-Null
}

# ==============================================================================
# 3. TCP Port & Connection Checker Dialog
# ==============================================================================
function Show-TcpCheckerDialog {
    $script:tcpForm = New-Object System.Windows.Forms.Form
    $tcpForm = $script:tcpForm
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

    $script:tcpHost = New-Object System.Windows.Forms.TextBox
    $txtHost = $script:tcpHost
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

    $script:tcpPort = New-Object System.Windows.Forms.TextBox
    $txtPort = $script:tcpPort
    $txtPort.Location = New-Object System.Drawing.Point(420, ($y - 3))
    $txtPort.Size = New-Object System.Drawing.Size(75, 25)
    $txtPort.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtPort.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtPort.Text = "53"
    $tcpForm.Controls.Add($txtPort)

    $script:tcpBtnCheck = New-Object System.Windows.Forms.Button
    $btnCheck = $script:tcpBtnCheck
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
    $script:tcpLog = New-Object System.Windows.Forms.TextBox
    $txtLog = $script:tcpLog
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
    $script:tcpBtnClose = New-Object System.Windows.Forms.Button
    $btnClose = $script:tcpBtnClose
    $btnClose.Location = New-Object System.Drawing.Point(515, $y)
    $btnClose.Size = New-Object System.Drawing.Size(115, 35)
    $btnClose.Text = "Close"
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $tcpForm.Controls.Add($btnClose)

    $btnCheck.Add_Click({
        $hostVal = $script:tcpHost.Text.Trim()
        $portVal = 0
        if (-not [int]::TryParse($script:tcpPort.Text.Trim(), [ref]$portVal) -or $portVal -lt 1 -or $portVal -gt 65535) {
            PopupError "Please enter a valid port number between 1 and 65535." "Warning"
            return
        }
        if ([string]::IsNullOrWhiteSpace($hostVal)) {
            PopupError "Please enter a target hostname or IP address." "Warning"
            return
        }

        $script:tcpBtnCheck.Enabled = $false
        $script:tcpLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] Testing $hostVal on TCP port $portVal...`r`n")
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
            $script:tcpLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] SUCCESS: Port $portVal is OPEN! (Latency: $($sw.ElapsedMilliseconds) ms)`r`n`r`n")
        } else {
            $script:tcpLog.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] FAILED: Port $portVal is CLOSED or filtered / unreachable.`r`n`r`n")
        }
        $script:tcpLog.SelectionStart = $script:tcpLog.Text.Length
        $script:tcpLog.ScrollToCaret()
        $script:tcpBtnCheck.Enabled = $true
    }.GetNewClosure())

    $btnClose.Add_Click({
        if ($script:tcpForm) { $script:tcpForm.Close() }
    }.GetNewClosure())

    $tcpForm.Add_Load({
        Invoke-HMTScale $script:tcpForm
        Set-RoundedControl $script:tcpBtnCheck
        Set-RoundedControl $script:tcpBtnClose
    }.GetNewClosure())

    Show-HMTWindow $script:tcpForm | Out-Null
}

# ==============================================================================
# 4. Storage SMART Health & Benchmark Dashboard (Revamped)
# ==============================================================================
function Show-StorageHealthDialog {
    $script:shForm = New-Object System.Windows.Forms.Form
    $shForm = $script:shForm
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

    $script:shCmbDrives = New-Object HMT.Tools.DarkComboBox
    $cmbDrives = $script:shCmbDrives
    $cmbDrives.Location = New-Object System.Drawing.Point(160, 11)
    $cmbDrives.Size = New-Object System.Drawing.Size(530, 26)
    $shForm.Controls.Add($cmbDrives)

    $script:shBtnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh = $script:shBtnRefresh
    $btnRefresh.Text = "Refresh"
    $btnRefresh.Location = New-Object System.Drawing.Point(705, 9)
    $btnRefresh.Size = New-Object System.Drawing.Size(115, 30)
    $btnRefresh.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnRefresh.FlatStyle = 'Flat'
    $btnRefresh.FlatAppearance.BorderSize = 1
    $shForm.Controls.Add($btnRefresh)

    # Tab Control
    $script:shTabs = New-Object HMT.Tools.DarkTabControl
    $shTabs = $script:shTabs
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

    $script:shLblCardModel = New-Object System.Windows.Forms.Label
    $lblCardModel = $script:shLblCardModel
    $lblCardModel.Text = "Drive: Selecting..."
    $lblCardModel.Font = New-Object System.Drawing.Font($font.FontFamily, 11, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $lblCardModel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblCardModel.Location = New-Object System.Drawing.Point(15, 10)
    $lblCardModel.Size = New-Object System.Drawing.Size(460, 22)
    $cardPanel.Controls.Add($lblCardModel)

    $script:shLblCardBus = New-Object System.Windows.Forms.Label
    $lblCardBus = $script:shLblCardBus
    $lblCardBus.Text = "Interface: --"
    $lblCardBus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardBus.Location = New-Object System.Drawing.Point(15, 38)
    $lblCardBus.Size = New-Object System.Drawing.Size(220, 20)
    $cardPanel.Controls.Add($lblCardBus)

    $script:shLblCardHealth = New-Object System.Windows.Forms.Label
    $lblCardHealth = $script:shLblCardHealth
    $lblCardHealth.Text = "Health: --"
    $lblCardHealth.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $lblCardHealth.Location = New-Object System.Drawing.Point(245, 38)
    $lblCardHealth.Size = New-Object System.Drawing.Size(220, 20)
    $cardPanel.Controls.Add($lblCardHealth)

    $script:shLblCardWrites = New-Object System.Windows.Forms.Label
    $lblCardWrites = $script:shLblCardWrites
    $lblCardWrites.Text = "Total Writes: --"
    $lblCardWrites.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $lblCardWrites.Font = New-Object System.Drawing.Font($font.FontFamily, 11, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $lblCardWrites.Location = New-Object System.Drawing.Point(490, 10)
    $lblCardWrites.Size = New-Object System.Drawing.Size(260, 22)
    $cardPanel.Controls.Add($lblCardWrites)

    $script:shLblCardWear = New-Object System.Windows.Forms.Label
    $lblCardWear = $script:shLblCardWear
    $lblCardWear.Text = "Wearout: --"
    $lblCardWear.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardWear.Location = New-Object System.Drawing.Point(490, 38)
    $lblCardWear.Size = New-Object System.Drawing.Size(260, 20)
    $cardPanel.Controls.Add($lblCardWear)

    # Physical Disks Table
    $script:shLV = New-Object HMT.Tools.DarkListView
    $shLV = $script:shLV
    $shLV.Location = New-Object System.Drawing.Point(15, 96)
    $shLV.Size = New-Object System.Drawing.Size(765, 310)
    $shLV.Columns.Add("Disk #", 55) | Out-Null
    $shLV.Columns.Add("Model", 210) | Out-Null
    $shLV.Columns.Add("Bus / Type", 100) | Out-Null
    $shLV.Columns.Add("Media", 75) | Out-Null
    $shLV.Columns.Add("Size", 75) | Out-Null
    $shLV.Columns.Add("Wearout", 70) | Out-Null
    $shLV.Columns.Add("Total Writes", 95) | Out-Null
    $shLV.Columns.Add("Health", 80) | Out-Null
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

    $script:shCmbBenchTarget = New-Object HMT.Tools.DarkComboBox
    $cmbBenchTarget = $script:shCmbBenchTarget
    $cmbBenchTarget.Location = New-Object System.Drawing.Point(125, 11)
    $cmbBenchTarget.Size = New-Object System.Drawing.Size(150, 26)
    $tabBench.Controls.Add($cmbBenchTarget)

    $lblBenchSize = New-Object System.Windows.Forms.Label
    $lblBenchSize.Text = "Test Size:"
    $lblBenchSize.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblBenchSize.Location = New-Object System.Drawing.Point(290, 15)
    $lblBenchSize.AutoSize = $true
    $tabBench.Controls.Add($lblBenchSize)

    $script:shCmbBenchSize = New-Object HMT.Tools.DarkComboBox
    $cmbBenchSize = $script:shCmbBenchSize
    $cmbBenchSize.Items.AddRange(@("100 MB (Quick)", "250 MB (Standard)", "500 MB (Thorough)", "1 GB (Extended)"))
    $cmbBenchSize.SelectedIndex = 1
    $cmbBenchSize.Location = New-Object System.Drawing.Point(360, 11)
    $cmbBenchSize.Size = New-Object System.Drawing.Size(160, 26)
    $tabBench.Controls.Add($cmbBenchSize)

    $script:shBtnBenchStart = New-Object System.Windows.Forms.Button
    $btnBenchStart = $script:shBtnBenchStart
    $btnBenchStart.Text = "Start Benchmark"
    $btnBenchStart.Location = New-Object System.Drawing.Point(540, 9)
    $btnBenchStart.Size = New-Object System.Drawing.Size(130, 30)
    $btnBenchStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $btnBenchStart.FlatStyle = 'Flat'
    $btnBenchStart.FlatAppearance.BorderSize = 1
    $tabBench.Controls.Add($btnBenchStart)

    $script:shBtnBenchCancel = New-Object System.Windows.Forms.Button
    $btnBenchCancel = $script:shBtnBenchCancel
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

    $script:shValSeqRead = &$createScoreCard "SEQ READ (128K)" "-- MB/s" 0 185
    $valSeqRead = $script:shValSeqRead
    $script:shValSeqWrite = &$createScoreCard "SEQ WRITE (128K)" "-- MB/s" 193 185
    $valSeqWrite = $script:shValSeqWrite
    $script:shValRandRead = &$createScoreCard "RANDOM 4K READ" "-- IOPS" 386 185
    $valRandRead = $script:shValRandRead
    $script:shValRandWrite = &$createScoreCard "RANDOM 4K WRITE" "-- IOPS" 580 185
    $valRandWrite = $script:shValRandWrite

    # Benchmark Progress & Real-time Graph
    $script:shLblBenchStatus = New-Object System.Windows.Forms.Label
    $lblBenchStatus = $script:shLblBenchStatus
    $lblBenchStatus.Text = "Ready to benchmark selected drive."
    $lblBenchStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblBenchStatus.Location = New-Object System.Drawing.Point(15, 124)
    $lblBenchStatus.Size = New-Object System.Drawing.Size(765, 18)
    $tabBench.Controls.Add($lblBenchStatus)

    $script:shBenchPBar = New-Object HMT.Tools.SmoothProgressBar
    $benchProgressBar = $script:shBenchPBar
    $benchProgressBar.Location = New-Object System.Drawing.Point(15, 144)
    $benchProgressBar.Size = New-Object System.Drawing.Size(765, 8)
    $benchProgressBar.BorderRadius = 4
    $benchProgressBar.ProgressColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
    $benchProgressBar.ProgressColorEnd = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $benchProgressBar.ShowShimmer = $true
    $benchProgressBar.Minimum = 0
    $benchProgressBar.Maximum = 100
    $tabBench.Controls.Add($benchProgressBar)

    $script:shBenchGraph = New-Object HMT.Tools.SmoothGraphControl
    $benchGraph = $script:shBenchGraph
    $benchGraph.Location = New-Object System.Drawing.Point(15, 158)
    $benchGraph.Size = New-Object System.Drawing.Size(765, 245)
    $benchGraph.UnitLabel = "MB/s"
    $benchGraph.LineColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $tabBench.Controls.Add($benchGraph)

    # Bottom Close Button
    $script:shBtnClose = New-Object System.Windows.Forms.Button
    $btnClose = $script:shBtnClose
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
        try {
            $script:shLV.Items.Clear()
            $script:shCmbDrives.Items.Clear()
            $script:shCmbBenchTarget.Items.Clear()
            $script:diskListCache = @()

            # Populate logical partition benchmark targets
            $logDrives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | Where-Object { $_.Free -gt 0 }
            if ($logDrives) {
                foreach ($ld in $logDrives) {
                    $freeGb = [math]::Round($ld.Free / 1GB, 1)
                    $script:shCmbBenchTarget.Items.Add("$($ld.Name):\ ($freeGb GB Free)") | Out-Null
                }
            }
            if ($script:shCmbBenchTarget.Items.Count -gt 0) {
                $script:shCmbBenchTarget.SelectedIndex = 0
            }

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
                    $script:shLV.Items.Add($item) | Out-Null

                    $displayStr = "Disk $($d.DeviceId): $($d.FriendlyName) [$busType $sizeGb GB] - $($d.HealthStatus)"
                    $script:shCmbDrives.Items.Add($displayStr) | Out-Null
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

            if ($script:shCmbDrives.Items.Count -gt 0) {
                $script:shCmbDrives.SelectedIndex = 0
            }
        } catch {
            Log-Message "Error refreshing storage drive list: $_" "Warning"
        }
    }

    $cmbDrives.Add_SelectedIndexChanged({
        $idx = $script:shCmbDrives.SelectedIndex
        if ($idx -ge 0 -and $idx -lt $script:diskListCache.Count) {
            $sel = $script:diskListCache[$idx]
            $script:shLblCardModel.Text = "Drive: $($sel.Model) ($($sel.Size))"
            $script:shLblCardBus.Text = "Interface: $($sel.BusType) ($($sel.MediaType))"
            $script:shLblCardHealth.Text = "Health: $($sel.Health)"
            $script:shLblCardHealth.ForeColor = if ($sel.Health -eq 'Healthy') { [System.Drawing.ColorTranslator]::FromHtml("#57F287") } else { [System.Drawing.ColorTranslator]::FromHtml("#FEE75C") }
            $script:shLblCardWrites.Text = "Total Writes: $($sel.Writes)"
            $script:shLblCardWear.Text = "Wearout: $($sel.Wearout)"
        }
    }.GetNewClosure())

    # Benchmark Execution
    $btnBenchStart.Add_Click({
        if ($script:shCmbBenchTarget.SelectedIndex -lt 0 -or -not $script:shCmbBenchTarget.SelectedItem) {
            $script:shLblBenchStatus.Text = "Please select a target partition first."
            $script:shLblBenchStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
            return
        }

        $selText = [string]$script:shCmbBenchTarget.SelectedItem
        $targetRoot = if ($selText -match '^([a-zA-Z]:\\?)') { $matches[1] } else { ($selText -split '\s+')[0] }
        if (-not $targetRoot.EndsWith("\")) { $targetRoot += "\" }

        $sizeMb = switch ($script:shCmbBenchSize.SelectedIndex) {
            0 { 100 }
            1 { 250 }
            2 { 500 }
            3 { 1000 }
            Default { 250 }
        }

        try {
            $script:shBtnBenchStart.Enabled = $false
            $script:shBtnBenchCancel.Enabled = $true
            $script:shCmbBenchTarget.Enabled = $false
            $script:shCmbBenchSize.Enabled = $false
            $script:shBenchGraph.Clear()
            $script:shValSeqRead.Text = "-- MB/s"
            $script:shValSeqWrite.Text = "-- MB/s"
            $script:shValRandRead.Text = "-- IOPS"
            $script:shValRandWrite.Text = "-- IOPS"

            $script:benchEngine.StartBenchmark($targetRoot, $sizeMb)

            while (-not $script:benchEngine.IsFinished) {
                $p = $script:benchEngine.CurrentProgress
                if ($null -ne $p) {
                    $script:shBenchPBar.Value = [math]::Max(0, [math]::Min(100, [int]$p.ProgressPercent))
                    $script:shLblBenchStatus.Text = "$($p.CurrentTest)... $([math]::Round($p.CurrentSpeedMBs, 1)) MB/s"
                    if ($p.CurrentSpeedMBs -gt 0) {
                        $script:shBenchGraph.AddPoint($p.CurrentSpeedMBs)
                    }
                }
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 40
            }

            $res = $script:benchEngine.Result
            if ($res -and $res.Success) {
                $script:shValSeqRead.Text = "$([math]::Round($res.SeqReadMBs, 1)) MB/s"
                $script:shValSeqWrite.Text = "$([math]::Round($res.SeqWriteMBs, 1)) MB/s"
                $script:shValRandRead.Text = "$([int]$res.Rand4KReadIops) IOPS"
                $script:shValRandWrite.Text = "$([int]$res.Rand4KWriteIops) IOPS"
                $script:shLblBenchStatus.Text = "Benchmark completed successfully!"
                $script:shLblBenchStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                $script:shBenchPBar.Value = 100
            } else {
                $script:shLblBenchStatus.Text = if ($res -and $res.ErrorMessage) { "Benchmark failed: $($res.ErrorMessage)" } else { "Benchmark cancelled." }
                $script:shLblBenchStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
            }
        } catch {
            $script:shLblBenchStatus.Text = "Benchmark error: $_"
            $script:shLblBenchStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
        } finally {
            $script:shBtnBenchStart.Enabled = $true
            $script:shBtnBenchCancel.Enabled = $false
            $script:shCmbBenchTarget.Enabled = $true
            $script:shCmbBenchSize.Enabled = $true
        }
    }.GetNewClosure())

    $btnBenchCancel.Add_Click({
        if ($script:benchEngine) { $script:benchEngine.Cancel() }
        $script:shBtnBenchCancel.Enabled = $false
    }.GetNewClosure())

    $btnRefresh.Add_Click({
        &$populateDisks
    }.GetNewClosure())

    $btnClose.Add_Click({
        if ($script:benchEngine) { $script:benchEngine.Cancel() }
        if ($script:shForm) { $script:shForm.Close() }
    }.GetNewClosure())

    $shForm.Add_FormClosing({
        if ($script:benchEngine) { $script:benchEngine.Cancel() }
    }.GetNewClosure())

    $shForm.Add_Load({
        Invoke-HMTScale $script:shForm
        Set-RoundedControl $script:shBtnRefresh
        Set-RoundedControl $script:shBtnBenchStart
        Set-RoundedControl $script:shBtnBenchCancel
        Set-RoundedControl $script:shBtnClose
        &$populateDisks
    }.GetNewClosure())

    Show-HMTWindow $script:shForm | Out-Null
}

# ==============================================================================
# 5. High-Precision Packet Loss & Latency Tester Dialog (Revamped with C# Engine)
# ==============================================================================
function Show-PacketLossTestDialog {
    $script:pltForm = New-Object System.Windows.Forms.Form
    $pltForm = $script:pltForm
    $pltForm.Text = "Packet Loss & Latency Precision Tester"
    $pltForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $pltForm.ClientSize = New-Object System.Drawing.Size(780, 455)
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

    $script:pltTxtHost = New-Object System.Windows.Forms.TextBox
    $txtHost = $script:pltTxtHost
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

    $script:pltTxtPps = New-Object System.Windows.Forms.TextBox
    $txtPps = $script:pltTxtPps
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

    $script:pltTxtSize = New-Object System.Windows.Forms.TextBox
    $txtSize = $script:pltTxtSize
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

    $script:pltTxtDuration = New-Object System.Windows.Forms.TextBox
    $txtDuration = $script:pltTxtDuration
    $txtDuration.Location = New-Object System.Drawing.Point(580, ($y - 3))
    $txtDuration.Size = New-Object System.Drawing.Size(45, 25)
    $txtDuration.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtDuration.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtDuration.Text = "0"
    $pltForm.Controls.Add($txtDuration)

    $script:pltBtnStart = New-Object System.Windows.Forms.Button
    $btnStart = $script:pltBtnStart
    $btnStart.Location = New-Object System.Drawing.Point(645, ($y - 5))
    $btnStart.Size = New-Object System.Drawing.Size(115, 32)
    $btnStart.Text = "Start Test"
    $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $btnStart.FlatStyle = 'Flat'
    $btnStart.FlatAppearance.BorderSize = 1
    $pltForm.Controls.Add($btnStart)

    # Preset Target Buttons Row
    $y += 38
    $script:pltBtnP1 = New-Object System.Windows.Forms.Button
    $btnP1 = $script:pltBtnP1
    $btnP1.Text = "Cloudflare (1.1.1.1)"
    $btnP1.Location = New-Object System.Drawing.Point(20, $y)
    $btnP1.Size = New-Object System.Drawing.Size(175, 26)
    $btnP1.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $btnP1.FlatStyle = 'Flat'
    $btnP1.FlatAppearance.BorderSize = 1
    $btnP1.Add_Click({ $script:pltTxtHost.Text = "1.1.1.1" }.GetNewClosure())
    $pltForm.Controls.Add($btnP1)

    $script:pltBtnP2 = New-Object System.Windows.Forms.Button
    $btnP2 = $script:pltBtnP2
    $btnP2.Text = "Google (8.8.8.8)"
    $btnP2.Location = New-Object System.Drawing.Point(205, $y)
    $btnP2.Size = New-Object System.Drawing.Size(175, 26)
    $btnP2.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $btnP2.FlatStyle = 'Flat'
    $btnP2.FlatAppearance.BorderSize = 1
    $btnP2.Add_Click({ $script:pltTxtHost.Text = "8.8.8.8" }.GetNewClosure())
    $pltForm.Controls.Add($btnP2)

    $script:pltBtnP3 = New-Object System.Windows.Forms.Button
    $btnP3 = $script:pltBtnP3
    $btnP3.Text = "Default Gateway"
    $btnP3.Location = New-Object System.Drawing.Point(390, $y)
    $btnP3.Size = New-Object System.Drawing.Size(175, 26)
    $btnP3.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $btnP3.FlatStyle = 'Flat'
    $btnP3.FlatAppearance.BorderSize = 1
    $btnP3.Add_Click({
        try {
            $gw = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue | Select-Object -First 1).NextHop
            if ($gw) { $script:pltTxtHost.Text = $gw }
        } catch {}
    }.GetNewClosure())
    $pltForm.Controls.Add($btnP3)

    $script:pltBtnP4 = New-Object System.Windows.Forms.Button
    $btnP4 = $script:pltBtnP4
    $btnP4.Text = "Local Host (127.0.0.1)"
    $btnP4.Location = New-Object System.Drawing.Point(575, $y)
    $btnP4.Size = New-Object System.Drawing.Size(185, 26)
    $btnP4.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $btnP4.FlatStyle = 'Flat'
    $btnP4.FlatAppearance.BorderSize = 1
    $btnP4.Add_Click({ $script:pltTxtHost.Text = "127.0.0.1" }.GetNewClosure())
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

    $script:pltValLatency = &$createKpiCard "LATENCY" "-- ms" 0 178
    $valLatency = $script:pltValLatency
    $script:pltValJitter = &$createKpiCard "JITTER (RFC 3550)" "-- ms" 188 178
    $valJitter = $script:pltValJitter
    $script:pltValLoss = &$createKpiCard "PACKET LOSS" "0.0%" 376 178
    $valLoss = $script:pltValLoss
    $script:pltValPackets = &$createKpiCard "PACKETS (RECV / LOST)" "0 / 0" 564 176
    $valPackets = $script:pltValPackets

    # Smooth GDI+ Double-Buffered Ping Graph with Dynamic Latency Gradient
    $y += 78
    $script:pltPingGraph = New-Object HMT.Tools.SmoothGraphControl
    $pingGraph = $script:pltPingGraph
    $pingGraph.Location = New-Object System.Drawing.Point(20, $y)
    $pingGraph.Size = New-Object System.Drawing.Size(740, 225)
    $pingGraph.UnitLabel = "ms"
    $pingGraph.LineColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $pingGraph.UseDynamicLatencyColors = $true
    $pingGraph.MaxPoints = 100
    $pltForm.Controls.Add($pingGraph)

    $y += 238
    $script:pltBtnClose = New-Object System.Windows.Forms.Button
    $btnClose = $script:pltBtnClose
    $btnClose.Location = New-Object System.Drawing.Point(645, $y)
    $btnClose.Size = New-Object System.Drawing.Size(115, 36)
    $btnClose.Text = "Close"
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $pltForm.Controls.Add($btnClose)

    $script:pingEngine = New-Object HMT.Tools.HighPrecisionPingEngine

    $script:pltPingTimer = New-Object System.Windows.Forms.Timer
    $pingTimer = $script:pltPingTimer
    $pingTimer.Interval = 40
    $pingTimer.Add_Tick({
        if ($null -ne $script:pingEngine) {
            $samples = $script:pingEngine.DrainSamples()
            if ($samples -and $samples.Length -gt 0) {
                foreach ($s in $samples) {
                    if ($s.Success) {
                        $script:pltPingGraph.AddPoint($s.RttMs)
                        $script:pltValLatency.Text = "$([math]::Round($s.RttMs, 1)) ms"
                        $script:pltValJitter.Text = "$([math]::Round($s.JitterMs, 1)) ms"
                    } else {
                        $script:pltPingGraph.AddPoint(0)
                    }
                }

                $sum = $script:pingEngine.GetSummary()
                if ($null -ne $sum) {
                    $script:pltValLoss.Text = "$([math]::Round($sum.LossPercent, 1))%"
                    $script:pltValLoss.ForeColor = if ($sum.LossPercent -eq 0) {
                        [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                    } elseif ($sum.LossPercent -lt 5) {
                        [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
                    } else {
                        [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
                    }
                    $script:pltValPackets.Text = "$($sum.TotalReceived) / $($sum.TotalLost)"
                }
            }

            if (-not $script:pingEngine.IsRunning) {
                if ($script:pltPingTimer) { $script:pltPingTimer.Stop() }
                $script:pltBtnStart.Text = "Start Test"
                $script:pltBtnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                $script:pltTxtHost.Enabled = $true
                $script:pltTxtPps.Enabled = $true
                $script:pltTxtSize.Enabled = $true
                $script:pltTxtDuration.Enabled = $true
            }
        }
    }.GetNewClosure())

    $btnStart.Add_Click({
        if ($script:pingEngine.IsRunning) {
            $script:pingEngine.Stop()
            if ($script:pltPingTimer) { $script:pltPingTimer.Stop() }
            $script:pltBtnStart.Text = "Start Test"
            $script:pltBtnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
            $script:pltTxtHost.Enabled = $true
            $script:pltTxtPps.Enabled = $true
            $script:pltTxtSize.Enabled = $true
            $script:pltTxtDuration.Enabled = $true
            return
        }

        $hostVal = $script:pltTxtHost.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($hostVal)) {
            PopupError "Please enter a valid target host or IP address." "Warning"
            return
        }

        $pps = 5
        [int]::TryParse($script:pltTxtPps.Text.Trim(), [ref]$pps) | Out-Null
        $sz = 32
        [int]::TryParse($script:pltTxtSize.Text.Trim(), [ref]$sz) | Out-Null
        $dur = 0
        [int]::TryParse($script:pltTxtDuration.Text.Trim(), [ref]$dur) | Out-Null

        $script:pltBtnStart.Text = "Stop Test"
        $script:pltBtnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
        $script:pltTxtHost.Enabled = $false
        $script:pltTxtPps.Enabled = $false
        $script:pltTxtSize.Enabled = $false
        $script:pltTxtDuration.Enabled = $false
        $script:pltPingGraph.MaxPoints = [math]::Max(60, ($pps * 60))
        $script:pltPingGraph.Clear()

        $script:pingEngine.Start($hostVal, $pps, $sz, $dur)
        if ($script:pltPingTimer) { $script:pltPingTimer.Start() }
    }.GetNewClosure())

    $btnClose.Add_Click({
        if ($script:pltPingTimer) { $script:pltPingTimer.Stop() }
        if ($script:pingEngine.IsRunning) { $script:pingEngine.Stop() }
        if ($script:pltForm) { $script:pltForm.Close() }
    }.GetNewClosure())

    $pltForm.Add_FormClosing({
        if ($script:pltPingTimer) {
            $script:pltPingTimer.Stop()
            $script:pltPingTimer.Dispose()
        }
        if ($script:pingEngine.IsRunning) { $script:pingEngine.Stop() }
    }.GetNewClosure())

    $pltForm.Add_Load({
        Invoke-HMTScale $script:pltForm
        Set-RoundedControl $script:pltBtnStart
        Set-RoundedControl $script:pltBtnP1
        Set-RoundedControl $script:pltBtnP2
        Set-RoundedControl $script:pltBtnP3
        Set-RoundedControl $script:pltBtnP4
        Set-RoundedControl $script:pltBtnClose
    }.GetNewClosure())

    Show-HMTWindow $script:pltForm | Out-Null
}

# ==============================================================================
# 6. BitLocker Drive Encryption & Recovery Manager
# ==============================================================================
function Show-BitLockerManagerDialog {
    $script:blForm = New-Object System.Windows.Forms.Form
    $blForm = $script:blForm
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

    $script:blCmbDrives = New-Object HMT.Tools.DarkComboBox
    $cmbDrives = $script:blCmbDrives
    $cmbDrives.Location = New-Object System.Drawing.Point(170, 14)
    $cmbDrives.Size = New-Object System.Drawing.Size(430, 26)
    $blForm.Controls.Add($cmbDrives)

    $script:blBtnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh = $script:blBtnRefresh
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

    $script:blLblCardVol = New-Object System.Windows.Forms.Label
    $lblCardVol = $script:blLblCardVol
    $lblCardVol.Text = "Volume: --"
    $lblCardVol.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblCardVol.Location = New-Object System.Drawing.Point(15, 10)
    $lblCardVol.Size = New-Object System.Drawing.Size(220, 20)
    $statusCard.Controls.Add($lblCardVol)

    $script:blLblCardStatus = New-Object System.Windows.Forms.Label
    $lblCardStatus = $script:blLblCardStatus
    $lblCardStatus.Text = "Status: --"
    $lblCardStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardStatus.Location = New-Object System.Drawing.Point(245, 10)
    $lblCardStatus.Size = New-Object System.Drawing.Size(230, 20)
    $statusCard.Controls.Add($lblCardStatus)

    $script:blLblCardLock = New-Object System.Windows.Forms.Label
    $lblCardLock = $script:blLblCardLock
    $lblCardLock.Text = "Lock: --"
    $lblCardLock.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardLock.Location = New-Object System.Drawing.Point(485, 10)
    $lblCardLock.Size = New-Object System.Drawing.Size(220, 20)
    $statusCard.Controls.Add($lblCardLock)

    $script:blLblCardProt = New-Object System.Windows.Forms.Label
    $lblCardProt = $script:blLblCardProt
    $lblCardProt.Text = "Protection: --"
    $lblCardProt.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardProt.Location = New-Object System.Drawing.Point(15, 38)
    $lblCardProt.Size = New-Object System.Drawing.Size(220, 20)
    $statusCard.Controls.Add($lblCardProt)

    $script:blLblCardMethod = New-Object System.Windows.Forms.Label
    $lblCardMethod = $script:blLblCardMethod
    $lblCardMethod.Text = "Algorithm: --"
    $lblCardMethod.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardMethod.Location = New-Object System.Drawing.Point(245, 38)
    $lblCardMethod.Size = New-Object System.Drawing.Size(230, 20)
    $statusCard.Controls.Add($lblCardMethod)

    $script:blLblCardPct = New-Object System.Windows.Forms.Label
    $lblCardPct = $script:blLblCardPct
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

    $script:blTxtRecoveryKey = New-Object System.Windows.Forms.TextBox
    $txtRecoveryKey = $script:blTxtRecoveryKey
    $txtRecoveryKey.Location = New-Object System.Drawing.Point(20, 158)
    $txtRecoveryKey.Size = New-Object System.Drawing.Size(490, 26)
    $txtRecoveryKey.ReadOnly = $true
    $txtRecoveryKey.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1f22")
    $txtRecoveryKey.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $txtRecoveryKey.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $txtRecoveryKey.Text = "No active Recovery Password selected"
    $blForm.Controls.Add($txtRecoveryKey)

    $script:blBtnCopyKey = New-Object System.Windows.Forms.Button
    $btnCopyKey = $script:blBtnCopyKey
    $btnCopyKey.Text = "Copy Key"
    $btnCopyKey.Location = New-Object System.Drawing.Point(520, 156)
    $btnCopyKey.Size = New-Object System.Drawing.Size(105, 30)
    $btnCopyKey.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnCopyKey.FlatStyle = 'Flat'
    $btnCopyKey.FlatAppearance.BorderSize = 1
    $blForm.Controls.Add($btnCopyKey)

    $script:blBtnSaveKey = New-Object System.Windows.Forms.Button
    $btnSaveKey = $script:blBtnSaveKey
    $btnSaveKey.Text = "Save Key"
    $btnSaveKey.Location = New-Object System.Drawing.Point(635, 156)
    $btnSaveKey.Size = New-Object System.Drawing.Size(105, 30)
    $btnSaveKey.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnSaveKey.FlatStyle = 'Flat'
    $btnSaveKey.FlatAppearance.BorderSize = 1
    $blForm.Controls.Add($btnSaveKey)

    $script:blLvProtectors = New-Object HMT.Tools.DarkListView
    $lvProtectors = $script:blLvProtectors
    $lvProtectors.Location = New-Object System.Drawing.Point(20, 192)
    $lvProtectors.Size = New-Object System.Drawing.Size(720, 85)
    $lvProtectors.Columns.Add("Protector Type", 180) | Out-Null
    $lvProtectors.Columns.Add("Key / Details", 410) | Out-Null
    $lvProtectors.Columns.Add("ID", 110) | Out-Null
    $blForm.Controls.Add($lvProtectors)

    # Section 2: Unlock Mechanism (Visible/Enabled when drive is locked)
    $script:blUnlockPanel = New-Object System.Windows.Forms.Panel
    $unlockPanel = $script:blUnlockPanel
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

    $script:blCmbUnlockMethod = New-Object HMT.Tools.DarkComboBox
    $cmbUnlockMethod = $script:blCmbUnlockMethod
    $cmbUnlockMethod.Items.AddRange(@("Recovery Password (48-digit)", "Password / Passphrase", "PIN"))
    $cmbUnlockMethod.SelectedIndex = 0
    $cmbUnlockMethod.Location = New-Object System.Drawing.Point(10, 28)
    $cmbUnlockMethod.Size = New-Object System.Drawing.Size(210, 26)
    $unlockPanel.Controls.Add($cmbUnlockMethod)

    $lblUnlockInput = New-Object System.Windows.Forms.Label
    $lblUnlockInput.Text = "Password / Recovery Key:"
    $lblUnlockInput.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblUnlockInput.Location = New-Object System.Drawing.Point(235, 8)
    $lblUnlockInput.Size = New-Object System.Drawing.Size(200, 18)
    $unlockPanel.Controls.Add($lblUnlockInput)

    $script:blTxtUnlockSecret = New-Object System.Windows.Forms.TextBox
    $txtUnlockSecret = $script:blTxtUnlockSecret
    $txtUnlockSecret.Location = New-Object System.Drawing.Point(235, 28)
    $txtUnlockSecret.Size = New-Object System.Drawing.Size(350, 25)
    $txtUnlockSecret.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtUnlockSecret.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $unlockPanel.Controls.Add($txtUnlockSecret)

    $script:blBtnUnlock = New-Object System.Windows.Forms.Button
    $btnUnlock = $script:blBtnUnlock
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

    $script:blLblProgStatus = New-Object System.Windows.Forms.Label
    $lblProgStatus = $script:blLblProgStatus
    $lblProgStatus.Text = "Operation Status: Idle"
    $lblProgStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblProgStatus.Location = New-Object System.Drawing.Point(15, 8)
    $lblProgStatus.Size = New-Object System.Drawing.Size(480, 20)
    $progPanel.Controls.Add($lblProgStatus)

    $script:blPBar = New-Object HMT.Tools.SmoothProgressBar
    $pBar = $script:blPBar
    $pBar.Location = New-Object System.Drawing.Point(15, 30)
    $pBar.Size = New-Object System.Drawing.Size(685, 18)
    $pBar.BorderRadius = 5
    $pBar.ProgressColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
    $pBar.ProgressColorEnd = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $pBar.ShowShimmer = $false
    $pBar.Minimum = 0
    $pBar.Maximum = 100
    $pBar.Value = 0
    $progPanel.Controls.Add($pBar)

    $script:blBtnContinueBg = New-Object System.Windows.Forms.Button
    $btnContinueBg = $script:blBtnContinueBg
    $btnContinueBg.Text = "Continue in Background & Close"
    $btnContinueBg.Location = New-Object System.Drawing.Point(15, 54)
    $btnContinueBg.Size = New-Object System.Drawing.Size(230, 28)
    $btnContinueBg.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnContinueBg.FlatStyle = 'Flat'
    $btnContinueBg.FlatAppearance.BorderSize = 1
    $btnContinueBg.Enabled = $false
    $progPanel.Controls.Add($btnContinueBg)

    $script:blBtnPauseResume = New-Object System.Windows.Forms.Button
    $btnPauseResume = $script:blBtnPauseResume
    $btnPauseResume.Text = "Pause / Resume"
    $btnPauseResume.Location = New-Object System.Drawing.Point(255, 54)
    $btnPauseResume.Size = New-Object System.Drawing.Size(140, 28)
    $btnPauseResume.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnPauseResume.FlatStyle = 'Flat'
    $btnPauseResume.FlatAppearance.BorderSize = 1
    $btnPauseResume.Enabled = $false
    $progPanel.Controls.Add($btnPauseResume)

    # Section 4: Main Action Buttons
    $yActions = 465
    $script:blBtnEnable = New-Object System.Windows.Forms.Button
    $btnEnable = $script:blBtnEnable
    $btnEnable.Text = "Enable BitLocker (Encrypt)"
    $btnEnable.Location = New-Object System.Drawing.Point(20, $yActions)
    $btnEnable.Size = New-Object System.Drawing.Size(190, 36)
    $btnEnable.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $btnEnable.FlatStyle = 'Flat'
    $btnEnable.FlatAppearance.BorderSize = 1
    $blForm.Controls.Add($btnEnable)

    $script:blBtnDisable = New-Object System.Windows.Forms.Button
    $btnDisable = $script:blBtnDisable
    $btnDisable.Text = "Disable BitLocker (Decrypt)"
    $btnDisable.Location = New-Object System.Drawing.Point(218, $yActions)
    $btnDisable.Size = New-Object System.Drawing.Size(190, 36)
    $btnDisable.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
    $btnDisable.FlatStyle = 'Flat'
    $btnDisable.FlatAppearance.BorderSize = 1
    $blForm.Controls.Add($btnDisable)

    $script:blBtnAddProtector = New-Object System.Windows.Forms.Button
    $btnAddProtector = $script:blBtnAddProtector
    $btnAddProtector.Text = "Add Recovery Password"
    $btnAddProtector.Location = New-Object System.Drawing.Point(416, $yActions)
    $btnAddProtector.Size = New-Object System.Drawing.Size(190, 36)
    $btnAddProtector.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnAddProtector.FlatStyle = 'Flat'
    $btnAddProtector.FlatAppearance.BorderSize = 1
    $blForm.Controls.Add($btnAddProtector)

    $script:blBtnClose = New-Object System.Windows.Forms.Button
    $btnClose = $script:blBtnClose
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
    $script:blPollTimer = New-Object System.Windows.Forms.Timer
    $pollTimer = $script:blPollTimer
    $pollTimer.Interval = 1000

    # Data Population Logic
    $refreshVolumes = {
        $script:blCmbDrives.Items.Clear()
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
                    $script:blCmbDrives.Items.Add($display) | Out-Null
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
                    $script:blCmbDrives.Items.Add($display) | Out-Null
                }
            }
        } catch {
            $display = "Error querying BitLocker: $_"
            $script:blCmbDrives.Items.Add($display) | Out-Null
        }

        if ($script:blCmbDrives.Items.Count -gt 0) {
            $script:blCmbDrives.SelectedIndex = 0
        }
    }

    $updateSelectedDriveUI = {
        if ($script:blCmbDrives.SelectedItem -and $script:blVolumes.ContainsKey($script:blCmbDrives.SelectedItem.ToString())) {
            $v = $script:blVolumes[$script:blCmbDrives.SelectedItem.ToString()]
            $script:selectedVolume = $v
            $mp = $v.MountPoint

            try {
                $latest = Get-BitLockerVolume -MountPoint $mp -ErrorAction SilentlyContinue
                if ($latest) { $v = $latest; $script:selectedVolume = $latest }
            } catch {}

            $convStatus = "Full Volume"
            try {
                $bdeOut = & "$env:WINDIR\System32\manage-bde.exe" -status $mp 2>&1
                if ($bdeOut -match "Conversion Status:\s*(.*)") {
                    $convStatus = $matches[1].Trim()
                }
            } catch {}

            $script:blLblCardVol.Text = "Volume: $mp ($($v.VolumeType))"
            $script:blLblCardStatus.Text = "Status: $($v.VolumeStatus)"
            $script:blLblCardLock.Text = "Lock: $($v.LockStatus)"
            $script:blLblCardLock.ForeColor = if ($v.LockStatus -eq 'Locked') { [System.Drawing.ColorTranslator]::FromHtml("#ED4245") } else { [System.Drawing.ColorTranslator]::FromHtml("#57F287") }
            $script:blLblCardProt.Text = "Protection: $($v.ProtectionStatus)"
            $script:blLblCardMethod.Text = "Algorithm: $($v.EncryptionMethod)"
            $pct = if ($null -ne $v.EncryptionPercentage) { $v.EncryptionPercentage } else { 0 }
            $script:blLblCardPct.Text = "Encrypted: $pct% ($convStatus)"

            # Key Protectors & Recovery Key Extraction
            $script:blLvProtectors.Items.Clear()
            $script:blTxtRecoveryKey.Text = "No Recovery Password found"
            $script:blTxtRecoveryKey.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")

            if ($v.KeyProtector) {
                foreach ($kp in $v.KeyProtector) {
                    $item = New-Object System.Windows.Forms.ListViewItem([string]$kp.KeyProtectorType)
                    $detail = "Protected"
                    if ($kp.RecoveryPassword) {
                        $detail = $kp.RecoveryPassword
                        $script:blTxtRecoveryKey.Text = $kp.RecoveryPassword
                        $script:blTxtRecoveryKey.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                    } elseif ($kp.KeyProtectorType -eq 'Tpm') {
                        $detail = "TPM Hardware Security Module"
                    } elseif ($kp.KeyProtectorType -eq 'TpmPin') {
                        $detail = "TPM with Startup PIN"
                    } elseif ($kp.KeyProtectorType -eq 'Password') {
                        $detail = "User Passphrase"
                    }
                    $item.SubItems.Add($detail) | Out-Null
                    $item.SubItems.Add([string]$kp.KeyProtectorId) | Out-Null
                    $script:blLvProtectors.Items.Add($item) | Out-Null
                }
            }

            # Unlock Panel state
            if ($v.LockStatus -eq 'Locked') {
                $script:blUnlockPanel.Enabled = $true
                $script:blBtnUnlock.Enabled = $true
            } else {
                $script:blUnlockPanel.Enabled = $false
                $script:blBtnUnlock.Enabled = $false
            }

            # Progress Bar & Actions
            $isInProgress = ($v.VolumeStatus -eq 'EncryptionInProgress' -or $v.VolumeStatus -eq 'DecryptionInProgress')
            if ($isInProgress) {
                $script:blLblProgStatus.Text = "$($v.VolumeStatus) on $mp ($pct% Complete)..."
                $script:blPBar.Value = [math]::Max(0, [math]::Min(100, [int]$pct))
                $script:blPBar.ShowShimmer = $true
                $script:blBtnContinueBg.Enabled = $true
                $script:blBtnPauseResume.Enabled = $true
                if ($script:blPollTimer) { $script:blPollTimer.Start() }
            } else {
                $script:blLblProgStatus.Text = "Operation Status: Idle ($($v.VolumeStatus))"
                $script:blPBar.Value = 0
                $script:blPBar.ShowShimmer = $false
                $script:blBtnContinueBg.Enabled = $false
                $script:blBtnPauseResume.Enabled = $false
                if ($script:blPollTimer) { $script:blPollTimer.Stop() }
            }

            # Button states
            $script:blBtnEnable.Enabled = ($v.VolumeStatus -eq 'FullyDecrypted' -and $v.LockStatus -ne 'Locked')
            $script:blBtnDisable.Enabled = ($v.VolumeStatus -eq 'FullyEncrypted' -or $v.VolumeStatus -eq 'EncryptionInProgress')
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
                    $script:blLblProgStatus.Text = "$($latest.VolumeStatus) on $mp ($pct% Complete)..."
                    $script:blPBar.Value = [math]::Max(0, [math]::Min(100, [int]$pct))
                    $script:blLblCardPct.Text = "Encrypted: $pct%"
                    $script:blLblCardStatus.Text = "Status: $($latest.VolumeStatus)"
                    
                    if ($latest.VolumeStatus -ne 'EncryptionInProgress' -and $latest.VolumeStatus -ne 'DecryptionInProgress') {
                        if ($script:blPollTimer) { $script:blPollTimer.Stop() }
                        &$updateSelectedDriveUI
                    }
                }
            } catch {}
        }
    }.GetNewClosure())

    $cmbDrives.Add_SelectedIndexChanged({ &$updateSelectedDriveUI }.GetNewClosure())
    $btnRefresh.Add_Click({ &$refreshVolumes }.GetNewClosure())

    # Copy Recovery Key
    $btnCopyKey.Add_Click({
        if ($script:blTxtRecoveryKey.Text -and $script:blTxtRecoveryKey.Text -ne "No active Recovery Password selected" -and $script:blTxtRecoveryKey.Text -ne "No Recovery Password found") {
            [System.Windows.Forms.Clipboard]::SetText($script:blTxtRecoveryKey.Text)
            PopupError "Recovery Password copied to clipboard!`n`n$($script:blTxtRecoveryKey.Text)" "Information"
        } else {
            PopupError "No recovery password available to copy." "Warning"
        }
    }.GetNewClosure())

    # Save Key to File
    $btnSaveKey.Add_Click({
        if ($script:blTxtRecoveryKey.Text -and $script:blTxtRecoveryKey.Text -ne "No active Recovery Password selected" -and $script:blTxtRecoveryKey.Text -ne "No Recovery Password found") {
            $sfd = New-Object System.Windows.Forms.SaveFileDialog
            $sfd.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
            $sfd.FileName = "BitLocker_Recovery_Key_$($script:selectedVolume.MountPoint -replace ':', '').txt"
            if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $content = @"
BitLocker Drive Encryption Recovery Key
========================================
Volume: $($script:selectedVolume.MountPoint)
Generated / Exported: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Recovery Password: $($script:blTxtRecoveryKey.Text)
========================================
Store this recovery password in a secure, confidential location.
"@
                Set-Content -Path $sfd.FileName -Value $content -Encoding UTF8 -Force
                PopupError "Recovery Key saved successfully to:`n$($sfd.FileName)" "Information"
            }
        } else {
            PopupError "No recovery password available to save." "Warning"
        }
    }.GetNewClosure())

    # Unlock Drive Action
    $btnUnlock.Add_Click({
        if (-not $script:selectedVolume) { return }
        $mp = $script:selectedVolume.MountPoint
        $secret = $script:blTxtUnlockSecret.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($secret)) {
            PopupError "Please enter the password, PIN, or 48-digit recovery key." "Warning"
            return
        }

        $script:blBtnUnlock.Enabled = $false
        try {
            $method = $script:blCmbUnlockMethod.SelectedIndex
            if ($method -eq 0) {
                Unlock-BitLocker -MountPoint $mp -RecoveryPassword $secret -ErrorAction Stop
            } elseif ($method -eq 1) {
                $secStr = ConvertTo-SecureString $secret -AsPlainText -Force
                Unlock-BitLocker -MountPoint $mp -Password $secStr -ErrorAction Stop
            } elseif ($method -eq 2) {
                Start-Process manage-bde.exe -ArgumentList "-unlock $mp -pin $secret" -Wait -WindowStyle Hidden
            }
            PopupError "Volume $mp unlocked successfully!" "Information"
            $script:blTxtUnlockSecret.Clear()
            &$refreshVolumes
        } catch {
            PopupError "Failed to unlock volume $($mp):`n$_" "Error"
        } finally {
            $script:blBtnUnlock.Enabled = $true
        }
    }.GetNewClosure())

    # Enable BitLocker Action
    $btnEnable.Add_Click({
        if (-not $script:selectedVolume) { return }
        $mp = $script:selectedVolume.MountPoint
        
        $modeChoice = PopupError "Choose BitLocker Encryption Mode for $($mp):`n`nClick 'Yes' for Used Space Only (Faster - recommended for clean/new PCs)`nClick 'No' for Full Volume Encryption (Thorough - recommended for active PCs)`nClick 'Cancel' to abort." "Question" "YesNoCancel"
        if ($modeChoice -eq [System.Windows.Forms.DialogResult]::Cancel) { return }
        $usedOnly = ($modeChoice -eq [System.Windows.Forms.DialogResult]::Yes)

        try {
            $isOs = ($script:selectedVolume.VolumeType -eq 'OperatingSystem')
            if ($isOs) {
                if ($usedOnly) {
                    Enable-BitLocker -MountPoint $mp -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector -RecoveryPasswordProtector -ErrorAction Stop
                } else {
                    Enable-BitLocker -MountPoint $mp -EncryptionMethod XtsAes256 -TpmProtector -RecoveryPasswordProtector -ErrorAction Stop
                }
            } else {
                if ($usedOnly) {
                    Enable-BitLocker -MountPoint $mp -EncryptionMethod XtsAes256 -UsedSpaceOnly -RecoveryPasswordProtector -ErrorAction Stop
                } else {
                    Enable-BitLocker -MountPoint $mp -EncryptionMethod XtsAes256 -RecoveryPasswordProtector -ErrorAction Stop
                }
            }
            PopupError "BitLocker encryption initiated on $mp!`n`nPlease view and save your Recovery Key." "Information"
            &$refreshVolumes
        } catch {
            PopupError "Failed to enable BitLocker on $($mp):`n$_" "Error"
        }
    }.GetNewClosure())

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
    }.GetNewClosure())

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
    }.GetNewClosure())

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
    }.GetNewClosure())

    # Continue in Background & Close
    $btnContinueBg.Add_Click({
        if ($script:blPollTimer) { $script:blPollTimer.Stop() }
        if ($script:blForm) { $script:blForm.Close() }
    }.GetNewClosure())

    $btnClose.Add_Click({
        if ($script:blPollTimer) { $script:blPollTimer.Stop() }
        if ($script:blForm) { $script:blForm.Close() }
    }.GetNewClosure())

    $blForm.Add_FormClosing({
        if ($script:blPollTimer) {
            $script:blPollTimer.Stop()
            $script:blPollTimer.Dispose()
        }
    }.GetNewClosure())

    $blForm.Add_Load({
        Invoke-HMTScale $script:blForm
        Set-RoundedControl $script:blBtnRefresh
        Set-RoundedControl $script:blBtnCopyKey
        Set-RoundedControl $script:blBtnSaveKey
        Set-RoundedControl $script:blBtnUnlock
        Set-RoundedControl $script:blBtnContinueBg
        Set-RoundedControl $script:blBtnPauseResume
        Set-RoundedControl $script:blBtnEnable
        Set-RoundedControl $script:blBtnDisable
        Set-RoundedControl $script:blBtnAddProtector
        Set-RoundedControl $script:blBtnClose
        &$refreshVolumes
    }.GetNewClosure())

    Show-HMTWindow $script:blForm | Out-Null
}

# ==============================================================================
# 7. Startup & Autoruns Manager Dialog
# ==============================================================================
function Show-StartupManagerDialog {
    $script:smForm = New-Object System.Windows.Forms.Form
    $suForm = $script:smForm
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

    # Header / Search Filter & Category Row
    $lblCategory = New-Object System.Windows.Forms.Label
    $lblCategory.Text = "Category:"
    $lblCategory.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblCategory.Location = New-Object System.Drawing.Point(20, 15)
    $lblCategory.AutoSize = $true
    $suForm.Controls.Add($lblCategory)

    $script:smCmbCategory = New-Object HMT.Tools.DarkComboBox
    $cmbCategory = $script:smCmbCategory
    $cmbCategory.Items.AddRange(@("All Categories", "Registry Run (HKCU/HKLM)", "Startup Folders (Shell)", "Logon Scheduled Tasks", "Shell & Winlogon Extensions", "Startup Services"))
    $cmbCategory.SelectedIndex = 0
    $cmbCategory.Location = New-Object System.Drawing.Point(85, 11)
    $cmbCategory.Size = New-Object System.Drawing.Size(200, 26)
    $suForm.Controls.Add($cmbCategory)

    $lblSearch = New-Object System.Windows.Forms.Label
    $lblSearch.Text = "Filter:"
    $lblSearch.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblSearch.Location = New-Object System.Drawing.Point(295, 15)
    $lblSearch.AutoSize = $true
    $suForm.Controls.Add($lblSearch)

    $script:smTxtSearch = New-Object System.Windows.Forms.TextBox
    $txtSearch = $script:smTxtSearch
    $txtSearch.Location = New-Object System.Drawing.Point(340, 12)
    $txtSearch.Size = New-Object System.Drawing.Size(180, 25)
    $txtSearch.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtSearch.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $suForm.Controls.Add($txtSearch)

    $script:smLblSummary = New-Object System.Windows.Forms.Label
    $lblSummary = $script:smLblSummary
    $lblSummary.Text = "Total Items: 0 (Enabled: 0, Disabled: 0)"
    $lblSummary.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblSummary.Location = New-Object System.Drawing.Point(525, 15)
    $lblSummary.Size = New-Object System.Drawing.Size(295, 20)
    $lblSummary.TextAlign = 'MiddleRight'
    $suForm.Controls.Add($lblSummary)

    # Startup Items ListView
    $script:smLvStartup = New-Object HMT.Tools.DarkListView
    $lvStartup = $script:smLvStartup
    $lvStartup.Location = New-Object System.Drawing.Point(20, 45)
    $lvStartup.Size = New-Object System.Drawing.Size(800, 445)
    $lvStartup.Columns.Add("Program Name", 180) | Out-Null
    $lvStartup.Columns.Add("Category", 130) | Out-Null
    $lvStartup.Columns.Add("Command Line / Target", 290) | Out-Null
    $lvStartup.Columns.Add("Location", 130) | Out-Null
    $lvStartup.Columns.Add("Status", 70) | Out-Null
    $suForm.Controls.Add($lvStartup)

    # Buttons Row
    $yBtn = 502
    $script:smBtnToggle = New-Object System.Windows.Forms.Button
    $btnToggle = $script:smBtnToggle
    $btnToggle.Text = "Toggle Enable / Disable"
    $btnToggle.Location = New-Object System.Drawing.Point(20, $yBtn)
    $btnToggle.Size = New-Object System.Drawing.Size(180, 36)
    $btnToggle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $btnToggle.FlatStyle = 'Flat'
    $btnToggle.FlatAppearance.BorderSize = 1
    $suForm.Controls.Add($btnToggle)

    $script:smBtnDelete = New-Object System.Windows.Forms.Button
    $btnDelete = $script:smBtnDelete
    $btnDelete.Text = "Delete Entry"
    $btnDelete.Location = New-Object System.Drawing.Point(210, $yBtn)
    $btnDelete.Size = New-Object System.Drawing.Size(130, 36)
    $btnDelete.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
    $btnDelete.FlatStyle = 'Flat'
    $btnDelete.FlatAppearance.BorderSize = 1
    $suForm.Controls.Add($btnDelete)

    $script:smBtnOpenLoc = New-Object System.Windows.Forms.Button
    $btnOpenLoc = $script:smBtnOpenLoc
    $btnOpenLoc.Text = "Open Location"
    $btnOpenLoc.Location = New-Object System.Drawing.Point(350, $yBtn)
    $btnOpenLoc.Size = New-Object System.Drawing.Size(130, 36)
    $btnOpenLoc.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnOpenLoc.FlatStyle = 'Flat'
    $btnOpenLoc.FlatAppearance.BorderSize = 1
    $suForm.Controls.Add($btnOpenLoc)

    $script:smBtnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh = $script:smBtnRefresh
    $btnRefresh.Text = "Refresh"
    $btnRefresh.Location = New-Object System.Drawing.Point(565, $yBtn)
    $btnRefresh.Size = New-Object System.Drawing.Size(115, 36)
    $btnRefresh.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnRefresh.FlatStyle = 'Flat'
    $btnRefresh.FlatAppearance.BorderSize = 1
    $suForm.Controls.Add($btnRefresh)

    $script:smBtnClose = New-Object System.Windows.Forms.Button
    $btnClose = $script:smBtnClose
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
        $script:smLvStartup.Items.Clear()

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
                            Category = "Registry Run"
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
                            Category = "Registry Run"
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
                            Category = "Registry Run"
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
                    Category = "Startup Folder"
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
                    Category = "Startup Folder"
                    Command = $f.FullName
                    Location = "All Users Startup Folder"
                    Type = "File"
                    FilePath = $f.FullName
                    ApprPath = $commonApprFolder
                    Status = $st
                }
            }
        }

        # 6. Scheduled Tasks (Logon Triggers)
        try {
            $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
                $_.Triggers.CimClass.CimClassName -match 'Logon|Boot|Startup' -and $_.TaskPath -notlike '\Microsoft\Windows\*'
            }
            foreach ($t in $tasks) {
                $actionExec = ($t.Actions | Select-Object -First 1).Execute
                $script:startupData += [pscustomobject]@{
                    Name = $t.TaskName
                    Category = "Scheduled Task"
                    Command = [string]$actionExec
                    Location = $t.TaskPath
                    Type = "Task"
                    TaskName = $t.TaskName
                    TaskPath = $t.TaskPath
                    Status = if ($t.State -eq 'Disabled') { "Disabled" } else { "Enabled" }
                }
            }
        } catch {}

        # 7. Shell & Winlogon Extensions
        $winlogonPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
        try {
            $wl = Get-ItemProperty -Path $winlogonPath -ErrorAction SilentlyContinue
            if ($wl.Userinit) {
                $script:startupData += [pscustomobject]@{
                    Name = "Userinit"
                    Category = "Shell / Winlogon"
                    Command = [string]$wl.Userinit
                    Location = "HKLM Winlogon"
                    Type = "Winlogon"
                    RegPath = $winlogonPath
                    Status = "Enabled"
                }
            }
            if ($wl.Shell -and $wl.Shell -ne "explorer.exe") {
                $script:startupData += [pscustomobject]@{
                    Name = "Custom Shell"
                    Category = "Shell / Winlogon"
                    Command = [string]$wl.Shell
                    Location = "HKLM Winlogon"
                    Type = "Winlogon"
                    RegPath = $winlogonPath
                    Status = "Enabled"
                }
            }
        } catch {}

        # 8. Startup Services (Auto-start 3rd party services)
        try {
            $services = Get-CimInstance -ClassName Win32_Service -Filter "StartMode = 'Auto'" -ErrorAction SilentlyContinue | Where-Object {
                $_.PathName -and $_.PathName -notlike "*Windows\System32\svchost.exe*" -and $_.PathName -notlike "*Windows\System32\*"
            }
            foreach ($svc in $services) {
                $script:startupData += [pscustomobject]@{
                    Name = $svc.DisplayName
                    Category = "Startup Service"
                    Command = [string]$svc.PathName
                    Location = "Services ($($svc.Name))"
                    Type = "Service"
                    ServiceName = $svc.Name
                    Status = if ($svc.State -eq 'Running') { "Enabled" } else { "Disabled" }
                }
            }
        } catch {}

        &$renderStartupList
    }

    $renderStartupList = {
        $script:smLvStartup.Items.Clear()
        $filter = $script:smTxtSearch.Text.Trim()
        $catFilter = if ($script:smCmbCategory.SelectedItem) { $script:smCmbCategory.SelectedItem.ToString() } else { "All Categories" }
        $enabledCount = 0
        $disabledCount = 0

        foreach ($item in $script:startupData) {
            if ($item.Status -eq "Enabled") { $enabledCount++ } else { $disabledCount++ }

            # Filter by Category
            if ($catFilter -ne "All Categories") {
                if ($catFilter -eq "Registry Run (HKCU/HKLM)" -and $item.Category -ne "Registry Run") { continue }
                if ($catFilter -eq "Startup Folders (Shell)" -and $item.Category -ne "Startup Folder") { continue }
                if ($catFilter -eq "Logon Scheduled Tasks" -and $item.Category -ne "Scheduled Task") { continue }
                if ($catFilter -eq "Shell & Winlogon Extensions" -and $item.Category -ne "Shell / Winlogon") { continue }
                if ($catFilter -eq "Startup Services" -and $item.Category -ne "Startup Service") { continue }
            }

            # Filter by Search text
            if ($filter) {
                if ($item.Name -notlike "*$filter*" -and $item.Command -notlike "*$filter*" -and $item.Location -notlike "*$filter*" -and $item.Category -notlike "*$filter*") {
                    continue
                }
            }

            $lvi = New-Object System.Windows.Forms.ListViewItem($item.Name)
            $lvi.SubItems.Add($item.Category) | Out-Null
            $lvi.SubItems.Add($item.Command) | Out-Null
            $lvi.SubItems.Add($item.Location) | Out-Null
            $lvi.SubItems.Add($item.Status) | Out-Null
            $lvi.Tag = $item

            if ($item.Status -eq "Enabled") {
                $lvi.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
            } else {
                $lvi.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
            }
            $script:smLvStartup.Items.Add($lvi) | Out-Null
        }

        $script:smLblSummary.Text = "Total Items: $($script:startupData.Count) (Enabled: $enabledCount, Disabled: $disabledCount)"
    }

    $txtSearch.Add_TextChanged({ &$renderStartupList }.GetNewClosure())
    $cmbCategory.Add_SelectedIndexChanged({ &$renderStartupList }.GetNewClosure())
    $btnRefresh.Add_Click({ &$loadStartupItems }.GetNewClosure())
    $btnClose.Add_Click({ if ($script:smForm) { $script:smForm.Close() } }.GetNewClosure())

    # Toggle Action
    $btnToggle.Add_Click({
        if ($script:smLvStartup.SelectedItems.Count -eq 0) {
            PopupError "Please select a startup item to toggle." "Warning"
            return
        }

        $selItem = $script:smLvStartup.SelectedItems[0].Tag
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
            } elseif ($selItem.Type -eq "Task") {
                if ($newStatus -eq "Disabled") {
                    Disable-ScheduledTask -TaskName $selItem.TaskName -TaskPath $selItem.TaskPath -ErrorAction Stop | Out-Null
                } else {
                    Enable-ScheduledTask -TaskName $selItem.TaskName -TaskPath $selItem.TaskPath -ErrorAction Stop | Out-Null
                }
            } elseif ($selItem.Type -eq "Service") {
                if ($newStatus -eq "Disabled") {
                    Set-Service -Name $selItem.ServiceName -StartupType Disabled -ErrorAction Stop
                    Stop-Service -Name $selItem.ServiceName -Force -ErrorAction SilentlyContinue
                } else {
                    Set-Service -Name $selItem.ServiceName -StartupType Automatic -ErrorAction Stop
                    Start-Service -Name $selItem.ServiceName -ErrorAction SilentlyContinue
                }
            }
            &$loadStartupItems
        } catch {
            PopupError "Failed to toggle startup status:`n$_" "Error"
        }
    }.GetNewClosure())

    # Delete Action
    $btnDelete.Add_Click({
        if ($script:smLvStartup.SelectedItems.Count -eq 0) {
            PopupError "Please select a startup item to delete." "Warning"
            return
        }

        $selItem = $script:smLvStartup.SelectedItems[0].Tag
        $confirm = PopupError "Are you sure you want to permanently DELETE startup item '$($selItem.Name)'?" "Question" "YesNo"
        if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

        try {
            if ($selItem.Type -eq "Registry") {
                Remove-ItemProperty -Path $selItem.RegPath -Name $selItem.Name -Force -ErrorAction Stop
                try { Remove-ItemProperty -Path $selItem.ApprPath -Name $selItem.Name -Force -ErrorAction SilentlyContinue } catch {}
            } elseif ($selItem.Type -eq "File") {
                Remove-Item -Path $selItem.FilePath -Force -ErrorAction Stop
            } elseif ($selItem.Type -eq "Task") {
                Unregister-ScheduledTask -TaskName $selItem.TaskName -TaskPath $selItem.TaskPath -Confirm:$false -ErrorAction Stop
            }
            PopupError "Startup item '$($selItem.Name)' deleted successfully." "Information"
            &$loadStartupItems
        } catch {
            PopupError "Failed to delete startup entry:`n$_" "Error"
        }
    }.GetNewClosure())

    # Open Location Action
    $btnOpenLoc.Add_Click({
        if ($script:smLvStartup.SelectedItems.Count -eq 0) { return }
        $selItem = $script:smLvStartup.SelectedItems[0].Tag

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
        } catch {}
    }.GetNewClosure())

    $suForm.Add_Load({
        Invoke-HMTScale $script:smForm
        Set-RoundedControl $script:smBtnToggle
        Set-RoundedControl $script:smBtnDelete
        Set-RoundedControl $script:smBtnOpenLoc
        Set-RoundedControl $script:smBtnRefresh
        Set-RoundedControl $script:smBtnClose
        &$loadStartupItems
    }.GetNewClosure())

    Show-HMTWindow $script:smForm | Out-Null
}

# ==============================================================================
# 8. Windows Update Component Reset Dialog (Smooth, Non-Blocking Step-by-Step UI)
# ==============================================================================
function Show-WindowsUpdateResetDialog {
    $wuForm = New-Object System.Windows.Forms.Form
    $wuForm.Text = "Reset Windows Update Components"
    $wuForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $wuForm.ClientSize = New-Object System.Drawing.Size(560, 290)
    $wuForm.StartPosition = 'CenterScreen'
    if ($HMTIcon) { $wuForm.Icon = $HMTIcon }
    $wuForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $wuForm.MaximizeBox = $false
    $wuForm.MinimizeBox = $true
    $wuForm.ShowInTaskbar = $true
    $wuForm.Font = $font
    $wuForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $wuForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $wuForm

    # Header Title & Subtitle
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Reset Windows Update Components"
    $lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    $lblTitle.Font = New-Object System.Drawing.Font($font.FontFamily, 13, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $lblTitle.Location = New-Object System.Drawing.Point(20, 16)
    $lblTitle.Size = New-Object System.Drawing.Size(520, 22)
    $wuForm.Controls.Add($lblTitle)

    $lblSubtitle = New-Object System.Windows.Forms.Label
    $lblSubtitle.Text = "Stops update services, clears SoftwareDistribution & catroot2 caches, and restarts services."
    $lblSubtitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblSubtitle.Location = New-Object System.Drawing.Point(20, 40)
    $lblSubtitle.Size = New-Object System.Drawing.Size(520, 36)
    $wuForm.Controls.Add($lblSubtitle)

    # Step Status Card
    $cardPanel = New-Object System.Windows.Forms.Panel
    $cardPanel.Location = New-Object System.Drawing.Point(20, 82)
    $cardPanel.Size = New-Object System.Drawing.Size(520, 110)
    $cardPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $cardPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $wuForm.Controls.Add($cardPanel)

    $script:wuLblStepNum = New-Object System.Windows.Forms.Label
    $lblStepNum = $script:wuLblStepNum
    $lblStepNum.Text = "Status: Ready"
    $lblStepNum.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $lblStepNum.Font = New-Object System.Drawing.Font($font.FontFamily, 11, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $lblStepNum.Location = New-Object System.Drawing.Point(15, 12)
    $lblStepNum.Size = New-Object System.Drawing.Size(490, 18)
    $cardPanel.Controls.Add($lblStepNum)

    $script:wuLblStepDetail = New-Object System.Windows.Forms.Label
    $lblStepDetail = $script:wuLblStepDetail
    $lblStepDetail.Text = "Click 'Start Reset' to begin resetting Windows Update components."
    $lblStepDetail.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblStepDetail.Font = New-Object System.Drawing.Font($font.FontFamily, 12, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $lblStepDetail.Location = New-Object System.Drawing.Point(15, 34)
    $lblStepDetail.Size = New-Object System.Drawing.Size(490, 28)
    $cardPanel.Controls.Add($lblStepDetail)

    $script:wuPb = New-Object HMT.Tools.SmoothProgressBar
    $pb = $script:wuPb
    $pb.Location = New-Object System.Drawing.Point(15, 70)
    $pb.Size = New-Object System.Drawing.Size(490, 18)
    $pb.Value = 0
    $pb.ShowShimmer = $false
    $cardPanel.Controls.Add($pb)

    # Action Buttons
    $script:wuBtnStart = New-Object System.Windows.Forms.Button
    $btnStart = $script:wuBtnStart
    $btnStart.Location = New-Object System.Drawing.Point(305, 210)
    $btnStart.Size = New-Object System.Drawing.Size(120, 36)
    $btnStart.Text = "Start Reset"
    $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $btnStart.FlatStyle = 'Flat'
    $btnStart.FlatAppearance.BorderSize = 1
    $wuForm.Controls.Add($btnStart)

    $script:wuBtnClose = New-Object System.Windows.Forms.Button
    $btnClose = $script:wuBtnClose
    $btnClose.Location = New-Object System.Drawing.Point(435, 210)
    $btnClose.Size = New-Object System.Drawing.Size(105, 36)
    $btnClose.Text = "Cancel"
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $wuForm.Controls.Add($btnClose)

    $script:wuForm = $wuForm

    $btnStart.Add_Click({
        $script:wuBtnStart.Enabled = $false
        $script:wuBtnClose.Text = "Close"
        $script:wuBtnClose.Enabled = $false
        $script:wuPb.ShowShimmer = $true

        $script:wuRunning = $true
        Log-Message "Beginning Windows Update component reset..." "Info"

        # Worker action with smooth UI updates
        $updateUI = {
            param($step, $total, $titleText, $detailText, $pct)
            $script:wuLblStepNum.Text = "Step $($step) of $($total): $titleText"
            $script:wuLblStepDetail.Text = $detailText
            $script:wuPb.Value = $pct
            [System.Windows.Forms.Application]::DoEvents()
        }

        try {
            # Step 1: Stopping Windows Update & Transfer Services
            &$updateUI 1 4 "Stopping Services" "Stopping wuauserv, bits, cryptsvc, and msiserver..." 15
            $services = @("wuauserv", "bits", "cryptsvc", "msiserver")
            foreach ($s in $services) {
                $script:wuLblStepDetail.Text = "Stopping service: $s..."
                [System.Windows.Forms.Application]::DoEvents()
                try {
                    $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
                    if ($svc -and $svc.Status -ne 'Stopped') {
                        Stop-Service -Name $s -Force -NoWait -ErrorAction SilentlyContinue
                    }
                } catch {}
            }
            # Wait up to 5 seconds for services to stop gracefully
            for ($w = 0; $w -lt 20; $w++) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 100
            }

            # Step 2: Clearing / Renaming Cache Folders
            &$updateUI 2 4 "Clearing Cache Folders" "Renaming SoftwareDistribution and catroot2 cache folders..." 50
            $timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
            $sdPath = "$env:WINDIR\SoftwareDistribution"
            $crPath = "$env:WINDIR\System32\catroot2"

            if (Test-Path -LiteralPath $sdPath) {
                $script:wuLblStepDetail.Text = "Renaming SoftwareDistribution cache..."
                [System.Windows.Forms.Application]::DoEvents()
                Rename-Item -LiteralPath $sdPath -NewName "SoftwareDistribution.old.$timestamp" -ErrorAction SilentlyContinue
            }

            if (Test-Path -LiteralPath $crPath) {
                $script:wuLblStepDetail.Text = "Renaming catroot2 cache..."
                [System.Windows.Forms.Application]::DoEvents()
                Rename-Item -LiteralPath $crPath -NewName "catroot2.old.$timestamp" -ErrorAction SilentlyContinue
            }

            # Clean BITS qmgr files
            $qmgrFiles = Get-ChildItem -Path "$env:ALLUSERSPROFILE\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction SilentlyContinue
            if ($qmgrFiles) {
                $qmgrFiles | Remove-Item -Force -ErrorAction SilentlyContinue
            }
            Start-Sleep -Milliseconds 250
            [System.Windows.Forms.Application]::DoEvents()

            # Step 3: Starting Services
            &$updateUI 3 4 "Starting Services" "Restarting cryptsvc, bits, wuauserv, and msiserver..." 75
            foreach ($s in @("cryptsvc", "bits", "wuauserv", "msiserver")) {
                $script:wuLblStepDetail.Text = "Starting service: $s..."
                [System.Windows.Forms.Application]::DoEvents()
                try {
                    Start-Service -Name $s -ErrorAction SilentlyContinue
                } catch {}
                Start-Sleep -Milliseconds 150
            }

            # Step 4: Finished
            $script:wuPb.Value = 100
            $script:wuPb.ShowShimmer = $false
            $script:wuLblStepNum.Text = "Status: Completed Successfully"
            $script:wuLblStepNum.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
            $script:wuLblStepDetail.Text = "Windows Update services restarted and caches cleared."
            Log-Message "Successfully reset Windows Update services and cleared caches." "Success"
        } catch {
            $script:wuPb.ShowShimmer = $false
            $script:wuLblStepNum.Text = "Status: Error Encountered"
            $script:wuLblStepNum.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
            $script:wuLblStepDetail.Text = "Error: $($_.Exception.Message)"
            Log-Message "Windows Update reset failed: $_" "Error"
        } finally {
            $script:wuBtnClose.Text = "Close"
            $script:wuBtnClose.Enabled = $true
            $script:wuBtnStart.Visible = $false
        }
    }.GetNewClosure())

    $btnClose.Add_Click({
        if ($script:wuForm) { $script:wuForm.Close() }
    }.GetNewClosure())

    $wuForm.Add_Load({
        Invoke-HMTScale $script:wuForm
        Set-RoundedControl $script:wuBtnStart
        Set-RoundedControl $script:wuBtnClose
    }.GetNewClosure())

    Show-HMTWindow $script:wuForm | Out-Null
}

