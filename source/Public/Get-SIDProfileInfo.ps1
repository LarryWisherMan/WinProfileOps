<#
.SYNOPSIS
    Retrieves profile information from the registry for all SIDs on a specified computer.
.DESCRIPTION
    The Get-SIDProfileInfo function queries the ProfileList registry key on the specified computer and retrieves profile information for each Security Identifier (SID). The function returns a list of profiles, including details such as the SID, profile path, and whether the profile exists in the registry.
.PARAMETER ComputerName
    The name of the computer from which to retrieve profile information. Defaults to the local computer.
.EXAMPLE
    Get-SIDProfileInfo -ComputerName "Server01"
    Retrieves profile information for all SIDs stored in the registry on "Server01".
.EXAMPLE
    Get-SIDProfileInfo
    Retrieves profile information for all SIDs stored in the registry on the local computer.
.NOTES
    This function returns a list of objects where each object contains the SID, profile path, and whether the profile exists in the registry.
    If a registry subkey for an SID cannot be opened, a warning is written to the output.
#>
function Get-SIDProfileInfo
{
    [CmdletBinding()]
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $RegistryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    $ProfileListKey = Open-RegistryKey -RegistryPath $RegistryPath -ComputerName $ComputerName

    if ($ProfileListKey -eq $null)
    {
        Write-Error "Failed to open registry path: $RegistryPath on $ComputerName."
        return
    }

    $ProfileRegistryItems = foreach ($sid in $ProfileListKey.GetSubKeyNames())
    {
        # Use Open-RegistrySubKey to get the subkey for the SID
        $subKey = Open-RegistrySubKey -ParentKey $ProfileListKey -SubKeyName $sid

        if ($subKey -eq $null)
        {
            Write-Warning "Registry key for SID '$sid' could not be opened."
            continue
        }

        # Use Get-ProfilePathFromSID to get the ProfileImagePath for the SID
        $profilePath = Get-ProfilePathFromSID -SidKey $subKey

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
