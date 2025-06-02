# powershell

A collection of my PowerShell scripts

## **Active Directory**
|Name|Description|
|-|-|
|[Generate-RandomUser](./scripts/Generate-RandomUser)|Generates random user accounts in Active Directory.|
|[Update-DynamicGroup](./scripts/Update-DynamicGroup)|Automates Active Directory group membership by adding/removing users based on a dynamic attribute filter, with detailed logging.|

## **Microsoft Intune (Compliance)**
|Name|Description|
|-|-|
|[Check-ASRRules](./scripts/Check-ASRRules)|Script checks status of all ASR rules on device.|
|[Check-BitLockerOnAllDrives](./scripts/Check-BitLockerOnAllDrives)|Script checks if device has all drives encrypted with BitLocker.|
|[Check-UnwantedProgramInstalled](./scripts/Check-UnwantedProgramInstalled)|Script checks if an unwanted program is installed.|

## **Security**
|Name|Description|
|-|-|
|[Test-ASRObfuscatedScript](./scripts/Test-ASRObfuscatedScript)|This is a script that will test "Block execution of potentially obfuscated scripts" Attack Surface Reduction rule in Microsoft Defender for Endpoint.|

## **Templates**
|Name|Description|
|-|-|
|[Get-IntuneComplianceTemplate](./scripts/Get-IntuneComplianceTemplate)|This template was designed for use in Device Compliance in Microsoft Intune.|
|[Get-Template](./scripts/Get-Template)|A ready-to-use template PowerShell for miscellaneous purposes.|