# One Line Runner Script - Tyler Hatfield - v1.8

# Script setup
$host.UI.RawUI.BackgroundColor = "Black"
Clear-Host
$Host.UI.RawUI.WindowTitle = "Hat's Multitool Downloader"
$shell = New-Object -ComObject Shell.Application
$downloadsFolder = $shell.Namespace('shell:Downloads').Self.Path

# Download and launch main script executable
Try {
	$remoteRequest = Invoke-WebRequest -Uri "https://hatsthings.com/MultitoolFiles/HatsMultitoolVersion.txt" -UseBasicParsing -ErrorAction Stop
} catch {
	Write-Host "Unable to determine remote version, please download manually."
	pause
	exit
}
$remoteVersionString = $remoteRequest.Content.Trim()
[version]$remoteVersion = $remoteVersionString
Write-Host "Downloading and launching Hat's Multitool..."
$sourceURL = "https://github.com/TylerHats/Hats-Multitool/releases/download/v$remoteVersion/Hats-Multitool-v$remoteVersion.exe"
$outputPath = "$downloadsFolder\Hats-Multitool-v$remoteVersion.exe"
Try {
	Invoke-WebRequest -Uri $sourceURL -OutFile $outputPath -ErrorAction Stop
} catch {
	Write-Host "Failed to download Hat's Multitool, please download manually."
	Pause
	exit
}

# Drop a breadcrumb for the cleanup script so it knows where to find this EXE
$breadcrumbPath = Join-Path $env:PUBLIC "HMT_IRM_Target.txt"
$outputPath | Out-File -FilePath $breadcrumbPath -Force -ErrorAction SilentlyContinue

# Launch executable
try { Unblock-File -Path $outputPath } catch {}
Start-Process -FilePath $outputPath -WorkingDirectory $downloadsFolder -WindowStyle Minimized
# Exit current script
exit