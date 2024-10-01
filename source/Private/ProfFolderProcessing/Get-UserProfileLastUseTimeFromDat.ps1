<#
.SYNOPSIS
    Retrieves the last use time of user profiles by reading the UsrClass.dat file on a specified computer.

.DESCRIPTION
    The Get-UserProfileLastUseTimeFromDat function scans the UsrClass.dat files located in user profile directories on a specified computer
    (local or remote) and retrieves the last write time of each file. This last write time is used as an approximation of the user's last logon time.
    The function handles both local and remote computers, returning custom objects with profile details such as username, profile path, and last logon time.

.PARAMETER ComputerName
    The name of the computer from which to retrieve the last use time of user profiles. Defaults to the local computer.

.PARAMETER SystemDrive
    The system drive to search for user profiles, where the UsrClass.dat files are located. Defaults to the system drive of the current computer ($env:SystemDrive).

.OUTPUTS
    PSCustomObject
    Returns an array of custom objects containing the following properties:
    - Success: [bool] Whether the operation was successful.
    - ComputerName: [string] The name of the computer where the profile data was retrieved from.
    - Username: [string] The name of the user associated with the profile (if available).
    - LastLogon: [DateTime] The last write time of the UsrClass.dat file, representing the last logon time.
    - UserPath: [string] The full path to the user profile folder.
    - Error: [string] Error message in case of failure (if applicable).

.EXAMPLE
    Get-UserProfileLastUseTimeFromDat -ComputerName "Server01" -SystemDrive "D:"
    Retrieves the last logon times of user profiles from UsrClass.dat files on "Server01" in the "D:\Users" directory.

.EXAMPLE
    Get-UserProfileLastUseTimeFromDat
    Retrieves the last logon times of user profiles from UsrClass.dat files on the local computer.

.NOTES
    - This function checks if the specified computer is local or remote and adjusts the search path for UsrClass.dat files accordingly.
    - If no UsrClass.dat files are found, a warning is logged, and the function returns an empty result with a success value of $false.
    - If an error occurs during the process, the function logs a warning and returns an error message.

#>

function Get-UserProfileLastUseTimeFromDat
{
    [CmdletBinding()]
    param (
        [string]$ComputerName = $env:COMPUTERNAME,

        [ValidateNotNullOrEmpty()]
        [string]$SystemDrive = $env:SystemDrive
    )

    begin
    {
        Write-Verbose "Starting function Get-UserProfileLastUseTimeFromDat for computer: $ComputerName"

        # Check if we are querying a local or remote computer
        $isLocal = ($ComputerName -eq $env:COMPUTERNAME)

        # Base path to search for UsrClass.dat files in user profiles
        $BasePath = "$SystemDrive\Users\*\AppData\Local\Microsoft\Windows\UsrClass.dat"
        Write-Verbose "Base path for UsrClass.dat: $BasePath"

        $Path = Get-DirectoryPath -BasePath $BasePath -ComputerName $ComputerName -IsLocal $isLocal
        Write-Verbose "Resolved path: $Path"
    }

    process
    {
        try
        {
            # Retrieve the UsrClass.dat file's last write time for each user profile
            Write-Verbose "Retrieving UsrClass.dat files from $Path"
            $profileItems = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue | Sort-Object LastWriteTime

            # Check if any UsrClass.dat files were found
            if (-not $profileItems)
            {
                Write-Warning "No UsrClass.dat files found in path: $Path"
                return [pscustomobject]@{
                    Success      = $false
                    ComputerName = $ComputerName
                    Message      = "No UsrClass.dat files found."
                }
            }

            # Create custom objects for each profile
            $profileItems | ForEach-Object {
                $datFilePath = $_.FullName

                # Extract the user folder path (everything before 'AppData\Local\Microsoft\Windows')
                $userPath = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetDirectoryName([System.IO.Path]::GetDirectoryName([System.IO.Path]::GetDirectoryName([System.IO.Path]::GetDirectoryName($datFilePath)))))


                # Extract the user name based on the user folder path
                $userName = if ($isLocal)
                {
                    ($userPath).split("\")[2]
                }
                else
                {
                    ($userPath).split("\")[5]
                }

                $lastLogon = $_.LastWriteTime

                [pscustomobject]@{
                    Success      = $true
                    ComputerName = $ComputerName
                    Username     = $userName
                    LastLogon    = $lastLogon
                    UserPath     = (Get-DirectoryPath -BasePath $userPath -IsLocal $true -ComputerName $ComputerName)
                }
            }
        }
        catch
        {
            Write-Warning "An error occurred while processing UsrClass.dat files: $_"
            return [pscustomobject]@{
                Success      = $false
                ComputerName = $ComputerName
                Error        = $_.Exception.Message
                LastLogon    = $null
            }
        }
    }

    end
    {
        Write-Verbose "Completed function Get-UserProfileLastUseTimeFromDat for computer: $ComputerName"
    }
}
