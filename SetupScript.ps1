# PC Setup and Config Script - Tyler Hatfield - v2.0

# Build ordered list of active setup modules
$selectedModules = @()
if ($Run_TimeZone) { $selectedModules += [pscustomobject]@{ Name = "Time Zone"; Script = "TimeZone.ps1" } }
if ($Run_LocalAccounts) { $selectedModules += [pscustomobject]@{ Name = "Local Accounts"; Script = "Accounts.ps1" } }
if ($Run_SystemProperties) { $selectedModules += [pscustomobject]@{ Name = "System Properties"; Script = "SystemManagement.ps1" } }
if ($Run_SetupOptions) { $selectedModules += [pscustomobject]@{ Name = "Setup Options"; Script = "FinalOptions.ps1" } }
if ($Run_BloatCleanup) { $selectedModules += [pscustomobject]@{ Name = "Bloat Cleanup"; Script = "BloatCleanup.ps1" } }
if ($Run_Programs) { $selectedModules += [pscustomobject]@{ Name = "Programs"; Script = "Programs.ps1" } }

$global:HMTSetupTotalSteps = $selectedModules.Count
$global:HMTSetupCurrentStepIndex = 0

for ($i = 0; $i -lt $selectedModules.Count; $i++) {
    $global:HMTSetupCurrentStepIndex = $i + 1
    $mod = $selectedModules[$i]
    $global:HMTSetupStepName = $mod.Name

    Log-Message "Starting $($mod.Name) module (Step $($global:HMTSetupCurrentStepIndex) of $($global:HMTSetupTotalSteps))..." "Info"
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $mod.Script
    if (Test-Path $scriptPath) {
        . "$scriptPath"
    }
}

if ($global:RunUserExitOnComplete -eq $true) {
    Log-Message "Auto-exit enabled by Programs module. Closing and cleaning up..." "Info"
    User-Exit
}