# One Line Runner Script - Tyler Hatfield

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
try {
    [version]$remoteVersion = $remoteVersionString
} catch {
    Write-Host "Failed to parse remote version string: $remoteVersionString"
    pause
    exit
}
Write-Host "Downloading and launching Hat's Multitool..."
$sourceURL = "https://github.com/TylerHats/Hats-Multitool/releases/download/v$remoteVersion/Hats-Multitool-v$remoteVersion.exe"
$outputPath = "$downloadsFolder\Hats-Multitool-v$remoteVersion.exe"

Try {
    Import-Module BitsTransfer
    Start-BitsTransfer -Source $sourceURL -Destination $outputPath -ErrorAction Stop
} catch {
    Write-Host "Failed to download Hat's Multitool via BITS, falling back..."
    Try {
        Invoke-WebRequest -Uri $sourceURL -OutFile $outputPath -ErrorAction Stop
    } catch {
        Write-Host "Download completely failed. Please download manually."
        Pause
        exit
    }
}

# Launch executable with cleanup-on-exit flag
try { Unblock-File -Path $outputPath } catch { Write-Verbose "Unblock-File failed: $_" }
Start-Process -FilePath $outputPath -ArgumentList "--cleanup-on-exit" -WorkingDirectory $downloadsFolder
exit
