<#
.SYNOPSIS
    Retrieves profile information from the registry for all SIDs on a specified computer.

.DESCRIPTION
    The Get-SIDProfileInfo function queries the ProfileList registry key on the specified computer and retrieves
    profile information for each Security Identifier (SID). It validates the SID format, opens the corresponding
    registry subkeys, and fetches the ProfileImagePath for each valid SID. The function returns a list of profiles,
    including details such as the SID, profile path, and whether the profile exists in the registry.

.PARAMETER ComputerName
    The name of the computer from which to retrieve profile information. Defaults to the local computer.

.EXAMPLE
    Get-SIDProfileInfo -ComputerName "Server01"
    Retrieves profile information for all valid SIDs stored in the registry on "Server01".

.EXAMPLE
    Get-SIDProfileInfo
    Retrieves profile information for all valid SIDs stored in the registry on the local computer.

.OUTPUTS
    [PSCustomObject[]]
    An array of custom objects, where each object contains the following properties:
        - SID: [string] The Security Identifier of the profile.
        - ProfilePath: [string] The path to the user profile folder in the file system.
        - ComputerName: [string] The name of the computer from which the profile information was retrieved.
        - ExistsInRegistry: [bool] Indicates whether the profile exists in the registry.

.NOTES
    - If a registry subkey for an SID cannot be opened, a warning is written to the output.
    - Invalid SID formats are skipped with a warning.
    - If a ProfileImagePath is not found for a valid SID, a verbose message is logged and the profile is returned
      with a null ProfilePath.
    - The function returns an empty array if no SIDs are found or if the registry path cannot be opened.
#>
function Get-SIDProfileInfo
{
    [OutputType([PSCustomObject[]])]
    [CmdletBinding()]
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $RegistryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    $ProfileListKey = Open-RegistryKey -RegistryPath $RegistryPath -ComputerName $ComputerName

    # Handle null or empty registry key
    if (-not $ProfileListKey)
    {
        Write-Error "Failed to open registry path: $RegistryPath on $ComputerName."
        return @()  # Return an empty array
    }

    $subKeyNames = $ProfileListKey.GetSubKeyNames()

    # If no SIDs are found, return an empty array
    if (-not $subKeyNames -or $subKeyNames.Count -eq 0)
    {
        Write-Verbose "No SIDs found in the registry key on $ComputerName."
        return @()  # Return an empty array
    }

    $ProfileRegistryItems = foreach ($sid in $subKeyNames)
    {
        # Validate SID format (SIDs typically start with 'S-1-' and follow a specific pattern)
        if (-not (Validate-SIDFormat -SID $sid))
        {
            continue
        }

        # Use Open-RegistrySubKey to get the subkey for the SID
        $subKey = Open-RegistrySubKey -ParentKey $ProfileListKey -SubKeyName $sid

        if ($subKey -eq $null)
        {
            Write-Warning "Registry key for SID '$sid' could not be opened."
            continue
        }

        # Use Get-ProfilePathFromSID to get the ProfileImagePath for the SID
        $profilePath = Get-ProfilePathFromSID -SidKey $subKey

        if (-not $profilePath)
        {
            Write-Verbose "ProfileImagePath not found for SID '$sid'."
            $profilePath = $null
        }

        # Return a PSCustomObject with SID, ProfilePath, and ComputerName
        [PSCustomObject]@{
            SID              = $sid
            ProfilePath      = $profilePath
            ComputerName     = $ComputerName
            ExistsInRegistry = $true
        }
    }

    return $ProfileRegistryItems
}
