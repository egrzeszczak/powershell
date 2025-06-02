<#
.SYNOPSIS
    Automates Active Directory group membership by adding/removing users based on a dynamic attribute filter, with detailed logging.

.DESCRIPTION
    This script queries the Active Directory for users by a filter specified in the $UserFilter. Then based on he filter,
    the group provided in the $GroupName will have it's members updated accordingly.

.EXAMPLE
    This script is meant to be run as a scheduled task. Please consider risks of running the script in production environments 
    (such as running the script with admin/system privileges, or the fact that this script is unsigned and untrusted).

.NOTES
    Author:         egrzeszczak
    Created:        2025-05-01
    Version:        v1.0.1
    Dependencies:   Requires AD MSAT module for PS cmdlets like Get-ADGroup, Get-ADUser
    Compatibility:  >=5.0

.LINK
    https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-membership

#>

##  Configure: Define group name
$GroupName = "EGSGRP-PRD-Critical-Identity"

##  Configure: Define a dynamic filter
$UserFilter = {
    Title -like '*Director*'
}

##  Configure: Log file location (Log-Output)
$LogDir = "C:\Log\Update-DynamicGroupMembership"

##  -----------------------------------------------------------------------------------------------
##  Generate a random 8-character alphanumeric session ID and save to a global variable (for script execution logging purposes)
$global:ScriptSessionId = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_})
##  -----------------------------------------------------------------------------------------------

# Function outputs progress to stdout and to a file
function Log-Output {
    param (
        [Parameter(Mandatory)]
        [string]$Level,      # Log level (trace|debug|informational|notice|warning|error|critical|alert|emergency)
        [Parameter(Mandatory)]
        [string]$Message     # Log message
    )
    # Get the current timestamp in ISO 8601 / RFC 3339 format
    $timestamp = (Get-Date).ToString("o")

    # Get the current user running the script
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    # Compose the log line for both console and file output
    Write-Host "time=$timestamp level=`"$Level`" user=`"$currentUser`" session=`"$ScriptSessionId`" msg=`"$Message`""

    # Ensure the log directory exists; create it if it doesn't
    if (-not (Test-Path $LogDir)) {
        New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
    }

    # Build the log file path using the current date
    $logFile = Join-Path $LogDir ("script-{0}.log" -f (Get-Date).ToString("yyyy-MM-dd"))

    # Prepare the log entry line
    $logLine = "time=$timestamp level=`"$Level`" user=`"$currentUser`" session=`"$ScriptSessionId`" msg=`"$Message`""

    # Append the log entry to the log file
    Add-Content -Path $logFile -Value $logLine
}

# Function parses a ScriptBlock into a string (for logging purposes)
function Get-FilterString {
    param([ScriptBlock]$Filter)
    
    # Convert the scriptblock filter to a readable string for logging.
    $filterString = $Filter.Ast.Extent.Text
    
    # Replace newlines with a space
    $filterString = $filterString -replace "`r?`n", " "
    
    # Replace tabs with a space
    $filterString = $filterString -replace "`t", " "
    
    # Replace multiple spaces with a single space
    $filterString = $filterString -replace "\s+", " "
    
    # Trim leading/trailing spaces
    $filterString = $filterString.Trim()
    return $filterString
}

# Start script
Log-Output "notice" "Starting dynamic group $GroupName script execution."
Log-Output "informational" "Group name: $GroupName"
Log-Output "informational" "User filter: $(Get-FilterString $UserFilter)"

# Get AD group in Active Directory and select only the first one found.
Log-Output "informational" "Looking for group: $GroupName"
$Group = Get-ADGroup -Filter { Name -eq $GroupName } | Select-Object -First 1

# If group is not found, exit script
if (-not $Group) {
    Log-Output "error" "Group '$GroupName' not found."
    exit 1
} else {
    Log-Output "informational" "Found group: $($Group.DistinguishedName)"
}

# Get all users meeting the $UserFilter criteria:
Log-Output "informational" "Querying AD users for matching filter criteria."
$Users = Get-ADUser -Filter $UserFilter
Log-Output "informational" "Found $($Users.Count) users matching filter criteria."

# If there are no users found, means that the group should be empty
if($Users.Count -eq 0){

    Log-Output "warning" "No users match filter criteria."
    # Remove all current members from the group to empty it
    # Get current group members (user distinguished names)
    $CurrentMembers = Get-ADGroupMember -Identity $Group.DistinguishedName -Recursive | Where-Object { $_.objectClass -eq 'user' }
    $CurrentMemberDNs = $CurrentMembers | Select-Object -ExpandProperty DistinguishedName

    if ($CurrentMemberDNs -and $CurrentMemberDNs.Count -gt 0) {
        Remove-ADGroupMember -Identity $Group.DistinguishedName -Members $CurrentMemberDNs -Confirm:$false
        Log-Output "notice" "All users removed from group $GroupName."
    } else {
        Log-Output "informational" "Group $GroupName is already empty."
    }
    exit 0

} else {

    # Update group membership based on the filter criteria. 
    # Don't delete all users as a start. 
    # Add the differential users and then remove the differential users.

    # Get current group members (user distinguished names)
    Log-Output "informational" "Fetching current group members."
    $CurrentMembers = Get-ADGroupMember -Identity $Group.DistinguishedName -Recursive | Where-Object { $_.objectClass -eq 'user' }
    $CurrentMemberDNs = $CurrentMembers | Select-Object -ExpandProperty DistinguishedName
    Log-Output "informational" "Current group member count: $($CurrentMemberDNs.Count)"

    # Get new user DNs
    $NewUserDNs = $Users | Select-Object -ExpandProperty DistinguishedName
    Log-Output "informational" "User DNs to be in group: $($NewUserDNs.Count)"

    if (-not $CurrentMemberDNs -or $CurrentMemberDNs.Count -eq 0) {
        Log-Output "informational" "Group is empty. All matching users will be added."
        $ToAdd = $NewUserDNs
        $ToRemove = @()
    } else {
        $ToAdd = Compare-Object -ReferenceObject $CurrentMemberDNs -DifferenceObject $NewUserDNs -PassThru | Where-Object { $_ -in $NewUserDNs }
        $ToRemove = Compare-Object -ReferenceObject $CurrentMemberDNs -DifferenceObject $NewUserDNs -PassThru | Where-Object { $_ -in $CurrentMemberDNs }
        Log-Output "informational" "Users to add: $($ToAdd.Count)"
        Log-Output "informational" "Users to remove: $($ToRemove.Count)"
    }

    # Add users
    foreach ($UserDN in $ToAdd) {
        try {
            Add-ADGroupMember -Identity $Group.DistinguishedName -Members $UserDN
            Log-Output "informational" "Added: $UserDN"
        } catch {
            Log-Output "warning" "Failed to add $UserDN`: $_"
        }
    }

    # Remove users
    foreach ($UserDN in $ToRemove) {
        try {
            Remove-ADGroupMember -Identity $Group.DistinguishedName -Members $UserDN -Confirm:$false
            Log-Output "informational" "Removed: $UserDN"
        } catch {
            Log-Output "warning" "Failed to remove $UserDN`: $_"
        }
    }

}

#End script
Log-Output "notice" "Script execution completed."