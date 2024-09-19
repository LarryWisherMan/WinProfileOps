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
