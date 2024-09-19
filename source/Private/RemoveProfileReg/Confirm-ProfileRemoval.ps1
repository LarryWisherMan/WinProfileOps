function Confirm-ProfileRemoval
{
    param (
        [string]$SID,
        [Microsoft.Win32.RegistryKey]$BaseKey
    )

    try
    {
        return ($BaseKey.GetSubKeyNames() -notcontains $SID)
    }
    catch
    {
        Write-Error "Error verifying profile removal for SID $SID`: $_"
        return $false
    }
}
