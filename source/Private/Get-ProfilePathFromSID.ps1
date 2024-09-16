<#
.SYNOPSIS
    Retrieves the profile path associated with a specific SID from the registry.
.DESCRIPTION
    The Get-ProfilePathFromSID function retrieves the "ProfileImagePath" registry value for the provided SID registry key. This path indicates the location of the user profile associated with the SID.
.PARAMETER SidKey
    The registry key representing the Security Identifier (SID) from which to retrieve the profile path.
.EXAMPLE
    Get-ProfilePathFromSID -SidKey $sidKey
    Retrieves the profile path for the given SID from the registry.
.NOTES
    If the "ProfileImagePath" cannot be found, the function will return `$null` and a verbose message will indicate the issue.
    In case of an error during retrieval, an error message is logged and the function returns `$null`.
#>
function Get-ProfilePathFromSID
{
    param (
        [Microsoft.Win32.RegistryKey]$SidKey
    )

    try
    {
        # Use Get-RegistryValue to retrieve the "ProfileImagePath"
        $profileImagePath = Get-RegistryValue -BaseKey $SidKey -ValueName "ProfileImagePath"

        if (-not $profileImagePath)
        {
            Write-Verbose "ProfileImagePath not found for SID '$($SidKey.Name)'."
        }

        return $profileImagePath
    }
    catch
    {
        Write-Error "Failed to retrieve ProfileImagePath for SID '$($SidKey.Name)'. Error: $_"
        return $null
    }
}
