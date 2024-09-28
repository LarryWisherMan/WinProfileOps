<#
.SYNOPSIS
    Retrieves a list of user profile folders from a specified computer.
.DESCRIPTION
    The Get-UserFolders function scans the user profile directory on the specified computer
    and returns a list of folders that represent user profiles. It determines whether the
    target computer is local or remote and retrieves information such as the folder name,
    profile path, and computer name for each folder.

    If an error occurs during the folder retrieval, the function logs the error and returns
    an empty array.
.PARAMETER ComputerName
    The name of the computer from which to retrieve user profile folders. If not provided,
    defaults to the local computer.
.PARAMETER ProfileFolderPath
    The path to the folder where user profiles are stored. Defaults to "$env:SystemDrive\Users".
    This can be overridden to target a custom directory path for user profiles.
.OUTPUTS
    [PSCustomObject[]]
    An array of custom objects, where each object contains the following properties:
        - FolderName: [string] The name of the user profile folder.
        - ProfilePath: [string] The full path to the user profile folder.
        - ComputerName: [string] The name of the computer from which the user profile folder
          was retrieved.
.EXAMPLE
    Get-UserFolders -ComputerName "Server01" -ProfileFolderPath "D:\UserProfiles"
    Retrieves a list of user profile folders from the "D:\UserProfiles" directory on "Server01".
.EXAMPLE
    Get-UserFolders -ComputerName $env:COMPUTERNAME
    Retrieves a list of user profile folders from the local computer's default user directory.
.EXAMPLE
    Get-UserFolders -ComputerName "RemotePC"
    Retrieves a list of user profile folders from the default user directory on the remote computer
    "RemotePC".
.NOTES
    - If the Get-ChildItem command fails (e.g., due to access issues), the function logs an error
      and returns an empty array.
    - The ProfilePath for local computers is returned as a local path, while for remote computers,
      the folder is first accessed using a UNC path, but the returned ProfilePath is formatted as a
      local path for consistency.
    - Use the optional ProfileFolderPath parameter to target custom directories for user profiles.
#>

function Get-UserFolders
{
    [OutputType([PSCustomObject[]])]
    [CmdletBinding()]
    param (
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$ProfileFolderPath = $env:WinProfileOps_ProfileFolderPath
    )


    $IsLocal = ($ComputerName -eq $env:COMPUTERNAME)
    $FolderPath = Get-DirectoryPath -BasePath $ProfileFolderPath -ComputerName $ComputerName -IsLocal $IsLocal

    try
    {
        # Get list of all folders in the user profile directory
        $ProfileFolders = Get-ChildItem -Path $FolderPath -Directory | ForEach-Object {
            [PSCustomObject]@{
                FolderName   = $_.Name
                ProfilePath  = Get-DirectoryPath -BasePath $_.FullName -ComputerName $ComputerName -IsLocal $true
                ComputerName = $ComputerName
            }
        }

        return $ProfileFolders
    }
    catch
    {
        # Handle the error when Get-ChildItem fails
        Write-Error "Failed to retrieve folders from '$FolderPath' on '$ComputerName'. Error: $_"
        return @()  # Return an empty array in case of failure
    }
}
