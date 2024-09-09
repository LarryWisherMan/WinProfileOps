function Remove-SIDProfile {
    #Coordinates the registry key deletion and provides a result for a single SID.
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    param (
        [string]$SID,
        [Microsoft.Win32.RegistryKey]$ProfileListKey,
        [string]$ComputerName,
        [string]$ProfilePath
    )

    # Attempt to remove the registry key
    $deletionSuccess = Remove-RegistryKeyForSID -SID $SID -ProfileListKey $ProfileListKey -ComputerName $ComputerName

    if ($deletionSuccess) {
        return [ProfileDeletionResult]::new(
            $SID,
            $ProfilePath,
            $true,
            "Profile registry key for SID '$SID' successfully deleted.",
            $ComputerName
        )
    } else {
        return [ProfileDeletionResult]::new(
            $SID,
            $ProfilePath,
            $false,
            "Failed to delete the profile registry key for SID '$SID'.",
            $ComputerName
        )
    }
}
