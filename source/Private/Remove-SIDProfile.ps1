<#
.SYNOPSIS
    Removes a profile for a specific SID by deleting its registry key.
.DESCRIPTION
    The Remove-SIDProfile function attempts to delete the profile registry key for the specified SID. It returns a ProfileDeletionResult object indicating whether the deletion was successful or not.
.PARAMETER SID
    The Security Identifier (SID) for the profile to be removed.
.PARAMETER ProfileListKey
    The opened registry key for the ProfileList where the profile's SID is located.
.PARAMETER ComputerName
    The name of the computer where the registry key will be deleted.
.PARAMETER ProfilePath
    The file path of the profile to be deleted.
.EXAMPLE
    Remove-SIDProfile -SID "S-1-5-21-123456789-1001" -ProfileListKey $profileListKey -ComputerName "Server01" -ProfilePath "C:\Users\John"
    Removes the profile associated with the specified SID from "Server01".
#>

function Remove-SIDProfile
{
    #Coordinates the registry key deletion and provides a result for a single SID.
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [string]$SID,
        [Microsoft.Win32.RegistryKey]$ProfileListKey,
        [string]$ComputerName,
        [string]$ProfilePath
    )

    # Attempt to remove the registry key
    $deletionSuccess = Remove-RegistryKeyForSID -SID $SID -ProfileListKey $ProfileListKey -ComputerName $ComputerName

    if ($deletionSuccess)
    {
        return [ProfileDeletionResult]::new(
            $SID,
            $ProfilePath,
            $true,
            "Profile registry key for SID '$SID' successfully deleted.",
            $ComputerName
        )
    }
    else
    {
        return [ProfileDeletionResult]::new(
            $SID,
            $ProfilePath,
            $false,
            "Failed to delete the profile registry key for SID '$SID'.",
            $ComputerName
        )
    }
}
