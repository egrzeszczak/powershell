# powershell

A collection of my PowerShell scripts

## **Active Directory**
|Name|Description|
|-|-|
|[Generate-RandomUser](./scripts/active-directory/Generate-RandomUser)|Generates random user accounts in Active Directory.|
|[Update-DynamicGroup](./scripts/active-directory/Update-DynamicGroup)|Automates Active Directory group membership by adding/removing users based on a dynamic attribute filter, with detailed logging.|

## **Microsoft Intune (Compliance)**
|Name|Description|
|-|-|
|[Check-ASRRules](./scripts/intune-compliance/Check-ASRRules)|Script checks status of all ASR rules on device.|
|[Check-BitLockerOnAllDrives](./scripts/intune-compliance/Check-BitLockerOnAllDrives)|Script checks if device has all drives encrypted with BitLocker.|
|[Check-MicrosoftDefenderForEndpoint](./scripts/intune-compliance/Check-MicrosoftDefenderForEndpoint)|Script checks for basic Microsoft Defender for Endpoint configuration.|
|[Check-Template](./scripts/intune-compliance/Check-Template)|This template was designed for use in Device Compliance in Microsoft Intune.|
|[Check-UnwantedProgramInstalled](./scripts/intune-compliance/Check-UnwantedProgramInstalled)|Script checks if an unwanted program is installed.|

## **Windows Security**
|Name|Description|
|-|-|
|[Test-ASRObfuscatedScript](./scripts/Test-ASRObfuscatedScript)|This is a script that will test "Block execution of potentially obfuscated scripts" Attack Surface Reduction rule in Microsoft Defender for Endpoint.|

## **Miscellaneous**
|Name|Description|
|-|-|
|[New-Template](./scripts/miscellaneous/New-Template)|A ready-to-use template PowerShell for miscellaneous purposes.|