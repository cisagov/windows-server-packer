# check for existence windows defender
Write-Output "[ ] Checking if Windows Defender is running"
Get-Service -Name WinDefend -ErrorVariable err -ErrorAction SilentlyContinue
if ($err) {
    Write-Output "[ ] Windows Defender not found, skipping removal"
    exit 1
}
Write-Output "[*] Windows Defender found"

# uninstall windows defender service
Write-Output "[ ] Attempting to uninstall Windows Defender"
Uninstall-WindowsFeature -Name Windows-Defender -ErrorAction stop
Write-Output "[*] Successfully ran uninstall command"
Write-Output "[ ] Rebooting and then checking if uninstall was successful"
