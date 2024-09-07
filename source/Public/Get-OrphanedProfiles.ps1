function Get-OrphanedProfiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$ProfileFolderPath = "C:\Users",

        [switch]$IgnoreSpecial
    )

    # Get all user profiles (both registry and filesystem) using the existing function
    $allProfiles = Get-AllUserProfiles -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath -IgnoreSpecial

    # Filter the profiles to return only orphaned ones
    $orphanedProfiles = $allProfiles | Where-Object { $_.IsOrphaned -eq $true }

    # Return the orphaned profiles
    return $orphanedProfiles
}
