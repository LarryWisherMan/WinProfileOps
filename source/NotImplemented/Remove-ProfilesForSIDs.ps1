
<#
.SYNOPSIS
    Orchestrates the deletion process for multiple profiles by SID.
.DESCRIPTION
    The Remove-ProfilesForSIDs function removes profiles for multiple Security Identifiers (SIDs) from the ProfileList in the Windows registry. It loops through each SID provided, attempts to delete the associated profile, and returns the results of each deletion.
    If a profile cannot be found in the registry, the function will return a result indicating that the profile was not found.
.PARAMETER SIDs
    An array of Security Identifiers (SIDs) for which the profile registry keys will be deleted.
.PARAMETER ComputerName
    The name of the computer where the profiles reside. By default, this is the local computer.
.EXAMPLE
    Remove-ProfilesForSIDs -SIDs "S-1-5-21-123456789-1001", "S-1-5-21-123456789-1002" -ComputerName "Server01"
    Deletes the profiles associated with the specified SIDs from the registry on "Server01" and returns the results of each deletion.
.NOTES
    This function supports 'ShouldProcess', allowing the use of -WhatIf or -Confirm to simulate the deletion process.
    Each profile deletion is handled individually, with errors caught and returned in the final result.
#>

function Remove-ProfilesForSIDs
{
    #Orchestrates the deletion process for multiple SIDs.
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$SIDs, # Accept multiple SIDs as an array

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME  # Default to local computer
    )

    # Open the ProfileList registry key
    $RegistryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    $ProfileListKey = Open-RegistryKey -RegistryPath $RegistryPath -ComputerName $ComputerName

    if ($ProfileListKey -eq $null)
    {
        Write-Error "Failed to open ProfileList registry path on $ComputerName."
        return
    }

    $deletionResults = @()

    # Loop through each SID and process deletion
    foreach ($sid in $SIDs)
    {
        try
        {
            # Get profile information for the SID
            $sidProfileInfo = Get-SIDProfileInfo -SID $sid -ProfileListKey $ProfileListKey

            if (-not $sidProfileInfo.ExistsInRegistry)
            {
                $deletionResults += [ProfileDeletionResult]::new(
                    $sid,
                    $null,
                    $false,
                    $sidProfileInfo.Message,
                    $ComputerName
                )
                continue
            }

            # Process the deletion of the profile for the SID
            $deletionResult = Remove-SIDProfile -SID $sid `
                -ProfileListKey $ProfileListKey `
                -ComputerName $ComputerName `
                -ProfilePath $sidProfileInfo.ProfilePath

            $deletionResults += $deletionResult
        }
        catch
        {
            Write-Error "An error occurred while processing SID '$sid'. $_"

            # Add a deletion result indicating failure due to error
            $deletionResults += [ProfileDeletionResult]::new(
                $sid,
                $null,
                $false,
                "Error occurred while processing SID '$sid'. Error: $_",
                $ComputerName
            )
        }
    }

    # Close the registry key when done
    $ProfileListKey.Close()

    # Return the array of deletion results
    return $deletionResults
}
