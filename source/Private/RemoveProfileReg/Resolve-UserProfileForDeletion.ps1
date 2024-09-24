<#
.SYNOPSIS
Finds the user profile for a specific SID in an audit result.

.DESCRIPTION
The `Resolve-UserProfileForDeletion` function searches through audit results to find the profile associated with a given SID. If the profile is not found, a warning is logged, and a `ProfileDeletionResult` is returned indicating failure.

.PARAMETER SID
Specifies the Security Identifier (SID) of the profile to search for.

.PARAMETER AuditResults
Specifies the audit results to search for the profile.

.PARAMETER ComputerName
Specifies the name of the computer where the profile is located.

.EXAMPLE
Resolve-UserProfileForDeletion -SID 'S-1-5-21-...' -AuditResults $AuditResults -ComputerName 'Server01'

Description:
Finds the user profile associated with the specified SID in the audit results for Server01.

.OUTPUTS
UserProfile or ProfileDeletionResult object.
#>
function Resolve-UserProfileForDeletion
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$SID, # The SID to search for
        [Parameter(Mandatory = $false)]
        [UserProfile[]]$AuditResults, # The audit results
        [Parameter(Mandatory = $true)]
        [string]$ComputerName       # The target computer name
    )

    # Find the corresponding user profile from the audit
    $SelectedProfile = $AuditResults | Where-Object { $_.SID -eq $SID }

    # Handle cases where profile is not found
    if ($null -eq $SelectedProfile)
    {
        # Determine if it's an invalid SID or just not found
        $message = if (Validate-SIDFormat -SID $SID)
        {
            "Profile not found"
            Write-Warning "Profile not found for SID: $SID on $ComputerName."
        }
        else
        {
            "Invalid SID format encountered"
            Write-Warning "Invalid SID format encountered: $SID on $ComputerName."
        }

        # Return a ProfileDeletionResult if the profile is not found or invalid
        return New-ProfileDeletionResult -SID $SID -ProfilePath $null -DeletionSuccess $false -DeletionMessage $message -ComputerName $ComputerName
    }

    # If profile is found, return the UserProfile object
    return $SelectedProfile
}
