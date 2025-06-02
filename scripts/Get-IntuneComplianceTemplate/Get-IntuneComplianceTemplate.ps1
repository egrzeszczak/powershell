<#
.SYNOPSIS
    [Provide a brief summary of what the script or function does.]

.DESCRIPTION
    This script was designed for use in Device Compliance in Microsoft Intune.
    [Give a detailed description of the script's purpose, functionality, and any important implementation details.
    Explain how the script works, its main features, and any assumptions or requirements.]

.EXAMPLE
    This script was designed for use in Device Compliance in Microsoft Intune.

.NOTES
    Author:         [Your Name]
    Created:        [Creation Date]
    Version:        [Script Version]
    Dependencies:   [List any required modules or dependencies]
    Compatibility:  [Supported PowerShell versions or platforms]

.LINK
    [Optional: Link to related documentation or resources]
#>

##  Script logic below

$ComputerColor = "Blue"

##  Output for Microsoft Intune

# Prepare the result as a hashtable. If no unencrypted drives are found, set value to "None".
$Result = @{
    ComputerColor = $ComputerColor
}

# Return the result as a compressed JSON string for Intune compliance reporting
return $Result | ConvertTo-Json -Compress