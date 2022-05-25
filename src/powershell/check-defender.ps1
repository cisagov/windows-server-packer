# Ensure that Windows Defender has been uninstalled
Write-Output "[ ] Checking if Windows Defender is running"
Get-Service -Name WinDefend -ErrorVariable err -ErrorAction SilentlyContinue
if (!$err) {
    Write-Error "[X] Failed to uninstall Windows Defender" -ErrorAction Stop
}
Write-Output "[*] Windows Defender successfully uninstalled"
