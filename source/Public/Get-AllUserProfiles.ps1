<#
.SYNOPSIS
    Retrieves all user profiles from both the registry and file system on a specified computer.
.DESCRIPTION
    The Get-AllUserProfiles function collects user profile information from both the file system (profile folders) and the registry on the specified computer. It compares the two sets of profiles, identifying orphaned profiles that exist in one location but not the other. The function also allows the option to ignore special or default profiles, such as system or service accounts.
.PARAMETER ComputerName
    The name of the computer from which to retrieve user profiles. Defaults to the local computer.
.PARAMETER ProfileFolderPath
    The folder path where user profiles are stored. Defaults to "$env:SystemDrive\Users".
.PARAMETER IgnoreSpecial
    Switch to ignore special or default profiles during the profile retrieval process.
.EXAMPLE
    Get-AllUserProfiles -ComputerName "Server01"
    Retrieves all user profiles from both the file system and registry on "Server01".
.EXAMPLE
    Get-AllUserProfiles -ProfileFolderPath "D:\UserProfiles" -IgnoreSpecial
    Retrieves user profiles from the specified folder and ignores special or default profiles.
.NOTES
    This function compares user profiles found in the file system and the registry to identify orphaned profiles.
    It supports pipeline input for multiple computer names, allowing you to retrieve profiles from multiple systems.
    Special or default profiles, such as system accounts, can be ignored by using the -IgnoreSpecial parameter.
#>
function Get-AllUserProfiles
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [string]$ProfileFolderPath = "$env:SystemDrive\Users",
        [switch]$IgnoreSpecial
    )

    # Begin block runs once before processing pipeline input
    begin
    {
        # Initialize an array to hold all UserProfile objects across multiple pipeline inputs
        $AllProfiles = @()
    }

    # Process block runs once for each input object (in case of pipeline)
    process
    {
        # Test if the computer is online before proceeding
        if (-not (Test-ComputerPing -ComputerName $ComputerName))
        {
            Write-Warning "Computer '$ComputerName' is offline or unreachable."
            return  # Skip to the next input in the pipeline
        }

        # Get profiles from folders and registry
        $UserFolders = Get-UserProfilesFromFolders -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath
        $RegistryProfiles = Get-UserProfilesFromRegistry -ComputerName $ComputerName

        # Loop through registry profiles and check for folder existence and ProfileImagePath
        foreach ($regProfile in $RegistryProfiles)
        {
            $profilePath = $regProfile.ProfilePath
            $folderExists = Test-FolderExists -ProfilePath $profilePath -ComputerName $regProfile.ComputerName
            $folderName = Split-Path -Path $profilePath -Leaf
            $isSpecial = Test-SpecialAccount -FolderName $folderName -SID $regProfile.SID -ProfilePath $profilePath

            # Skip special profiles if IgnoreSpecial is set
            if ($IgnoreSpecial -and $isSpecial)
            {
                continue
            }

            # Detect if the profile is orphaned and create the user profile object
            $userProfile = Test-OrphanedProfile -SID $regProfile.SID -ProfilePath $profilePath `
                -FolderExists $folderExists -IgnoreSpecial $IgnoreSpecial `
                -IsSpecial $isSpecial -ComputerName $ComputerName
            $AllProfiles += $userProfile
        }

        # Loop through user folders and check if they exist in the registry
        foreach ($folder in $UserFolders)
        {
            $registryProfile = $RegistryProfiles | Where-Object { $_.ProfilePath -eq $folder.ProfilePath }
            $isSpecial = Test-SpecialAccount -FolderName $folder.FolderName -SID $null -ProfilePath $folder.ProfilePath

            # Skip special profiles if IgnoreSpecial is set
            if ($IgnoreSpecial -and $isSpecial)
            {
                continue
            }

            # Case 4: Folder exists in C:\Users but not in the registry
            if (-not $registryProfile)
            {
                $AllProfiles += New-UserProfileObject $null $folder.ProfilePath $true "MissingRegistryEntry" $ComputerName $isSpecial
            }
        }
    }

    # End block runs once after all processing is complete
    end
    {
        # Output all collected profiles
        $AllProfiles
    }
}
