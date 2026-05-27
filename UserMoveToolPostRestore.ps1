#UserMoveToolPostRestore Script v1.0

Add-Type -AssemblyName System.Windows.Forms, System.Drawing

`$SettingsFile = "C:\Users\Public\System_Profile_Migration\PendingSettings.json"
if (-not (Test-Path `$SettingsFile)) { exit }

`$Pending = Get-Content `$SettingsFile -Raw | ConvertFrom-Json
`$StagedUsers = Get-ChildItem "C:\Users\Public\System_Profile_Migration\StagedFiles" -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name

`$MatchFound = `$false
`$MatchedOldUser = ""

foreach (`$oldUser in `$StagedUsers) {
    # Loose Auto-Matching (e.g. jsmith matches john.smith, or jsmith.DOMAIN)
    if (`$env:USERNAME -match `$oldUser -or `$oldUser -match `$env:USERNAME) {
        `$MatchFound = `$true
        `$MatchedOldUser = `$oldUser
        break
    }
}

if (`$MatchFound) {
    # 1. Spawn Mandatory Blocking Screen
    `$Blocker = New-Object System.Windows.Forms.Form
    `$Blocker.FormBorderStyle = 'None'
    `$Blocker.WindowState = 'Maximized'
    `$Blocker.TopMost = `$true
    `$Blocker.BackColor = [System.Drawing.Color]::Black
    `$Blocker.Cursor = [System.Windows.Forms.Cursors]::WaitCursor

    `$Label = New-Object System.Windows.Forms.Label
    `$Label.Text = "Finalizing User Profile Integration... Please wait."
    `$Label.ForeColor = [System.Drawing.Color]::White
    `$Label.Font = New-Object System.Drawing.Font("Segoe UI", 16)
    `$Label.AutoSize = `$false
    `$Label.Dock = 'Fill'
    `$Label.TextAlign = 'MiddleCenter'
    `$Blocker.Controls.Add(`$Label)

    `$Blocker.Show()
    [System.Windows.Forms.Application]::DoEvents()

    # 2. Run Robocopy to instantly move files into active profile
    `$Src = "C:\Users\Public\System_Profile_Migration\StagedFiles\`$MatchedOldUser"
    Start-Process cmd.exe -ArgumentList "/c robocopy `"`$Src`" `"`$env:USERPROFILE`" /E /MOVE /IS /IT" -WindowStyle Hidden -Wait

    # 3. Apply Registry Themes
    `$uSettings = `$Pending.`$MatchedOldUser
    if (`$uSettings.AppsUseLightTheme -ne `$null) { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name AppsUseLightTheme -Value `$uSettings.AppsUseLightTheme -ErrorAction SilentlyContinue }
    if (`$uSettings.SystemUsesLightTheme -ne `$null) { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name SystemUsesLightTheme -Value `$uSettings.SystemUsesLightTheme -ErrorAction SilentlyContinue }
    if (`$uSettings.TaskbarAl -ne `$null) { Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name TaskbarAl -Value `$uSettings.TaskbarAl -ErrorAction SilentlyContinue }

    # 4. Map Network Drives
    if (`$uSettings.MappedDrives) {
        foreach (`$drive in `$uSettings.MappedDrives) {
            Start-Process cmd.exe -ArgumentList "/c net use `$(`$drive.Drive): `"`$(`$drive.Path)`" /persistent:yes" -WindowStyle Hidden
        }
    }

    # Remove user from pending list and cleanup staging folder
    Remove-Item "C:\Users\Public\System_Profile_Migration\StagedFiles\`$MatchedOldUser" -Recurse -Force -ErrorAction SilentlyContinue

    # Update UI to notify forced sign out
    `$Label.Text = "Integration Complete.`nSigning out to apply deep system themes..."
    [System.Windows.Forms.Application]::DoEvents()
    Start-Sleep -Seconds 10

    # Force Logoff to cleanly reload cached HKCU settings
    Start-Process cmd.exe -ArgumentList "/c logoff" -WindowStyle Hidden
}

# Cleanup Agent if Empty
`$Remaining = Get-ChildItem "C:\Users\Public\System_Profile_Migration\StagedFiles" -Directory -ErrorAction SilentlyContinue
if (-not `$Remaining) {
    Remove-Item "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp\ProfileOOBE.lnk" -Force -ErrorAction SilentlyContinue
    Start-Process cmd.exe -ArgumentList "/c rmdir /s /q `"C:\Users\Public\System_Profile_Migration`"" -WindowStyle Hidden
}
