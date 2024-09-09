function Remove-OrphanedProfiles {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string]$ProfileFolderPath = "C:\Users",

        [switch]$IgnoreSpecial
    )

    # Step 1: Get the list of orphaned profiles
    $orphanedProfiles = Get-OrphanedProfiles-ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath -IgnoreSpecial

    if (-not $orphanedProfiles) {
        Write-Verbose "No orphaned profiles found on $ComputerName."
        return
    }

    # Step 2: Extract the SIDs of orphaned profiles that exist in the registry
    $orphanedSIDs = $orphanedProfiles | Where-Object { $_.SID } | Select-Object -ExpandProperty SID

    if (-not $orphanedSIDs) {
        Write-Verbose "No orphaned profiles with valid SIDs found for removal on $ComputerName."
        return
    }

    # Step 3: Remove profiles for the collected SIDs
    $removalResults = Remove-ProfilesForSIDs -SIDs $orphanedSIDs -ComputerName $ComputerName -Confirm:$false

    # Step 4: Return the results of the removal process
    return $removalResults
}
