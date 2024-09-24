<#
.SYNOPSIS
Removes a registry key associated with a specific SID.

.DESCRIPTION
The `Remove-ProfileRegistryKey` function deletes the registry key associated with a specified SID. If the operation fails, an error is logged.

.PARAMETER SID
Specifies the Security Identifier (SID) whose registry key is being removed.

.PARAMETER BaseKey
Specifies the base registry key under which the SID subkey exists.

.EXAMPLE
Remove-ProfileRegistryKey -SID 'S-1-5-21-...' -BaseKey $RegistryKey

Description:
Removes the registry key for the specified SID from the provided base key.

.OUTPUTS
Boolean indicating whether the registry key was successfully removed.
#>

function Remove-ProfileRegistryKey
{
    param (
        [string]$SID,
        [Microsoft.Win32.RegistryKey]$BaseKey
    )

    try
    {
        Remove-RegistrySubKey -ParentKey $BaseKey -SubKeyName $SID -ThrowOnMissingSubKey $false -Confirm:$false
        return $true
    }
    catch
    {
        Write-Error "Error removing registry key for SID $SID`: $_"
        return $false
    }
}
