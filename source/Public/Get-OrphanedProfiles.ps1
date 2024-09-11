<#
.SYNOPSIS
    Retrieves orphaned user profiles from a specified computer.
.DESCRIPTION
    The Get-OrphanedProfiles function scans the user profiles on a specified computer and identifies profiles that are orphaned. Orphaned profiles are those that exist either in the filesystem but not in the registry, or vice versa. The function returns a list of only the orphaned profiles.
.PARAMETER ComputerName
    The name of the computer from which to retrieve orphaned profiles. Defaults to the local computer.
.PARAMETER ProfileFolderPath
    The path to the folder where user profiles are stored. Defaults to "$env:SystemDrive\Users".
.PARAMETER IgnoreSpecial
    Switch to ignore special or default profiles (such as system or service accounts) during the orphan detection process.
.EXAMPLE
    Get-OrphanedProfiles -ComputerName "Server01"
    Retrieves orphaned user profiles from "Server01".
.EXAMPLE
    Get-OrphanedProfiles -ProfileFolderPath "D:\UserProfiles" -IgnoreSpecial
    Retrieves orphaned profiles from the specified folder while ignoring special or default profiles.
.NOTES
    This function relies on the Get-AllUserProfiles function to retrieve profiles from both the filesystem and the registry.
    Orphaned profiles are returned as a filtered list where only profiles marked as orphaned are included.
#>

function Get-OrphanedProfiles
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$ProfileFolderPath = "$env:SystemDrive\Users",

        [switch]$IgnoreSpecial
    )

    # Get all user profiles (both registry and filesystem) using the existing function
    $allProfiles = Get-AllUserProfiles -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath -IgnoreSpecial

    # Filter the profiles to return only orphaned ones
    $orphanedProfiles = $allProfiles | Where-Object { $_.IsOrphaned -eq $true }

    # Return the orphaned profiles
    return $orphanedProfiles
}
