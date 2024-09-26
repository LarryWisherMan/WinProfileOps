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
                { -not $profileItem.ProfilePath -and -not $profileItem.HasUserFolder }
                {
                    $IsOrphaned = $true
                    $OrphanReason = "MissingProfileImagePathAndFolder"
                    break
                }
                { -not $profileItem.ProfilePath }
                {
                    $IsOrphaned = $true
                    $OrphanReason = "MissingProfileImagePath"
                    break
                }
                { -not $profileItem.HasUserFolder }
                {
                    $IsOrphaned = $true
                    $OrphanReason = "MissingFolder"
                    break
                }
                { ($profileItem.HasUserFolder) -and $ErrorAccess -and ($profileItem.IsSpecial) }
                {
                    $IsOrphaned = $false
                    $OrphanReason = "AccessDenied"
                    break
                }
                { -not $profileItem.HasRegistryEntry -and -not $profileItem.IsSpecial }
                {
                    $IsOrphaned = $true
                    $OrphanReason = "MissingRegistryEntry"
                    break
                }
                default
                {
                    $IsOrphaned = $false
                    $OrphanReason = $null
                }
            }


            $LastLogonDate = if ($profileItem.LastLogonDate) { $profileItem.LastLogonDate } else { [datetime]::MinValue }
            $LastLogOffDate = if ($profileItem.LastLogOffDate) { $profileItem.LastLogOffDate } else { [datetime]::MinValue }


            # Create the UserProfile object using the $LastLogonDate from $ProfileRegistryItems
            $userProfile = [UserProfile]::new(
                $profileItem.SID,
                $profileItem.UserName,
                $profileItem.ProfilePath,
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
