<#
.SYNOPSIS
    Retrieves user profiles from the registry of a specified computer.
.DESCRIPTION
    The Get-UserProfilesFromRegistry function queries the ProfileList registry key on the specified computer
    and returns information about the user profiles found in the registry. This includes details such as the
    security identifier (SID) and the profile path. The function checks if the computer is reachable before
    proceeding with the operation and handles errors gracefully if there are issues accessing the registry.
.PARAMETER ComputerName
    The name of the computer from which to retrieve user profiles. Defaults to the local computer.
.OUTPUTS
    PSCustomObject[]
    Returns an array of custom objects representing the user profiles found in the registry. Each object contains
    the following properties:
    - SID: [string] The security identifier (SID) of the user profile.
    - ProfilePath: [string] The path to the user profile.
    - ComputerName: [string] The name of the computer where the profile was retrieved.
.EXAMPLE
    Get-UserProfilesFromRegistry -ComputerName "Server01"
    Retrieves the user profiles from the registry on "Server01".
.EXAMPLE
    Get-UserProfilesFromRegistry
    Retrieves the user profiles from the local computer's registry.
.NOTES
    - The function first checks if the target computer is reachable. If the computer is unreachable, a warning
      is logged, and the function returns an empty array.
    - If an error occurs while accessing the registry, an error is logged, and the function returns an empty array.
#>
function Get-UserProfilesFromRegistry
{
    [OutputType([PSCustomObject[]])]
    [CmdletBinding()]
    param (
        [string] $ComputerName = $env:COMPUTERNAME
    )

    try
    {
        # Test if the computer is online before proceeding
        if (-not (Test-ComputerPing -ComputerName $ComputerName))
        {
            Write-Warning "Computer '$ComputerName' is offline or unreachable."
            return @()  # Return an empty array
        }

        # If user is an admin, use Get-SIDProfileInfo (Registry-based)
        if ($ENV:WinProfileOps_IsAdmin -eq $true)
        {
            Write-Verbose "User has administrator privileges, using registry-based method."
            return Get-SIDProfileInfo -ComputerName $ComputerName
        }
        else
        {
            Write-Warning "User lacks administrator privileges. Switching to fallback method which excludes special accounts from the results."
            return Get-SIDProfileInfoFallback -ComputerName $ComputerName
        }

    }
    catch
    {
        Write-Error "Error accessing registry profiles on computer '$ComputerName'. Error: $_"
        return @()  # Return an empty array in case of failure
    }
}
