# Script Functions File - Tyler Hatfield - v1.1

# Log-Message takes a string or command output and sends it both to the registered $logPath and the PS consol
function Log-Message {
    param(
        [string]$message,
        [string]$level = "Info"  # Options: Info, Success, Error
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$level] - $message"
    
    Write-Host $logMessage  # Output to console
    $logMessage | Out-File -FilePath $logPath -Append  # Write to log
}

