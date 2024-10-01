<#
.SYNOPSIS
    Converts profile registry items into user profile objects.

.DESCRIPTION
    The `ConvertTo-UserProfile` function takes a collection of profile registry items and converts them into custom user profile objects.
    The function evaluates each profile based on certain conditions (e.g., missing profile path, missing user folder, access denied, etc.)
    and determines whether the profile is orphaned. The output is a `UserProfile` object with properties such as `SID`, `UserName`, `ProfilePath`,
    `ProfileState`, `IsOrphaned`, and more. The function also supports different views, including an `OrphanDetails` view for additional detail.

.PARAMETER ProfileRegistryItems
    A collection of profile registry items to be processed. Each item must contain properties such as `SID`, `UserName`, `ProfilePath`,
    `HasRegistryEntry`, `HasUserFolder`, and others used to determine the profile's state. This parameter is mandatory.

.PARAMETER View
    Specifies the view of the output object. By default, it outputs in the `Default` view. If `OrphanDetails` is selected, additional type
    information is included in the output for orphaned profiles. This parameter is optional and accepts values of "Default" and "OrphanDetails".

.EXAMPLE
    $profiles = Get-ProfileRegistryItems -ComputerName "Server01"
    $userProfiles = $profiles | ConvertTo-UserProfile

    Description:
    This example retrieves profile registry items from "Server01" and converts them into user profile objects.

.EXAMPLE
    $profiles = Get-ProfileRegistryItems -ComputerName "Server01"
    $orphanProfiles = $profiles | ConvertTo-UserProfile -View "OrphanDetails"

    Description:
    This example retrieves profile registry items and converts them into user profile objects, including detailed information for orphaned profiles
    using the `OrphanDetails` view.

.INPUTS
    [psobject[]] - Profile registry items as input objects.

.OUTPUTS
    [UserProfile] - A custom user profile object with properties such as:
      - `SID`: Security Identifier of the user profile.
      - `UserName`: The username associated with the profile.
      - `ProfilePath`: The path to the profile folder.
      - `ProfileState`: The state of the profile (e.g., Active, Orphaned).
      - `IsOrphaned`: Indicates whether the profile is considered orphaned.
      - `OrphanReason`: Reason for the profile being orphaned.
      - `HasRegistryEntry`: Indicates if the profile has a registry entry.
      - `HasUserFolder`: Indicates if the profile has a user folder.
      - `LastLogonDate`: The last logon date for the profile.
      - `LastLogOffDate`: The last logoff date for the profile.
      - `ComputerName`: The name of the computer where the profile resides.
      - `IsSpecial`: Indicates if the profile belongs to a special account (e.g., system accounts).
      - `IsLoaded`: Indicates if the profile is currently loaded.
      - `Domain`: The domain associated with the user, if applicable.

.NOTES
    The function uses a switch statement to evaluate different conditions for orphaning a profile. If a profile lacks both a registry entry and a user folder, it is marked as orphaned. The function outputs a custom `UserProfile` object with properties relevant to user profile management, such as last logon/logoff dates, orphan status, and more.

#>
function ConvertTo-UserProfile
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [psobject[]]$ProfileRegistryItems,

        [Parameter()]
        [ValidateSet("Default", "OrphanDetails")]
        [string]$View = "Default"
    )

    process
    {
        foreach ($profileItem in $ProfileRegistryItems)
        {
            $IsOrphaned = $false
            $OrphanReason = $null
            $ErrorAccess = $profileItem.ErrorAccess

            switch ($true)
            {
                # Case: Both ProfilePath and User Folder are missing
                { -not $profileItem.ProfilePath -and -not $profileItem.HasUserFolder }
                {
                    $IsOrphaned = $true
                    $OrphanReason = "MissingProfileImagePathAndFolder"
                    break
                }

                # Case: ProfilePath is missing (but folder might exist)
                { -not $profileItem.ProfilePath -and $profileItem.HasRegistryEntry }
                {
                    $IsOrphaned = $true
                    $OrphanReason = "MissingProfileImagePath"
                    break
                }

                # Case: User folder is missing, but ProfilePath exists
                { -not $profileItem.HasUserFolder }
                {
                    $IsOrphaned = $true
                    $OrphanReason = "MissingFolder"
                    break
                }

                # Case: Registry entry exists but folder is missing (tracked by FolderMissing flag)
                { $profileItem.HasRegistryEntry -and $profileItem.FolderMissing }
                {
                    $IsOrphaned = $true
                    $OrphanReason = "FolderMissingOnDisk"
                    break
                }

                # Case: Access denied for special account
                { ($profileItem.HasUserFolder) -and $ErrorAccess -and ($profileItem.IsSpecial) }
                {
                    $IsOrphaned = $false
                    $OrphanReason = "AccessDenied"
                    break
                }

                # Case: Registry entry is missing but it's not a special account
                { -not $profileItem.HasRegistryEntry -and -not $profileItem.IsSpecial }
                {
                    $IsOrphaned = $true
                    $OrphanReason = "MissingRegistryEntry"
                    break
                }

                # Default case
                default
                {
                    $IsOrphaned = $false
                    $OrphanReason = $null
                }
            }

            $LastLogonDate = if ($profileItem.LastLogonDate) { $profileItem.LastLogonDate } else { [datetime]::MinValue }
            $LastLogOffDate = if ($profileItem.LastLogOffDate) { $profileItem.LastLogOffDate } else { [datetime]::MinValue }

            # Using New-Object to create the UserProfile object
            $userProfile = New-Object -TypeName "UserProfile" -ArgumentList (
                $profileItem.SID,
                $profileItem.UserName,
                $profileItem.ProfilePath,
                $profileItem.FolderPath,
                $profileItem.ProfileState,
                $profileItem.HasRegistryEntry,
                $profileItem.HasUserFolder,
                $LastLogonDate,
                $LastLogOffDate,
                $IsOrphaned,
                $OrphanReason,
                $profileItem.ComputerName,
                $profileItem.IsSpecial,
                $profileItem.IsLoaded,
                $profileItem.Domain
            )

            if ($View -eq "OrphanDetails")
            {
                $userProfile.psobject.TypeNames.Insert(0, 'UserProfile.OrphanDetails')
            }

            # Output the UserProfile object
            $userProfile
        }
    }
}
