<#
.SYNOPSIS
    Retrieves user profile folders from a specified computer.
.DESCRIPTION
    The Get-UserProfilesFromFolders function scans the user profile directory on the specified
    computer and returns information about the user profile folders found. This function is useful
    for identifying profile folders stored on disk, which may or may not match entries in the registry.
    The function checks if the specified computer is online before attempting to retrieve the profile folders.
    If the computer is unreachable, it logs a warning and returns an empty array.
    If no profile folders are found, another warning is logged and an empty array is returned.
.PARAMETER ComputerName
    The name of the computer from which to retrieve user profile folders. If null or empty, it defaults to the local computer.
.PARAMETER ProfileFolderPath
    The path to the folder where user profiles are stored. Defaults to "$env:WinProfileOps_ProfileFolderPath".
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
    Retrieves user profile folders from the default "$env:WinProfileOps_ProfileFolderPath" directory on the local computer.
.NOTES
    - This function checks if the specified computer is reachable using Test-ComputerPing. If the computer is offline or unreachable,
      it logs a warning and returns an empty array.
    - If no user profile folders are found in the specified directory, another warning is logged, and an empty array is returned.
    - In case of any errors during the retrieval process, the function handles exceptions, logs an error, and returns an empty array.
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

        if (-not $ComputerName -or $null -eq $ComputerName)
        {
            $ComputerName = $env:COMPUTERNAME
        }

        # Test if the computer is online before proceeding
        if (-not (Test-ComputerPing -ComputerName $ComputerName))
        {
            Write-Warning "Computer '$ComputerName' is offline or unreachable."
            return @()  # Return an empty array
        }

        # Get user folders and return them
        $UserFolders = Get-UserFolders -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath -ErrorAction Stop

        if (-not $UserFolders)
        {
            Write-Warning "No user profile folders found in '$ProfileFolderPath' on computer '$ComputerName'."
            return @()  # Return an empty array
        }

        Get-ProcessedUserProfilesFromFolders -UserFolders $UserFolders -ComputerName $ComputerName

    }
    catch
    {
        Write-Error "Error retrieving user folders from '$ProfileFolderPath' on computer '$ComputerName'. Error: $_"
        return @()  # Return an empty array in case of failure
    }
}
