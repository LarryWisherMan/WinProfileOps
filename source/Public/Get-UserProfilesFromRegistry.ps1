function Get-UserProfilesFromRegistry {
    param (
        [string]$ComputerName
    )

    # Get registry profiles and return them
    $RegistryProfiles = Get-SIDProfileInfo -ComputerName $ComputerName
    return $RegistryProfiles
}
