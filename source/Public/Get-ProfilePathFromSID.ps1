function Get-ProfilePathFromSID {
    param (
        [Microsoft.Win32.RegistryKey]$SidKey
    )

    try {
        # Use Get-RegistryValue to retrieve the "ProfileImagePath"
        $profileImagePath = Get-RegistryValue -Key $SidKey -ValueName "ProfileImagePath"

        if (-not $profileImagePath) {
            Write-Verbose "ProfileImagePath not found for SID '$($SidKey.Name)'."
        }

        return $profileImagePath
    } catch {
        Write-Error "Failed to retrieve ProfileImagePath for SID '$($SidKey.Name)'. Error: $_"
        return $null
    }
}
