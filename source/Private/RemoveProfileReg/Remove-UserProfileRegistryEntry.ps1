<#
.SYNOPSIS
Removes a user profile registry entry and backs up the registry data before deletion.

.DESCRIPTION
The `Remove-UserProfileRegistryEntry` function removes a user profile from the Windows registry. Before removal, it backs up the registry data to a specified directory. The function also supports audit mode, where no deletion occurs but an audit log is created.

.PARAMETER SelectedProfile
Specifies the user profile object representing the profile to be deleted.

.PARAMETER BaseKey
Specifies the base registry key under which the profile's SID subkey exists.

.PARAMETER AuditOnly
If specified, the function will only perform an audit and will not delete the registry entry.

.EXAMPLE
Remove-UserProfileRegistryEntry -SelectedProfile $Profile -BaseKey $RegistryKey -AuditOnly

Description:
Performs an audit of the profile without deleting it from the registry.

.OUTPUTS
ProfileDeletionResult object indicating the outcome of the deletion or audit operation.
#>

function Remove-UserProfileRegistryEntry
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [UserProfile]$SelectedProfile,
        [Microsoft.Win32.RegistryKey]$BaseKey,
        [switch]$AuditOnly
    )

    Process
    {
        # Prepare the deletion result parameters
        $deletionResultParams = @{
            SID             = $SelectedProfile.SID
            ProfilePath     = $SelectedProfile.ProfilePath
            ComputerName    = $SelectedProfile.ComputerName
            DeletionSuccess = $false
            DeletionMessage = "Profile not removed."
        }

        # Check if BaseKey is null
        if (-not $BaseKey)
        {
            $deletionResultParams.DeletionMessage = "Failed: BaseKey is null, cannot remove the profile."
            New-ProfileDeletionResult @deletionResultParams
            return  # Return early to stop further processing
        }

        # If in audit mode, output an audit-only result directly to the pipeline and return
        if ($AuditOnly)
        {
            $deletionResultParams.DeletionSuccess = $true
            $deletionResultParams.DeletionMessage = "Audit only, no deletion performed."
            New-ProfileDeletionResult @deletionResultParams
            return  # Return to allow pipeline to continue with the next item
        }

        # Determine backup directory
        $RegBackUpDirectory = Get-DirectoryPath -basePath $env:WinProfileOps_RegBackUpDirectory -ComputerName $SelectedProfile.ComputerName -IsLocal ($SelectedProfile.ComputerName -eq $env:COMPUTERNAME)

        # Backup the registry key, output failure message if backup fails and skip further processing
        if (-not (Backup-RegistryKeyForSID -SID $SelectedProfile.SID -BaseKey $BaseKey -RegBackUpDirectory $RegBackUpDirectory -ComputerName $SelectedProfile.ComputerName))
        {
            $deletionResultParams.DeletionMessage = "Failed to backup profile."
            New-ProfileDeletionResult @deletionResultParams
            return  # Return to allow pipeline to continue with the next item
        }

        # Remove the registry key, output failure message if removal fails
        if (-not (Remove-ProfileRegistryKey -SID $SelectedProfile.SID -BaseKey $BaseKey))
        {
            $deletionResultParams.DeletionMessage = "Failed to remove profile registry key."
            New-ProfileDeletionResult @deletionResultParams
            return  # Return to allow pipeline to continue with the next item
        }

        # Verify the removal and update the result
        if (Confirm-ProfileRemoval -SID $SelectedProfile.SID -BaseKey $BaseKey)
        {
            $deletionResultParams.DeletionSuccess = $true
            $deletionResultParams.DeletionMessage = "Profile removed successfully."
        }
        else
        {
            $deletionResultParams.DeletionMessage = "Profile removal verification failed."
        }

        # Output the final deletion result
        New-ProfileDeletionResult @deletionResultParams
    }
}
