# Script Functions File - Tyler Hatfield - v1.1

# Log-Message takes a string or command output and sends it both to the registered $logPath and the PS consol
function Log-Message {
    param(
        [string]$message,
        [string]$level = "Info"  # Options: Info, Success, Error, Prompt
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$level] - $message"
    $consoleMessage = "[$level] - $message"
    $logMessage | Out-File -FilePath $logPath -Append  # Write to log
    if ($level.ToLower -eq "info") {
        Write-Host $consoleMessage  # Output to console
    } elseif ($level.ToLower -eq "prompt") {
        Write-Host -NoNewLine "$consoleMessage " -ForegroundColor "Yellow"
    } elseif ($level.ToLower -eq "error") {
        Write-Host $consoleMessage -ForegroundColor "Red"
    } elseif ($level.ToLower -eq "success") {
        Write-Host $consoleMessage -ForegroundColor "Green"
    } else {
        Write-Host $consoleMessage
    }
}

