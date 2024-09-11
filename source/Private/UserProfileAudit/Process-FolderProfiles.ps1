function Process-FolderProfiles
{
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
