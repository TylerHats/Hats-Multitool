# One Line Runner Script - Tyler Hatfield - v1.3

# Script setup
$host.UI.RawUI.BackgroundColor = "Black"
Clear-Host
$Host.UI.RawUI.WindowTitle = "Hat's Multitool Downloader"
$shell = New-Object -ComObject Shell.Application
$downloadsFolder = $shell.Namespace('shell:Downloads').Self.Path

# Download and launch main script executable
Try {
	$remoteRequest = Invoke-WebRequest -Uri "https://hatsthings.com/HatsScriptsVersion.txt"
} catch {
	Write-Host "Unable to determine remote version, please download manually."
	pause
	exit
}
$remoteVersionString = $remoteRequest.Content
[version]$remoteVersion = $remoteVersionString
Write-Host "Downloading and launching Hat's Multitool..."
$sourceURL = "https://github.com/TylerHats/Hats-Multitool/releases/latest/download/Hats-Multitool-v$remoteVersion.exe"
$outputPath = "$downloadsFolder\Hats-Multitool-v$remoteVersion.exe"
Add-MpPreference -ExclusionPath $downloadsFolder *>&1 | Out-Null
Try {
	Invoke-WebRequest -Uri $sourceURL -OutFile $outputPath *>&1
} catch {
	Write-Host "Failed to download Hat's Multitool, please download manually."
	Pause
	exit
}
# Launch executable
Start-Process $outputPath -WindowStyle Minimized
# Exit current script
exit