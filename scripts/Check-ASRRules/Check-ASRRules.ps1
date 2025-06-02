<#
.SYNOPSIS
    Script returns current setting status for each ASR rule (Microsoft Defender for Endpoint)

.DESCRIPTION
    This script was designed for use in Device Compliance in Microsoft Intune.
    Checks the settings of each ASR Rule on the device against the compliance settings in 
    corresponding JSON file.

.EXAMPLE
    This script was designed for use in Device Compliance in Microsoft Intune.

.NOTES
    Author:         egrzeszczak
    Created:        2025-06-02
    Version:        v1.0.1
    Dependencies:   none
    Compatibility:  >=5.0

.LINK
    https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-rules-reference
#>

##  Join-Object Function
function AddItemProperties($item, $properties, $output)
{
    if($item -ne $null)
    {
        foreach($property in $properties)
        {
            $propertyHash =$property -as [hashtable]
            if($propertyHash -ne $null)
            {
                $hashName=$propertyHash["name"] -as [string]
                if($hashName -eq $null)
                {
                    throw "there should be a string Name" 
                }
        
                $expression=$propertyHash["expression"] -as [scriptblock]
                if($expression -eq $null)
                {
                    throw "there should be a ScriptBlock Expression" 
                }
        
                $_=$item
                $expressionValue=& $expression
        
                $output | add-member -MemberType "NoteProperty" -Name $hashName -Value $expressionValue -Force
            }
            else
            {
                # .psobject.Properties allows you to list the properties of any object, also known as "reflection"
                foreach($itemProperty in $item.psobject.Properties)
                {
                    if ($itemProperty.Name -like $property)
                    {
                        $output | add-member -MemberType "NoteProperty" -Name $itemProperty.Name -Value $itemProperty.Value -Force
                    }
                }
            }
        }
    }
}

   
function WriteJoinObjectOutput($leftItem, $rightItem, $leftProperties, $rightProperties, $Type)
{
    $output = new-object psobject

    if($Type -eq "AllInRight")
    {
        # This mix of rightItem with LeftProperties and vice versa is due to
        # the switch of Left and Right arguments for AllInRight
        AddItemProperties $rightItem $leftProperties $output
        AddItemProperties $leftItem $rightProperties $output
    }
    else
    {
        AddItemProperties $leftItem $leftProperties $output
        AddItemProperties $rightItem $rightProperties $output
    }
    $output
}

##  Joins two lists of objects
function Join-Object
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # List to join with $Right
        [Parameter(Mandatory=$true,
                   Position=0)]
        [object[]]
        $Left,

        # List to join with $Left
        [Parameter(Mandatory=$true,
                   Position=1)]
        [object[]]
        $Right,

        # Condition in which an item in the left matches an item in the right
        # typically something like: {$args[0].Id -eq $args[1].Id}
        [Parameter(Mandatory=$true,
                   Position=2)]
        [scriptblock]
        $Where,

        # Properties from $Left we want in the output.
        # Each property can:
        # – Be a plain property name like "Name"
        # – Contain wildcards like "*"
        # – Be a hashtable like @{Name="Product Name";Expression={$_.Name}}. Name is the output property name
        #   and Expression is the property value. The same syntax is available in select-object and it is
        #   important for join-object because joined lists could have a property with the same name
        [Parameter(Mandatory=$true,
                   Position=3)]
        [object[]]
        $LeftProperties,

        # Properties from $Right we want in the output.
        # Like LeftProperties, each can be a plain name, wildcard or hashtable. See the LeftProperties comments.
        [Parameter(Mandatory=$true,
                   Position=4)]
        [object[]]
        $RightProperties,

        # Type of join.
        #   AllInLeft will have all elements from Left at least once in the output, and might appear more than once
        # if the where clause is true for more than one element in right, Left elements with matches in Right are
        # preceded by elements with no matches. This is equivalent to an outer left join (or simply left join)
        # SQL statement.
        #  AllInRight is similar to AllInLeft.
        #  OnlyIfInBoth will cause all elements from Left to be placed in the output, only if there is at least one
        # match in Right. This is equivalent to a SQL inner join (or simply join) statement.
        #  AllInBoth will have all entries in right and left in the output. Specifically, it will have all entries
        # in right with at least one match in left, followed by all entries in Right with no matches in left,
        # followed by all entries in Left with no matches in Right.This is equivallent to a SQL full join.
        [Parameter(Mandatory=$false,
                   Position=5)]
        [ValidateSet("AllInLeft","OnlyIfInBoth","AllInBoth", "AllInRight")]
        [string]
        $Type="OnlyIfInBoth"
    )

    Begin
    {
        # a list of the matches in right for each object in left
        $leftMatchesInRight = new-object System.Collections.ArrayList

        # the count for all matches 
        $rightMatchesCount = New-Object "object[]" $Right.Count

        for($i=0;$i -lt $Right.Count;$i++)
        {
            $rightMatchesCount[$i]=0
        }
    }

    Process
    {
        if($Type -eq "AllInRight")
        {
            # for AllInRight we just switch Left and Right
            $aux = $Left
            $Left = $Right
            $Right = $aux
        }

        # go over items in $Left and produce the list of matches
        foreach($leftItem in $Left)
        {
            $leftItemMatchesInRight = new-object System.Collections.ArrayList
            $null = $leftMatchesInRight.Add($leftItemMatchesInRight)

            for($i=0; $i -lt $right.Count;$i++)
            {
                $rightItem=$right[$i]

                if($Type -eq "AllInRight")
                {
                    # For AllInRight, we want $args[0] to refer to the left and $args[1] to refer to right,
                    # but since we switched left and right, we have to switch the where arguments
                    $whereLeft = $rightItem
                    $whereRight = $leftItem
                }
                else
                {
                    $whereLeft = $leftItem
                    $whereRight = $rightItem
                }

                if(Invoke-Command -ScriptBlock $where -ArgumentList $whereLeft,$whereRight)
                {
                    $null = $leftItemMatchesInRight.Add($rightItem)
                    $rightMatchesCount[$i]++
                }
           
            }
        }

        # go over the list of matches and produce output
        for($i=0; $i -lt $left.Count;$i++)
        {
            $leftItemMatchesInRight=$leftMatchesInRight[$i]
            $leftItem=$left[$i]
                              
            if($leftItemMatchesInRight.Count -eq 0)
            {
                if($Type -ne "OnlyIfInBoth")
                {
                    WriteJoinObjectOutput $leftItem  $null  $LeftProperties  $RightProperties $Type
                }

                continue
            }

            foreach($leftItemMatchInRight in $leftItemMatchesInRight)
            {
                WriteJoinObjectOutput $leftItem $leftItemMatchInRight  $LeftProperties  $RightProperties $Type
            }
        }
    }

    End
    {
        #produce final output for members of right with no matches for the AllInBoth option
        if($Type -eq "AllInBoth")
        {
            for($i=0; $i -lt $right.Count;$i++)
            {
                $rightMatchCount=$rightMatchesCount[$i]
                if($rightMatchCount -eq 0)
                {
                    $rightItem=$Right[$i]
                    WriteJoinObjectOutput $null $rightItem $LeftProperties $RightProperties $Type
                }
            }
        }
    }
}

##  (Get-MpPreference) Resolve-ASRRulesAction zwróci status o typie String 'Audit' albo 'Block' na podstawie argumentu Uint8
function Resolve-ASRRulesAction {
##  '1' oznacza że reguła jest w trybie blokowania
##  '2' oznacza że reguła jest w trybie audytowania

    param (
        [uint32]$ActionID
    )
    
    $actionMap = @{
        0  = 'Off'
        1  = 'Block'
        2  = 'Audit'
    }

    $key = [int]$ActionID
    if ($actionMap.ContainsKey($key)) {
        return "$($actionMap[$key])"
    } else {
        return "N/A"
    }
}

##  (Get-MpPreference) Resolve-ASRRuleName zwróci nazwę reguły o typie String na podstawie argumentu String
function Resolve-ASRRuleName {
# https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-rules-reference

# 56a863a9-875e-4185-98a7-b882c64b5ce5 Block abuse of exploited vulnerable signed drivers                                                  
# 7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c Block Adobe Reader from creating child processes                                                    
# d4f940ab-401b-4efc-aadc-ad5f3c50688a Block all Office applications from creating child processes                                         
# 9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2 Block credential stealing from the Windows local security authority subsystem (lsass.exe)           
# be9ba2d9-53ea-4cdc-84e5-9b1eeee46550 Block executable content from email client and webmail                                              
# 01443614-cd74-433a-b99e-2ecdc07bfc25 Block executable files from running unless they meet a prevalence, age, or trusted list criterion   
# 5beb7efe-fd9a-4556-801d-275e5ffc04cc Block execution of potentially obfuscated scripts                                                   
# d3e037e1-3eb8-44c8-a917-57927947596d Block JavaScript or VBScript from launching downloaded executable content                           
# 3b576869-a4ec-4529-8536-b80a7769e899 Block Office applications from creating executable content                                          
# 75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84 Block Office applications from injecting code into other processes                                  
# 26190899-1602-49e8-8b27-eb1d0a1ce869 Block Office communication application from creating child processes                                
# e6db77e5-3df2-4cf1-b95a-636979351e5b Block persistence through WMI event subscription (*File and folder exclusions not supported.)       
# d1e49aac-8f56-4280-b9ba-993a6d77406c Block process creations originating from PSExec and WMI commands                                    
# 33ddedf1-c6e0-47cb-833e-de6133960387 Block rebooting machine in Safe Mode                                                                
# b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4 Block untrusted and unsigned processes that run from USB                                            
# c0033c00-d16d-4114-a5a0-dc9b3a7d2ceb Block use of copied or impersonated system tools                                                    
# a8f5898e-1dc8-49a9-9878-85004b8a61e6 Block Webshell creation for Servers                                                                 
# 92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b Block Win32 API calls from Office macros                                                            
# c1db55ab-c21a-4637-bb3f-a12568109d35 Use advanced protection against ransomware                                                          

    param (
        [string]$RuleID
    )

    $ruleMap = @{
        '56a863a9-875e-4185-98a7-b882c64b5ce5' = "Block abuse of exploited vulnerable signed drivers"
        '7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c' = "Block Adobe Reader from creating child processes"
        'd4f940ab-401b-4efc-aadc-ad5f3c50688a' = "Block all Office applications from creating child processes"
        '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2' = "Block credential stealing from the Windows local security authority subsystem"
        'be9ba2d9-53ea-4cdc-84e5-9b1eeee46550' = "Block executable content from email client and webmail"
        '01443614-cd74-433a-b99e-2ecdc07bfc25' = "Block executable files from running unless they meet a prevalence, age, or trusted list criterion"
        '5beb7efe-fd9a-4556-801d-275e5ffc04cc' = "Block execution of potentially obfuscated scripts"
        'd3e037e1-3eb8-44c8-a917-57927947596d' = "Block JavaScript or VBScript from launching downloaded executable content"
        '3b576869-a4ec-4529-8536-b80a7769e899' = "Block Office applications from creating executable content"
        '75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84' = "Block Office applications from injecting code into other processes"
        '26190899-1602-49e8-8b27-eb1d0a1ce869' = "Block Office communication application from creating child processes"
        'e6db77e5-3df2-4cf1-b95a-636979351e5b' = "Block persistence through WMI event subscription"
        'd1e49aac-8f56-4280-b9ba-993a6d77406c' = "Block process creations originating from PSExec and WMI commands"
        '33ddedf1-c6e0-47cb-833e-de6133960387' = "Block rebooting machine in Safe Mode"
        'b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4' = "Block untrusted and unsigned processes that run from USB"
        'c0033c00-d16d-4114-a5a0-dc9b3a7d2ceb' = "Block use of copied or impersonated system tools"
        'a8f5898e-1dc8-49a9-9878-85004b8a61e6' = "Block Webshell creation for Servers"
        '92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b' = "Block Win32 API calls from Office macros"
        'c1db55ab-c21a-4637-bb3f-a12568109d35' = "Use advanced protection against ransomware"
    }

    # Check if the provided RuleID exists in the mapping
    if ($ruleMap.ContainsKey($RuleID)) {
        return $ruleMap[$RuleID]
    } else {
        return "N/A"
    }
}

##  (Get-MpPreference) Resolve-ASRRuleAdvancedHuntingActionType zwróci nazwę techniczną reguły o typie String na podstawie argumentu String
function Resolve-ASRRuleAdvancedHuntingActionType {
# https://learn.microsoft.com/en-us/defender-endpoint/attack-surface-reduction-rules-reference

# 56a863a9-875e-4185-98a7-b882c64b5ce5 Block abuse of exploited vulnerable signed drivers                                                  AsrVulnerableSignedDriver
# 7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c Block Adobe Reader from creating child processes                                                    AsrAdobeReaderChildProcess
# d4f940ab-401b-4efc-aadc-ad5f3c50688a Block all Office applications from creating child processes                                         AsrOfficeChildProcess
# 9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2 Block credential stealing from the Windows local security authority subsystem (lsass.exe)           AsrLsassCredentialTheft
# be9ba2d9-53ea-4cdc-84e5-9b1eeee46550 Block executable content from email client and webmail                                              AsrExecutableEmailContent
# 01443614-cd74-433a-b99e-2ecdc07bfc25 Block executable files from running unless they meet a prevalence, age, or trusted list criterion   AsrUntrustedExecutable
# 5beb7efe-fd9a-4556-801d-275e5ffc04cc Block execution of potentially obfuscated scripts                                                   AsrObfuscatedScript
# d3e037e1-3eb8-44c8-a917-57927947596d Block JavaScript or VBScript from launching downloaded executable content                           AsrScriptExecutableDownload
# 3b576869-a4ec-4529-8536-b80a7769e899 Block Office applications from creating executable content                                          AsrExecutableOfficeContent
# 75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84 Block Office applications from injecting code into other processes                                  AsrOfficeProcessInjection
# 26190899-1602-49e8-8b27-eb1d0a1ce869 Block Office communication application from creating child processes                                AsrOfficeCommAppChildProcess
# e6db77e5-3df2-4cf1-b95a-636979351e5b Block persistence through WMI event subscription (*File and folder exclusions not supported.)       AsrPersistenceThroughWmi
# d1e49aac-8f56-4280-b9ba-993a6d77406c Block process creations originating from PSExec and WMI commands                                    AsrPsexecWmiChildProcess
# 33ddedf1-c6e0-47cb-833e-de6133960387 Block rebooting machine in Safe Mode                                                                AsrSafeModeReboot
# b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4 Block untrusted and unsigned processes that run from USB                                            AsrUntrustedUsbProcess
# c0033c00-d16d-4114-a5a0-dc9b3a7d2ceb Block use of copied or impersonated system tools                                                    AsrAbusedSystemTool
# a8f5898e-1dc8-49a9-9878-85004b8a61e6 Block Webshell creation for Servers                                                                 AsrServerWebshellCreation (generated since Microsoft didn't have one)
# 92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b Block Win32 API calls from Office macros                                                            AsrOfficeMacroWin32ApiCalls
# c1db55ab-c21a-4637-bb3f-a12568109d35 Use advanced protection against ransomware                                                          AsrRansomware

    param (
        [string]$RuleID
    )

    $ruleMap = @{
        '56a863a9-875e-4185-98a7-b882c64b5ce5' = "AsrVulnerableSignedDriver"
        '7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c' = "AsrAdobeReaderChildProcess"
        'd4f940ab-401b-4efc-aadc-ad5f3c50688a' = "AsrOfficeChildProcess"
        '9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2' = "AsrLsassCredentialTheft"
        'be9ba2d9-53ea-4cdc-84e5-9b1eeee46550' = "AsrExecutableEmailContent"
        '01443614-cd74-433a-b99e-2ecdc07bfc25' = "AsrUntrustedExecutable"
        '5beb7efe-fd9a-4556-801d-275e5ffc04cc' = "AsrObfuscatedScript"
        'd3e037e1-3eb8-44c8-a917-57927947596d' = "AsrScriptExecutableDownload"
        '3b576869-a4ec-4529-8536-b80a7769e899' = "AsrExecutableOfficeContent"
        '75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84' = "AsrOfficeProcessInjection"
        '26190899-1602-49e8-8b27-eb1d0a1ce869' = "AsrOfficeCommAppChildProcess"
        'e6db77e5-3df2-4cf1-b95a-636979351e5b' = "AsrPersistenceThroughWmi"
        'd1e49aac-8f56-4280-b9ba-993a6d77406c' = "AsrPsexecWmiChildProcess"
        '33ddedf1-c6e0-47cb-833e-de6133960387' = "AsrSafeModeReboot"
        'b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4' = "AsrUntrustedUsbProcess"
        'c0033c00-d16d-4114-a5a0-dc9b3a7d2ceb' = "AsrAbusedSystemTool"
        'a8f5898e-1dc8-49a9-9878-85004b8a61e6' = "AsrServerWebshellCreation"
        '92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b' = "AsrOfficeMacroWin32ApiCalls"
        'c1db55ab-c21a-4637-bb3f-a12568109d35' = "AsrRansomware"
    }

    # Check if the provided RuleID exists in the mapping
    if ($ruleMap.ContainsKey($RuleID)) {
        return $ruleMap[$RuleID]
    } else {
        return "N/A"
    }
}

##  -----------------------------------------------------------------------------------------------------

$MpPreference = Get-MpPreference
$ASROnlyExclusions = $MpPreference.AttackSurfaceReductionOnlyExclusions
$ASRRulesActions = $MpPreference.AttackSurfaceReductionRules_Actions
$ASRRulesIds = $MpPreference.AttackSurfaceReductionRules_Ids
$ASRRulesRuleSpecificExclusions = $MpPreference.AttackSurfaceReductionRules_RuleSpecificExclusions
$ASRRulesRuleSpecificExclusionsId = $MpPreference.AttackSurfaceReductionRules_RuleSpecificExclusions_Id


# ASRRulesIds into a Map
$ASRRulesIdsSplit = $ASRRulesIds -split ' '
$ASRRuleMap = @{}
for ($i = 0; $i -lt $ASRRulesIdsSplit.Length; $i++) {
    $ASRRuleMap[$i + 1] = $ASRRulesIdsSplit[$i].ToLower()
}

# ASRRulesActions into a Map
$ASRRulesActionsSplit = $ASRRulesActions -split ' '
$ASRRulesActionsMap = @{}
for ($i = 0; $i -lt $ASRRulesActionsSplit.Length; $i++) {
    $ASRRulesActionsMap[$i + 1] = $ASRRulesActionsSplit[$i]
}

# ASRRulesRuleSpecificExclusionsId into a Map
$ASRRulesRuleSpecificExclusionsIdSplit = $ASRRulesRuleSpecificExclusionsId -split ' '
$ASRRulesRuleSpecificExclusionsIdMap = @{}
for ($i = 0; $i -lt $ASRRulesRuleSpecificExclusionsIdSplit.Length; $i++) {
    $ASRRulesRuleSpecificExclusionsIdMap[$i + 1] = $ASRRulesRuleSpecificExclusionsIdSplit[$i].ToLower()
}

# ASRRulesRuleSpecificExclusions into a Map, but the order should be based on the UUID of the ASRRulesIds position
$ASRRulesRuleSpecificExclusionsSplit = $ASRRulesRuleSpecificExclusions -split ' '
$ASRRulesRuleSpecificExclusionsMap = @{}
for ($i = 0; $i -lt $ASRRulesRuleSpecificExclusionsSplit.Length; $i++) {
    $ASRRulesRuleSpecificExclusionsMap[$i + 1] = $ASRRulesRuleSpecificExclusionsSplit[$i]
}

# Convert maps to arrays of [pscustomobject] with index
$LeftArray = $ASRRulesRuleSpecificExclusionsIdMap.GetEnumerator() | ForEach-Object {
    [pscustomobject]@{ Index = $_.Key; Key = $_.Value }
}
$RightArray = $ASRRulesRuleSpecificExclusionsMap.GetEnumerator() | ForEach-Object {
    [pscustomobject]@{ Index = $_.Key; Value = $_.Value }
}

# Join on matching index
$ASRRuleExlusions = Join-Object `
    -Left $LeftArray `
    -Right $RightArray `
    -Where { $args[0].Index -eq $args[1].Index } `
    -LeftProperties * `
    -RightProperties * `
    -Type "OnlyIfInBoth"

# Merging the data into a single variable $ASRRules
$ASRRules = @()

# Iterate over the ASRRuleMap (assuming it has been defined and contains UUIDs and Order)
foreach ($rule in $ASRRuleMap.GetEnumerator()) {
    $order = $rule.Key
    $uuid = $rule.Value
    $name = Resolve-ASRRuleName -RuleID $uuid
    $advhunname = Resolve-ASRRuleAdvancedHuntingActionType -RuleID $uuid

    # Get the Action for the corresponding RuleID from ASRRulesActionsMap
    $action = Resolve-ASRRulesAction -ActionID $ASRRulesActionsMap[$order]

    # Get the Exclusions from ASRRulesRuleSpecificExclusionsMap for the corresponding RuleID
    $exclusions1 = $ASRRuleExlusions | Where-Object { $_.Key -eq $uuid }
    $exclusions = $exclusions1.Value -split '\|'

    # Create the ASR rule object and add it to $ASRRules array
    $ASRRules += [PSCustomObject]@{
        Order            = $order
        GUID             = $uuid
        FriendlyName     = $name
        Name             = $advhunname
        Action           = $action
        Exclusions       = $exclusions
    }
}

##  Output for Microsoft Intune

# Prepare the result as a hashtable. If no unencrypted drives are found, set value to "None".
$Result = @{
    AsrVulnerableSignedDriver =     ($ASRRules | Where-Object { $_.Name -eq "AsrVulnerableSignedDriver" }).Action;
    AsrAdobeReaderChildProcess =    ($ASRRules | Where-Object { $_.Name -eq "AsrAdobeReaderChildProcess" }).Action;
    AsrOfficeChildProcess =         ($ASRRules | Where-Object { $_.Name -eq "AsrOfficeChildProcess" }).Action;
    AsrLsassCredentialTheft =       ($ASRRules | Where-Object { $_.Name -eq "AsrLsassCredentialTheft" }).Action;
    AsrExecutableEmailContent =     ($ASRRules | Where-Object { $_.Name -eq "AsrExecutableEmailContent" }).Action;
    AsrUntrustedExecutable =        ($ASRRules | Where-Object { $_.Name -eq "AsrUntrustedExecutable" }).Action;
    AsrObfuscatedScript =           ($ASRRules | Where-Object { $_.Name -eq "AsrObfuscatedScript" }).Action;
    AsrScriptExecutableDownload =   ($ASRRules | Where-Object { $_.Name -eq "AsrScriptExecutableDownload" }).Action;
    AsrExecutableOfficeContent =    ($ASRRules | Where-Object { $_.Name -eq "AsrExecutableOfficeContent" }).Action;
    AsrOfficeProcessInjection =     ($ASRRules | Where-Object { $_.Name -eq "AsrOfficeProcessInjection" }).Action;
    AsrOfficeCommAppChildProcess =  ($ASRRules | Where-Object { $_.Name -eq "AsrOfficeCommAppChildProcess" }).Action;
    AsrPersistenceThroughWmi =      ($ASRRules | Where-Object { $_.Name -eq "AsrPersistenceThroughWmi" }).Action;
    AsrPsexecWmiChildProcess =      ($ASRRules | Where-Object { $_.Name -eq "AsrPsexecWmiChildProcess" }).Action;
    AsrSafeModeReboot =             ($ASRRules | Where-Object { $_.Name -eq "AsrSafeModeReboot" }).Action;
    AsrUntrustedUsbProcess =        ($ASRRules | Where-Object { $_.Name -eq "AsrUntrustedUsbProcess" }).Action;
    AsrAbusedSystemTool =           ($ASRRules | Where-Object { $_.Name -eq "AsrAbusedSystemTool" }).Action;
    AsrServerWebshellCreation =     ($ASRRules | Where-Object { $_.Name -eq "AsrServerWebshellCreation" }).Action;
    AsrOfficeMacroWin32ApiCalls =   ($ASRRules | Where-Object { $_.Name -eq "AsrOfficeMacroWin32ApiCalls" }).Action;
    AsrRansomware =                 ($ASRRules | Where-Object { $_.Name -eq "AsrRansomware" }).Action;
}

# Return the result as a compressed JSON string for Intune compliance reporting
return $Result | ConvertTo-Json -Compress