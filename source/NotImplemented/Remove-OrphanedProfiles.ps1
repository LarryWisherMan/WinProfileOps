<#
.SYNOPSIS
    Removes orphaned user profiles from a specified computer.
.DESCRIPTION
    The Remove-OrphanedProfiles function identifies and removes orphaned profiles from the specified computer. Orphaned profiles are those that exist in the file system but not in the registry, or vice versa. The function can also optionally ignore special or default profiles.
.PARAMETER ComputerName
    The name of the computer from which orphaned profiles will be removed. This is a required parameter.
.PARAMETER ProfileFolderPath
    The path to the folder containing user profiles. Defaults to "$env:SystemDrive\Users".
.PARAMETER IgnoreSpecial
    Switch to ignore special or default profiles during the removal process.
.EXAMPLE
    Remove-OrphanedProfiles -ComputerName "Server01" -ProfileFolderPath "C:\Users" -IgnoreSpecial
    Removes orphaned profiles from "Server01", excluding special or default profiles.
.EXAMPLE
    Remove-OrphanedProfiles -ComputerName "Server01"
    Removes orphaned profiles from "Server01" using the default profile folder path "$env:SystemDrive\Users".
.NOTES
    This function supports 'ShouldProcess', allowing the use of -WhatIf or -Confirm to simulate the deletion process.
    The function first collects all orphaned profiles, identifies the SIDs associated with them, and then removes the corresponding registry entries.
#>

function Remove-OrphanedProfiles
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string]$ProfileFolderPath = $env:WinProfileOps_ProfileFolderPath,

        [switch]$IgnoreSpecial
    )

    # Step 1: Get the list of orphaned profiles
    $orphanedProfiles = Get-OrphanedProfiles-ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath -IgnoreSpecial

    if (-not $orphanedProfiles)
    {
        Write-Verbose "No orphaned profiles found on $ComputerName."
        return
    }

    # Step 2: Extract the SIDs of orphaned profiles that exist in the registry
    $orphanedSIDs = $orphanedProfiles | Where-Object { $_.SID } | Select-Object -ExpandProperty SID

    if (-not $orphanedSIDs)
    {
        Write-Verbose "No orphaned profiles with valid SIDs found for removal on $ComputerName."
        return
    }

    # Step 3: Remove profiles for the collected SIDs
    $removalResults = Remove-ProfilesForSIDs -SIDs $orphanedSIDs -ComputerName $ComputerName -Confirm:$false

    # Step 4: Return the results of the removal process
    return $removalResults
}
