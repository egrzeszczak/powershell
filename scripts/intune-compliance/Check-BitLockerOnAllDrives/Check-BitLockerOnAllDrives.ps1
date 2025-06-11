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
    https://learn.microsoft.com/en-us/intune/intune-service/protect/device-compliance-get-started
    https://support.microsoft.com/pl-pl/windows/szyfrowanie-dysk%C3%B3w-funkcj%C4%85-bitlocker-76b92ac9-1040-48d6-9f5f-d14b3c5fa178
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