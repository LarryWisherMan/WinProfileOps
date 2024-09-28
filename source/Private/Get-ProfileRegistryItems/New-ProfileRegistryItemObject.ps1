<#
.SYNOPSIS
    Creates a custom object representing a user profile from registry and file system data.

.DESCRIPTION
    The New-ProfileRegistryItemObject function generates a PSCustomObject that holds detailed information about a user profile.
    This object includes properties such as the profile's SID, path, profile state, computer name, and other relevant metadata.
    It is useful for representing user profile information from both the registry and file system during system audits or troubleshooting tasks.

.PARAMETER SID
    The security identifier (SID) of the user profile.

.PARAMETER ProfilePath
    The file system path to the user profile directory.

.PARAMETER ProfileState
    A string representing the state of the user profile (e.g., active, inactive).

.PARAMETER ComputerName
    The name of the computer where the profile is located.

.PARAMETER HasRegistryEntry
    Indicates whether the profile has a corresponding entry in the registry. Defaults to $true.

.PARAMETER IsLoaded
    Indicates whether the user profile is currently loaded on the system.

.PARAMETER HasUserFolder
    Indicates whether a folder exists for the user profile in the file system.

.PARAMETER UserName
    The name of the user associated with the profile.

.PARAMETER Domain
    The domain associated with the user profile, if applicable.

.PARAMETER IsSpecial
    Indicates whether the profile is a special or system profile (e.g., Default or System profiles).

.PARAMETER LastLogOnDate
    The date and time of the user's last logon.

.PARAMETER LastLogOffDate
    The date and time of the user's last logoff.

.PARAMETER ErrorAccess
    Indicates if there was an error accessing the profile.

.PARAMETER errorCapture
    Captures any errors or additional information about access issues, if applicable.

.OUTPUTS
    PSCustomObject
    A custom object representing the user profile, with properties including the SID, ProfilePath, ProfileState, and other relevant data.

.EXAMPLE
    $profileObject = New-ProfileRegistryItemObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\User1' -ProfileState 'Active' `
                                                     -ComputerName 'Server01' -IsLoaded $true -HasUserFolder $true -UserName 'User1' `
                                                     -Domain 'Domain' -IsSpecial $false -LastLogOnDate (Get-Date) -LastLogOffDate (Get-Date)

    Creates a profile object with the specified parameters for the user 'User1' on 'Server01'.

.NOTES
    This function is designed to consolidate user profile data from both the registry and file system into a single object,
    which can be used for audits, reports, or profile management tasks.
#>

function New-ProfileRegistryItemObject
{
    param (
        [string]$SID,
        [string]$ProfilePath,
        [string]$ProfileState,
        [string]$ComputerName,
        [bool]$HasRegistryEntry = $true,
        [bool]$IsLoaded,
        [bool]$HasUserFolder,
        [string]$UserName,
        [string]$Domain,
        [bool]$IsSpecial,
        [DateTime]$LastLogOnDate,
        [DateTime]$LastLogOffDate,
        [bool]$ErrorAccess,
        $errorCapture
    )

    return [pscustomobject]@{
        SID              = $SID
        ProfilePath      = $ProfilePath
        ProfileState     = $ProfileState
        ComputerName     = $ComputerName
        HasRegistryEntry = $HasRegistryEntry
        IsLoaded         = $IsLoaded
        HasUserFolder    = $HasUserFolder
        UserName         = $UserName
        Domain           = $Domain
        IsSpecial        = $IsSpecial
        LastLogOnDate    = $LastLogOnDate
        LastLogOffDate   = $LastLogOffDate
        ErrorAccess      = $ErrorAccess
        ErrorCapture     = $errorCapture
    }
}
