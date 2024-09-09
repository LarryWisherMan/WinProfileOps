function Remove-ProfilesForSIDs {
    #Orchestrates the deletion process for multiple SIDs.
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$SIDs,  # Accept multiple SIDs as an array

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME  # Default to local computer
    )

    # Open the ProfileList registry key
    $RegistryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    $ProfileListKey = Open-RegistryKey -RegistryPath $RegistryPath -ComputerName $ComputerName

    if ($ProfileListKey -eq $null) {
        Write-Error "Failed to open ProfileList registry path on $ComputerName."
        return
    }

    $deletionResults = @()

    # Loop through each SID and process deletion
    foreach ($sid in $SIDs) {
        try {
            # Get profile information for the SID
            $sidProfileInfo = Get-SIDProfileInfo -SID $sid -ProfileListKey $ProfileListKey

            if (-not $sidProfileInfo.ExistsInRegistry) {
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
        } catch {
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
