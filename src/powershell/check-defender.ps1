# Ensure that Windows Defender has been uninstalled
Write-Output "[ ] Checking if Windows Defender is running"
Get-Service -Name WinDefend -ErrorVariable err -ErrorAction SilentlyContinue

if ($err.length -eq 0) {
    Write-Error "[X] Failed to uninstall Windows Defender" -ErrorAction Stop
    exit 1
}

# Check for expected error
$expectedId = "NoServiceFoundForGivenName,Microsoft.PowerShell.Commands.GetServiceCommand"
$record = $err[0]
if ($record.FullyQualifiedErrorId -eq $expectedId)
{
    Write-Output "[*] Windows Defender successfully uninstalled"
    exit 0
}

# Print output of unexpected error
Write-Output "[ ] An unexpected error occurred"
Write-Output $record
exit 1
