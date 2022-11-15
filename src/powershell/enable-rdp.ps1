Write-Output "[ ] Attempting to enable RDP service"

# Allow Terminal Server connections
$name = "fDenyTSConnections"
$path = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
Write-Output "[ ] Configuring setting: $name"
Set-ItemProperty -Path $path -Name $name -Value "0"
if ($(Get-ItemProperty -Path $path -Name $name).fDenyTSConnections -ne 0) {
    Write-Error "[X] Failed to verify setting: $name" -ErrorAction Stop
}
Write-Output "[*] Setting successfully verified: $name"

# Enable Terminal Server user authentication
$name = "UserAuthentication"
$path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
Write-Output "[ ] Configuring setting: $name"
Set-ItemProperty -Path $path -Name $name -Value "1"
if ($(Get-ItemProperty -Path $path -Name $name).UserAuthentication -ne 1) {
    Write-Error "[X] Failed to verify setting: $name" -ErrorAction Stop
}
Write-Output "[*] Setting successfully verified: $name"

# Allow Terminal Server connections through the Windows firewall
$name = "RemoteDesktop-In-TCP-WS"
Write-Output "[ ] Configuring firewall rule: $name"
Set-NetFirewallRule -Name $name -Enabled True
if ($(Get-NetFirewallRule -Name $name).Enabled -ne $true) {
    Write-Error "[X] Failed to verify firewall rule: $name" -ErrorAction Stop
}
Write-Output "[*] Firewall rule successfully verified: $name"

# Allow Terminal Server shadowing through the Windows firewall
$name = "Remote Desktop - Shadow (TCP-In)"
Write-Output "[ ] Configuring firewall rule: $name"
Set-NetFirewallRule -DisplayName $name -Enabled True -Profile Private
if ($(Get-NetFirewallRule -DisplayName $name).Enabled -ne $true) {
    Write-Error "[X] Failed to verify firewall rule: $name" -ErrorAction Stop
}
Write-Output "[*] Firewall rule successfully verified: $name"

# Enable Terminal Server shadowing
$name = "Shadow"
$path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
Write-Output "[ ] Configuring setting: $name"
Set-ItemProperty -Path $path -Name $name -Value "1"
if ($(Get-ItemProperty -Path $path -Name $name).Shadow -ne 1) {
    Write-Error "[X] Failed to verify setting: $name" -ErrorAction Stop
}
Write-Output "[*] Setting successfully verified: $name"

# Give the Administrators group full control of Terminal Server
Get-CimInstance -Namespace root\CIMV2\TerminalServices -ClassName Win32_TSPermissionsSetting -Filter 'TerminalName ="RDP-Tcp"' |
        Invoke-CimMethod -MethodName AddAccount -Arguments @{AccountName="BUILTIN\Administrators"; PermissionPreSet="2"}
