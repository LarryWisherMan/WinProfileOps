function Get-AllUserProfiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [string]$ProfileFolderPath = "C:\Users",
        [switch]$IgnoreSpecial
    )

    # Begin block runs once before processing pipeline input
    begin {
        # Initialize an array to hold all UserProfile objects across multiple pipeline inputs
        $AllProfiles = @()
    }

    # Process block runs once for each input object (in case of pipeline)
    process {
        # Test if the computer is online before proceeding
        if (-not (Test-ComputerPing -ComputerName $ComputerName)) {
            Write-Warning "Computer '$ComputerName' is offline or unreachable."
            return  # Skip to the next input in the pipeline
        }

        # Get profiles from folders and registry
        $UserFolders = Get-UserProfilesFromFolders -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath
        $RegistryProfiles = Get-UserProfilesFromRegistry -ComputerName $ComputerName

        # Loop through registry profiles and check for folder existence and ProfileImagePath
        foreach ($regProfile in $RegistryProfiles) {
            $profilePath = $regProfile.ProfilePath
            $folderExists = Test-FolderExists -ProfilePath $profilePath -ComputerName $regProfile.ComputerName
            $folderName = Split-Path -Path $profilePath -Leaf
            $isSpecial = Test-SpecialAccount -FolderName $folderName -SID $regProfile.SID -ProfilePath $profilePath

            # Skip special profiles if IgnoreSpecial is set
            if ($IgnoreSpecial -and $isSpecial) {
                continue
            }

            # Detect if the profile is orphaned and create the user profile object
            $userProfile = Test-OrphanedProfile -SID $regProfile.SID -ProfilePath $profilePath `
                                                  -FolderExists $folderExists -IgnoreSpecial $IgnoreSpecial `
                                                  -IsSpecial $isSpecial -ComputerName $ComputerName
            $AllProfiles += $userProfile
        }

        # Loop through user folders and check if they exist in the registry
        foreach ($folder in $UserFolders) {
            $registryProfile = $RegistryProfiles | Where-Object { $_.ProfilePath -eq $folder.ProfilePath }
            $isSpecial = Test-SpecialAccount -FolderName $folder.FolderName -SID $null -ProfilePath $folder.ProfilePath

            # Skip special profiles if IgnoreSpecial is set
            if ($IgnoreSpecial -and $isSpecial) {
                continue
            }

            # Case 4: Folder exists in C:\Users but not in the registry
            if (-not $registryProfile) {
                $AllProfiles += New-UserProfileObject $null $folder.ProfilePath $true "MissingRegistryEntry" $ComputerName $isSpecial
            }
        }
    }

    # End block runs once after all processing is complete
    end {
        # Output all collected profiles
        $AllProfiles
    }
}
