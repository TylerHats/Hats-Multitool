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

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = $Title
    $lblTitle.UseMnemonic = $false
    $lblTitle.Font = Get-HMTFont $font.FontFamily 14 ([System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblTitle.Location = New-Object System.Drawing.Point(20, 10)
    $lblTitle.AutoSize = $true
    $runnerForm.Controls.Add($lblTitle)

    $lblStatus = New-Object System.Windows.Forms.Label
    $lblStatus.Text = if ($Description) { "$Description (Starting...)" } elseif ($Title -match '\.NET|NetFx') { "Installing .NET Framework 3.5 (Starting...)" } else { "Executing command..." }
    $lblStatus.UseMnemonic = $false
    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $lblStatus.Font = Get-HMTFont $font.FontFamily 11 ([System.Drawing.FontStyle]::Bold)
    $lblStatus.Location = New-Object System.Drawing.Point(20, 34)
    $lblStatus.Size = New-Object System.Drawing.Size(700, 22)
    $lblStatus.AutoEllipsis = $true
    $runnerForm.Controls.Add($lblStatus)

    $lblDetail = New-Object System.Windows.Forms.Label
    $lblDetail.Text = if ($Title -match '\.NET|NetFx') { "Initializing .NET Framework 3.5 installation..." } else { "Initializing diagnostic process..." }
    $lblDetail.UseMnemonic = $false
    $lblDetail.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblDetail.Font = Get-HMTFont $font.FontFamily 10
    $lblDetail.Location = New-Object System.Drawing.Point(20, 58)
    $lblDetail.Size = New-Object System.Drawing.Size(700, 18)
    $lblDetail.AutoEllipsis = $true
    $runnerForm.Controls.Add($lblDetail)

    $pBar = New-Object HMT.Tools.SmoothProgressBar
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

    $txtOutput = New-Object HMT.Tools.DarkTextBox
    $txtOutput.Location = New-Object System.Drawing.Point(20, 100)
    $txtOutput.Size = New-Object System.Drawing.Size(700, 338)
    $txtOutput.Multiline = $true
    $txtOutput.ReadOnly = $true
    $txtOutput.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $txtOutput.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1f22")
    $txtOutput.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtOutput.Font = Get-HMTFont "Consolas" 12
    $runnerForm.Controls.Add($txtOutput)

    $yBtn = 455
    $btnCopy = New-Object System.Windows.Forms.Button
    $btnCopy.Text = "Copy Output"
    $btnCopy.Location = New-Object System.Drawing.Point(20, $yBtn)
    $btnCopy.Size = New-Object System.Drawing.Size(110, 36)
    $btnCopy.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnCopy.FlatStyle = 'Flat'
    $btnCopy.FlatAppearance.BorderSize = 1
    $runnerForm.Controls.Add($btnCopy)

    $btnContinueBg = New-Object System.Windows.Forms.Button
    $btnContinueBg.Text = "Continue in Background & Close"
    $btnContinueBg.UseMnemonic = $false
    $btnContinueBg.Location = New-Object System.Drawing.Point(140, $yBtn)
    $btnContinueBg.Size = New-Object System.Drawing.Size(230, 36)
    $btnContinueBg.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnContinueBg.FlatStyle = 'Flat'
    $btnContinueBg.FlatAppearance.BorderSize = 1
    $runnerForm.Controls.Add($btnContinueBg)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Cancel"
    $btnCancel.Location = New-Object System.Drawing.Point(485, $yBtn)
    $btnCancel.Size = New-Object System.Drawing.Size(110, 36)
    $btnCancel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
    $btnCancel.FlatStyle = 'Flat'
    $btnCancel.FlatAppearance.BorderSize = 1
    $runnerForm.Controls.Add($btnCancel)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close"
    $btnClose.Location = New-Object System.Drawing.Point(605, $yBtn)
    $btnClose.Size = New-Object System.Drawing.Size(115, 36)
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $runnerForm.Controls.Add($btnClose)

    $pollTimer = New-Object System.Windows.Forms.Timer
    $pollTimer.Interval = 50

    $toolKind = if ($Title -match '\.NET|NetFx') { 'NETFX' } elseif ($Title -match 'SFC') { 'SFC' } elseif ($Title -match 'DISM') { 'DISM' } elseif ($Title -match 'Check Disk|ChkDsk') { 'CHKDSK' } else { 'GENERIC' }

    $state = @{
        Runner = New-Object HMT.Tools.ProcessRunnerEngine
        Cancelled = $false
        RunInBackground = $false
        Stopwatch = $null
        ToolKind = $toolKind
        Stage = 1
        StageTotal = if ($toolKind -eq 'CHKDSK') { 3 } elseif ($toolKind -eq 'DISM') { 3 } elseif ($toolKind -eq 'NETFX') { 2 } elseif ($toolKind -eq 'SFC') { 2 } else { 1 }
        StageName = if ($toolKind -eq 'CHKDSK') { "Examining file system structure" } elseif ($toolKind -eq 'DISM') { "Checking component store integrity" } elseif ($toolKind -eq 'NETFX') { "Downloading .NET 3.5 feature payload" } elseif ($toolKind -eq 'SFC') { "Initializing system file scan" } else { "Executing" }
        ProgressPct = 0
        LastLoggedProgress = -1
        Stage1Sec = 0
        Stage2Sec = 0
        ReportedEta = ""
        Verdict = ""
        VerdictType = "None" # Success, Repaired, Warning, Error
        DetailInfo = ""
    }

    $calculateEta = {
        param([double]$pct)
        $elapsedSec = if ($state.Stopwatch) { $state.Stopwatch.Elapsed.TotalSeconds } else { 0 }
        if ($elapsedSec -lt 3) { return "Calculating..." }

        if ($state.ToolKind -eq 'DISM') {
            # Phase-aware DISM ETA
            if ($pct -lt 20.0) {
                return "Scanning component store (~2-4m total)"
            } elseif ($pct -lt 80.0) {
                $phasePct = $pct - 20.0
                $phaseElapsed = [math]::Max(1.0, ($elapsedSec - $state.Stage1Sec))
                $rate = $phasePct / $phaseElapsed
                if ($rate -gt 0) {
                    $remPhase = [int]((60.0 - $phasePct) / $rate) + 40 # 40s buffer for phase 3
                    if ($remPhase -ge 60) {
                        return "~{0}m {1}s" -f [int]($remPhase / 60), ($remPhase % 60)
                    } else {
                        return "~{0}s" -f [math]::Max(10, $remPhase)
                    }
                }
                return "Downloading repair payloads..."
            } else {
                $remPct = 100.0 - $pct
                return "Finalizing repairs (~1-2m)"
            }
        }
        elseif ($state.ToolKind -eq 'NETFX') {
            if ($pct -lt 50.0) {
                return "Downloading feature payload (~1-3m)"
            } elseif ($pct -lt 99.0) {
                return "Enabling .NET 3.5 components (~30-60s)"
            } else {
                return "Finishing..."
            }
        }
        elseif ($state.ToolKind -eq 'SFC') {
            if ($pct -ge 4.0) {
                $rate = $pct / $elapsedSec
                if ($rate -gt 0) {
                    $remSec = [int]((100.0 - $pct) / $rate)
                    if ($remSec -ge 60) {
                        return "~{0}m {1}s" -f [int]($remSec / 60), ($remSec % 60)
                    } else {
                        return "~{0}s" -f [math]::Max(1, $remSec)
                    }
                }
            }
            return "Estimating (~2-5m)..."
        }
        elseif ($state.ToolKind -eq 'CHKDSK') {
            if ($state.ReportedEta) {
                return "~$($state.ReportedEta)"
            }
            if ($pct -ge 5.0) {
                $rate = $pct / $elapsedSec
                if ($rate -gt 0) {
                    $remSec = [int]((100.0 - $pct) / $rate)
                    if ($remSec -ge 60) {
                        return "~{0}m {1}s" -f [int]($remSec / 60), ($remSec % 60)
                    } else {
                        return "~{0}s" -f [math]::Max(1, $remSec)
                    }
                }
            }
            return "Scanning volume..."
        }
        else {
            if ($pct -ge 5.0) {
                $rate = $pct / $elapsedSec
                if ($rate -gt 0) {
                    $remSec = [int]((100.0 - $pct) / $rate)
                    return "~{0}s" -f [math]::Max(1, $remSec)
                }
            }
            return "Estimating..."
        }
    }.GetNewClosure()

    $processLine = {
        param([string]$line)
        if ([string]::IsNullOrWhiteSpace($line)) { return }
        
        $lineClean = $line.Trim()
        $elapsed = if ($state.Stopwatch) { $state.Stopwatch.Elapsed } else { [timespan]::Zero }
        $elapsedStr = "{0:D2}:{1:D2}" -f [int]$elapsed.TotalMinutes, $elapsed.Seconds

        # --- 1. SFC Parsing ---
        if ($state.ToolKind -eq 'SFC') {
            if ($lineClean -match '(?:Verification|Verifying|Scan|Phase)?\s*(\d+)%\s*(?:complete|\.|$)' -or $lineClean -match '(\d+)%\s*(?:complete|\.|$)') {
                $pct = [int]$matches[1]
                if ($pct -ge 0 -and $pct -le 100) {
                    $state.ProgressPct = $pct
                    $state.Stage = 2
                    $state.StageName = "Verifying Windows system files"
                    $pBar.IsMarquee = $false
                    $pBar.Value = [math]::Max(0, [math]::Min(100, $pct))
                    $lblStatus.Text = "Stage 2/2: Verifying protected system files ($pct% complete)..."
                    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")

                    # In-place terminal update: rewrite the "Verification XX% complete." line cleanly
                    $curText = $txtOutput.Text
                    $lastVerif = $curText.LastIndexOf("Verification ")
                    if ($lastVerif -ge 0) {
                        $txtOutput.Text = $curText.Substring(0, $lastVerif) + "Verification $pct% complete.`r`n"
                    } else {
                        $txtOutput.AppendText("Verification $pct% complete.`r`n")
                    }
                }
            }
            elseif ($lineClean -match 'Beginning system scan') {
                $state.Stage = 1
                $state.StageName = "Initializing system scan"
                $pBar.IsMarquee = $true
                $lblStatus.Text = "Stage 1/2: Initializing system file scan..."
                $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
                $txtOutput.AppendText("$lineClean`r`n`r`n")
            }
            elseif ($lineClean -match 'Beginning verification phase') {
                $state.Stage = 2
                $state.StageName = "Verifying system files"
                $pBar.IsMarquee = $false
                $pBar.Value = 0
                $lblStatus.Text = "Stage 2/2: Verifying Windows system files..."
                $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
                $txtOutput.AppendText("$lineClean`r`n")
            }
            elseif ($lineClean -match 'did not find any integrity violations') {
                $state.Verdict = "Verification Complete: No integrity violations found (System files healthy)."
                $state.VerdictType = "Success"
                $txtOutput.AppendText("`r`n$lineClean`r`n")
            }
            elseif ($lineClean -match 'found corrupt files and successfully repaired them') {
                $state.Verdict = "Verification Complete: Corrupted files found and successfully repaired."
                $state.VerdictType = "Repaired"
                $txtOutput.AppendText("`r`n$lineClean`r`n")
            }
            elseif ($lineClean -match 'found corrupt files but was unable to fix some') {
                $state.Verdict = "Corrupted files found that could not all be repaired (Check CBS.log)."
                $state.VerdictType = "Warning"
                $txtOutput.AppendText("`r`n$lineClean`r`n")
            }
            elseif ($lineClean -match 'could not perform the requested operation' -or $lineClean -match 'could not start the repair service') {
                $state.Verdict = "SFC failed: Windows Resource Protection could not perform operation."
                $state.VerdictType = "Error"
                $txtOutput.AppendText("`r`n$lineClean`r`n")
            }
            else {
                $txtOutput.AppendText("$lineClean`r`n")
            }
            $txtOutput.SelectionStart = $txtOutput.Text.Length
            $txtOutput.ScrollToCaret()
            return
        }

        # --- 2. DISM & .NET 3.5 Feature Parsing ---
        if ($lineClean -match 'Enabling feature\(s\)') {
            $state.Stage = 1
            $state.StageName = "Downloading and enabling .NET 3.5 features"
            $pBar.IsMarquee = $false
            $pBar.Value = 10
            $lblStatus.Text = "Stage 1/2: Downloading and enabling .NET Framework 3.5..."
            $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
            $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match '\[\s*={0,}\s*(\d+(?:\.\d+)?)%\s*={0,}\s*\]' -or $lineClean -match '^(\d+(?:\.\d+)?)%\s*$') {
            $pctFloat = [double]$matches[1]
            $pct = [int]$pctFloat
            $state.ProgressPct = $pct
            $pBar.IsMarquee = $false
            $pBar.Value = [math]::Max(0, [math]::Min(100, $pct))

            if ($pctFloat -ge 20.0 -and $state.Stage1Sec -eq 0 -and $state.Stopwatch) {
                $state.Stage1Sec = $state.Stopwatch.Elapsed.TotalSeconds
            }

            $phaseText = "Processing component store..."
            if ($state.ToolKind -eq 'NETFX') {
                if ($pctFloat -lt 60.0) {
                    $state.Stage = 1
                    $state.StageName = "Downloading .NET 3.5 payloads from Windows Update"
                    $phaseText = "Stage 1/2: Downloading .NET 3.5 payloads from Windows Update ($pct%)..."
                } else {
                    $state.Stage = 2
                    $state.StageName = "Enabling and installing .NET Framework 3.5 / 2.0 / 3.0"
                    $phaseText = "Stage 2/2: Enabling and installing .NET 3.5 / 2.0 / 3.0 ($pct%)..."
                }
            } else {
                if ($pctFloat -lt 20.0) {
                    $state.Stage = 1
                    $state.StageName = "Checking component store corruption & hash integrity"
                    $phaseText = "Stage 1/3: Checking component store corruption & hash integrity..."
                } elseif ($pctFloat -lt 80.0) {
                    $state.Stage = 2
                    $state.StageName = "Restoring store & downloading repair payloads from Windows Update"
                    $phaseText = "Stage 2/3: Restoring store & downloading repair payloads from Windows Update..."
                } elseif ($pctFloat -lt 100.0) {
                    $state.Stage = 3
                    $state.StageName = "Applying component repairs to Windows system image"
                    $phaseText = "Stage 3/3: Applying component repairs to Windows system image..."
                } else {
                    $phaseText = "Finalizing component store operations..."
                }
            }

            $lblStatus.Text = $phaseText
            $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")

            if ($pct -eq 100 -or ($pct % 20 -eq 0 -and $pct -ne $state.LastLoggedProgress)) {
                $state.LastLoggedProgress = $pct
                $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] Progress: $pctFloat% complete`r`n")
            }
        }
        elseif ($lineClean -match 'The restore operation completed successfully') {
            $state.Verdict = "Restore Complete: Component store corruption was found & successfully repaired."
            $state.VerdictType = "Repaired"
            $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'No component store corruption detected') {
            $state.Verdict = "Check Complete: No component store corruption detected (Image is clean)."
            $state.VerdictType = "Success"
            $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'The operation completed successfully') {
            if (-not $state.Verdict) {
                if ($state.ToolKind -eq 'NETFX') {
                    $state.Verdict = "Installation Complete: .NET Framework 3.5 (includes 2.0 & 3.0) is enabled & ready."
                } else {
                    $state.Verdict = "Operation completed successfully (Exit Code 0)."
                }
                $state.VerdictType = "Success"
            }
            $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'Error:\s*(.+)') {
            $state.Verdict = "DISM Error Encountered: $($matches[1].Trim())"
            $state.VerdictType = "Error"
            $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }

        # --- 3. CHKDSK Parsing ---
        elseif ($lineClean -match 'Stage\s+(\d+)(?:\s+of\s+(\d+))?:\s*(.+?)(?:\.{2,})?$') {
            $stg = [int]$matches[1]
            $stgTot = if ($matches[2]) { [int]$matches[2] } else { 3 }
            $stgDesc = $matches[3].Trim()
            $state.Stage = $stg
            $state.StageTotal = $stgTot
            $state.StageName = $stgDesc
            $pBar.IsMarquee = $false
            $stageBase = [int](($stg - 1) * (100.0 / $stgTot))
            $state.ProgressPct = $stageBase
            $pBar.Value = $stageBase
            $lblStatus.Text = "Stage $stg of $($stgTot): $stgDesc..."
            $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
            $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] Stage $stg of $($stgTot): $stgDesc`r`n")
        }
        elseif ($lineClean -match 'Estimated remaining time:\s*([0-9:]+)' -or $lineClean -match 'ETA:\s*([0-9:]+)') {
            $state.ReportedEta = $matches[1].Trim()
        }
        elseif ($lineClean -match '(\d+)\s*(?:percent|%)\s*complete' -or $lineClean -match '\(\s*(\d+)%\s*\)') {
            $stgPct = [int]$matches[1]
            $stg = if ($state.Stage) { $state.Stage } else { 1 }
            $stgTot = if ($state.StageTotal) { $state.StageTotal } else { 3 }
            $overallPct = [int]((($stg - 1) * (100.0 / $stgTot)) + ($stgPct / $stgTot))
            $state.ProgressPct = $overallPct
            $pBar.IsMarquee = $false
            $pBar.Value = [math]::Max(0, [math]::Min(100, $overallPct))
            $lblStatus.Text = "Stage $stg of $($stgTot): $($state.StageName) ($stgPct%)..."

            if ($stgPct % 25 -eq 0 -and $stgPct -ne $state.LastLoggedProgress) {
                $state.LastLoggedProgress = $stgPct
                $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] Stage $($stg): $stgPct% complete (Overall: ~$overallPct%)`r`n")
            }
        }
        elseif ($lineClean -match 'The type of the file system is\s+(\w+)') {
            $state.DetailInfo = "File System: $($matches[1])"
            $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match '(\d+)\s+file records processed') {
            if ($state.Stage -eq 1 -and $state.ProgressPct -lt 25) {
                $state.ProgressPct = 25
                $pBar.IsMarquee = $false
                $pBar.Value = 25
            }
            $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'File verification completed') {
            if ($state.Stage -le 1) {
                $state.Stage = 2
                $state.StageName = "Examining file name linkage"
                $state.ProgressPct = 33
                $pBar.IsMarquee = $false
                $pBar.Value = 33
            }
            $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'Index verification completed') {
            if ($state.Stage -le 2) {
                $state.Stage = 3
                $state.StageName = "Examining security descriptors"
                $state.ProgressPct = 66
                $pBar.IsMarquee = $false
                $pBar.Value = 66
            }
            $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'Security descriptor verification completed') {
            $state.ProgressPct = 95
            $pBar.IsMarquee = $false
            $pBar.Value = 95
            $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'Windows has scanned the file system and found no problems') {
            $state.Verdict = "Check Disk Complete: No file system problems found (Volume healthy)."
            $state.VerdictType = "Success"
            $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        elseif ($lineClean -match 'Windows found problems with the file system') {
            $state.Verdict = "File system errors detected on volume (Run ChkDsk with /F to repair)."
            $state.VerdictType = "Warning"
            $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $lineClean`r`n")
        }
        else {
            $txtOutput.AppendText($line + "`r`n")
        }

        $txtOutput.SelectionStart = $txtOutput.Text.Length
        $txtOutput.ScrollToCaret()
    }.GetNewClosure()

    $btnCopy.Add_Click({
        if ($txtOutput.Text) {
            [System.Windows.Forms.Clipboard]::SetText($txtOutput.Text)
            PopupError "Output copied to clipboard." "Information"
        }
    }.GetNewClosure())

    $btnCancel.Add_Click({
        $confirm = PopupError "Are you sure you want to cancel and terminate this process ($Title)?" "Question" "YesNo"
        if ($confirm -ne [System.Windows.Forms.DialogResult]::Yes) { return }

        $state.Cancelled = $true
        if ($null -ne $state.Runner) {
            $state.Runner.Kill()
        }
        $lblStatus.Text = "Cancelled by user."
        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
        $lblDetail.Text = "Execution aborted."
        $pBar.IsMarquee = $false
        $pBar.Value = 0
        $btnCancel.Enabled = $false
        $btnContinueBg.Enabled = $false
        $btnClose.Enabled = $true
        $btnCopy.Enabled = $true
    }.GetNewClosure())

    $btnContinueBg.Add_Click({
        $state.RunInBackground = $true
        if ($pollTimer) { $pollTimer.Stop() }
        $runnerForm.Close()
    }.GetNewClosure())

    $btnClose.Add_Click({
        if ($null -ne $state.Runner -and $state.Runner.IsRunning) {
            $choice = PopupError "This process ($Title) is still running.`n`nClick 'Yes' to continue running in the background and close this window.`nClick 'No' to abort and terminate the process.`nClick 'Cancel' to keep this window open." "Question" "YesNoCancel"
            if ($choice -eq [System.Windows.Forms.DialogResult]::Cancel) { return }
            if ($choice -eq [System.Windows.Forms.DialogResult]::Yes) {
                $state.RunInBackground = $true
                if ($pollTimer) { $pollTimer.Stop() }
                $runnerForm.Close()
                return
            } else {
                $state.Cancelled = $true
                $state.Runner.Kill()
            }
        }
        if ($pollTimer) { $pollTimer.Stop() }
        $runnerForm.Close()
    }.GetNewClosure())

    $runnerForm.Add_Load({
        Invoke-HMTScale $runnerForm
        Set-RoundedControl $btnCopy
        Set-RoundedControl $btnContinueBg
        Set-RoundedControl $btnCancel
        Set-RoundedControl $btnClose
    }.GetNewClosure())

    $pollTimer.Add_Tick({
        if ($null -ne $state.Runner) {
            $lines = $state.Runner.DrainOutput()
            if ($lines -and $lines.Length -gt 0) {
                foreach ($l in $lines) {
                    if ($null -ne $l) {
                        &$processLine $l
                    }
                }
            }

            $elapsed = if ($state.Stopwatch) { $state.Stopwatch.Elapsed } else { [timespan]::Zero }
            $elapsedStr = "{0:D2}:{1:D2}" -f [int]$elapsed.TotalMinutes, $elapsed.Seconds
            $etaStr = &$calculateEta $state.ProgressPct

            if ($state.Runner.IsRunning -and -not $state.Cancelled) {
                # Live dynamic detail text updated with clock tick
                if ($state.ToolKind -eq 'SFC') {
                    $lblDetail.Text = "Stage $($state.Stage)/$($state.StageTotal): $($state.StageName) ($($state.ProgressPct)%) | Elapsed: $elapsedStr | Est. Remaining: $etaStr"
                } elseif ($state.ToolKind -eq 'NETFX') {
                    $lblDetail.Text = "Stage $($state.Stage)/$($state.StageTotal): $($state.StageName) ($($state.ProgressPct)%) | Elapsed: $elapsedStr | Est. Remaining: $etaStr"
                } elseif ($state.ToolKind -eq 'DISM') {
                    $lblDetail.Text = "Progress: $($state.ProgressPct)% | Elapsed: $elapsedStr | Est. Remaining: $etaStr"
                } elseif ($state.ToolKind -eq 'CHKDSK') {
                    $prefix = if ($state.DetailInfo) { "$($state.DetailInfo) | " } else { "" }
                    $lblDetail.Text = "$prefix Stage $($state.Stage)/$($state.StageTotal) (~$($state.ProgressPct)%) | Elapsed: $elapsedStr | Est. Remaining: $etaStr"
                } else {
                    $lblDetail.Text = "Elapsed: $elapsedStr | Est. Remaining: $etaStr"
                }
            }

            if ($state.Runner.HasExited -or $state.Cancelled) {
                $remLines = $state.Runner.DrainOutput()
                if ($remLines -and $remLines.Length -gt 0) {
                    foreach ($rl in $remLines) {
                        if ($null -ne $rl) { &$processLine $rl }
                    }
                }

                if ($pollTimer) { $pollTimer.Stop() }
                $pBar.IsMarquee = $false
                $pBar.Value = 100

                if ($state.Cancelled) {
                    $lblStatus.Text = "Execution cancelled by user."
                    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
                    $lblDetail.Text = "Total Execution Time: $elapsedStr | Aborted"
                } elseif ($state.Verdict) {
                    $lblStatus.Text = $state.Verdict
                    $lblStatus.ForeColor = if ($state.VerdictType -eq "Success" -or $state.VerdictType -eq "Repaired") {
                        [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                    } elseif ($state.VerdictType -eq "Warning") {
                        [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
                    } else {
                        [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
                    }
                    $lblDetail.Text = "Total Execution Time: $elapsedStr | Process Finished"
                    $txtOutput.AppendText("`r`n[$((Get-Date).ToString('HH:mm:ss'))] ===== Process Complete: $($state.Verdict) (Elapsed: $elapsedStr) =====`r`n")
                } elseif ($state.Runner.ExitCode -eq 0) {
                    $lblStatus.Text = "Completed successfully (Exit code: 0)."
                    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                    $lblDetail.Text = "Total Execution Time: $elapsedStr | Success"
                    $txtOutput.AppendText("`r`n[$((Get-Date).ToString('HH:mm:ss'))] ===== Process Complete: Completed successfully (Elapsed: $elapsedStr) =====`r`n")
                } else {
                    $lblStatus.Text = "Finished with exit code $($state.Runner.ExitCode)."
                    $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
                    $lblDetail.Text = "Total Execution Time: $elapsedStr | Check log output above."
                    $txtOutput.AppendText("`r`n[$((Get-Date).ToString('HH:mm:ss'))] ===== Process Complete: Exit Code $($state.Runner.ExitCode) (Elapsed: $elapsedStr) =====`r`n")
                }

                $btnCancel.Enabled = $false
                $btnContinueBg.Enabled = $false
                $btnClose.Enabled = $true
                $btnCopy.Enabled = $true
            }
        }
    }.GetNewClosure())

    $runnerForm.Add_Shown({
        $state.Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $lblStatus.Text = "Running diagnostic process..."
        $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")

        if ($state.ToolKind -in @('CHKDSK', 'DISM', 'SFC')) {
            $procName = switch ($state.ToolKind) { 'CHKDSK' { 'chkdsk' } 'DISM' { 'dism' } 'SFC' { 'sfc' } }
            $existing = Get-Process -Name $procName -ErrorAction SilentlyContinue
            if ($existing) {
                $p = $existing | Select-Object -First 1
                $txtOutput.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] Note: Detected active $procName task (PID: $($p.Id)) currently running on system.`r`n")
            }
        }

        $started = $state.Runner.Start($CommandName, $Arguments, [bool]$IsPowerShellScript)
        if ($started) {
            if ($pollTimer) { $pollTimer.Start() }
        } else {
            $err = if ($state.Runner.ErrorMessage) { $state.Runner.ErrorMessage } else { "Unknown error" }
            $lblStatus.Text = "Execution failed: $err"
            $lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
            $txtOutput.AppendText("`r`nError starting process: $err`r`n")
            $btnCancel.Enabled = $false
            $btnContinueBg.Enabled = $false
            $btnClose.Enabled = $true
            $btnCopy.Enabled = $true
        }
    }.GetNewClosure())

    $runnerForm.Add_FormClosing({
        if ($pollTimer) {
            $pollTimer.Stop()
            $pollTimer.Dispose()
        }
        if (-not $state.RunInBackground -and $null -ne $state.Runner) {
            $state.Runner.Dispose()
        }
    }.GetNewClosure())

    Show-HMTWindow $runnerForm | Out-Null
}

# ==============================================================================
# 2. Internet Speed Test Dialog (Cloudflare Anycast + Smooth GDI+ Graph)
# ==============================================================================
function Show-SpeedTestDialog {
    $stForm = New-Object System.Windows.Forms.Form
    $stForm.Text = "Internet Speed Test"
    $stForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $stForm.ClientSize = New-Object System.Drawing.Size(680, 442)
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
        $lTitle.UseMnemonic = $false
        $lTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
        $lTitle.Location = New-Object System.Drawing.Point(0, 8)
        $lTitle.Size = New-Object System.Drawing.Size($width, 18)
        $lTitle.TextAlign = 'MiddleCenter'
        $p.Controls.Add($lTitle)

        $lVal = New-Object System.Windows.Forms.Label
        $lVal.Text = $initialVal
        $lVal.UseMnemonic = $false
        $lVal.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $lVal.Font = Get-HMTFont $font.FontFamily 16 ([System.Drawing.FontStyle]::Bold)
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
    $valDownload.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#00A8FC")
    $valUpload.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#BD00FF")

    # Status / Phase Indicator
    $lblCurrentPhase = New-Object System.Windows.Forms.Label
    $lblCurrentPhase.Text = "Ready to test"
    $lblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblCurrentPhase.Font = Get-HMTFont $font.FontFamily 12 ([System.Drawing.FontStyle]::Bold)
    $lblCurrentPhase.Location = New-Object System.Drawing.Point(20, 130)
    $lblCurrentPhase.Size = New-Object System.Drawing.Size(640, 20)
    $lblCurrentPhase.TextAlign = 'MiddleCenter'
    $stForm.Controls.Add($lblCurrentPhase)

    # Smooth GDI+ Double-Buffered Graph
    $smoothChart = New-Object HMT.Tools.SmoothGraphControl
    $smoothChart.Location = New-Object System.Drawing.Point(20, 155)
    $smoothChart.Size = New-Object System.Drawing.Size(640, 220)
    $smoothChart.UnitLabel = "Mbps"
    $smoothChart.LineColor = [System.Drawing.ColorTranslator]::FromHtml("#00A8FC")
    $smoothChart.MaxPoints = 250
    $smoothChart.EnableSmoothing = $true
    $smoothChart.SmoothWeight = 0.15
    $stForm.Controls.Add($smoothChart)

    # Settings Row
    $yBot = 390
    $lblStreams = New-Object System.Windows.Forms.Label
    $lblStreams.Text = "Streams:"
    $lblStreams.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblStreams.Location = New-Object System.Drawing.Point(20, ($yBot + 6))
    $lblStreams.AutoSize = $true
    $stForm.Controls.Add($lblStreams)

    $cmbStreams = New-Object HMT.Tools.DarkComboBox
    $cmbStreams.Items.AddRange(@("2 Streams", "4 Streams (Recommended)", "8 Streams", "16 Streams (Gigabit+)"))
    $cmbStreams.SelectedIndex = 1
    $cmbStreams.Location = New-Object System.Drawing.Point(85, $yBot)
    $cmbStreams.Size = New-Object System.Drawing.Size(200, 26)
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

    $state = @{
        Running = $false
        Engine = New-Object HMT.Tools.FastSpeedTestEngine
    }

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
    }.GetNewClosure()

    $btnStart.Add_Click({
        if ($state.Running) {
            if ($state.Engine) { $state.Engine.Cancel() }
            $state.Running = $false
            $btnStart.Text = "Start Test"
            $lblCurrentPhase.Text = "Test cancelled."
            $lblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
            $cmbStreams.Enabled = $true
            $btnClose.Enabled = $true
            return
        }

        try {
            $state.Running = $true
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
                if (-not $state.Running) { break }
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

            if (-not $state.Running) { return }

            # --- Phase 2: Download Test (Blue #00A8FC) ---
            $colorBlue = [System.Drawing.ColorTranslator]::FromHtml("#00A8FC")
            $lblCurrentPhase.Text = "Testing Download Speed ($streamCount streams)..."
            $lblCurrentPhase.ForeColor = $colorBlue

            $downUrl = "https://speed.cloudflare.com/__down"
            $state.Engine.StartDownloadTest($downUrl, $streamCount, 6, 14)

            while (-not $state.Engine.IsFinished) {
                $sample = $state.Engine.CurrentSample
                if ($null -ne $sample) {
                    $smoothChart.AddPoint($sample.CurrentMbps, $colorBlue)
                    $valDownload.Text = "$([math]::Round($sample.AverageMbps, 1)) Mbps"
                    $lblCurrentPhase.Text = "Downloading ($([math]::Round($sample.CurrentMbps, 1)) Mbps) | Total: $([math]::Round($sample.TotalBytesTransferred / 1MB, 1)) MB"
                }
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 40
                if (-not $state.Running) { break }
            }

            $finalDownMbps = 0
            if ($state.Engine.Result) {
                $finalDownMbps = $state.Engine.Result.AverageMbps
                $valDownload.Text = "$([math]::Round($finalDownMbps, 1)) Mbps"
            }

            if (-not $state.Running) { return }
            Start-Sleep -Milliseconds 300

            # --- Phase 3: Upload Test (Purple #BD00FF) ---
            $colorPurple = [System.Drawing.ColorTranslator]::FromHtml("#BD00FF")
            $lblCurrentPhase.Text = "Testing Upload Speed ($streamCount streams)..."
            $lblCurrentPhase.ForeColor = $colorPurple

            $upUrl = "https://speed.cloudflare.com/__up"
            $state.Engine.StartUploadTest($upUrl, $streamCount, 6, 14)

            while (-not $state.Engine.IsFinished) {
                $sample = $state.Engine.CurrentSample
                if ($null -ne $sample) {
                    $smoothChart.AddPoint($sample.CurrentMbps, $colorPurple)
                    $valUpload.Text = "$([math]::Round($sample.AverageMbps, 1)) Mbps"
                    $lblCurrentPhase.Text = "Uploading ($([math]::Round($sample.CurrentMbps, 1)) Mbps) | Total: $([math]::Round($sample.TotalBytesTransferred / 1MB, 1)) MB"
                }
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 40
                if (-not $state.Running) { break }
            }

            $finalUpMbps = 0
            if ($state.Engine.Result) {
                $finalUpMbps = $state.Engine.Result.AverageMbps
                $valUpload.Text = "$([math]::Round($finalUpMbps, 1)) Mbps"
            }

            # --- Finished ---
            $state.Running = $false
            $btnStart.Text = "Test Again"
            $cmbStreams.Enabled = $true
            $btnClose.Enabled = $true
            $lblCurrentPhase.Text = "Speed Test Complete!"
            $lblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
        } catch {
            $state.Running = $false
            $btnStart.Text = "Start Test"
            $cmbStreams.Enabled = $true
            $btnClose.Enabled = $true
            $lblCurrentPhase.Text = "Speed test error: $_"
            $lblCurrentPhase.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
        } finally {
            $state.Running = $false
            $cmbStreams.Enabled = $true
            $btnClose.Enabled = $true
        }
    }.GetNewClosure())

    $btnClose.Add_Click({
        if ($state.Running -and $state.Engine) { $state.Engine.Cancel() }
        $stForm.Close()
    }.GetNewClosure())

    $stForm.Add_FormClosing({
        if ($state.Running -and $state.Engine) { $state.Engine.Cancel() }
    }.GetNewClosure())

    $stForm.Add_Load({
        Invoke-HMTScale $stForm
        Set-RoundedControl $btnStart
        Set-RoundedControl $btnClose
    }.GetNewClosure())

    $stForm.Add_Shown({
        &$detectServer
    }.GetNewClosure())

    Show-HMTWindow $stForm | Out-Null
}

# ==============================================================================
# 3. TCP Port & Connection Checker Dialog
# ==============================================================================
function Show-TcpCheckerDialog {
    $tcpForm = New-Object System.Windows.Forms.Form
    $tcpForm.Text = "TCP Port & Connection Checker"
    $tcpForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $tcpForm.ClientSize = New-Object System.Drawing.Size(650, 388)
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

    $txtHost = New-Object HMT.Tools.DarkTextBox
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

    $txtPort = New-Object HMT.Tools.DarkTextBox
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
    $lblRes.UseMnemonic = $false
    $lblRes.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblRes.Location = New-Object System.Drawing.Point(20, $y)
    $lblRes.AutoSize = $true
    $tcpForm.Controls.Add($lblRes)

    $y += 24
    $txtLog = New-Object HMT.Tools.DarkTextBox
    $txtLog.Location = New-Object System.Drawing.Point(20, $y)
    $txtLog.Size = New-Object System.Drawing.Size(610, 240)
    $txtLog.Multiline = $true
    $txtLog.ReadOnly = $true
    $txtLog.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
    $txtLog.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1f22")
    $txtLog.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $txtLog.Font = Get-HMTFont "Consolas" 12
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
    }.GetNewClosure())

    $btnClose.Add_Click({
        $tcpForm.Close()
    }.GetNewClosure())

    $tcpForm.Add_Load({
        Invoke-HMTScale $tcpForm
        Set-RoundedControl $btnCheck
        Set-RoundedControl $btnClose
    }.GetNewClosure())

    Show-HMTWindow $tcpForm | Out-Null
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
    $shForm.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $shForm.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::None
    Set-DarkTitleBar -TargetForm $shForm

    # Header / Drive Selector
    $lblSelDrive = New-Object System.Windows.Forms.Label
    $lblSelDrive.Text = "Target Storage Drive:"
    $lblSelDrive.UseMnemonic = $false
    $lblSelDrive.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblSelDrive.Location = New-Object System.Drawing.Point(20, 15)
    $lblSelDrive.AutoSize = $true
    $shForm.Controls.Add($lblSelDrive)

    $cmbDrives = New-Object HMT.Tools.DarkComboBox
    $cmbDrives.Location = New-Object System.Drawing.Point(160, 11)
    $cmbDrives.Size = New-Object System.Drawing.Size(530, 26)
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
    $shTabs = New-Object HMT.Tools.DarkTabControl
    $shTabs.Location = New-Object System.Drawing.Point(20, 48)
    $shTabs.Size = New-Object System.Drawing.Size(800, 455)
    $shForm.Controls.Add($shTabs)

    # ---------------- TAB 1: Health & SMART Telemetry ----------------
    $tabHealth = New-Object System.Windows.Forms.TabPage("Health & SMART Telemetry")
    $tabHealth.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $shTabs.TabPages.Add($tabHealth)

    # Top Summary Card
    $cardPanel = New-Object System.Windows.Forms.Panel
    $cardPanel.Location = New-Object System.Drawing.Point(12, 12)
    $cardPanel.Size = New-Object System.Drawing.Size(776, 75)
    $cardPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $cardPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $tabHealth.Controls.Add($cardPanel)

    $lblCardModel = New-Object System.Windows.Forms.Label
    $lblCardModel.Text = "Drive: Selecting..."
    $lblCardModel.UseMnemonic = $false
    $lblCardModel.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
    $lblCardModel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblCardModel.Location = New-Object System.Drawing.Point(15, 10)
    $lblCardModel.Size = New-Object System.Drawing.Size(460, 22)
    $cardPanel.Controls.Add($lblCardModel)

    $lblCardBus = New-Object System.Windows.Forms.Label
    $lblCardBus.Text = "Interface: --"
    $lblCardBus.UseMnemonic = $false
    $lblCardBus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardBus.Location = New-Object System.Drawing.Point(15, 38)
    $lblCardBus.Size = New-Object System.Drawing.Size(220, 20)
    $cardPanel.Controls.Add($lblCardBus)

    $lblCardHealth = New-Object System.Windows.Forms.Label
    $lblCardHealth.Text = "Health: --"
    $lblCardHealth.UseMnemonic = $false
    $lblCardHealth.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $lblCardHealth.Location = New-Object System.Drawing.Point(245, 38)
    $lblCardHealth.Size = New-Object System.Drawing.Size(220, 20)
    $cardPanel.Controls.Add($lblCardHealth)

    $lblCardWrites = New-Object System.Windows.Forms.Label
    $lblCardWrites.Text = "Total Writes: --"
    $lblCardWrites.UseMnemonic = $false
    $lblCardWrites.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $lblCardWrites.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
    $lblCardWrites.Location = New-Object System.Drawing.Point(490, 10)
    $lblCardWrites.Size = New-Object System.Drawing.Size(260, 22)
    $cardPanel.Controls.Add($lblCardWrites)

    $lblCardWear = New-Object System.Windows.Forms.Label
    $lblCardWear.Text = "Wearout: --"
    $lblCardWear.UseMnemonic = $false
    $lblCardWear.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblCardWear.Location = New-Object System.Drawing.Point(490, 38)
    $lblCardWear.Size = New-Object System.Drawing.Size(260, 20)
    $cardPanel.Controls.Add($lblCardWear)

    # Physical Disks Table
    $shLV = New-Object HMT.Tools.DarkListView
    $shLV.Location = New-Object System.Drawing.Point(12, 95)
    $shLV.Size = New-Object System.Drawing.Size(776, 312)
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
    $lblBenchTarget.UseMnemonic = $false
    $lblBenchTarget.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblBenchTarget.Location = New-Object System.Drawing.Point(12, 15)
    $lblBenchTarget.AutoSize = $true
    $tabBench.Controls.Add($lblBenchTarget)

    $cmbBenchTarget = New-Object HMT.Tools.DarkComboBox
    $cmbBenchTarget.Location = New-Object System.Drawing.Point(125, 11)
    $cmbBenchTarget.Size = New-Object System.Drawing.Size(150, 26)
    $tabBench.Controls.Add($cmbBenchTarget)

    $lblBenchSize = New-Object System.Windows.Forms.Label
    $lblBenchSize.Text = "Test Size:"
    $lblBenchSize.UseMnemonic = $false
    $lblBenchSize.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblBenchSize.Location = New-Object System.Drawing.Point(290, 15)
    $lblBenchSize.AutoSize = $true
    $tabBench.Controls.Add($lblBenchSize)

    $cmbBenchSize = New-Object HMT.Tools.DarkComboBox
    $cmbBenchSize.Items.AddRange(@("100 MB (Quick)", "250 MB (Standard)", "500 MB (Thorough)", "1 GB (Extended)", "5 GB (Deep)", "10 GB (Longest)"))
    $cmbBenchSize.SelectedIndex = 1
    $cmbBenchSize.Location = New-Object System.Drawing.Point(360, 11)
    $cmbBenchSize.Size = New-Object System.Drawing.Size(160, 26)
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
    $btnBenchCancel.Size = New-Object System.Drawing.Size(108, 30)
    $btnBenchCancel.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnBenchCancel.FlatStyle = 'Flat'
    $btnBenchCancel.FlatAppearance.BorderSize = 1
    $btnBenchCancel.Enabled = $false
    $tabBench.Controls.Add($btnBenchCancel)

    # 4 Scorecards
    $scorePanel = New-Object System.Windows.Forms.Panel
    $scorePanel.Location = New-Object System.Drawing.Point(12, 48)
    $scorePanel.Size = New-Object System.Drawing.Size(776, 70)
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
        $lTitle.UseMnemonic = $false
        $lTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
        $lTitle.Location = New-Object System.Drawing.Point(0, 6)
        $lTitle.Size = New-Object System.Drawing.Size($width, 16)
        $lTitle.TextAlign = 'MiddleCenter'
        $p.Controls.Add($lTitle)

        $lVal = New-Object System.Windows.Forms.Label
        $lVal.Text = $initialVal
        $lVal.UseMnemonic = $false
        $lVal.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $lVal.Font = Get-HMTFont $font.FontFamily 14 ([System.Drawing.FontStyle]::Bold)
        $lVal.Location = New-Object System.Drawing.Point(0, 26)
        $lVal.Size = New-Object System.Drawing.Size($width, 26)
        $lVal.TextAlign = 'MiddleCenter'
        $p.Controls.Add($lVal)

        return $lVal
    }

    $valSeqRead = &$createScoreCard "SEQ READ (128K)" "-- MB/s" 0 188
    $valSeqWrite = &$createScoreCard "SEQ WRITE (128K)" "-- MB/s" 196 188
    $valRandRead = &$createScoreCard "RANDOM 4K READ" "-- IOPS" 392 188
    $valRandWrite = &$createScoreCard "RANDOM 4K WRITE" "-- IOPS" 588 188

    # Benchmark Progress & Real-time Graph
    $lblBenchStatus = New-Object System.Windows.Forms.Label
    $lblBenchStatus.Text = "Ready to benchmark selected drive."
    $lblBenchStatus.UseMnemonic = $false
    $lblBenchStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblBenchStatus.Location = New-Object System.Drawing.Point(12, 124)
    $lblBenchStatus.Size = New-Object System.Drawing.Size(776, 18)
    $tabBench.Controls.Add($lblBenchStatus)

    $benchProgressBar = New-Object HMT.Tools.SmoothProgressBar
    $benchProgressBar.Location = New-Object System.Drawing.Point(12, 144)
    $benchProgressBar.Size = New-Object System.Drawing.Size(776, 8)
    $benchProgressBar.BorderRadius = 4
    $benchProgressBar.ProgressColor = [System.Drawing.ColorTranslator]::FromHtml("#6f1fde")
    $benchProgressBar.ProgressColorEnd = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $benchProgressBar.ShowShimmer = $true
    $benchProgressBar.Minimum = 0
    $benchProgressBar.Maximum = 100
    $tabBench.Controls.Add($benchProgressBar)

    $benchGraph = New-Object HMT.Tools.SmoothGraphControl
    $benchGraph.Location = New-Object System.Drawing.Point(12, 158)
    $benchGraph.Size = New-Object System.Drawing.Size(776, 248)
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

    $state = @{
        DiskListCache = @()
        BenchEngine = New-Object HMT.Tools.DiskBenchmarkEngine
    }

    # Drive Population Logic
    $populateDisks = {
        try {
            $shLV.Items.Clear()
            $cmbDrives.Items.Clear()
            $cmbBenchTarget.Items.Clear()
            $state.DiskListCache = @()

            # Populate logical partition benchmark targets
            $logDrives = Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue | Where-Object { $_.Free -gt 0 }
            if ($logDrives) {
                foreach ($ld in $logDrives) {
                    $freeGb = [math]::Round($ld.Free / 1GB, 1)
                    $cmbBenchTarget.Items.Add("$($ld.Name):\ ($freeGb GB Free)") | Out-Null
                }
            }
            if ($cmbBenchTarget.Items.Count -gt 0) {
                $cmbBenchTarget.SelectedIndex = 0
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
                    $shLV.Items.Add($item) | Out-Null

                    $displayStr = "Disk $($d.DeviceId): $($d.FriendlyName) [$busType $sizeGb GB] - $($d.HealthStatus)"
                    $cmbDrives.Items.Add($displayStr) | Out-Null
                    $state.DiskListCache += [pscustomobject]@{
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

            if ($cmbDrives.Items.Count -gt 0) {
                $cmbDrives.SelectedIndex = 0
            }
        } catch {
            Log-Message "Error refreshing storage drive list: $_" "Warning"
        }
    }.GetNewClosure()

    $cmbDrives.Add_SelectedIndexChanged({
        $idx = $cmbDrives.SelectedIndex
        if ($idx -ge 0 -and $idx -lt $state.DiskListCache.Count) {
            $sel = $state.DiskListCache[$idx]
            $lblCardModel.Text = "Drive: $($sel.Model) ($($sel.Size))"
            $lblCardBus.Text = "Interface: $($sel.BusType) ($($sel.MediaType))"
            $lblCardHealth.Text = "Health: $($sel.Health)"
            $lblCardHealth.ForeColor = if ($sel.Health -eq 'Healthy') { [System.Drawing.ColorTranslator]::FromHtml("#57F287") } else { [System.Drawing.ColorTranslator]::FromHtml("#FEE75C") }
            $lblCardWrites.Text = "Total Writes: $($sel.Writes)"
            $lblCardWear.Text = "Wearout: $($sel.Wearout)"
        }
    }.GetNewClosure())

    # Benchmark Execution
    $btnBenchStart.Add_Click({
        if ($cmbBenchTarget.SelectedIndex -lt 0 -or -not $cmbBenchTarget.SelectedItem) {
            $lblBenchStatus.Text = "Please select a target partition first."
            $lblBenchStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
            return
        }

        $selText = [string]$cmbBenchTarget.SelectedItem
        $targetRoot = if ($selText -match '^([a-zA-Z]:\\?)') { $matches[1] } else { ($selText -split '\s+')[0] }
        if (-not $targetRoot.EndsWith("\")) { $targetRoot += "\" }

        $sizeMb = switch ($cmbBenchSize.SelectedIndex) {
            0 { 100 }
            1 { 250 }
            2 { 500 }
            3 { 1024 }
            4 { 5120 }
            5 { 10240 }
            Default { 250 }
        }

        try {
            $btnBenchStart.Enabled = $false
            $btnBenchCancel.Enabled = $true
            $cmbBenchTarget.Enabled = $false
            $cmbBenchSize.Enabled = $false
            $benchGraph.Clear()
            $valSeqRead.Text = "-- MB/s"
            $valSeqWrite.Text = "-- MB/s"
            $valRandRead.Text = "-- IOPS"
            $valRandWrite.Text = "-- IOPS"

            $state.BenchEngine.StartBenchmark($targetRoot, $sizeMb)

            while (-not $state.BenchEngine.IsFinished) {
                $p = $state.BenchEngine.CurrentProgress
                if ($null -ne $p) {
                    $benchProgressBar.Value = [math]::Max(0, [math]::Min(100, [int]$p.ProgressPercent))
                    $lblBenchStatus.Text = "$($p.CurrentTest)... $([math]::Round($p.CurrentSpeedMBs, 1)) MB/s"
                    if ($p.CurrentSpeedMBs -gt 0) {
                        $benchGraph.AddPoint($p.CurrentSpeedMBs)
                    }
                }
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 40
            }

            $res = $state.BenchEngine.Result
            if ($res -and $res.Success) {
                $valSeqRead.Text = "$([math]::Round($res.SeqReadMBs, 1)) MB/s"
                $valSeqWrite.Text = "$([math]::Round($res.SeqWriteMBs, 1)) MB/s"
                $valRandRead.Text = "$([int]$res.Rand4KReadIops) IOPS"
                $valRandWrite.Text = "$([int]$res.Rand4KWriteIops) IOPS"
                $lblBenchStatus.Text = "Benchmark completed successfully!"
                $lblBenchStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                $benchProgressBar.Value = 100
            } else {
                $lblBenchStatus.Text = if ($res -and $res.ErrorMessage) { "Benchmark failed: $($res.ErrorMessage)" } else { "Benchmark cancelled." }
                $lblBenchStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
            }
        } catch {
            $lblBenchStatus.Text = "Benchmark error: $_"
            $lblBenchStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
        } finally {
            $btnBenchStart.Enabled = $true
            $btnBenchCancel.Enabled = $false
            $cmbBenchTarget.Enabled = $true
            $cmbBenchSize.Enabled = $true
        }
    }.GetNewClosure())

    $btnBenchCancel.Add_Click({
        if ($state.BenchEngine) { $state.BenchEngine.Cancel() }
        $btnBenchCancel.Enabled = $false
    }.GetNewClosure())

    $btnRefresh.Add_Click({
        &$populateDisks
    }.GetNewClosure())

    $btnClose.Add_Click({
        if ($state.BenchEngine) { $state.BenchEngine.Cancel() }
        $shForm.Close()
    }.GetNewClosure())

    $shForm.Add_FormClosing({
        if ($state.BenchEngine) { $state.BenchEngine.Cancel() }
    }.GetNewClosure())

    $shForm.Add_Load({
        Invoke-HMTScale $shForm
        Set-RoundedControl $btnRefresh
        Set-RoundedControl $btnBenchStart
        Set-RoundedControl $btnBenchCancel
        Set-RoundedControl $btnClose

        if ($global:HMTScaleFactor -ne 1.0) {
            foreach ($col in $shLV.Columns) {
                $col.Width = [int]($col.Width * $global:HMTScaleFactor)
            }
        }
        &$populateDisks
    }.GetNewClosure())

    Show-HMTWindow $shForm | Out-Null
}

# ==============================================================================
# 5. High-Precision Packet Loss & Latency Tester Dialog (Revamped with C# Engine)
# ==============================================================================
function Show-PacketLossTestDialog {
    $pltForm = New-Object System.Windows.Forms.Form
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

    $txtHost = New-Object HMT.Tools.DarkTextBox
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

    $txtPps = New-Object HMT.Tools.DarkTextBox
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

    $txtSize = New-Object HMT.Tools.DarkTextBox
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

    $txtDuration = New-Object HMT.Tools.DarkTextBox
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
    $btnP1.Add_Click({ $txtHost.Text = "1.1.1.1" }.GetNewClosure())
    $pltForm.Controls.Add($btnP1)

    $btnP2 = New-Object System.Windows.Forms.Button
    $btnP2.Text = "Google (8.8.8.8)"
    $btnP2.Location = New-Object System.Drawing.Point(205, $y)
    $btnP2.Size = New-Object System.Drawing.Size(175, 26)
    $btnP2.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $btnP2.FlatStyle = 'Flat'
    $btnP2.FlatAppearance.BorderSize = 1
    $btnP2.Add_Click({ $txtHost.Text = "8.8.8.8" }.GetNewClosure())
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
    }.GetNewClosure())
    $pltForm.Controls.Add($btnP3)

    $btnP4 = New-Object System.Windows.Forms.Button
    $btnP4.Text = "Local Host (127.0.0.1)"
    $btnP4.Location = New-Object System.Drawing.Point(575, $y)
    $btnP4.Size = New-Object System.Drawing.Size(185, 26)
    $btnP4.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $btnP4.FlatStyle = 'Flat'
    $btnP4.FlatAppearance.BorderSize = 1
    $btnP4.Add_Click({ $txtHost.Text = "127.0.0.1" }.GetNewClosure())
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
        $lTitle.UseMnemonic = $false
        $lTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
        $lTitle.Location = New-Object System.Drawing.Point(0, 6)
        $lTitle.Size = New-Object System.Drawing.Size($width, 16)
        $lTitle.TextAlign = 'MiddleCenter'
        $p.Controls.Add($lTitle)

        $lVal = New-Object System.Windows.Forms.Label
        $lVal.Text = $initialVal
        $lVal.UseMnemonic = $false
        $lVal.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
        $lVal.Font = Get-HMTFont $font.FontFamily 14 ([System.Drawing.FontStyle]::Bold)
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

    # Smooth GDI+ Double-Buffered Ping Graph with Dynamic Latency Gradient
    $y += 78
    $pingGraph = New-Object HMT.Tools.SmoothGraphControl
    $pingGraph.Location = New-Object System.Drawing.Point(20, $y)
    $pingGraph.Size = New-Object System.Drawing.Size(740, 225)
    $pingGraph.UnitLabel = "ms"
    $pingGraph.LineColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $pingGraph.UseDynamicLatencyColors = $true
    $pingGraph.MaxPoints = 100
    $pltForm.Controls.Add($pingGraph)

    $y += 238
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point(645, $y)
    $btnClose.Size = New-Object System.Drawing.Size(115, 36)
    $btnClose.Text = "Close"
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $pltForm.Controls.Add($btnClose)

    $state = @{
        PingEngine = New-Object HMT.Tools.HighPrecisionPingEngine
    }

    $pingTimer = New-Object System.Windows.Forms.Timer
    $pingTimer.Interval = 40
    $pingTimer.Add_Tick({
        if ($null -ne $state.PingEngine) {
            $samples = $state.PingEngine.DrainSamples()
            if ($samples -and $samples.Length -gt 0) {
                foreach ($s in $samples) {
                    if ($s.Success) {
                        $pingGraph.AddPoint($s.RttMs)
                        $valLatency.Text = "$([math]::Round($s.RttMs, 1)) ms"
                        $valJitter.Text = "$([math]::Round($s.JitterMs, 1)) ms"
                    } else {
                        $pingGraph.AddPoint(0)
                    }
                }

                $sum = $state.PingEngine.GetSummary()
                if ($null -ne $sum) {
                    $valLoss.Text = "$([math]::Round($sum.LossPercent, 1))%"
                    $valLoss.ForeColor = if ($sum.LossPercent -eq 0) {
                        [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                    } elseif ($sum.LossPercent -lt 5) {
                        [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
                    } else {
                        [System.Drawing.ColorTranslator]::FromHtml("#ED4245")
                    }
                    $valPackets.Text = "$($sum.TotalReceived) / $($sum.TotalLost)"
                }
            }

            if (-not $state.PingEngine.IsRunning) {
                if ($pingTimer) { $pingTimer.Stop() }
                $btnStart.Text = "Start Test"
                $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                $txtHost.Enabled = $true
                $txtPps.Enabled = $true
                $txtSize.Enabled = $true
                $txtDuration.Enabled = $true
            }
        }
    }.GetNewClosure())

    $btnStart.Add_Click({
        if ($state.PingEngine.IsRunning) {
            $state.PingEngine.Stop()
            if ($pingTimer) { $pingTimer.Stop() }
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
        $pingGraph.MaxPoints = [math]::Max(60, ($pps * 60))
        $pingGraph.Clear()

        $state.PingEngine.Start($hostVal, $pps, $sz, $dur)
        if ($pingTimer) { $pingTimer.Start() }
    }.GetNewClosure())

    $btnClose.Add_Click({
        if ($pingTimer) { $pingTimer.Stop() }
        if ($state.PingEngine.IsRunning) { $state.PingEngine.Stop() }
        $pltForm.Close()
    }.GetNewClosure())

    $pltForm.Add_FormClosing({
        if ($pingTimer) {
            $pingTimer.Stop()
            $pingTimer.Dispose()
        }
        if ($state.PingEngine.IsRunning) { $state.PingEngine.Stop() }
    }.GetNewClosure())

    $pltForm.Add_Load({
        Invoke-HMTScale $pltForm
        Set-RoundedControl $btnStart
        Set-RoundedControl $btnP1
        Set-RoundedControl $btnP2
        Set-RoundedControl $btnP3
        Set-RoundedControl $btnP4
        Set-RoundedControl $btnClose
    }.GetNewClosure())

    Show-HMTWindow $pltForm | Out-Null
}

# ==============================================================================
# 6. BitLocker Drive Encryption & Recovery Manager
# ==============================================================================
function Show-BitLockerManagerDialog {
    $blForm = New-Object System.Windows.Forms.Form
    $blForm.Text = "BitLocker Drive Encryption & Recovery Manager"
    $blForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $blForm.ClientSize = New-Object System.Drawing.Size(760, 518)
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
    $lblSelectDrive.UseMnemonic = $false
    $lblSelectDrive.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblSelectDrive.Location = New-Object System.Drawing.Point(20, 15)
    $lblSelectDrive.AutoSize = $true
    $blForm.Controls.Add($lblSelectDrive)

    $cmbDrives = New-Object HMT.Tools.DarkComboBox
    $cmbDrives.Location = New-Object System.Drawing.Point(170, 11)
    $cmbDrives.Size = New-Object System.Drawing.Size(460, 26)
    $blForm.Controls.Add($cmbDrives)

    $btnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh.Text = "Refresh"
    $btnRefresh.Location = New-Object System.Drawing.Point(640, 9)
    $btnRefresh.Size = New-Object System.Drawing.Size(100, 30)
    $btnRefresh.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnRefresh.FlatStyle = 'Flat'
    $btnRefresh.FlatAppearance.BorderSize = 1
    $blForm.Controls.Add($btnRefresh)

    # Drive Status Summary Panel
    $summaryPanel = New-Object System.Windows.Forms.Panel
    $summaryPanel.Location = New-Object System.Drawing.Point(20, 48)
    $summaryPanel.Size = New-Object System.Drawing.Size(720, 75)
    $summaryPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $summaryPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $blForm.Controls.Add($summaryPanel)

    $lblVolStatus = New-Object System.Windows.Forms.Label
    $lblVolStatus.Text = "Status: Detecting..."
    $lblVolStatus.UseMnemonic = $false
    $lblVolStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $lblVolStatus.Location = New-Object System.Drawing.Point(15, 10)
    $lblVolStatus.Size = New-Object System.Drawing.Size(450, 20)
    $summaryPanel.Controls.Add($lblVolStatus)

    $lblVolType = New-Object System.Windows.Forms.Label
    $lblVolType.Text = "Volume Type: -- | Encryption Method: --"
    $lblVolType.UseMnemonic = $false
    $lblVolType.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblVolType.Location = New-Object System.Drawing.Point(15, 32)
    $lblVolType.Size = New-Object System.Drawing.Size(450, 18)
    $summaryPanel.Controls.Add($lblVolType)

    $lblLockStatus = New-Object System.Windows.Forms.Label
    $lblLockStatus.Text = "Lock Status: -- | Protection: --"
    $lblLockStatus.UseMnemonic = $false
    $lblLockStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblLockStatus.Location = New-Object System.Drawing.Point(15, 52)
    $lblLockStatus.Size = New-Object System.Drawing.Size(450, 18)
    $summaryPanel.Controls.Add($lblLockStatus)

    $lblVolPct = New-Object System.Windows.Forms.Label
    $lblVolPct.Text = "-- %"
    $lblVolPct.UseMnemonic = $false
    $lblVolPct.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $lblVolPct.Font = Get-HMTFont $font.FontFamily 18 ([System.Drawing.FontStyle]::Bold)
    $lblVolPct.Location = New-Object System.Drawing.Point(480, 10)
    $lblVolPct.Size = New-Object System.Drawing.Size(225, 30)
    $lblVolPct.TextAlign = 'MiddleRight'
    $summaryPanel.Controls.Add($lblVolPct)

    $lblVolPctSub = New-Object System.Windows.Forms.Label
    $lblVolPctSub.Text = "Encrypted"
    $lblVolPctSub.UseMnemonic = $false
    $lblVolPctSub.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblVolPctSub.Location = New-Object System.Drawing.Point(480, 42)
    $lblVolPctSub.Size = New-Object System.Drawing.Size(225, 20)
    $lblVolPctSub.TextAlign = 'MiddleRight'
    $summaryPanel.Controls.Add($lblVolPctSub)

    # Section 1: Protectors & Recovery Password Inspector
    $lblProtTitle = New-Object System.Windows.Forms.Label
    $lblProtTitle.Text = "Key Protectors & Recovery Password:"
    $lblProtTitle.UseMnemonic = $false
    $lblProtTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblProtTitle.Font = Get-HMTFont $font.FontFamily 11 ([System.Drawing.FontStyle]::Bold)
    $lblProtTitle.Location = New-Object System.Drawing.Point(20, 136)
    $lblProtTitle.AutoSize = $true
    $blForm.Controls.Add($lblProtTitle)

    $txtRecoveryKey = New-Object HMT.Tools.DarkTextBox
    $txtRecoveryKey.Location = New-Object System.Drawing.Point(20, 158)
    $txtRecoveryKey.Size = New-Object System.Drawing.Size(490, 26)
    $txtRecoveryKey.ReadOnly = $true
    $txtRecoveryKey.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#1e1f22")
    $txtRecoveryKey.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $txtRecoveryKey.Font = Get-HMTFont "Consolas" 12 ([System.Drawing.FontStyle]::Bold)
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

    $lvProtectors = New-Object HMT.Tools.DarkListView
    $lvProtectors.Location = New-Object System.Drawing.Point(20, 192)
    $lvProtectors.Size = New-Object System.Drawing.Size(720, 85)
    $lvProtectors.Columns.Add("Protector Type", 180) | Out-Null
    $lvProtectors.Columns.Add("Key / Details", 410) | Out-Null
    $lvProtectors.Columns.Add("ID", 110) | Out-Null
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
    $lblUnlockMethod.UseMnemonic = $false
    $lblUnlockMethod.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblUnlockMethod.Location = New-Object System.Drawing.Point(10, 8)
    $lblUnlockMethod.Size = New-Object System.Drawing.Size(120, 18)
    $unlockPanel.Controls.Add($lblUnlockMethod)

    $cmbUnlockMethod = New-Object HMT.Tools.DarkComboBox
    $cmbUnlockMethod.Items.AddRange(@("Recovery Password (48-digit)", "Password / Passphrase", "PIN"))
    $cmbUnlockMethod.SelectedIndex = 0
    $cmbUnlockMethod.Location = New-Object System.Drawing.Point(10, 28)
    $cmbUnlockMethod.Size = New-Object System.Drawing.Size(210, 26)
    $unlockPanel.Controls.Add($cmbUnlockMethod)

    $lblUnlockInput = New-Object System.Windows.Forms.Label
    $lblUnlockInput.Text = "Password / Recovery Key:"
    $lblUnlockInput.UseMnemonic = $false
    $lblUnlockInput.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblUnlockInput.Location = New-Object System.Drawing.Point(235, 8)
    $lblUnlockInput.Size = New-Object System.Drawing.Size(200, 18)
    $unlockPanel.Controls.Add($lblUnlockInput)

    $txtUnlockSecret = New-Object HMT.Tools.DarkTextBox
    $txtUnlockSecret.Location = New-Object System.Drawing.Point(235, 28)
    $txtUnlockSecret.Size = New-Object System.Drawing.Size(350, 25)
    $txtUnlockSecret.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
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
    $lblProgStatus.UseMnemonic = $false
    $lblProgStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblProgStatus.Location = New-Object System.Drawing.Point(15, 8)
    $lblProgStatus.Size = New-Object System.Drawing.Size(480, 20)
    $progPanel.Controls.Add($lblProgStatus)

    $pBar = New-Object HMT.Tools.SmoothProgressBar
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

    $btnContinueBg = New-Object System.Windows.Forms.Button
    $btnContinueBg.Text = "Continue in Background & Close"
    $btnContinueBg.UseMnemonic = $false
    $btnContinueBg.Location = New-Object System.Drawing.Point(15, 54)
    $btnContinueBg.Size = New-Object System.Drawing.Size(230, 28)
    $btnContinueBg.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnContinueBg.FlatStyle = 'Flat'
    $btnContinueBg.FlatAppearance.BorderSize = 1
    $btnContinueBg.Enabled = $false
    $progPanel.Controls.Add($btnContinueBg)

    $btnPauseResume = New-Object System.Windows.Forms.Button
    $btnPauseResume.Text = "Pause / Resume"
    $btnPauseResume.UseMnemonic = $false
    $btnPauseResume.Location = New-Object System.Drawing.Point(255, 54)
    $btnPauseResume.Size = New-Object System.Drawing.Size(140, 28)
    $btnPauseResume.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnPauseResume.FlatStyle = 'Flat'
    $btnPauseResume.FlatAppearance.BorderSize = 1
    $btnPauseResume.Enabled = $false
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
    $state = @{
        Volumes = @{}
        SelectedVolume = $null
    }
    $pollTimer = New-Object System.Windows.Forms.Timer
    $pollTimer.Interval = 1000

    $formatStatus = {
        param($rawStatus)
        if (-not $rawStatus) { return "Unknown" }
        switch ($rawStatus.ToString()) {
            "EncryptionInProgress" { "Encryption in Progress" }
            "DecryptionInProgress" { "Decryption in Progress" }
            "FullyEncrypted"       { "Fully Encrypted" }
            "FullyDecrypted"       { "Fully Decrypted" }
            Default {
                $rawStatus.ToString() -creplace '([a-z])([A-Z])', '$1 $2'
            }
        }
    }

    # Data Population Logic
    $refreshVolumes = {
        $cmbDrives.Items.Clear()
        $state.Volumes.Clear()
        
        try {
            $vols = Get-BitLockerVolume -ErrorAction SilentlyContinue
            if ($vols) {
                foreach ($v in $vols) {
                    $mp = $v.MountPoint
                    $label = if ($v.VolumeType) { "$($v.VolumeType)" } else { "Drive" }
                    $statusNice = &$formatStatus $v.VolumeStatus
                    if ($v.VolumeStatus -eq 'FullyDecrypted' -and $v.ProtectionStatus -ne 'On') {
                        $display = "$mp ($label) - Fully Decrypted"
                    } else {
                        $lock = if ($v.LockStatus -eq 'Locked') { "LOCKED" } else { "Unlocked" }
                        $prot = if ($v.ProtectionStatus -eq 'On') { "Prot:On" } else { "Prot:Off" }
                        $display = "$mp ($label) - $statusNice [$lock, $prot]"
                    }
                    $state.Volumes[$display] = $v
                    $cmbDrives.Items.Add($display) | Out-Null
                }
            } else {
                $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.DisplayRoot -or $_.Free -gt 0 }
                foreach ($d in $drives) {
                    $mp = "$($d.Name):"
                    $display = "$mp [Drive] - Fully Decrypted"
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
                    $state.Volumes[$display] = $dummy
                    $cmbDrives.Items.Add($display) | Out-Null
                }
            }
        } catch {
            $display = "Error querying BitLocker: $_"
            $cmbDrives.Items.Add($display) | Out-Null
        }

        # Auto-select active in-progress volume if any exists, otherwise select first item
        $inProgressIndex = -1
        for ($i = 0; $i -lt $cmbDrives.Items.Count; $i++) {
            $itemStr = $cmbDrives.Items[$i].ToString()
            if ($state.Volumes.ContainsKey($itemStr)) {
                $volObj = $state.Volumes[$itemStr]
                if ($volObj.VolumeStatus -eq 'EncryptionInProgress' -or $volObj.VolumeStatus -eq 'DecryptionInProgress') {
                    $inProgressIndex = $i
                    break
                }
            }
        }

        if ($inProgressIndex -ge 0) {
            $cmbDrives.SelectedIndex = $inProgressIndex
        } elseif ($cmbDrives.Items.Count -gt 0) {
            $cmbDrives.SelectedIndex = 0
        }
    }.GetNewClosure()

    $updateSelectedDriveUI = {
        if ($cmbDrives.SelectedItem -and $state.Volumes.ContainsKey($cmbDrives.SelectedItem.ToString())) {
            $v = $state.Volumes[$cmbDrives.SelectedItem.ToString()]
            $state.SelectedVolume = $v
            $mp = $v.MountPoint

            try {
                $latest = Get-BitLockerVolume -MountPoint $mp -ErrorAction SilentlyContinue
                if ($latest) { $v = $latest; $state.SelectedVolume = $latest }
            } catch {}

            $convStatus = $null
            try {
                $wmiVol = Get-CimInstance -Namespace root\CIMV2\Security\MicrosoftVolumeEncryption -ClassName Win32_EncryptableVolume -Filter "DriveLetter = '$mp'" -ErrorAction SilentlyContinue
                if ($wmiVol) {
                    $convRes = Invoke-CimMethod -InputObject $wmiVol -MethodName GetConversionStatus -ErrorAction SilentlyContinue
                    if ($convRes -and $null -ne $convRes.EncryptionFlags) {
                        if (($convRes.EncryptionFlags -band 1) -eq 1) {
                            $convStatus = "Used Space Only"
                        } else {
                            $convStatus = "Full Volume"
                        }
                    }
                }
            } catch {}

            if (-not $convStatus) {
                try {
                    $bdeText = (& "$env:WINDIR\System32\manage-bde.exe" -status $mp 2>&1 | Out-String)
                    if ($bdeText -match 'Used Space Only') {
                        $convStatus = "Used Space Only"
                    } elseif ($bdeText -match 'Fully Encrypted|Full Volume') {
                        $convStatus = "Full Volume"
                    }
                } catch {}
            }
            if (-not $convStatus) { $convStatus = "Full Volume" }

            $statusText = &$formatStatus $v.VolumeStatus
            $lblVolStatus.Text = "Status: $statusText on $mp"
            $lblVolType.Text = "Volume: $mp ($($v.VolumeType)) | Method: $($v.EncryptionMethod)"
            $lblLockStatus.Text = "Lock Status: $($v.LockStatus) | Protection: $($v.ProtectionStatus)"
            $pct = if ($null -ne $v.EncryptionPercentage) { $v.EncryptionPercentage } else { 0 }
            if ($v.VolumeStatus -eq 'FullyDecrypted' -or ($pct -eq 0 -and $v.ProtectionStatus -ne 'On')) {
                $lblVolPct.Text = "0 %"
                $lblVolPctSub.Text = "Decrypted"
                $lblVolPct.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
            } else {
                $lblVolPct.Text = "$pct %"
                $lblVolPctSub.Text = "$convStatus"
                $lblVolPct.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
            }

            $isRebootPending = ($bdeText -match '(?i)waiting for restart|restart required|hardware test|protection off \(restart')
            if ($isRebootPending) {
                $lblVolStatus.Text = "Status: Restart Required (Hardware Test Pending)"
                $lblVolStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
                $lblProgStatus.Text = "System restart required before encryption starts."
                $lblVolPctSub.Text = "Reboot Needed"
            }

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
            $isPaused = ($v.VolumeStatus.ToString() -match 'Paused' -or ($convRes -and $convRes.ConversionStatus -in @(4,5)) -or $bdeText -match '(?i)conversion status.*paused|encryption paused|decryption paused')
            $isInProgress = ($v.VolumeStatus -eq 'EncryptionInProgress' -or $v.VolumeStatus -eq 'DecryptionInProgress' -or ($convRes -and $convRes.ConversionStatus -in @(2,3)) -or $isPaused)

            if ($isInProgress) {
                $statusMsg = if ($isPaused) { "Conversion Paused" } else { $statusText }
                $lblProgStatus.Text = "$statusMsg on $mp ($pct% Complete)..."
                $pBar.Value = [math]::Max(0, [math]::Min(100, [int]$pct))
                $pBar.ShowShimmer = (-not $isPaused)
                $btnContinueBg.Enabled = $true
                $btnPauseResume.Enabled = $true
                $btnPauseResume.Text = if ($isPaused) { "Resume Conversion" } else { "Pause Conversion" }
                if ($pollTimer -and (-not $isPaused)) { $pollTimer.Start() }
            } else {
                if (-not $isRebootPending) {
                    $lblProgStatus.Text = "Operation Status: Idle ($statusText)"
                }
                $pBar.Value = 0
                $pBar.ShowShimmer = $false
                $btnContinueBg.Enabled = $false
                if ($v.VolumeStatus -eq 'FullyEncrypted') {
                    $btnPauseResume.Enabled = $true
                    $btnPauseResume.Text = if ($v.ProtectionStatus -eq 'On') { "Suspend Protection" } else { "Resume Protection" }
                } else {
                    $btnPauseResume.Enabled = $false
                    $btnPauseResume.Text = "Pause / Resume"
                }
                if ($pollTimer) { $pollTimer.Stop() }
            }

            # Button states
            $btnEnable.Enabled = ($v.VolumeStatus -eq 'FullyDecrypted' -and $v.LockStatus -ne 'Locked')
            $btnDisable.Enabled = ($v.VolumeStatus -eq 'FullyEncrypted' -or $isInProgress)
        }
    }.GetNewClosure()

    # Timer handler for live progress polling
    $pollTimer.Add_Tick({
        if ($state.SelectedVolume) {
            $mp = $state.SelectedVolume.MountPoint
            try {
                $latest = Get-BitLockerVolume -MountPoint $mp -ErrorAction SilentlyContinue
                if ($latest) {
                    $pct = if ($null -ne $latest.EncryptionPercentage) { $latest.EncryptionPercentage } else { 0 }
                    $liveStatus = &$formatStatus $latest.VolumeStatus
                    $lblProgStatus.Text = "$liveStatus on $mp ($pct% Complete)..."
                    $pBar.Value = [math]::Max(0, [math]::Min(100, [int]$pct))
                    $lblVolPct.Text = "$pct %"
                    $lblVolStatus.Text = "Status: $liveStatus on $mp"
                    
                    $isStillActive = ($latest.VolumeStatus -eq 'EncryptionInProgress' -or $latest.VolumeStatus -eq 'DecryptionInProgress')
                    if (-not $isStillActive) {
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
        if ($txtRecoveryKey.Text -and $txtRecoveryKey.Text -ne "No active Recovery Password selected" -and $txtRecoveryKey.Text -ne "No Recovery Password found") {
            [System.Windows.Forms.Clipboard]::SetText($txtRecoveryKey.Text)
            PopupError "Recovery Password copied to clipboard!`n`n$($txtRecoveryKey.Text)" "Information"
        } else {
            PopupError "No recovery password available to copy." "Warning"
        }
    }.GetNewClosure())

    # Save Key to File
    $btnSaveKey.Add_Click({
        if ($txtRecoveryKey.Text -and $txtRecoveryKey.Text -ne "No active Recovery Password selected" -and $txtRecoveryKey.Text -ne "No Recovery Password found") {
            $sfd = New-Object System.Windows.Forms.SaveFileDialog
            $sfd.Filter = "Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
            $sfd.FileName = "BitLocker_Recovery_Key_$($state.SelectedVolume.MountPoint -replace ':', '').txt"
            if ($sfd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $content = @"
BitLocker Drive Encryption Recovery Key
========================================
Volume: $($state.SelectedVolume.MountPoint)
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
    }.GetNewClosure())

    # Unlock Drive Action
    $btnUnlock.Add_Click({
        if (-not $state.SelectedVolume) { return }
        $mp = $state.SelectedVolume.MountPoint
        $secret = $txtUnlockSecret.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($secret)) {
            PopupError "Please enter the password, PIN, or 48-digit recovery key." "Warning"
            return
        }

        $btnUnlock.Enabled = $false
        try {
            $method = $cmbUnlockMethod.SelectedIndex
            if ($method -eq 0) {
                Unlock-BitLocker -MountPoint $mp -RecoveryPassword $secret -ErrorAction Stop
            } elseif ($method -eq 1) {
                $secStr = ConvertTo-SecureString $secret -AsPlainText -Force
                Unlock-BitLocker -MountPoint $mp -Password $secStr -ErrorAction Stop
            } elseif ($method -eq 2) {
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
    }.GetNewClosure())

    # Enable BitLocker Action
    $btnEnable.Add_Click({
        if (-not $state.SelectedVolume) { return }
        $mp = $state.SelectedVolume.MountPoint
        
        $modeChoice = PopupError "Choose BitLocker Encryption Mode for $($mp):`n`nClick 'Yes' for Used Space Only (Faster - recommended for clean/new PCs)`nClick 'No' for Full Volume Encryption (Thorough - recommended for active PCs)`nClick 'Cancel' to abort." "Question" "YesNoCancel"
        if ($modeChoice -eq [System.Windows.Forms.DialogResult]::Cancel) { return }
        $usedOnly = ($modeChoice -eq [System.Windows.Forms.DialogResult]::Yes)

        try {
            $isOs = ($state.SelectedVolume.VolumeType -eq 'OperatingSystem')
            if ($isOs) {
                # Enable OS volume with TPM and SkipHardwareTest so encryption begins immediately
                try {
                    if ($usedOnly) {
                        Enable-BitLocker -MountPoint $mp -EncryptionMethod XtsAes256 -UsedSpaceOnly -TpmProtector -SkipHardwareTest -ErrorAction Stop
                    } else {
                        Enable-BitLocker -MountPoint $mp -EncryptionMethod XtsAes256 -TpmProtector -SkipHardwareTest -ErrorAction Stop
                    }
                } catch {
                    if ($usedOnly) {
                        Enable-BitLocker -MountPoint $mp -EncryptionMethod XtsAes256 -UsedSpaceOnly -RecoveryPasswordProtector -SkipHardwareTest -ErrorAction Stop
                    } else {
                        Enable-BitLocker -MountPoint $mp -EncryptionMethod XtsAes256 -RecoveryPasswordProtector -SkipHardwareTest -ErrorAction Stop
                    }
                }
                # Always ensure a numerical recovery password protector is added for disaster recovery
                Add-BitLockerKeyProtector -MountPoint $mp -RecoveryPasswordProtector -ErrorAction SilentlyContinue | Out-Null
            } else {
                if ($usedOnly) {
                    Enable-BitLocker -MountPoint $mp -EncryptionMethod XtsAes256 -UsedSpaceOnly -RecoveryPasswordProtector -ErrorAction Stop
                } else {
                    Enable-BitLocker -MountPoint $mp -EncryptionMethod XtsAes256 -RecoveryPasswordProtector -ErrorAction Stop
                }
            }
            PopupError "BitLocker encryption initiated on $mp!`n`nIf a system reboot is required for TPM validation, encryption will proceed automatically on next startup.`nPlease view and save your Recovery Key." "Information"
            &$refreshVolumes
        } catch {
            PopupError "Failed to enable BitLocker on $($mp):`n$_" "Error"
        }
    }.GetNewClosure())

    # Disable BitLocker Action
    $btnDisable.Add_Click({
        if (-not $state.SelectedVolume) { return }
        $mp = $state.SelectedVolume.MountPoint
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

    # Add Recovery Password Action
    $btnAddProtector.Add_Click({
        if (-not $state.SelectedVolume) { return }
        $mp = $state.SelectedVolume.MountPoint
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
        if (-not $state.SelectedVolume) { return }
        $mp = $state.SelectedVolume.MountPoint
        $driveLetter = $mp.TrimEnd('\')
        try {
            $btnText = $btnPauseResume.Text
            if ($btnText -match 'Resume Conversion') {
                $res = (& "$env:WINDIR\System32\manage-bde.exe" -resume $driveLetter 2>&1 | Out-String)
                PopupError "BitLocker encryption/decryption conversion resumed on $mp.`n`n$res" "Information"
            } elseif ($btnText -match 'Pause Conversion') {
                $res = (& "$env:WINDIR\System32\manage-bde.exe" -pause $driveLetter 2>&1 | Out-String)
                PopupError "BitLocker encryption/decryption conversion paused on $mp.`n`n$res" "Information"
            } elseif ($btnText -match 'Suspend Protection') {
                Suspend-BitLocker -MountPoint $mp -RebootCount 0 -ErrorAction Stop
                PopupError "BitLocker key protection suspended on $mp." "Information"
            } elseif ($btnText -match 'Resume Protection') {
                Resume-BitLocker -MountPoint $mp -ErrorAction Stop
                PopupError "BitLocker key protection resumed on $mp." "Information"
            } else {
                $bdeText = (& "$env:WINDIR\System32\manage-bde.exe" -status $mp 2>&1 | Out-String)
                if ($bdeText -match '(?i)paused') {
                    $res = (& "$env:WINDIR\System32\manage-bde.exe" -resume $driveLetter 2>&1 | Out-String)
                    PopupError "BitLocker encryption/decryption conversion resumed on $mp.`n`n$res" "Information"
                } else {
                    $res = (& "$env:WINDIR\System32\manage-bde.exe" -pause $driveLetter 2>&1 | Out-String)
                    PopupError "BitLocker encryption/decryption conversion paused on $mp.`n`n$res" "Information"
                }
            }
            &$refreshVolumes
        } catch {
            PopupError "Failed to toggle pause/resume on $($mp):`n$_" "Error"
        }
    }.GetNewClosure())

    # Continue in Background & Close
    $btnContinueBg.Add_Click({
        if ($pollTimer) { $pollTimer.Stop() }
        $blForm.Close()
    }.GetNewClosure())

    $btnClose.Add_Click({
        if ($pollTimer) { $pollTimer.Stop() }
        $blForm.Close()
    }.GetNewClosure())

    $blForm.Add_FormClosing({
        if ($pollTimer) {
            $pollTimer.Stop()
            $pollTimer.Dispose()
        }
    }.GetNewClosure())

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
    }.GetNewClosure())

    Show-HMTWindow $blForm | Out-Null
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

    # Header / Search Filter & Category Row
    $lblCategory = New-Object System.Windows.Forms.Label
    $lblCategory.Text = "Category:"
    $lblCategory.UseMnemonic = $false
    $lblCategory.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblCategory.Location = New-Object System.Drawing.Point(20, 15)
    $lblCategory.AutoSize = $true
    $suForm.Controls.Add($lblCategory)

    $cmbCategory = New-Object HMT.Tools.DarkComboBox
    $cmbCategory.Items.AddRange(@("All Categories", "Registry Run (HKCU/HKLM)", "Startup Folders (Shell)", "Logon Scheduled Tasks", "Shell & Winlogon Extensions", "Startup Services"))
    $cmbCategory.SelectedIndex = 0
    $cmbCategory.Location = New-Object System.Drawing.Point(85, 11)
    $cmbCategory.Size = New-Object System.Drawing.Size(200, 26)
    $suForm.Controls.Add($cmbCategory)

    $lblSearch = New-Object System.Windows.Forms.Label
    $lblSearch.Text = "Filter:"
    $lblSearch.UseMnemonic = $false
    $lblSearch.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblSearch.Location = New-Object System.Drawing.Point(295, 15)
    $lblSearch.AutoSize = $true
    $suForm.Controls.Add($lblSearch)

    $txtSearch = New-Object HMT.Tools.DarkTextBox
    $txtSearch.Location = New-Object System.Drawing.Point(340, 12)
    $txtSearch.Size = New-Object System.Drawing.Size(180, 25)
    $txtSearch.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $txtSearch.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $suForm.Controls.Add($txtSearch)

    $lblSummary = New-Object System.Windows.Forms.Label
    $lblSummary.Text = "Total Items: 0 (Enabled: 0, Disabled: 0)"
    $lblSummary.UseMnemonic = $false
    $lblSummary.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblSummary.Location = New-Object System.Drawing.Point(525, 15)
    $lblSummary.Size = New-Object System.Drawing.Size(295, 20)
    $lblSummary.TextAlign = 'MiddleRight'
    $suForm.Controls.Add($lblSummary)

    # Startup Items ListView
    $lvStartup = New-Object HMT.Tools.DarkListView
    $lvStartup.Location = New-Object System.Drawing.Point(20, 45)
    $lvStartup.Size = New-Object System.Drawing.Size(800, 445)
    $lvStartup.Columns.Add("Program Name", 160) | Out-Null
    $lvStartup.Columns.Add("Category", 120) | Out-Null
    $lvStartup.Columns.Add("Command Line / Target", 290) | Out-Null
    $lvStartup.Columns.Add("Location", 125) | Out-Null
    $lvStartup.Columns.Add("Status", 75) | Out-Null
    $lvStartup.AutoFitColumnIndex = 2
    $suForm.Controls.Add($lvStartup)

    # Buttons Row
    $yBtn = 502
    $btnToggle = New-Object System.Windows.Forms.Button
    $btnToggle.Text = "Toggle Enable / Disable"
    $btnToggle.UseMnemonic = $false
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

    $state = @{
        StartupData = @()
    }

    $renderStartupList = {
        $lvStartup.Items.Clear()
        $filter = $txtSearch.Text.Trim()
        $catFilter = if ($cmbCategory.SelectedItem) { $cmbCategory.SelectedItem.ToString() } else { "All Categories" }
        $enabledCount = 0
        $disabledCount = 0

        foreach ($item in $state.StartupData) {
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
            $lvStartup.Items.Add($lvi) | Out-Null
        }

        if ($lvStartup.SortColumn -ge 0) {
            $lvStartup.SortByColumn($lvStartup.SortColumn, $lvStartup.SortOrder)
        } else {
            $lvStartup.SortByColumn(0, [System.Windows.Forms.SortOrder]::Ascending)
        }
        $lvStartup.AutoResizeColumnsInternal()

        $lblSummary.Text = "Total Items: $($state.StartupData.Count) (Enabled: $enabledCount, Disabled: $disabledCount)"
    }.GetNewClosure()

    $loadStartupItems = {
        $btnRefresh.Enabled = $false
        $btnToggle.Enabled = $false
        $btnDelete.Enabled = $false
        $btnOpenLoc.Enabled = $false
        $cmbCategory.Enabled = $false
        $txtSearch.Enabled = $false
        $lvStartup.Enabled = $false
        $lblSummary.Text = "Scanning startup items, scheduled tasks & services..."
        $state.StartupData = @()
        $lvStartup.Items.Clear()
        [System.Windows.Forms.Application]::DoEvents()

        $items = @()

        # 1. Native High-Speed C# Scanner (Registry, Startup Folders, Shell, Services)
        try {
            $nativeItems = [HMT.Tools.StartupScanner]::ScanAll()
            if ($nativeItems) {
                foreach ($item in $nativeItems) {
                    $items += [pscustomobject]@{
                        Name        = $item.Name
                        Category    = $item.Category
                        Command     = $item.Command
                        Location    = $item.Location
                        Type        = $item.Type
                        RegPath     = $item.RegPath
                        ApprPath    = $item.ApprPath
                        FilePath    = $item.FilePath
                        ServiceName = $item.ServiceName
                        Status      = $item.Status
                    }
                }
            }
        } catch {}

        # 2. Scheduled Tasks (Root & Non-Microsoft Logon Triggers)
        try {
            $rootTasks = Get-ScheduledTask -TaskPath '\' -ErrorAction SilentlyContinue
            if ($rootTasks) {
                foreach ($t in $rootTasks) {
                    if ($t.TaskName -and $t.TaskPath -notlike '\Microsoft\*') {
                        $hasLogon = $false
                        foreach ($trig in $t.Triggers) {
                            if ($trig.CimClass.CimClassName -match 'Logon|Boot|Startup') { $hasLogon = $true; break }
                        }
                        if ($hasLogon) {
                            $actionExec = ($t.Actions | Select-Object -First 1).Execute
                            $items += [pscustomobject]@{
                                Name     = $t.TaskName
                                Category = "Scheduled Task"
                                Command  = [string]$actionExec
                                Location = $t.TaskPath
                                Type     = "Task"
                                TaskName = $t.TaskName
                                TaskPath = $t.TaskPath
                                Status   = if ($t.State -eq 'Disabled') { "Disabled" } else { "Enabled" }
                            }
                        }
                    }
                }
            }
        } catch {}

        $state.StartupData = $items

        # Re-enable controls once scanning finishes
        $btnRefresh.Enabled = $true
        $cmbCategory.Enabled = $true
        $txtSearch.Enabled = $true
        $lvStartup.Enabled = $true

        &$renderStartupList
    }.GetNewClosure()

    $lvStartup.Add_SelectedIndexChanged({
        $hasSel = ($lvStartup.SelectedItems.Count -gt 0)
        $btnToggle.Enabled = $hasSel
        $btnDelete.Enabled = $hasSel
        $btnOpenLoc.Enabled = $hasSel
    }.GetNewClosure())

    $txtSearch.Add_TextChanged({ &$renderStartupList }.GetNewClosure())
    $cmbCategory.Add_SelectedIndexChanged({ &$renderStartupList }.GetNewClosure())
    $btnRefresh.Add_Click({ &$loadStartupItems }.GetNewClosure())
    $btnClose.Add_Click({ $suForm.Close() }.GetNewClosure())

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
        } catch {}
    }.GetNewClosure())

    $suForm.Add_Load({
        Invoke-HMTScale $suForm
        Set-RoundedControl $btnToggle
        Set-RoundedControl $btnDelete
        Set-RoundedControl $btnOpenLoc
        Set-RoundedControl $btnRefresh
        Set-RoundedControl $btnClose
        try { [HMT.NativeMethods]::SetWindowTheme($lvStartup.Handle, "DarkMode_Explorer", $null) } catch {}
        $lvStartup.AutoResizeColumnsInternal()
        &$loadStartupItems
    }.GetNewClosure())

    Show-HMTWindow $suForm | Out-Null
}

# ==============================================================================
# 8. Windows Update Component Reset Dialog (Smooth, Non-Blocking Step-by-Step UI)
# ==============================================================================
function Show-WindowsUpdateResetDialog {
    $wuForm = New-Object System.Windows.Forms.Form
    $wuForm.Text = "Reset Windows Update Components"
    $wuForm.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#2f3136")
    $wuForm.ClientSize = New-Object System.Drawing.Size(560, 245)
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
    $lblTitle.UseMnemonic = $false
    $lblTitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
    $lblTitle.Font = Get-HMTFont $font.FontFamily 13 ([System.Drawing.FontStyle]::Bold)
    $lblTitle.Location = New-Object System.Drawing.Point(20, 14)
    $lblTitle.Size = New-Object System.Drawing.Size(520, 20)
    $wuForm.Controls.Add($lblTitle)

    $lblSubtitle = New-Object System.Windows.Forms.Label
    $lblSubtitle.Text = "Stops update services, clears SoftwareDistribution & catroot2 caches, and restarts services."
    $lblSubtitle.UseMnemonic = $false
    $lblSubtitle.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#a0a0a0")
    $lblSubtitle.Location = New-Object System.Drawing.Point(20, 36)
    $lblSubtitle.Size = New-Object System.Drawing.Size(520, 32)
    $wuForm.Controls.Add($lblSubtitle)

    # Step Status Card
    $cardPanel = New-Object System.Windows.Forms.Panel
    $cardPanel.Location = New-Object System.Drawing.Point(20, 72)
    $cardPanel.Size = New-Object System.Drawing.Size(520, 105)
    $cardPanel.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#202225")
    $cardPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $wuForm.Controls.Add($cardPanel)

    $lblStepNum = New-Object System.Windows.Forms.Label
    $lblStepNum.Text = "Status: Ready"
    $lblStepNum.UseMnemonic = $false
    $lblStepNum.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#5865F2")
    $lblStepNum.Font = Get-HMTFont $font.FontFamily 11 ([System.Drawing.FontStyle]::Bold)
    $lblStepNum.Location = New-Object System.Drawing.Point(15, 10)
    $lblStepNum.Size = New-Object System.Drawing.Size(490, 18)
    $cardPanel.Controls.Add($lblStepNum)

    $lblStepDetail = New-Object System.Windows.Forms.Label
    $lblStepDetail.Text = "Click 'Start Reset' to begin resetting Windows Update components."
    $lblStepDetail.UseMnemonic = $false
    $lblStepDetail.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $lblStepDetail.Font = Get-HMTFont $font.FontFamily 12
    $lblStepDetail.Location = New-Object System.Drawing.Point(15, 30)
    $lblStepDetail.Size = New-Object System.Drawing.Size(490, 26)
    $cardPanel.Controls.Add($lblStepDetail)

    $pb = New-Object HMT.Tools.SmoothProgressBar
    $pb.Location = New-Object System.Drawing.Point(15, 66)
    $pb.Size = New-Object System.Drawing.Size(490, 18)
    $pb.BorderRadius = 4
    $pb.Value = 0
    $pb.ShowShimmer = $false
    $cardPanel.Controls.Add($pb)

    # Action Buttons
    $yBtn = 192
    $btnStart = New-Object System.Windows.Forms.Button
    $btnStart.Location = New-Object System.Drawing.Point(305, $yBtn)
    $btnStart.Size = New-Object System.Drawing.Size(120, 36)
    $btnStart.Text = "Start Reset"
    $btnStart.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
    $btnStart.FlatStyle = 'Flat'
    $btnStart.FlatAppearance.BorderSize = 1
    $wuForm.Controls.Add($btnStart)

    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Location = New-Object System.Drawing.Point(435, $yBtn)
    $btnClose.Size = New-Object System.Drawing.Size(105, 36)
    $btnClose.Text = "Cancel"
    $btnClose.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d9d9d9")
    $btnClose.FlatStyle = 'Flat'
    $btnClose.FlatAppearance.BorderSize = 1
    $wuForm.Controls.Add($btnClose)

    $stepTimer = New-Object System.Windows.Forms.Timer
    $stepTimer.Interval = 50

    $state = @{
        Phase = 'Idle'
        WaitCount = 0
        SvcIndex = 0
        Services = @("wuauserv", "bits", "cryptsvc", "msiserver")
        Error = $null
    }

    $stepTimer.Add_Tick({
        switch ($state.Phase) {
            'StopInit' {
                $lblStepNum.Text = "Step 1/4: Stopping Services"
                $lblStepDetail.Text = "Requesting stop for wuauserv, bits, cryptsvc, msiserver..."
                $pb.Value = 15
                $pb.ShowShimmer = $true
                foreach ($s in $state.Services) {
                    try {
                        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
                        if ($svc -and $svc.Status -ne 'Stopped') {
                            Stop-Service -Name $s -Force -NoWait -ErrorAction SilentlyContinue
                        }
                    } catch {}
                }
                $state.Phase = 'WaitStop'
                $state.WaitCount = 0
            }
            'WaitStop' {
                $state.WaitCount++
                $allStopped = $true
                foreach ($s in $state.Services) {
                    try {
                        $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
                        if ($svc -and $svc.Status -ne 'Stopped') {
                            $allStopped = $false
                        }
                    } catch {}
                }
                if ($allStopped -or $state.WaitCount -ge 20) {
                    $state.Phase = 'ClearCaches'
                }
            }
            'ClearCaches' {
                $lblStepNum.Text = "Step 2/4: Clearing Cache Folders"
                $lblStepDetail.Text = "Renaming SoftwareDistribution & catroot2 cache folders..."
                $pb.Value = 50
                try {
                    $timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
                    $sdPath = "$env:WINDIR\SoftwareDistribution"
                    $crPath = "$env:WINDIR\System32\catroot2"

                    if (Test-Path -LiteralPath $sdPath) {
                        Rename-Item -LiteralPath $sdPath -NewName "SoftwareDistribution.old.$timestamp" -ErrorAction SilentlyContinue
                    }
                    if (Test-Path -LiteralPath $crPath) {
                        Rename-Item -LiteralPath $crPath -NewName "catroot2.old.$timestamp" -ErrorAction SilentlyContinue
                    }
                    $qmgrFiles = Get-ChildItem -Path "$env:ALLUSERSPROFILE\Microsoft\Network\Downloader\qmgr*.dat" -ErrorAction SilentlyContinue
                    if ($qmgrFiles) {
                        $qmgrFiles | Remove-Item -Force -ErrorAction SilentlyContinue
                    }
                } catch {
                    $state.Error = $_.Exception.Message
                }
                $state.Phase = 'StartServices'
                $state.SvcIndex = 0
            }
            'StartServices' {
                $lblStepNum.Text = "Step 3/4: Starting Services"
                $pb.Value = 75
                if ($state.SvcIndex -lt $state.Services.Count) {
                    $s = $state.Services[$state.SvcIndex]
                    $lblStepDetail.Text = "Starting service: $s..."
                    try {
                        Start-Service -Name $s -ErrorAction SilentlyContinue
                    } catch {}
                    $state.SvcIndex++
                } else {
                    $state.Phase = 'Finish'
                }
            }
            'Finish' {
                $stepTimer.Stop()
                $pb.Value = 100
                $pb.ShowShimmer = $false
                if ($state.Error) {
                    $lblStepNum.Text = "Status: Completed with Warnings"
                    $lblStepNum.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#FEE75C")
                    $lblStepDetail.Text = "Services restarted. ($($state.Error))"
                } else {
                    $lblStepNum.Text = "Status: Completed Successfully"
                    $lblStepNum.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#57F287")
                    $lblStepDetail.Text = "Windows Update services restarted and caches cleared."
                    Log-Message "Successfully reset Windows Update services and cleared caches." "Success"
                }
                $btnClose.Text = "Close"
                $btnClose.Enabled = $true
                $btnStart.Visible = $false
            }
        }
    }.GetNewClosure())

    $btnStart.Add_Click({
        $btnStart.Enabled = $false
        $btnClose.Text = "Close"
        $btnClose.Enabled = $false
        Log-Message "Beginning Windows Update component reset..." "Info"
        $state.Phase = 'StopInit'
        $stepTimer.Start()
    }.GetNewClosure())

    $btnClose.Add_Click({
        if ($stepTimer) { $stepTimer.Stop() }
        $wuForm.Close()
    }.GetNewClosure())

    $wuForm.Add_FormClosing({
        if ($stepTimer) {
            $stepTimer.Stop()
            $stepTimer.Dispose()
        }
    }.GetNewClosure())

    $wuForm.Add_Load({
        Invoke-HMTScale $wuForm
        Set-RoundedControl $btnStart
        Set-RoundedControl $btnClose
    }.GetNewClosure())

    Show-HMTWindow $wuForm | Out-Null
}

