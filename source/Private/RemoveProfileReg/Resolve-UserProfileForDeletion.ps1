function Resolve-UserProfileForDeletion
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$SID, # The SID to search for
        [Parameter(Mandatory = $true)]
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
