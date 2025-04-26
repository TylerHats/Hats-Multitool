# Accounts Module - Tyler Hatfield - v1

# Code block for local account creation, loops per user input
Log-Message "Setup Local Account(s)..."
$RepeatFunction = 1
While ($RepeatFunction -eq 1) {
    Log-Message "Please enter a username or leave blank to skip this section:" "Prompt"
	$AdminUser = Read-Host
	if ($AdminUser -ne "") {
		Log-Message "Please enter a password (can be empty):" "Prompt"
		$AdminPass = Read-Host
		$UExists = Get-LocalUser -Name "$AdminUser" -ErrorAction SilentlyContinue
		if (-not $UExists) {
			Log-Message "The specified user does not exist, create account now? (y/N):" "Prompt"
			$MakeUser = Read-Host
			if ($MakeUser -eq "y" -or $MakeUser -eq "Y") {
				Net User "$AdminUser" "$AdminPass" /add | Out-File -Append -FilePath $logPath
			} else {
				Log-Message "Skipping account creation." "Skip"
			}
		} else {
			Log-Message "Update the user's password? (y/N):" "Prompt"
			$UpdateUser = Read-Host
			if ($UpdateUser.ToLower() -eq "y" -or $UpdateUser.ToLower() -eq "yes") {
				Net User "$AdminUser" "$AdminPass" | Out-File -Append -FilePath $logPath
			}
		}
		$LocalUserCheck = "$env:COMPUTERNAME\$AdminUser"
		$IsAdmin = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | Where-Object { $_.Name -eq $LocalUserCheck }
		if ($UExists -and -not $IsAdmin) {
			Log-Message "The specified user is not a local admin, elevate now? (y/N):" "Prompt"
			$MakeAdmin = Read-Host
			if ($MakeAdmin -eq "y" -or $MakeAdmin -eq "Y") {
				Net Localgroup Administrators "$AdminUser" /add | Out-File -Append -FilePath $logPath
			} else {
				Log-Message "Skipping account elevation." "Skip"
			}
		} elseif ($UExists -and $IsAdmin) {
			Log-Message "Skipping account elevation, user account is already a local administrator." "Skip"
		}
		Log-Message "Repeat this segment to add, edit or test another user account? (y/N):" "Prompt"
		$RFQ = Read-Host
		if (-not ($RFQ.ToLower() -eq "y" -or $RFQ.ToLower() -eq "yes")) {
			$RepeatFunction = 0
		}
	} else {
		Log-Message "Skipping account management." "Skip"
		$RepeatFunction = 0
	}
}