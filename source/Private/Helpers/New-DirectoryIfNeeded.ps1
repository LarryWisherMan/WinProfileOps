<#
.SYNOPSIS
Creates a directory if it does not already exist.

.DESCRIPTION
The `New-DirectoryIfNeeded` function checks if the specified directory exists. If it doesn't, the function will create the directory and return the created directory object. If the directory already exists, the function returns `$true`. In case of any errors during directory creation, the function returns `$false` and logs the error.

.PARAMETER Directory
Specifies the full path of the directory to check or create. This parameter is mandatory. If the directory path is `null`, empty, or contains only whitespace, the function throws an error.

.EXAMPLE
New-DirectoryIfNeeded -Directory 'C:\Temp\NewFolder'

Description:
This command checks if the directory 'C:\Temp\NewFolder' exists. If it doesn't, the directory will be created. If the directory already exists, the function will return `$true`.

.EXAMPLE
New-DirectoryIfNeeded -Directory 'D:\Logs'

Description:
This command checks if the directory 'D:\Logs' exists. If it does not, the function will create the directory. If the directory already exists, it returns `$true`.

.EXAMPLE
$directory = New-DirectoryIfNeeded -Directory 'C:\Data\Reports'

Description:
This command attempts to create the directory 'C:\Data\Reports' if it doesn't exist and assigns the result to `$directory`. If successful, `$directory` will contain the created directory object. If the directory already exists, `$true` will be assigned to `$directory`.

.NOTES
If the directory path is invalid or if an error occurs during the creation process, the function writes an error message and returns `$false`.
#>

function New-DirectoryIfNeeded
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    try
    {
        # Check if the Directory parameter is null or an empty string
        if ([string]::IsNullOrWhiteSpace($Directory))
        {
            throw [System.ArgumentException]::new("The 'Directory' parameter cannot be null or empty.")
        }

        # If the directory does not exist, attempt to create it
        if (-not (Test-Path -Path $Directory))
        {
            $newDirectory = New-Item -Path $Directory -ItemType Directory -Force -ErrorAction Stop
            return $newDirectory
        }

        # If the directory exists, return $true
        return $true
    }
    catch
    {
        Write-Error "Failed to create directory: $Directory. Error: $_"
        return $false
    }
}
