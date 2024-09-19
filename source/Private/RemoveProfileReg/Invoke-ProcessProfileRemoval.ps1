# Main function to process profile removal
function Invoke-ProcessProfileRemoval
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [string]$SID,
        [Microsoft.Win32.RegistryKey]$BaseKey,
        [string]$ComputerName,
        [UserProfile]$SelectedProfile, # Now expecting a UserProfile object
        [switch]$AuditOnly
    )

    try
    {
        # Prepare the properties for the deletion result
        $deletionResultParams = @{
            SID             = $SelectedProfile.SID
            ProfilePath     = $SelectedProfile.ProfilePath
            ComputerName    = $ComputerName
            DeletionSuccess = $false
            DeletionMessage = "Profile not removed."
        }

        if ($AuditOnly)
        {
            $deletionResultParams.DeletionSuccess = $true
            $deletionResultParams.DeletionMessage = "Audit only, no deletion performed."
            return New-ProfileDeletionResult @deletionResultParams
        }

        # Get the directory path for backup
        $RegBackUpDirectory = Get-DirectoryPath -basePath $env:WinProfileOps_RegBackUpDirectory -ComputerName $ComputerName -IsLocal ($ComputerName -eq $env:COMPUTERNAME)

        if ($PSCmdlet.ShouldProcess("Profile for SID $SID on $ComputerName", "Remove Profile"))
        {
            # Backup the registry key
            if (-not (Backup-RegistryKeyForSID -SID $SID -BaseKey $BaseKey -RegBackUpDirectory $RegBackUpDirectory -ComputerName $ComputerName ))
            {
                $deletionResultParams.DeletionMessage = "Failed to backup profile."
                return New-ProfileDeletionResult @deletionResultParams
            }

            # Remove the registry key
            if (-not (Remove-ProfileRegistryKey -SID $SID -BaseKey $BaseKey))
            {
                $deletionResultParams.DeletionMessage = "Failed to remove profile registry key."
                return New-ProfileDeletionResult @deletionResultParams
            }

            # Verify the removal
            if (Confirm-ProfileRemoval -SID $SID -BaseKey $BaseKey)
            {
                $deletionResultParams.DeletionSuccess = $true
                $deletionResultParams.DeletionMessage = "Profile removed successfully."
            }
        }

        return New-ProfileDeletionResult @deletionResultParams
    }
    catch
    {
        Write-Error "Error processing profile removal for SID $SID`: $_"
        $deletionResultParams.DeletionMessage = "Error during removal."
        return New-ProfileDeletionResult @deletionResultParams
    }
}

# Helper function to process removal by SID
