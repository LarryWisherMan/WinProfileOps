<#
.SYNOPSIS
    Processes user profiles found in the registry to identify orphaned profiles.

.DESCRIPTION
    The Process-RegistryProfiles function compares user profiles found in the registry against the
    corresponding profile folders on the file system. It identifies registry profiles that are orphaned,
    meaning they exist in the registry but are missing in the file system. The function also provides an
    option to ignore special or default profiles, such as system or service accounts.

.PARAMETER RegistryProfiles
    An array of user profiles retrieved from the registry.

.PARAMETER ComputerName
    The name of the computer being audited for user profiles.

.PARAMETER IgnoreSpecial
    Switch to ignore special or default profiles (such as system or service accounts) during processing.

.OUTPUTS
    [UserProfile[]]
    Returns an array of UserProfile objects representing user profiles found in the registry but missing in the file system.

.EXAMPLE
    $registryProfiles = Get-UserProfilesFromRegistry -ComputerName "Server01"
    Process-RegistryProfiles -RegistryProfiles $registryProfiles -ComputerName "Server01"

    Processes the registry profiles on "Server01" to identify any profiles that are orphaned in the registry.

.EXAMPLE
    Process-RegistryProfiles -RegistryProfiles $registryProfiles -ComputerName "Server01" -IgnoreSpecial

    Processes the registry profiles on "Server01" while ignoring special or system profiles.

.NOTES
    This function compares profiles in the registry with their corresponding profile folders on the file system
    to identify orphaned profiles that exist only in the registry. Special profiles can be ignored with the -IgnoreSpecial switch.
#>
function Process-RegistryProfiles
{
    [OutputType ([UserProfile[]])]
    param (
        [array]$RegistryProfiles,
        [string]$ComputerName,
        [switch]$IgnoreSpecial
    )

    $processedProfiles = @()

    foreach ($regProfile in $RegistryProfiles)
    {
        $profilePath = $regProfile.ProfilePath
        $folderExists = $null
        $accessError = $false

        $isSpecial = Test-SpecialAccount -FolderName $folderName -SID $regProfile.SID -ProfilePath $profilePath

        if ($IgnoreSpecial -and $isSpecial)
        {
            continue
        }

        try
        {
            $folderExists = Test-FolderExists -ProfilePath $profilePath -ComputerName $ComputerName -ErrorAction Stop
        }
        catch [UnauthorizedAccessException]
        {
            $folderExists = $false
            $accessError = $true
        }
        catch
        {
            $folderExists = $false
            Write-Warning "Error testing folder existence for profile: $profilePath. Error: $_"
        }

        $folderName = Split-Path -Path $profilePath -Leaf

        $userProfile = Test-OrphanedProfile -SID $regProfile.SID -ProfilePath $profilePath `
            -FolderExists $folderExists -AccessError $accessError -IgnoreSpecial $IgnoreSpecial `
            -IsSpecial $isSpecial -ComputerName $ComputerName

        # Add this line to include the user profile in the processed array
        $processedProfiles += $userProfile
    }

    return $processedProfiles
}
