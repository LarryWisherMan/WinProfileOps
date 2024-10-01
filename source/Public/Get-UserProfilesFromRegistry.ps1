<#
.SYNOPSIS
    Retrieves user profiles from the registry of a specified computer.
.DESCRIPTION
    The Get-UserProfilesFromRegistry function queries the ProfileList registry key on the specified computer
    and returns information about the user profiles found in the registry. This includes details such as the
    security identifier (SID) and the profile path. The function checks if the computer is reachable before
    proceeding with the operation. If the computer is unreachable, a warning is logged, and an empty array is returned.
    If an error occurs while accessing the registry, the function logs an error and returns an empty array.
.PARAMETER ComputerName
    The name of the computer from which to retrieve user profiles. If null or empty, it defaults to the local computer.
.PARAMETER RegistryPath
    The path to the registry key containing the user profiles. Defaults to the value of the `$Env:WinProfileOps_RegistryPath` environment variable.
.PARAMETER RegistryHive
    The hive in the registry where the profile list is located (e.g., 'HKLM'). Defaults to the value of the `$Env:WinProfileOps_RegistryHive` environment variable.
.OUTPUTS
    PSCustomObject[]
    Returns an array of custom objects representing the user profiles found in the registry. Each object contains:
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
    - This function first checks if the specified computer is reachable using Test-ComputerPing. If the computer
      is offline or unreachable, a warning is logged and an empty array is returned.
    - If there is an issue accessing the registry or no profiles are found, an error is logged, and the function
      returns an empty array.
    - If no `ComputerName` is specified, it defaults to the local computer.
#>

function Get-UserProfilesFromRegistry
{
    [OutputType([PSCustomObject[]])]
    [CmdletBinding()]
    param (
        [string] $ComputerName = $env:COMPUTERNAME,
        [string]$RegistryPath = $Env:WinProfileOps_RegistryPath,
        [string]$RegistryHive = $env:WinProfileOps_RegistryHive
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

        # Get registry profiles and return them
        Get-ProfileRegistryItems -ComputerName $ComputerName -RegistryPath $RegistryPath -RegistryHive $RegistryHive -WarningAction SilentlyContinue

    }
    catch
    {
        Write-Error "Error accessing registry profiles on computer '$ComputerName'. Error: $_"
        return @()  # Return an empty array in case of failure
    }
}
