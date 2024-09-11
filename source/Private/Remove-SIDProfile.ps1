<#
.SYNOPSIS
    Coordinates the deletion of a profile registry key for a given SID.

.DESCRIPTION
    The Remove-SIDProfile function removes the registry key associated with a specific Security Identifier (SID) from the ProfileList on the specified computer. It supports confirmation prompts and -WhatIf scenarios by using the ShouldProcess pattern. The function also handles errors that occur during the deletion process and returns a ProfileDeletionResult object indicating success or failure.

.PARAMETER SID
    The Security Identifier (SID) of the profile to be deleted.

.PARAMETER ProfileListKey
    The registry key representing the ProfileList from which the SID's registry key will be removed.

.PARAMETER ComputerName
    The name of the computer where the profile registry key resides. Defaults to the current computer.

.PARAMETER ProfilePath
    The file path of the profile to be deleted, used for logging purposes in the ProfileDeletionResult object.

.OUTPUTS
    [ProfileDeletionResult]
    An object that indicates whether the profile registry key was successfully deleted or if the action was skipped or failed. Includes the SID, ProfilePath, DeletionSuccess status, DeletionMessage, and ComputerName.

.EXAMPLE
    Remove-SIDProfile -SID "S-1-5-21-123456789-1001" -ProfileListKey $profileListKey -ComputerName "Server01" -ProfilePath "C:\Users\John"
    Removes the registry key for the specified SID from the ProfileList on "Server01" and deletes the profile.

.EXAMPLE
    Remove-SIDProfile -SID "S-1-5-21-123456789-1001" -ProfileListKey $profileListKey -ProfilePath "C:\Users\John" -WhatIf
    Simulates the removal of the profile registry key for the specified SID using the -WhatIf parameter, showing what would have been done without performing the action.

.NOTES
    - The function supports 'ShouldProcess', allowing the use of -WhatIf and -Confirm parameters for safety.
    - In case of an error, the function returns a ProfileDeletionResult object with DeletionSuccess set to $false and logs the error message.
    - If the action is skipped (e.g., due to -WhatIf or confirmation denial), the function returns a ProfileDeletionResult with a status indicating that the action was skipped.
#>

function Remove-SIDProfile
{
    [outputtype([ProfileDeletionResult])]
    # Coordinates the registry key deletion and provides a result for a single SID.
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [string]$SID,
        [Microsoft.Win32.RegistryKey]$ProfileListKey,
        [string]$ComputerName,
        [string]$ProfilePath
    )

    try
    {
        # Use ShouldProcess to check if the action should proceed (with -WhatIf and -Confirm support)
        if ($PSCmdlet.ShouldProcess("SID: $SID on $ComputerName", "Remove profile registry key"))
        {
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
        else
        {
            Write-Verbose "Removal of profile registry key for SID '$SID' on '$ComputerName' was skipped."
            return [ProfileDeletionResult]::new(
                $SID,
                $ProfilePath,
                $false,
                "Action skipped.",
                $ComputerName
            )
        }
    }
    catch
    {
        Write-Error "Failed to remove the profile registry key for SID '$SID' on $ComputerName. Error: $_"
        return [ProfileDeletionResult]::new(
            $SID,
            $ProfilePath,
            $false,
            "Failed to delete the profile registry key for SID '$SID'. Error: $_",
            $ComputerName
        )
    }
}
