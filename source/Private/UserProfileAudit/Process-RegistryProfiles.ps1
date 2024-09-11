function Process-RegistryProfiles
{
    param (
        [array]$RegistryProfiles,
        [string]$ComputerName,
        [switch]$IgnoreSpecial
    )

    $processedProfiles = @()

    foreach ($regProfile in $RegistryProfiles)
    {
        $profilePath = $regProfile.ProfilePath
        $folderExists = Test-FolderExists -ProfilePath $profilePath -ComputerName $ComputerName
        $folderName = Split-Path -Path $profilePath -Leaf
        $isSpecial = Test-SpecialAccount -FolderName $folderName -SID $regProfile.SID -ProfilePath $profilePath

        if ($IgnoreSpecial -and $isSpecial)
        {
            continue
        }

        $userProfile = Test-OrphanedProfile -SID $regProfile.SID -ProfilePath $profilePath `
            -FolderExists $folderExists -IgnoreSpecial $IgnoreSpecial `
            -IsSpecial $isSpecial -ComputerName $ComputerName
        $processedProfiles += $userProfile
    }

    return $processedProfiles
}
