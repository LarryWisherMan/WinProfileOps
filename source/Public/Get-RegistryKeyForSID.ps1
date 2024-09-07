function Get-RegistryKeyForSID {
    param (
        [string]$SID,
        [Microsoft.Win32.RegistryKey]$ProfileListKey
    )

    try {
        # Use the general Open-RegistrySubKey function to get the subkey for the SID
        $sidKey = Open-RegistrySubKey -ParentKey $ProfileListKey -SubKeyName $SID
        if ($sidKey -eq $null) {
            Write-Warning "The SID '$SID' does not exist in the ProfileList registry."
            return $null
        }
        return $sidKey
    } catch {
        Write-Error "Error accessing registry key for SID '$SID'. Error: $_"
        return $null
    }
}
