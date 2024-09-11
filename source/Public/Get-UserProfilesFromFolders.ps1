<#
.SYNOPSIS
    Retrieves user profile folders from a specified computer.
.DESCRIPTION
    The Get-UserProfilesFromFolders function scans the user profile directory on the specified computer and returns information about the user profile folders found. This function is useful for identifying the profile folders stored on disk, which may or may not match entries in the registry.
.PARAMETER ComputerName
    The name of the computer from which to retrieve user profile folders. Defaults to the local computer.
.PARAMETER ProfileFolderPath
    The path to the folder where user profiles are stored. Defaults to "$env:SystemDrive\Users".
.EXAMPLE
    Get-UserProfilesFromFolders -ComputerName "Server01" -ProfileFolderPath "D:\UserProfiles"
    Retrieves user profile folders from the "D:\UserProfiles" directory on "Server01".
.EXAMPLE
    Get-UserProfilesFromFolders
    Retrieves user profile folders from the default "$env:SystemDrive\Users" directory on the local computer.
.NOTES
    This function returns a list of user profile folders found in the specified directory on the specified computer.
#>
function Get-UserProfilesFromFolders
{
    param (
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$ProfileFolderPath = "$env:SystemDrive\Users"
    )

    # Get user folders and return them
    $UserFolders = Get-UserFolders -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath
    return $UserFolders
}
