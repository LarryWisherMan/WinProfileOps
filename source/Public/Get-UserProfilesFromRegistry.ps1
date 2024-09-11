<#
.SYNOPSIS
    Retrieves user profiles from the registry of a specified computer.
.DESCRIPTION
    The Get-UserProfilesFromRegistry function queries the ProfileList registry key on the specified computer and returns information about the user profiles found in the registry. This includes details such as the SID and profile path.
.PARAMETER ComputerName
    The name of the computer from which to retrieve user profiles. Defaults to the local computer.
.EXAMPLE
    Get-UserProfilesFromRegistry -ComputerName "Server01"
    Retrieves the user profiles from the registry on "Server01".
.EXAMPLE
    Get-UserProfilesFromRegistry
    Retrieves the user profiles from the local computer's registry.
.NOTES
    This function returns a list of user profiles stored in the registry, including their SIDs and associated profile paths.
#>
function Get-UserProfilesFromRegistry
{
    param (
        [string] $ComputerName = $env:COMPUTERNAME
    )

    # Get registry profiles and return them
    $RegistryProfiles = Get-SIDProfileInfo -ComputerName $ComputerName
    return $RegistryProfiles
}

