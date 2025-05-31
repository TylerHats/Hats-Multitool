# Self Update Module - Tyler Hatfield - v1.7

# Check program version against remote, update if needed
$currentVersionString = "2.5.1"
$shell = New-Object -ComObject Shell.Application
$downloadsFolder = $shell.Namespace('shell:Downloads').Self.Path
[version]$currentVersion = $currentVersionString
$skipUpdate = 0
Try {
	$remoteRequest = Invoke-WebRequest -Uri "https://hatsthings.com/HatsScriptsVersion.txt"
} catch {
	Log-Message "Unable to determine remote version, skipping self update check."
	Write-Host ""
	$skipUpdate = 1
}
if ($skipUpdate -ne 1) {
	$remoteVersionString = $remoteRequest.Content
	[version]$remoteVersion = $remoteVersionString
	if ($currentVersion -eq $remoteVersion) {
		if ($env:hatsUpdated -eq "1") {
			Log-Message "Program updated successfully! (Version $currentVersion)" "Success"
		} else {
			Log-Message "The Hat's Multitool is up to date. (Version $currentVersion)" "Info"
			Write-Host ""
		}
	} elseif ($currentVersion -gt $remoteVersion) {
		Log-Message "The program is newer than the remote version. Download from the web and relaunch? (y/N)" "Prompt"
		$ReplaceNewer = Read-Host
		if ($ReplaceNewer -match 'y|yes') {
			Log-Message "Downloading and relaunching the script... (Current Version: $currentVersion - Remote Version: $remoteVersion)" "Info"
			$sourceURL = "https://github.com/TylerHats/Hats-Multitool/releases/latest/download/Hats-Multitool-v$remoteVersion.exe"
			$outputPath = "$downloadsFolder\Hats-Multitool-v$remoteVersion.exe"
			Add-MpPreference -ExclusionPath $downloadsFolder *>&1 | Out-File -FilePath $logPath -Append
			Try {
				Invoke-WebRequest -Uri $sourceURL -OutFile $outputPath *>&1
			} catch {
				Log-Message "Failed to download update, please update manually." "Error"
				Pause
				$ForceExit = $true
			}
			# Cleanup and exit current script, then launch updated script
			$folderToDelete = "$PSScriptRoot"
			$deletionCommand = "Start-Sleep -Seconds 2; Remove-Item -Path '$folderToDelete' -Recurse -Force; Add-Content -Path '$logPath' -Value 'Script self cleanup completed during self update'; Start-Process '$outputPath' -WindowStyle Minimized"
			Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-Command", $deletionCommand
			$ForceExit = $true
		} else {
			Log-Message "Proceed with caution, and if you run into errors please redownload from the web.`n" "Skip"
		}
	} else {
		Log-Message "Updating and relaunching the script... (Current Version: $currentVersion - Remote Version: $remoteVersion)" "Info"
		$sourceURL = "https://github.com/TylerHats/Hats-Multitool/releases/latest/download/Hats-Multitool-v$remoteVersion.exe"
		$outputPath = "$downloadsFolder\Hats-Multitool-v$remoteVersion.exe"
		Add-MpPreference -ExclusionPath $downloadsFolder | Out-File -FilePath $logPath -Append
		Try {
			Invoke-WebRequest -Uri $sourceURL -OutFile $outputPath *>&1
		} catch {
			Log-Message "Failed to download update, please update manually." "Error"
			Pause
			$ForceExit = $true
		}
		# Cleanup and exit current script, then launch updated script
		$env:hatsUpdated = "1"
		$folderToDelete = "$PSScriptRoot"
		$deletionCommand = "Start-Sleep -Seconds 2; Remove-Item -Path '$folderToDelete' -Recurse -Force; Add-Content -Path '$logPath' -Value 'Script self cleanup completed during self update'; Start-Process '$outputPath' -WindowStyle Minimized"
		Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-Command", $deletionCommand
		$ForceExit = $true
	}
}

# Changelog Display
if ($env:hatsUpdated -eq "1" -and $ForceExit -ne $true) {
	Write-Host ""
	Log-Message "`n- Added new intermediate Windows Update GUI`n- Added .NET 3.5 installation functionality`n- Corrected minor general and GUI bugs" "Skip"
	$clearEnvVarCommand = "[System.Environment]::SetEnvironmentVariable('hatsUpdated', `$null, [System.EnvironmentVariableTarget]::Machine)"
	Remove-MpPreference -ExclusionPath $downloadsFolder *>&1 | Out-File -FilePath $logPath -Append
	Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-Command $clearEnvVarCommand" -Verb RunAs -WindowStyle Hidden
	Write-Host ""
	Log-Message "Press any key to continue..." "Prompt"
	Read-Host
}