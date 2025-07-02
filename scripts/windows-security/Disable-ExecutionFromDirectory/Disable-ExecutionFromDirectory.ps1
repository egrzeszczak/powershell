<#
.SYNOPSIS
    Script will impose an execution restriction for given directories.

.DESCRIPTION
    The script sets registry-based Software Restriction Policies to block the execution of specified file types from the defined directories. This helps mitigate the risk of malware execution by preventing users or malicious processes from running unauthorized programs from these locations. 
    Administrator privileges required.

.PARAMETER $RestrictedDirectories
    Array of directory paths that will be restricted from running files with extensions specified in $RestrictedExtensions
.PARAMETER $RestrictedExtensions
    Array of extensions that will be restricted from executing within locations specified in $RestrictedDirectories

.EXAMPLE
    .\Disable-ExeuctionFromDirectory.ps1

.NOTES
    Author:         egrzeszczak
    Created:        2025-07-02
    Version:        v1.0.0
    Dependencies:   -
    Compatibility:  >=5.0

.LINK
    Based on https://www.ninjaone.com/script-hub/how-to-block-executables-from-appdata-and-folders/
#>

[CmdletBinding()]

##  Take parameters
param (
    [Parameter()]
    [string[]] $RestrictedDirectories = @('%UserProfile%\Downloads'),

    [Parameter()]
    [string[]] $RestrictedExtensions = @(
        'ADE', 'ADP', 'BAS', 'BAT', 'CHM', 'CMD', 'COM', 'CPL', 'CRT', 'EXE', 'HLP', 'HTA',
        'INF', 'INS', 'ISP', 'LNK', 'MDB', 'MDE', 'MSC', 'MSI', 'MSP', 'MST', 'OCX', 'PCD',
        'PIF', 'REG', 'SCR', 'SHS', 'URL', 'VB', 'WSC'
    )
)

##  Check for admin privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator." -ForegroundColor Red
    exit 1
}

##  Define registry paths
$BaseRegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\safer'
$CodeIdentifiersPath = "$BaseRegPath\codeidentifiers"
$PathsPath = "$CodeIdentifiersPath\0\Paths"

##  Ensure base keys exist (do not remove anything)
if (-not (Test-Path $BaseRegPath)) { New-Item $BaseRegPath | Out-Null }
if (-not (Test-Path $CodeIdentifiersPath)) { New-Item $CodeIdentifiersPath | Out-Null }
if (-not (Test-Path "$CodeIdentifiersPath\0")) { New-Item "$CodeIdentifiersPath\0" | Out-Null }
if (-not (Test-Path $PathsPath)) { New-Item $PathsPath | Out-Null }

##  Set ExecutableTypes if not already set
$currentExtensions = (Get-ItemProperty -Path $CodeIdentifiersPath -Name 'ExecutableTypes' -ErrorAction SilentlyContinue).ExecutableTypes
if (-not $currentExtensions) {
    New-ItemProperty -Path $CodeIdentifiersPath -Name 'ExecutableTypes' -Value $RestrictedExtensions -PropertyType MultiString | Out-Null
}

##  Set other policy values if not already set
$policyDefaults = @{
    'authenticodeenabled' = 0
    'DefaultLevel'        = 262144
    'TransparentEnabled'  = 1
    'PolicyScope'         = 0
}
foreach ($name in $policyDefaults.Keys) {
    if (-not (Get-ItemProperty -Path $CodeIdentifiersPath -Name $name -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $CodeIdentifiersPath -Name $name -Value $policyDefaults[$name] -PropertyType DWord | Out-Null
    }
}

##  Add new path rules for specified directories only if not already present
foreach ($Directory in $RestrictedDirectories) {
    $alreadyExists = $false
    $existingPaths = Get-ChildItem -Path $PathsPath -ErrorAction SilentlyContinue
    if ($existingPaths) {
        foreach ($pathKey in $existingPaths) {
            $itemData = (Get-ItemProperty -Path $pathKey.PSPath -Name 'ItemData' -ErrorAction SilentlyContinue).ItemData
            if ($itemData -eq $Directory) {
                $alreadyExists = $true
                break
            }
        }
    }
    if (-not $alreadyExists) {
        $pathguid = [guid]::NewGuid()
        $newpathkey = "$PathsPath\{$pathguid}"
        New-Item $newpathkey | Out-Null
        New-ItemProperty -Path $newpathkey -Name 'SaferFlags' -Value 0 -PropertyType DWord | Out-Null
        New-ItemProperty -Path $newpathkey -Name 'ItemData' -Value $Directory -PropertyType ExpandString | Out-Null
    }
}

##  Sync with domain's GPO
gpupdate.exe /force