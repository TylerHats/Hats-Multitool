# Self Update Module - Tyler Hatfield - v1

# Check program version against remote, update if needed
$currentVersion = "2.0.0"
$skipUpdate = 0
Try {
	$remoteRequest = Invoke-WebRequest -Uri "https://hatsthings.com/HatsScriptsVersion.txt"
} catch {
	Log-Message "Unable to determine remote version, skipping self update check."
	$skipUpdate = 1
}
if ($skipUpdate -ne 1) {
	$remoteVersion = $remoteRequest.Content
	if ($currentVersion -eq $remoteVersion) {
		Log-Message "The script is up to date. (Version $currentVersion)" "Info"
	} else {
		Log-Message "Updating and relaunching the script... (Current Version: $currentVersion - Remote Version: $remoteVersion)" "Info"
		$sourceURL = "https://github.com/TylerHats/Hats-Multitool/releases/latest/download/Hats-Multitool-v$remoteVersion.exe"
		$shell = New-Object -ComObject Shell.Application
		$downloadsFolder = $shell.Namespace('shell:Downloads').Self.Path
		$outputPath = "$downloadsFolder\Hats-Multitool-v$remoteVersion.exe"
		Try {
			Invoke-WebRequest -Uri $sourceURL -OutFile $outputPath *>&1
		} catch {
			Log-Message "Failed to download update, please update manually." "Error"
			Pause
			Exit
		}
		# Cleanup and exit current script, then launch updated script
		$env:hatsUpdated = "1"
		$folderToDelete = "$PSScriptRoot"
		$deletionCommand = "Start-Sleep -Seconds 2; Remove-Item -Path '$folderToDelete' -Recurse -Force; Add-Content -Path '$logPath' -Value 'Script self cleanup completed during self update'; Start-Process '$outputPath'"
		Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-Command", $deletionCommand
		exit 0
	}
}

# Changelog Display
if ($env:hatsUpdated -eq "1") {
	Write-Host ""
	Log-Message "- Program sections have been broken up into 'modules' for dynamic use.`n- Each 'module' has been updated with minor changes for better interactivity.`n- Certain code has been reworked in preparation for a GUI.`n- The script has been renamed to the 'Hat's Multitool'.`n- This update is experimental due to the amount of changes, please report any issues on GitHub at HatsThings.com/go/Hats-Scripts" "Info"
	[System.Environment]::SetEnvironmentVariable("hatsUpdated", $null, [System.EnvironmentVariableTarget]::Machine)
	Write-Host ""
}