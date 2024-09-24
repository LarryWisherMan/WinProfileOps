<#
.SYNOPSIS
    Retrieves user profile folders from a specified computer.
.DESCRIPTION
    The Get-UserProfilesFromFolders function scans the user profile directory on the specified
    computer and returns information about the user profile folders found. This function is useful
    for identifying profile folders stored on disk, which may or may not match entries in the registry.
    The function checks if the specified computer is online before attempting to retrieve the profile folders.
    If the computer is unreachable, it logs a warning and returns an empty array.
.PARAMETER ComputerName
    The name of the computer from which to retrieve user profile folders. Defaults to the local computer.
.PARAMETER ProfileFolderPath
    The path to the folder where user profiles are stored. Defaults to "$env:SystemDrive\Users".
.OUTPUTS
    PSCustomObject[]
    Returns an array of custom objects representing the user profile folders found. Each object contains:
    - FolderName: The name of the user profile folder.
    - ProfilePath: The full path to the user profile folder.
    - ComputerName: The name of the computer where the profile folder was retrieved from.
.EXAMPLE
    Get-UserProfilesFromFolders -ComputerName "Server01" -ProfileFolderPath "D:\UserProfiles"
    Retrieves user profile folders from the "D:\UserProfiles" directory on "Server01".
.EXAMPLE
    Get-UserProfilesFromFolders
    Retrieves user profile folders from the default "$env:SystemDrive\Users" directory on the local computer.
.NOTES
    This function returns an array of objects representing the user profile folders found in the specified
    directory on the specified computer. It logs a warning if the target computer is unreachable and
    returns an empty array in case of errors during the retrieval process.
#>

function Get-UserProfilesFromFolders
{
    [OutputType([PSCustomObject[]])]
    [CmdletBinding()]
    param (
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$ProfileFolderPath = $env:WinProfileOps_ProfileFolderPath
    )

    try
    {
        # Test if the computer is online before proceeding
        if (-not (Test-ComputerPing -ComputerName $ComputerName))
        {
            Write-Warning "Computer '$ComputerName' is offline or unreachable."
            return @()  # Return an empty array
        }

        # Get user folders and return them
        $UserFolders = Get-UserFolders -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath -ErrorAction Stop
        return $UserFolders
    }
    catch
    {
        Write-Error "Error retrieving user folders from '$ProfileFolderPath' on computer '$ComputerName'. Error: $_"
        return @()  # Return an empty array in case of failure
    }
}
