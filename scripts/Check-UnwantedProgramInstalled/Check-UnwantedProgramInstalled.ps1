<#
.SYNOPSIS
    Script checks if an unwanted program is installed.

.DESCRIPTION
    This script was designed for use in Device Compliance in Microsoft Intune.
    Script checks, if device has Windows ADK installed. As an example let's assume it shouldn't be installed.

.EXAMPLE
    This script was designed for use in Device Compliance in Microsoft Intune.

.NOTES
    Author:         egrzeszczak
    Created:        2025-06-01
    Version:        v1.0.0
    Dependencies:   none
    Compatibility:  >5.0

.LINK
    https://learn.microsoft.com/en-us/intune/intune-service/protect/device-compliance-get-started
#>

# Check if Windows ADK is installed using Get-Package
$WindowsAdkPackage = Get-Package -Name "Windows Assessment and Deployment Kit*" -ErrorAction SilentlyContinue | Select-Object Name, Version

if ($WindowsAdkPackage) {
    $WindowsAdkInstalled = $true
    $WindowsAdkVersion = $WindowsAdkPackage.Version
} else {
    $WindowsAdkInstalled = $false
    $WindowsAdkVersion = $null
}

##  Output

# Prepare the result as a hashtable. 
$Result = @{ WindowsADKInstalled = $WindowsAdkInstalled; WindowsADKVersion = $WindowsAdkVersion }

# Return the result as a compressed JSON string for Intune compliance reporting
return $Result | ConvertTo-Json -Compress