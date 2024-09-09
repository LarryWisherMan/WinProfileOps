function Test-OrphanedProfile {
    param (
        [string]$SID,
        [string]$ProfilePath,
        [bool]$FolderExists,
        [bool]$IgnoreSpecial,
        [bool]$IsSpecial,
        [string]$ComputerName
    )

    if (-not $ProfilePath) {
        return New-UserProfileObject $SID "(null)" $true "MissingProfileImagePath" $ComputerName $IsSpecial
    }
    elseif (-not $FolderExists) {
        return New-UserProfileObject $SID $ProfilePath $true "MissingFolder" $ComputerName $IsSpecial
    }
    else {
        return New-UserProfileObject $SID $ProfilePath $false $null $ComputerName $IsSpecial
    }
}
