function Get-SIDProfileInfo {
    [CmdletBinding()]
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $RegistryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    $ProfileListKey = Open-RegistryKey -RegistryPath $RegistryPath -ComputerName $ComputerName

    if ($ProfileListKey -eq $null) {
        Write-Error "Failed to open registry path: $RegistryPath on $ComputerName."
        return
    }

    $ProfileRegistryItems = foreach ($sid in $ProfileListKey.GetSubKeyNames()) {
        # Use Open-RegistrySubKey to get the subkey for the SID
        $subKey = Open-RegistrySubKey -ParentKey $ProfileListKey -SubKeyName $sid

        if ($subKey -eq $null) {
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
