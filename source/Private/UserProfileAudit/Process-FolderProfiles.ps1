<#
.SYNOPSIS
    Processes user profile folders to identify profiles missing in the registry.

.DESCRIPTION
    The Process-FolderProfiles function compares user profiles found in the file system (folders)
    against those found in the registry. It identifies folder profiles that do not have a corresponding
    entry in the registry and marks them as orphaned. The function also allows the option to ignore
    special or default profiles, such as system or service accounts.

.PARAMETER UserFolders
    An array of user profile folders found in the file system (e.g., C:\Users).

.PARAMETER RegistryProfiles
    An array of user profiles found in the registry.

.PARAMETER ComputerName
    The name of the computer being audited for user profiles.

.PARAMETER IgnoreSpecial
    Switch to ignore special or default profiles (such as system or service accounts) during processing.

.OUTPUTS
    [UserProfile[]]
    Returns an array of UserProfile objects representing user profiles found in the file system but missing in the registry.

.EXAMPLE
    $userFolders = Get-UserProfilesFromFolders -ComputerName "Server01"
    $registryProfiles = Get-UserProfilesFromRegistry -ComputerName "Server01"
    Process-FolderProfiles -UserFolders $userFolders -RegistryProfiles $registryProfiles -ComputerName "Server01"

    Processes the user profile folders on "Server01" to identify any profiles missing from the registry.

.EXAMPLE
    Process-FolderProfiles -UserFolders $folders -RegistryProfiles $registryProfiles -ComputerName "Server01" -IgnoreSpecial

    Processes the user profile folders on "Server01" while ignoring special or system profiles.

.NOTES
    This function compares profiles in the file system with those in the registry to identify orphaned
    profiles that exist only in the file system. Special profiles can be ignored with the -IgnoreSpecial switch.
#>
function Process-FolderProfiles
{
    [OutputType ([UserProfile[]])]
    param (
        [array]$UserFolders,
        [array]$RegistryProfiles,
        [string]$ComputerName,
        [switch]$IgnoreSpecial
    )

    $processedProfiles = @()

    foreach ($folder in $UserFolders)
    {
        $registryProfile = $RegistryProfiles | Where-Object { $_.ProfilePath -eq $folder.ProfilePath }
        $isSpecial = Test-SpecialAccount -FolderName $folder.FolderName -SID $null -ProfilePath $folder.ProfilePath

        if ($IgnoreSpecial -and $isSpecial)
        {
            continue
        }

        if (-not $registryProfile)
        {
            $processedProfiles += New-UserProfileObject $null $folder.ProfilePath $true "MissingRegistryEntry" $ComputerName $isSpecial
        }
    }

    return $processedProfiles
}
