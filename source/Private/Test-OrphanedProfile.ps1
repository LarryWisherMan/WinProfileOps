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
        [bool]$IgnoreSpecial,
        [bool]$IsSpecial,
        [string]$ComputerName
    )

    if (-not $ProfilePath)
    {
        return New-UserProfileObject $SID $null $true "MissingProfileImagePath" $ComputerName $IsSpecial
    }
    elseif (-not $FolderExists)
    {
        return New-UserProfileObject $SID $ProfilePath $true "MissingFolder" $ComputerName $IsSpecial
    }
    else
    {
        return New-UserProfileObject $SID $ProfilePath $false $null $ComputerName $IsSpecial
    }
}
