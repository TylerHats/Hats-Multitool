# Time Zone Module - Tyler Hatfield - v1

# Prompt for time zone
$loopTZ = "1"
# Set time zone and sync
while ($loopTZ -eq "1") {
	Log-Message "Please choose a Time Zone from p (Pacific), m (Mountain), c (Central), or E (Eastern):" "Prompt"
	$TimeZone = Read-Host
	if ($TimeZone.ToLower() -eq "e" -or $TimeZone.ToLower() -eq "eastern") {
		Log-Message "Setting Time Zone to Eastern Standard Time..."
		Set-TimeZone -Name "Eastern Standard Time" | Out-File -Append -FilePath $logPath
		$loopTZ = "0"
	} else if ($TimeZone.ToLower() -eq "c" -or $TimeZone.ToLower() -eq "central") {
		Log-Message "Setting Time Zone to Central Standard Time..."
		Set-TimeZone -Name "Central Standard Time" | Out-File -Append -FilePath $logPath
		$loopTZ = "0"
	} else if ($TimeZone.ToLower() -eq "m" -or $TimeZone.ToLower() -eq "mountain") {
		Log-Message "Setting Time Zone to Mountain Standard Time..."
		Set-TimeZone -Name "Mountain Standard Time" | Out-File -Append -FilePath $logPath
		$loopTZ = "0"
	} else if ($TimeZone.ToLower() -eq "p" -or $TimeZone.ToLower() -eq "pacific") {
		Log-Message "Setting Time Zone to Pacific Standard Time..."
		Set-TimeZone -Name "Pacific Standard Time" | Out-File -Append -FilePath $logPath
		$loopTZ = "0"
	} else {
		Log-Message "Input not recognized, please try again." "Error"
	}
}
if ((Get-Service -Name w32time).Status -ne 'Running') {
    Start-Service -Name w32time | Out-File -Append -FilePath $logPath
}
w32tm /resync | Out-File -Append -FilePath $logPath