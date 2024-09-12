<#
.SYNOPSIS
    Retrieves non-special user profile information from a remote or local computer.

.DESCRIPTION
    The Get-SIDProfileInfoFallback function uses the CIM (Common Information Model) method to retrieve user profile
    information from the specified computer. It filters out special profiles and returns the SID, profile path, and other
    relevant information for each user profile found on the system. This function serves as a fallback method for obtaining
    profile information without requiring administrative privileges to access the registry.

.PARAMETER ComputerName
    The name of the computer to query for user profiles. If not provided, the function will default to the local computer.

.OUTPUTS
    [PSCustomObject[]]
        Returns an array of PSCustomObject where each object contains:
            - SID: The security identifier for the user profile.
            - ProfilePath: The local file system path to the user profile.
            - ComputerName: The name of the computer from which the profile was retrieved.
            - ExistsInRegistry: Always set to $true, as this function is a fallback and does not query the registry directly.

.EXAMPLE
    Get-SIDProfileInfoFallback

    Retrieves non-special user profiles from the local computer and returns their SID, profile path, and other details.

.EXAMPLE
    Get-SIDProfileInfoFallback -ComputerName "Server01"

    Retrieves non-special user profiles from the remote computer "Server01" and returns their SID, profile path, and other details.

.NOTES
    This function does not require administrative privileges to access profile information, as it relies on CIM/WMI methods
    to retrieve data. It specifically filters out special profiles (such as system profiles) using the "Special=False" filter.
#>

function Get-SIDProfileInfoFallback
{
    [OutputType([PSCustomObject[]])]
    [CmdletBinding()]
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )
    # Use CIM as a fallback method to get user profile information
    $profiles = Get-CimInstance -ClassName Win32_UserProfile -ComputerName $ComputerName -Filter "Special=False"

    $ProfileRegistryItems = foreach ($profile in $profiles)
    {
        # Return a PSCustomObject similar to what Get-SIDProfileInfo returns
        [PSCustomObject]@{
            SID              = $profile.SID
            ProfilePath      = $profile.LocalPath
            ComputerName     = $ComputerName
            ExistsInRegistry = $true
        }
    }

    return $ProfileRegistryItems
}
