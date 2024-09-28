<#
.SYNOPSIS
    Creates a new UserProfile object.
.DESCRIPTION
    The New-UserProfileObject function creates and returns an instance of the UserProfile class.
    This object contains details about a user profile, including its SID, profile path, whether it is orphaned,
    and other relevant information such as the last logon/logoff times, registry and folder presence, and more.

    This function is useful when managing user profiles across different systems, allowing you to consolidate
    information about profiles and determine their status (e.g., orphaned, special, loaded).

.PARAMETER SID
    The Security Identifier (SID) of the user profile.
.PARAMETER UserName
    The username associated with the profile.
.PARAMETER ProfilePath
    The file path to the user profile folder.
.PARAMETER ProfileState
    The current state of the profile (e.g., Active, Inactive).
.PARAMETER HasRegistryEntry
    A boolean value indicating whether the profile has a corresponding registry entry.
.PARAMETER HasUserFolder
    A boolean value indicating whether the profile folder exists on disk.
.PARAMETER LastLogonDate
    The last logon date of the user. Defaults to [datetime]::MinValue if not provided.
.PARAMETER LastLogOffDate
    The last logoff date of the user. Defaults to [datetime]::MinValue if not provided.
.PARAMETER IsOrphaned
    A boolean value indicating whether the profile is orphaned (i.e., exists in the registry but not on disk, or vice versa).
.PARAMETER OrphanReason
    A description of why the profile is considered orphaned, if applicable.
.PARAMETER ComputerName
    The name of the computer where the profile is located.
.PARAMETER IsSpecial
    A boolean value indicating whether the profile is for a special account (e.g., system or default accounts).
.PARAMETER IsLoaded
    A boolean value indicating whether the profile is currently loaded.
.PARAMETER Domain
    The domain to which the user profile belongs.

.OUTPUTS
    Returns an instance of the UserProfile class with the specified details.

.EXAMPLE
    New-UserProfileObject -SID "S-1-5-21-123456789-1001" -UserName "JohnDoe" -ProfilePath "C:\Users\John" `
        -IsOrphaned $true -OrphanReason "MissingRegistryEntry" -ComputerName "Server01" -IsSpecial $false `
        -HasRegistryEntry $true -HasUserFolder $true -IsLoaded $false -ProfileState "Inactive" `
        -LastLogonDate (Get-Date) -LastLogOffDate (Get-Date).AddDays(-1) -Domain "MyDomain"

    Creates a new UserProfile object for the profile associated with the given SID, marking it as orphaned
    with a reason, specifying that it is not loaded, and providing additional details like the last logon/logoff dates.

.NOTES
    This function returns an instance of the UserProfile class, which is used for managing and reporting on
    user profiles across different systems. The class provides detailed information about the profile's status
    and is particularly useful in scenarios where profiles are being audited, removed, or investigated for inconsistencies.
#>

function New-UserProfileObject
{
    [OutputType([UserProfile])]
    param (
        [string]$SID,
        [string]$UserName,
        [string]$ProfilePath,
        [string]$ProfileState,
        [bool]$HasRegistryEntry,
        [bool]$HasUserFolder,
        [datetime]$LastLogonDate = [datetime]::MinValue,
        [datetime]$LastLogOffDate = [datetime]::MinValue,
        [bool]$IsOrphaned,
        [string]$OrphanReason = $null,
        [string]$ComputerName,
        [bool]$IsSpecial,
        [bool]$IsLoaded,
        [string]$Domain
    )

    return [UserProfile]::new(
        $SID,
        $UserName,
        $ProfilePath,
        $ProfileState,
        $HasRegistryEntry,
        $HasUserFolder,
        $LastLogonDate,
        $LastLogOffDate,
        $IsOrphaned,
        $OrphanReason,
        $ComputerName,
        $IsSpecial,
        $IsLoaded,
        $Domain
    )
}
