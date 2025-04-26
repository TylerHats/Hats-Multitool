# System Management Module - Tyler Hatfield - v1

# Determine if Windows edition is domain/EntraID joinable
$IsPro = if ($WindowsEdition -match 'Pro|Enterprise') { 1 } else { 0 }

# Rename PC and join to domain (if needed)
$DNRetry = "y"
while ($DNRetry.ToLower() -eq "y" -or $DNRetry.ToLower() -eq "yes") {
	$DNRetry = "n"
	Log-Message "The PC is currently named: $env:computername"
	Log-Message "Would you like to change the PC name? (y/N):" "Prompt"
	$Rename = Read-Host
	if ($Rename.ToLower() -eq "y" -or $Rename.ToLower() -eq "yes") {
	    Log-Message "The serial number is: $serialNumber"
    	Log-Message "Enter the new PC name and press Enter:" "Prompt"
    	$PCName = Read-Host
    	Log-Message "Would you like to join this PC to an Active Directory Domain? (y/N):" "Prompt"
		$Domain = Read-Host
		if ($Domain.ToLower() -eq "y" -or $Domain.ToLower() -eq "yes") {
			if ($IsPro -eq 0) {
				Log-Message "The system is running '$WindowsEdition', which is not domain joinable."
			} else {
				Log-Message "Enter the domain address and press Enter (Include the suffix, Ex: .local):" "Prompt"
				$DomainName = Read-Host
				$DomainCredential = Get-Credential -Message "Enter credentials with permission to add this device to $($DomainName):"
				try {
					Add-Computer -DomainName $DomainName -NewName $PCName -Credential $DomainCredential -ErrorAction Stop *>&1 | Out-File -Append -FilePath $logPath
					Log-Message "Domain joining and PC renaming successful." "Success"
				} catch {
					Log-Message "Domain joining and/or PC naming failed, please verify the name is <15 digits and contains no forbidden characters, and credentials are correct." "Error"
					Log-Message "Retry segment? (y/N):" "Prompt"
					$DNRetry = Read-Host
				}
			}
		} else {
			try {
				Rename-Computer -NewName $PCName -Force -ErrorAction Stop *>&1 | Out-File -Append -FilePath $logPath
				Log-Message "PC renaming successful." "Success"
			} catch {
				Log-Message "PC renaming failed, please verify the name is <15 digits and contains no forbidden characters." "Error"
				Log-Message "Retry segment? (y/N):" "Prompt"
				$DNRetry = Read-Host
			}
		}
	} else {
	    Log-Message "Would you like to join this PC to an Active Directory Domain? (y/N):" "Prompt"
		$Domain = Read-Host
		if ($Domain.ToLower() -eq "y" -or $Domain.ToLower() -eq "yes") {
			if ($IsPro -eq 0) {
				Log-Message "The system is running '$WindowsEdition', which is not domain joinable."
			} else {
				Log-Message "Enter the domain address and press Enter (Include the suffix, Ex: .local):" "Prompt"
				$DomainName = Read-Host
				$DomainCredential = Get-Credential -Message "Enter credentials with permission to add this device to $($DomainName):"
				try {
					Add-Computer -DomainName $DomainName -Credential $DomainCredential -ErrorAction Stop *>&1 | Out-File -Append -FilePath $logPath
					Log-Message "Domain joining successful." "Success"
				} catch {
					Log-Message "Domain joining failed, confirm credentials and domain address are correct." "Error"
					Log-Message "Retry segment? (y/N):" "Prompt"
					$DNRetry = Read-Host
				}
			}
		}
	}
	if (-not ($Domain.ToLower() -eq "y" -or $Domain.ToLower() -eq "yes")) {
		Log-Message "Would you like to launch the EntraID joining dialog? (y/N):" "Prompt"
		$Entra = Read-Host
		if ($Entra.ToLower() -eq "y" -or $Entra.ToLower() -eq "yes") {
			if ($IsPro -eq 0) {
				Log-Message "The system is running '$WindowsEdition', which is not EntraID joinable."
			} else {
				Log-Message "Launching EntraID dialog..." "Info"
				dsregcmd.exe /join *>&1 | Out-File -Append -FilePath $logPath
				if ($LASTEXITCODE -ne 0) {
					Log-Message "Failed to launch EntraID dialog, ensure the device is not joined to a domain and is Windows 10/11 Pro" "Error"
				}
			}
		}
	}
}