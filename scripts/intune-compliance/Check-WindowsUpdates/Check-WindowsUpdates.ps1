<#
.SYNOPSIS
    Check for Windows Update anomalies (old updates, service not running)

.DESCRIPTION
    This script was designed for use in Device Compliance in Microsoft Intune.
    Check for Windows Update anomalies:
        - Old updates
        - WU Source (WSUS or Intune) (WIP)
        - Errors in WinEvtLog (WIP)

.EXAMPLE
    This script was designed for use in Device Compliance in Microsoft Intune.

.NOTES
    Author:         egrzeszczak
    Created:        2025-06-12
    Version:        v1.0.0
    Dependencies:   none
    Compatibility:  >=5.0

.LINK
    https://support.microsoft.com/en-us/windows/install-windows-updates-3c5ae7fc-9fb6-9af1-1984-b5e0412c556a
#>

##  Script logic below

$LatestUpdate = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1 -Property HotFixID,Description,InstalledOn

# $WindowsUpdateService = Get-Service -Name wuauserv | Select-Object *

# Update Source (WSUS or Intune): Registry: HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\WUServer.

##  Output for Microsoft Intune

# Prepare the result as a hashtable. If no unencrypted drives are found, set value to "None".
$Result = @{
    LatestHotFixID = $LatestUpdate.HotFixID;
    LatestHotFixTimestamp = [int][double]::Parse((Get-Date $LatestUpdate.InstalledOn -UFormat %s));
    LatestHotFixViolation = ((Get-Date) - (Get-Date $LatestUpdate.InstalledOn)).Days -gt 21
    LatestHotFixDescription = $LatestUpdate.Description;
    # WindowsUpdateRunning = if ($WindowsUpdateService.Status -eq 'Running') { $true } else { $false }
}

# Return the result as a compressed JSON string for Intune compliance reporting
return $Result | ConvertTo-Json -Compress