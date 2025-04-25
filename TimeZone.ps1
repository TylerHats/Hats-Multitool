# Time Zone Module - Tyler Hatfield - v1

# Prompt for time zone
Log-Message "Please choose a Time Zone from p (Pacific), m (Mountain), c (Central), or E (Eastern):" "Prompt"
$TimeZone = Read-Host
# Set time zone and sync
Log-Message "Setting Time Zone to Eastern Standard Time..."
Set-TimeZone -Name "Eastern Standard Time" | Out-File -Append -FilePath $logPath
if ((Get-Service -Name w32time).Status -ne 'Running') {
    Start-Service -Name w32time | Out-File -Append -FilePath $logPath
}
w32tm /resync | Out-File -Append -FilePath $logPath