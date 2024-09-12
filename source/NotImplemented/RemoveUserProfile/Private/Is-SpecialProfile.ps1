function Is-SpecialProfile
{
    param (
        [string]$FolderName,
        [string]$SID,
        [string]$ProfilePath
    )

    return Test-SpecialAccount -FolderName $FolderName -SID $SID -ProfilePath $ProfilePath
}
