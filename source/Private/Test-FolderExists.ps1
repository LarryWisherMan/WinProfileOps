<#
.SYNOPSIS
    Checks if a profile folder exists on a specified computer.
.DESCRIPTION
    The Test-FolderExists function determines whether a given profile folder exists on the specified computer by testing the path.
    If the profile path or computer name is not provided, the function will default to using the local computer.
    In the event of any errors (e.g., invalid paths or inaccessible directories), the function returns $false and logs the error.

.PARAMETER ProfilePath
    The file path of the profile folder to check. This parameter is required. If it is null or empty, the function will return $false.
.PARAMETER ComputerName
    The name of the computer where the profile folder is located. If not provided, the local computer is used by default.
.OUTPUTS
    [bool]
        Returns $true if the folder exists at the specified path, and $false if it does not exist, or if an error occurs during execution.

.EXAMPLE
    Test-FolderExists -ProfilePath "C:\Users\John" -ComputerName "Server01"
    Checks if the folder "C:\Users\John" exists on "Server01".

.EXAMPLE
    Test-FolderExists -ProfilePath "C:\Users\Public"
    Checks if the folder "C:\Users\Public" exists on the local computer (since ComputerName is not specified).

.EXAMPLE
    Test-FolderExists -ProfilePath "C:\InvalidPath" -ComputerName "Server01"
    Returns $false if the specified folder does not exist or if an error occurs while accessing the path.

.NOTES
    The function includes error handling to catch and log any exceptions. In case of an error, the function returns $false.
#>

function Test-FolderExists
{
    [outputType([bool])]
    param (
        [string]$ProfilePath,
        [string]$ComputerName = $env:COMPUTERNAME
    )

    # Check for null or empty ProfilePath
    if (-not $ProfilePath)
    {
        Write-Warning "ProfilePath is null or empty."
        return $false
    }

    # Check for null or empty ComputerName and default to the local computer if it's null
    if (-not $ComputerName)
    {
        Write-Warning "ComputerName is null or empty. Defaulting to the local computer."
        $ComputerName = $env:COMPUTERNAME
    }

    try
    {
        # Determine if the computer is local or remote
        $IsLocal = $ComputerName -eq $env:COMPUTERNAME

        # Get the directory path to check
        $pathToCheck = Get-DirectoryPath -BasePath $ProfilePath -ComputerName $ComputerName -IsLocal $IsLocal

        # Return whether the path exists
        return Test-Path $pathToCheck
    }
    catch
    {
        Write-Error "An error occurred: $_"
        return $false
    }
}
