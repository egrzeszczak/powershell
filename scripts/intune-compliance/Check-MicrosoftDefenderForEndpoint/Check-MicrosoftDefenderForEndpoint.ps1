<#
.SYNOPSIS
    Script checks for current Microsoft Defender for Endpoint settings (if the device is onboarded and has correct basic settings)

.DESCRIPTION
    This script was designed for use in Device Compliance in Microsoft Intune.
    Script checks for Microsoft Defender for Endpoint settings, such as:
        AntivirusEnabled
        AMServiceEnabled
        AMRunningMode
        AntispywareEnabled
        BehaviorMonitorEnabled
        OnAccessProtectionEnabled
        RealTimeProtectionEnabled
        EnableNetworkProtection
        IsTamperProtected
        DefenderStatusOnboardingState
        DefenderStatusOrgId - you need to enter your organization id in the .JSON file

.EXAMPLE
    This script was designed for use in Device Compliance in Microsoft Intune.

.NOTES
    Author:         egrzeszczak
    Created:        2025-06-10
    Version:        v1.0.0
    Dependencies:   none
    Compatibility:  >=5.0

.LINK
    https://support.microsoft.com/
    https://learn.microsoft.com/en-us/defender-endpoint/
    https://learn.microsoft.com/en-us/defender-endpoint/enable-network-protection
    https://learn.microsoft.com/en-us/defender-endpoint/configure-protection-features-microsoft-defender-antivirus
    https://learn.microsoft.com/en-us/defender-endpoint/device-health-microsoft-defender-antivirus-health#antivirus-mode-card
    https://learn.microsoft.com/en-us/defender-endpoint/prevent-changes-to-security-settings-with-tamper-protection
    https://learn.microsoft.com/en-us/defender-endpoint/switch-to-mde-phase-3
#>

##  Script logic below

# Get the status of Microsoft Defender
$MpComputerStatus = Get-MpComputerStatus
$MpPreference = Get-MpPreference

# Microsoft Defender for Endpoint
$DefenderStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status" -Name "OnboardingState" -ErrorAction SilentlyContinue
$DefenderStatusOnboardingState = if ($DefenderStatus) { $True } else { $False }
$DefenderStatus = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status" -Name "OrgId" -ErrorAction SilentlyContinue
$DefenderStatusOrgId = if ($DefenderStatus) { $DefenderStatus.OrgId } else { "N/A" }
# Antivirus
$AntivirusOn = $MpComputerStatus.AntivirusEnabled
# Antimalware
$AntimalwareOn = $MpComputerStatus.AMServiceEnabled
$AntimalwareMode = $MpComputerStatus.AMRunningMode
# Antispyware
$AntispywareOn = $MpComputerStatus.AntispywareEnabled
# Behavior Monitoring
$BehaviorMonitoring = $MpComputerStatus.BehaviorMonitorEnabled;
# On-access Protection
$OnAccessProtection = $MpComputerStatus.OnAccessProtectionEnabled;
# Real-time Protection
$RealtimeProtection = $MpComputerStatus.RealTimeProtectionEnabled;
# Network Protection
$NetworkProtection = $MpPreference.EnableNetworkProtection;
# Tamper Protection
$TamperProtection = $MpComputerStatus.IsTamperProtected;

##  Output for Microsoft Intune

# Prepare the result as a hashtable. If no unencrypted drives are found, set value to "None".
$Result = @{
    DeviceOnboarded = $DefenderStatusOnboardingState;
    DeviceOrganization = $DefenderStatusOrgId;
    AntivirusOn = $AntivirusOn;
    AntimalwareOn = $AntimalwareOn;
    AntimalwareMode = $AntimalwareMode;
    AntispywareOn = $AntispywareOn;
    BehaviorMonitoring = $BehaviorMonitoring;
    OnAccessProtection = $OnAccessProtection;
    RealtimeProtection = $RealtimeProtection;
    NetworkProtectionMode = switch ($NetworkProtection) {
        1 { "Block" }
        2 { "Audit" }
        Default { "Off" }
    };
    TamperProtection = $TamperProtection;
}

# Return the result as a compressed JSON string for Intune compliance reporting
return $Result | ConvertTo-Json -Compress