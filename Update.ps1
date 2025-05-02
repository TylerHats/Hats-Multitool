# Self Update Module - Tyler Hatfield - v1.4

# Check program version against remote, update if needed
$currentVersion = "2.1.1"
$skipUpdate = 0
Try {
	$remoteRequest = Invoke-WebRequest -Uri "https://hatsthings.com/HatsScriptsVersion.txt"
} catch {
	Log-Message "Unable to determine remote version, skipping self update check."
	Write-Host ""
	$skipUpdate = 1
}
if ($skipUpdate -ne 1) {
	$remoteVersion = $remoteRequest.Content
	if ($currentVersion -eq $remoteVersion) {
		if ($env:hatsUpdated -eq "1") {
			Log-Message "Program updated successfully! (Version $currentVersion)" "Success"
		} else {
			Log-Message "The script is up to date. (Version $currentVersion)" "Info"
			Write-Host ""
		}
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
			$ForceExit = $true
		}
		# Cleanup and exit current script, then launch updated script
		$env:hatsUpdated = "1"
		$folderToDelete = "$PSScriptRoot"
		$deletionCommand = "Start-Sleep -Seconds 2; Remove-Item -Path '$folderToDelete' -Recurse -Force; Add-Content -Path '$logPath' -Value 'Script self cleanup completed during self update'; Start-Process '$outputPath'"
		Start-Process powershell.exe -ArgumentList "-NoProfile", "-WindowStyle", "Hidden", "-Command", $deletionCommand
		$ForceExit = $true
	}
}

# Changelog Display
if ($env:hatsUpdated -eq "1" -and $ForceExit -ne $true) {
	Write-Host ""
	Log-Message "Updated the visual style of GUIs and enabled navigation.`nUpdated closing behaviors and cleanup code.`nGeneral bug fixes and improvements to code." "Skip"
	$clearEnvVarCommand = "[System.Environment]::SetEnvironmentVariable('hatsUpdated', `$null, [System.EnvironmentVariableTarget]::Machine)"
	Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy Bypass", "-Command $clearEnvVarCommand" -Verb RunAs -WindowStyle Hidden
	Write-Host ""
	Log-Message "Press any key to continue..." "Prompt"
	Read-Host
}