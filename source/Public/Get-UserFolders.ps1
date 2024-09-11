<#
.SYNOPSIS
    Retrieves a list of user profile folders from a specified computer.
.DESCRIPTION
    The Get-UserFolders function scans the user profile directory on the specified computer and returns a list of folders that represent user profiles. It checks whether the target computer is local or remote and returns information such as the folder name and profile path for each folder.
.PARAMETER ComputerName
    The name of the computer from which to retrieve user profile folders.
.PARAMETER ProfileFolderPath
    The path to the folder where user profiles are stored. Defaults to "$env:SystemDrive\Users".
.EXAMPLE
    Get-UserFolders -ComputerName "Server01" -ProfileFolderPath "D:\UserProfiles"
    Retrieves a list of user profile folders from the "D:\UserProfiles" directory on "Server01".
.EXAMPLE
    Get-UserFolders -ComputerName $env:COMPUTERNAME
    Retrieves a list of user profile folders from the local computer's default user directory.
.NOTES
    This function returns an array of objects where each object represents a user profile folder, including the folder name, profile path, and computer name.
#>
function Get-UserFolders
{
    [CmdletBinding()]
    param (
        [string]$ComputerName,
        [string]$ProfileFolderPath = "$env:SystemDrive\Users"
    )

    $IsLocal = ($ComputerName -eq $env:COMPUTERNAME)
    $FolderPath = Get-DirectoryPath -BasePath $ProfileFolderPath -ComputerName $ComputerName -IsLocal $IsLocal

    # Get list of all folders in the user profile directory
    $ProfileFolders = Get-ChildItem -Path $FolderPath -Directory | ForEach-Object {
        [PSCustomObject]@{
            FolderName   = $_.Name
            ProfilePath  = Get-DirectoryPath -basepath $_.FullName -ComputerName $ComputerName -IsLocal $true
            ComputerName = $ComputerName
        }
    }

    return $ProfileFolders
}
