<#
.SYNOPSIS
    Tests whether a profile is orphaned.
.DESCRIPTION
    The Test-OrphanedProfile function checks if a profile is orphaned by evaluating the profile path, folder existence, and whether it's a special account.
.PARAMETER SID
    The Security Identifier (SID) of the profile being tested.
.PARAMETER ProfilePath
    The file path of the profile folder.
.PARAMETER FolderExists
    Indicates whether the profile folder exists on the computer.
.PARAMETER AccessError
    Indicates whether an access error occurred while testing the profile folder.
.PARAMETER IgnoreSpecial
    Switch to ignore special or default profiles when determining if the profile is orphaned.
.PARAMETER IsSpecial
    Indicates whether the profile is a special account.
.PARAMETER ComputerName
    The name of the computer where the profile is being tested.
.EXAMPLE
    Test-OrphanedProfile -SID "S-1-5-21-123456789-1001" -ProfilePath "C:\Users\John" -FolderExists $true -IgnoreSpecial -IsSpecial $false -ComputerName "Server01"
    Tests if the profile associated with the given SID is orphaned on "Server01".
#>
function Test-OrphanedProfile
{
    param (
        [string]$SID,
        [string]$ProfilePath,
        [bool]$FolderExists,
        [bool]$AccessError,
        [bool]$IgnoreSpecial,
        [bool]$IsSpecial,
        [string]$ComputerName
    )

    if ($AccessError)
    {
        return New-UserProfileObject -SID $SID -ProfilePath $ProfilePath -IsOrphaned $false `
            -OrphanReason "AccessDenied" -ComputerName $ComputerName -IsSpecial $IsSpecial
    }
    elseif (-not $ProfilePath)
    {
        return New-UserProfileObject -SID $SID -ProfilePath $null -IsOrphaned $true `
            -OrphanReason "MissingProfileImagePath" -ComputerName $ComputerName -IsSpecial $IsSpecial
    }
    elseif (-not $FolderExists)
    {
        return New-UserProfileObject -SID $SID -ProfilePath $ProfilePath -IsOrphaned $true `
            -OrphanReason "MissingFolder" -ComputerName $ComputerName -IsSpecial $IsSpecial
    }
    else
    {
        return New-UserProfileObject -SID $SID -ProfilePath $ProfilePath -IsOrphaned $false `
            -OrphanReason $null -ComputerName $ComputerName -IsSpecial $IsSpecial
    }
}
