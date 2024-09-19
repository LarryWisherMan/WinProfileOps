<#
.SYNOPSIS
Processes actions for a specific user profile identified by SID.

.DESCRIPTION
The Invoke-SingleProfileAction function processes profile actions such as removal for a specific
user profile, using the SID. The function can audit or remove profiles depending on the parameters passed.

.PARAMETER ComputerName
The name of the computer where the profile resides.

.PARAMETER SID
The Security Identifier (SID) of the user profile to process.

.PARAMETER AuditResults
The results of the audit for the user profiles on the computer.

.PARAMETER SelectedProfile
(Optional) The user profile object if it's already resolved. If not provided, the function will attempt to resolve it.

.PARAMETER BaseKey
The registry key for the profile in the registry.

.PARAMETER DeletionResults
A reference to the array that will store the results of the profile removal operation.

.PARAMETER Force
A switch to bypass confirmation prompts for profile removal.

.PARAMETER AuditOnly
A switch to only audit the profile without removing it.

.EXAMPLE
Invoke-SingleProfileAction -SID 'S-1-5-21-1234567890-1' -AuditResults $auditResults -BaseKey $baseKey -DeletionResults ([ref]$results)

This command processes the profile for the specified SID, auditing or removing it based on the flags passed.

.OUTPUTS
ProfileDeletionResult object that includes information about the profile processing result.

.NOTES
This function should be used in scenarios where profiles need to be audited or removed from the registry.
#>

function Invoke-SingleProfileAction
{
    param (
        [string]$ComputerName,
        [string]$SID,
        [UserProfile[]]$AuditResults,
        [UserProfile]$SelectedProfile = $null,
        [Microsoft.Win32.RegistryKey]$BaseKey,
        [ref]$DeletionResults, # Pass by reference
        [switch]$Force,
        [switch]$AuditOnly,
        [bool]$Confirm
    )

    # If $SelectedProfile is null, resolve it using Resolve-UserProfileForDeletion
    if (-not $SelectedProfile)
    {
        $SelectedProfile = Resolve-UserProfileForDeletion -SID $SID -AuditResults $AuditResults -ComputerName $ComputerName
    }

    if ($SelectedProfile -is [ProfileDeletionResult])
    {
        $DeletionResults.Value += $SelectedProfile
    }
    # If Force is not used, prompt the user with ShouldContinue
    elseif ($Force -or $PSCmdlet.ShouldContinue(
            "Remove profile for SID $SID on $($SelectedProfile.ComputerName)?", # Query (shorter message)
            "Confirm Deletion of Profile for User $($SelectedProfile.GetUserNameFromPath())" # Caption (more detailed message)
        ))
    {
        # Call the actual removal function
        $result = Invoke-ProcessProfileRemoval -SID $SID -SelectedProfile $SelectedProfile -BaseKey $BaseKey -AuditOnly:$AuditOnly -ComputerName $ComputerName -confirm:$Confirm

        # Append result to DeletionResults
        $DeletionResults.Value += $result
    }
}
