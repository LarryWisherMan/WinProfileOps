<#
.SYNOPSIS
    Retrieves orphaned user profiles from a specified computer.
.DESCRIPTION
    The Get-OrphanedProfiles function scans both the user profile folders and registry on a specified computer and returns profiles that are considered orphaned. Orphaned profiles are those that exist either in the file system but not in the registry, or in the registry but no longer have a corresponding folder in the file system.
.PARAMETER ComputerName
    The name of the computer from which to retrieve orphaned user profiles. Defaults to the local computer.
.PARAMETER ProfileFolderPath
    The path to the folder where user profiles are stored. Defaults to "$env:SystemDrive\Users".
.PARAMETER IgnoreSpecial
    Switch to ignore special or default profiles during the profile retrieval process.
.OUTPUTS
    [UserProfile[]]
    Returns an array of UserProfile objects that represent the profiles found during the audit. Each UserProfile object contains the following properties:
    - SID: [string] The security identifier of the user profile.
    - ProfilePath: [string] The file system path of the user profile.
    - IsOrphaned: [bool] Whether the profile is considered orphaned.
    - OrphanReason: [string] The reason for orphaned status if applicable.
    - ComputerName: [string] The name of the computer where the audit was performed.
    - IsSpecial: [bool] Whether the profile is considered special or a system account.
.EXAMPLE
    Get-OrphanedProfiles -ComputerName "Server01"
    Retrieves all orphaned user profiles from both the file system and registry on "Server01".
.EXAMPLE
    Get-OrphanedProfiles -ProfileFolderPath "D:\UserProfiles" -IgnoreSpecial
    Retrieves orphaned user profiles from the specified folder and ignores special or default profiles.
.NOTES
    This function filters orphaned profiles based on the results of the Invoke-UserProfileAudit function.
#>
function Get-OrphanedProfiles
{
    [CmdletBinding()]
    [OutputType([UserProfile[]])]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$ProfileFolderPath = $env:WinProfileOps_ProfileFolderPath,
        [switch]$IgnoreSpecial
    )


    try
    {
        # Call Invoke-UserProfileAudit to get all profiles
        $allProfiles = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath -IgnoreSpecial:$IgnoreSpecial

        # Filter to return only orphaned profiles
        $orphanedProfiles = $allProfiles | Where-Object { $_.IsOrphaned }

        # Handle the case where no orphaned profiles are found
        if (-not $orphanedProfiles)
        {
            Write-Verbose "No orphaned profiles found on computer '$ComputerName'."
            return @()  # Return an empty array
        }
    }
    catch
    {
        Write-Error "An error occurred while retrieving orphaned profiles: $_"
        return
    }

    return $orphanedProfiles
}
