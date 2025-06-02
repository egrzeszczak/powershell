<#
.SYNOPSIS
    Generates random user accounts in Active Directory.

.DESCRIPTION
    This script creates a random user Active Directory account, including details such as name, email, username, and password.
    It can be used for testing, demo data generation, or populating testing environments with sample users.
    It also creates an account with ".adm" suffix if user job title is related to IT.

.PARAMETER Count
    Specifies the number of random user accounts to generate.
    Type: Int
    Default: 1

.EXAMPLE
    .\Generate-RandomUser.ps1 -Count 5
        Generates 5 random user accounts, each with a randomly generated password.

.NOTES
    Author:         egrzeszczak
    Created:        2024-06-01
    Version:        1.0.0
    Dependencies:   Required AD RSAT Module
    Compatibility:  >5.0

.LINK
    https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview
#>

param(
    [Parameter(Mandatory=$true)]
    [int]$Count
)



##  Environment variables (please edit)         --------------------------------------------
# Configure: domain distinguished name
$DomainDN = "DC=contoso,DC=com"
# Configure: Root OU Name (OUs will be created there)
$RootOUName = "Identity and Access Management"
# Configure: unique positions keywords (positions with these positions will be created only once)
$UniquePositionsKeywords = @('Manager', 'Director', 'Chief', 'Head of')
##  Environment variables (please edit)         --------------------------------------------



##  Functions                                   --------------------------------------------
# Convert "DC=moloch,DC=net" to "moloch.net"
function Convert-DNToDNS {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DistinguishedName
    )
    ($DistinguishedName -split ',' |
        Where-Object { $_ -match '^DC=' } |
        ForEach-Object { $_.Substring(3) }) -join '.'
}
# Generate a random password
function New-RandomPassword {
    param([int]$Length = 24)
    $lower = 'abcdefghijklmnopqrstuvwxyz'
    $upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $digits = '0123456789'
    $special = '@#$%&-_'

    # Ensure at least 6 of each group
    $minEach = 6
    $passwordChars = @()
    $passwordChars += (1..$minEach | ForEach-Object { $lower[(Get-Random -Maximum $lower.Length)] })
    $passwordChars += (1..$minEach | ForEach-Object { $upper[(Get-Random -Maximum $upper.Length)] })
    $passwordChars += (1..$minEach | ForEach-Object { $digits[(Get-Random -Maximum $digits.Length)] })
    $passwordChars += (1..$minEach | ForEach-Object { $special[(Get-Random -Maximum $special.Length)] })

    # Fill the rest with random chars from all groups if needed
    $allChars = $lower + $upper + $digits + $special
    $remaining = $Length - $passwordChars.Count
    if ($remaining -gt 0) {
        $passwordChars += (1..$remaining | ForEach-Object { $allChars[(Get-Random -Maximum $allChars.Length)] })
    }

    # Shuffle the result
    $password = ($passwordChars | Get-Random -Count $passwordChars.Count) -join ''
    return $password
}
# Remove polish characters from a string
function Remove-PolishChars {
    param([string]$InputString)
    $map = @{
        "ą" = "a"; "ę" = "e"; "ź" = "z"; "ć" = "c"; "ż" = "z"; "ś" = "s"; "ł" = "l"; "ó" = "o"; "ń" = "n"
    }
    $result = ""
    foreach ($char in $InputString.ToCharArray()) {
        $charStr = [string]$char
        if ($map.ContainsKey($charStr)) {
            $result += $map[$charStr]
        } else {
            $result += $charStr
        }
    }
    return $result
}
# Create a username based on FirstName, LastName and already created usernames ($ExistingUsernameList)
function New-UniqueUsername {
    param($FirstName, $LastName, $ExistingUsernameList)
    $base = ("{0}.{1}" -f $FirstName.Substring(0,1).ToLower(), $LastName.ToLower())
    $username = Remove-PolishChars -InputString $base
    $i = 1
    while ($ExistingUsernameList -contains $username) {
        $i++
        $username = "$base$i"
    }
    return $username
}
##  Functions                                   --------------------------------------------



##  Load CSV data                               --------------------------------------------
$firstNames = Import-Csv -Path ".\first-names.csv"
$lastNames = Import-Csv -Path ".\last-names.csv"
$jobPositions = Import-Csv -Path ".\job-positions.csv"
##  Load CSV data                               --------------------------------------------



##  Global variables (do not edit)              --------------------------------------------
# Get domain
$Domain = Convert-DNToDNS -DistinguishedName $DomainDN
# List to track already used unique positions
$UniquePositionsTable = @()
# Root OU DN (OUs will be created there)
$RootOU = "OU=$RootOUName,$DomainDN"
# Created username list (for uniqueness tracking)
$Usernames = @()
##  Global variables (do not edit)              --------------------------------------------



##  Ensure Root OU exists, create if not        --------------------------------------------
if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$RootOU'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name $RootOUName -Path $DomainDN -ProtectedFromAccidentalDeletion $false
}
##  Ensure Root OU exists, create if not        --------------------------------------------



##  ----------------------------------------------------------------------------------------



for ($i = 1; $i -le $Count; $i++) {
    $attempts = 0
    do {
        $first = Get-Random -InputObject $firstNames
        $last = Get-Random -InputObject $lastNames
        $job = Get-Random -InputObject $jobPositions

        # Check if the position is unique (Manager/Director/Chief/Head of)
        $isUnique = $false
        foreach ($keyword in $UniquePositionsKeywords) {
            if ($job.position -match "(?i)\b$keyword\b") {
                $isUnique = $true
                break
            }
        }
        # If unique and already used, pick another
        if ($isUnique -and $UniquePositionsTable -contains $job.position) {
            $job = $null
        }
        $attempts++
        if ($attempts -gt 100) { break } # Prevent infinite loop
    } while (-not $job)

    # Pick gender-appropriate last name
    if ($first.sex -eq "F") {
        $lastName = $last.name_f
    } else {
        $lastName = $last.name_m
    }

    $username = New-UniqueUsername -FirstName $first.name -LastName $lastName -ExistingUsernameList $Usernames
    $Usernames += $username
    $password = New-RandomPassword
    $ouPath = $RootOU
    $displayName = "$($first.name) $lastName"
    $userPrincipalName = "$username@$Domain"

    # Mark unique position as used
    if ($isUnique) {
        $UniquePositionsTable += $job.position
    }

        # Create AD User
        $userCreated = $false
        try {
            New-ADUser `
                -Name $displayName `
                -GivenName $first.name `
                -Surname $lastName `
                -SamAccountName $username `
                -UserPrincipalName $userPrincipalName `
                -Department $job.department `
                -DisplayName $displayName `
                -Title $job.position `
                -Description $job.position `
                -Path $ouPath `
                -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
                -Enabled $true

            Write-Host "SUCCESS`t`tCreated $displayName ($username) in $ouPath"
            $userCreated = $true
        }
        catch {
            Write-Host "WARNING`t`tFailed when creating $displayName ($username) in $ouPath, due to: $($_.Exception.Message)"
        }

        # If user is in IT or IT Security, create an admin account only if user was created
        if ($userCreated -and ($job.department -in @("IT", "IT Security"))) {
            $adminDisplayName = "$displayName (Admin)"
            $adminUsername = "$username.adm"
            $adminUPN = "$adminUsername@$Domain"
            $adminOU = $RootOU
            $adminPassword = New-RandomPassword
            $adminDescription = "$($job.position) (Admin)"

            try {
                New-ADUser `
                    -Name $adminDisplayName `
                    -GivenName $first.name `
                    -Surname $lastName `
                    -SamAccountName $adminUsername `
                    -UserPrincipalName $adminUPN `
                    -Department $job.department `
                    -Title $job.position `
                    -Description $adminDescription `
                    -DisplayName $adminDisplayName `
                    -Path $adminOU `
                    -AccountPassword (ConvertTo-SecureString $adminPassword -AsPlainText -Force) `
                    -Enabled $true

                Write-Host "SUCCESS`t`tCreated $adminDisplayName ($adminUsername) in $adminOU"
            }
            catch {
                Write-Host "WARNING`t`tFailed when creating $adminDisplayName ($adminUsername) in $adminOU, due to: $($_.Exception.Message)"
            }
        }
}

