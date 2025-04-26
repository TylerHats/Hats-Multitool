# Bloat Cleanup Module - Tyler Hatfield - v1

Log-Message "Would you like to remove common Windows bloat programs? (y/N):" "Prompt"
$RemoveBloat = Read-Host

# Windows App Package Cleanup
if ($RemoveBloat.ToLower() -eq "y" -or $RemoveBloat.ToLower() -eq "yes") {
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*bingfinance*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*bingnews*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*bingsports*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*gethelp*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*getstarted*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*mixedreality*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*people*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*solitaire*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*wallet*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*windowsfeedback*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*windowsmaps*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*xbox*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
	Get-AppxPackage -AllUsers -PackageTypeFilter Bundle -Name "*zunevideo*" | Remove-AppxPackage -AllUsers -Verbose 4>&1 | Out-File -Append -FilePath $logPath
} else {
	Log-Message "Skipping bloat removal." "Skip"
}

# Further cleanup (Ex. Services, programs, etc)
#WIP