function Remove-RegistryKeyForSID {
    #Deletes a single registry key for a SID.
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SID,

        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$ProfileListKey,

        [Parameter(Mandatory = $true)]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try {
        # Use the general Remove-RegistrySubKey function to delete the SID's subkey
        return Remove-RegistrySubKey -ParentKey $ProfileListKey -SubKeyName $SID -ComputerName $ComputerName
    } catch {
        Write-Error "Failed to remove the profile registry key for SID '$SID' on $ComputerName. Error: $_"
        return $false
    }
}
