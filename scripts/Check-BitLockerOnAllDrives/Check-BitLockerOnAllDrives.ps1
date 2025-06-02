<#
.SYNOPSIS
    Script checks if device has all drives encrypted with BitLocker.

.DESCRIPTION
    This script was designed for use in Device Compliance in Microsoft Intune.
    The policy that the script checks compliance for is "All drives SHOULD be encrypted with BitLocker".

.EXAMPLE
    This script was designed for use in Device Compliance in Microsoft Intune.

.NOTES
    Author:         egrzeszczak
    Created:        2025-05-25
    Version:        v1.0.0
    Dependencies:   none
    Compatibility:  >5.0

.LINK
    [Optional: Link to related documentation or resources]
#>


# Initialize an array to store any drives that are not encrypted with BitLocker
$DetectedUnencryptedDrives = @()

# Retrieve all BitLocker volumes and select all their properties
$Drives = Get-BitLockerVolume | Select-Object *

# Iterate through each drive to check its BitLocker protection status
foreach ($Drive in $Drives) {
    # If the drive is not protected (ProtectionStatus is not 'On'), add its info to the array
    if ($Drive.ProtectionStatus -ne 'On') {
        # Format the drive information as "MountPoint\VolumeLabel"
        $DriveInfo = "{0}\{1}" -f $Drive.MountPoint, $Drive.VolumeLabel
        $DetectedUnencryptedDrives += $DriveInfo
    }
}

## Output

# Prepare the result as a hashtable. If no unencrypted drives are found, set value to "None".
$Result = @{
    DetectedUnencryptedDrives = if ($DetectedUnencryptedDrives.Count -eq 0) { "None" } else { $DetectedUnencryptedDrives -join ', ' }
}

# Return the result as a compressed JSON string for Intune compliance reporting
return $Result | ConvertTo-Json -Compress