# WinGet Setup Module - Tyler Hatfield - v1

# WinGet update and MSIExec check code
Log-Message "Updating WinGet and App Installer..."
Set-WinUserLanguageList -Language en-US -force *>&1 | Out-File -Append -FilePath $logPath
$ProgressPreference = 'Continue'
winget source add --name HatsRepoAdd https://cdn.winget.microsoft.com/cache *>&1 | Out-File -Append -FilePath $logPath
winget Source Update --disable-interactivity *>&1 | Out-File -Append -FilePath $logPath
if ($LASTEXITCODE -ne 0) { winget Source Update *>&1 | Out-File -Append -FilePath $logPath }
winget Upgrade --id Microsoft.Appinstaller --accept-package-agreements --accept-source-agreements *>&1 | Out-File -Append -FilePath $logPath
$maxWaitSeconds = 180    # 3 minutes
$waitIntervalSeconds = 30
$elapsedSeconds = 0
$WaitInstall = "blank"
# Loop while msiexec.exe is running
while (Get-Process -Name msiexec -ErrorAction SilentlyContinue) {
	if ($WaitInstall -eq "blank") {
    	Log-Message "Another installation is in progress. Would you like to wait or continue? (c/W):" "Prompt"
		$WaitInstall = Read-Host
	}
	if ($WaitInstall.ToLower() -eq "c" -or $WaitInstall.ToLower() -eq "continue") {
		Log-Message "Ignoring background installation and continuing..." "Info"
		break
	}
	Log-Message "Waiting $waitIntervalSeconds and checking again..." "Info"
    Start-Sleep -Seconds $waitIntervalSeconds
    $elapsedSeconds += $waitIntervalSeconds
    if ($elapsedSeconds -ge $maxWaitSeconds) {
        Log-Message "Waited for $maxWaitSeconds seconds and the installer still has not cleared. Would you like to kill MSIEXEC.exe? (y/N):" "Prompt"
        $KillMSIE = Read-Host
		if ($KillMSIE.ToLower() -eq "y" -or $KillMSIE.ToLower() -eq "yes") {
			Log-Message "Killing MSIEXEC.exe and continuing WinGet updates..." "Info"
			try {Get-Process -Name "msiexec" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction Stop *>&1 | Out-File -Append -FilePath $logPath} catch {Log-Message "Failed to kill process MSIEXEC.exe, continuing..." "Error"}
		} else {
			Log-Message "Ignoring background installation and continuing WinGet updates..." "Info"
		}
		break
    }
}