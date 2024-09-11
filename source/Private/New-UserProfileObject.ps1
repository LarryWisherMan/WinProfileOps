<#
.SYNOPSIS
    Creates a new UserProfile object.
.DESCRIPTION
    The New-UserProfileObject function creates and returns an instance of the UserProfile class. The function takes in various parameters such as SID, profile path, and whether the profile is orphaned or special, and returns a UserProfile object with these details.
.PARAMETER SID
    The Security Identifier (SID) of the user profile.
.PARAMETER ProfilePath
    The file path to the user profile folder.
.PARAMETER IsOrphaned
    A boolean value indicating whether the profile is orphaned (i.e., exists in the registry but not on disk, or vice versa).
.PARAMETER OrphanReason
    A description of why the profile is considered orphaned, if applicable.
.PARAMETER ComputerName
    The name of the computer where the profile is located.
.PARAMETER IsSpecial
    A boolean value indicating whether the profile is for a special account (e.g., system or default accounts).
.EXAMPLE
    New-UserProfileObject -SID "S-1-5-21-123456789-1001" -ProfilePath "C:\Users\John" -IsOrphaned $true -OrphanReason "MissingRegistryEntry" -ComputerName "Server01" -IsSpecial $false
    Creates a new UserProfile object for the profile associated with the given SID, marking it as orphaned with a reason.
.NOTES
    This function returns an instance of the UserProfile class, which is used for managing and reporting on user profiles across different systems.
#>

function New-UserProfileObject
{
    param (
        [string]$SID,
        [string]$ProfilePath,
        [bool]$IsOrphaned,
        [string]$OrphanReason = $null,
        [string]$ComputerName,
        [bool]$IsSpecial
    )

    return [UserProfile]::new(
        $SID,
        $ProfilePath,
        $IsOrphaned,
        $OrphanReason,
        $ComputerName,
        $IsSpecial
    )
}
