<#
.SYNOPSIS
    Merges user profile information from folder profiles and registry profiles.

.DESCRIPTION
    The Join-UserProfiles function takes folder profiles and registry profiles as input and merges them based on SID and ProfilePath.
    It prioritizes the registry profile data when both folder and registry profiles are present for the same user.
    The merged data is returned as an array of objects, sorted by SID and ProfilePath.

.PARAMETER FolderProfiles
    An array of custom objects representing folder profiles. These objects should include properties like SID, UserName, ProfilePath, LastLogonDate, HasUserFolder, ComputerName, IsSpecial, Domain, and ErrorAccess.
    This parameter is optional, but at least one of FolderProfiles or RegistryProfiles must be provided. If both FolderProfiles and RegistryProfiles are empty, the function throws an error.

.PARAMETER RegistryProfiles
    An array of custom objects representing registry profiles. These objects should include properties like SID, UserName, ProfilePath, LastLogonDate, LastLogOffDate, ProfileState, IsLoaded, and HasRegistryEntry.
    This parameter is optional, but at least one of RegistryProfiles or FolderProfiles must be provided. If both RegistryProfiles and FolderProfiles are empty, the function throws an error.

.EXAMPLE
    $folderProfiles = @(
        [pscustomobject]@{ SID = 'S-1-5-21-123456789-123456789-123456789-1001'; UserName = 'John'; ProfilePath = 'C:\Users\John'; LastLogonDate = (Get-Date); HasUserFolder = $true; ComputerName = 'PC01'; IsSpecial = $false; Domain = 'DOMAIN'; ErrorAccess = $false }
    )
    $registryProfiles = @(
        [pscustomobject]@{ SID = 'S-1-5-21-123456789-123456789-123456789-1001'; UserName = 'John'; ProfilePath = 'C:\Users\John'; LastLogonDate = (Get-Date).AddHours(-5); LastLogOffDate = (Get-Date).AddHours(-2); ProfileState = 1; IsLoaded = $false; HasRegistryEntry = $true }
    )
    Join-UserProfiles -FolderProfiles $folderProfiles -RegistryProfiles $registryProfiles

    This example merges the folder profile and registry profile for the user 'John' based on the SID.

.EXAMPLE
    $folderProfiles = @(
        [pscustomobject]@{ SID = 'S-1-5-21-123456789-123456789-123456789-1002'; UserName = 'Jane'; ProfilePath = 'C:\Users\Jane'; LastLogonDate = (Get-Date); HasUserFolder = $true; ComputerName = 'PC02'; IsSpecial = $false; Domain = 'DOMAIN'; ErrorAccess = $false }
    )
    $registryProfiles = @()
    Join-UserProfiles -FolderProfiles $folderProfiles -RegistryProfiles $registryProfiles

    This example merges the folder profile for the user 'Jane' and since no registry profile is provided, the resulting object will only include the folder profile information.

.EXAMPLE
    $registryProfiles = @(
        [pscustomobject]@{ SID = 'S-1-5-21-123456789-123456789-123456789-1003'; UserName = 'Admin'; ProfilePath = 'C:\Users\Admin'; LastLogonDate = (Get-Date).AddHours(-3); LastLogOffDate = (Get-Date).AddHours(-1); ProfileState = 1; IsLoaded = $true; HasRegistryEntry = $true }
    )
    Join-UserProfiles -RegistryProfiles $registryProfiles

    This example merges only the registry profile for the user 'Admin' since no folder profile is provided.

.NOTES
    If both FolderProfiles and RegistryProfiles are empty, the function will throw an error.
    If only one of FolderProfiles or RegistryProfiles is provided, it will return the data for the non-empty input.

#>
function Join-UserProfiles
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [pscustomobject[]]$FolderProfiles,

        [Parameter(Mandatory = $false)]
        [pscustomobject[]]$RegistryProfiles
    )

    # Check if both FolderProfiles and RegistryProfiles are empty, throw an error if true
    if (($FolderProfiles.Count -eq 0) -and ($RegistryProfiles.Count -eq 0))
    {
        throw "Both FolderProfiles and RegistryProfiles are empty. Cannot proceed."
    }

    # Create a hashtable to store the merged profiles by SID
    $MergedProfiles = @{}
    $unresolvedIndex = 1  # Counter for unresolved profiles

    # Process folder profiles if they exist
    if ($FolderProfiles.Count -ne 0)
    {
        foreach ($folderProfile in $FolderProfiles)
        {
            $mergeKey = $folderProfile.SID

            # Use a placeholder key if SID is missing
            if (-not $mergeKey)
            {
                $mergeKey = "UnknownSID-$unresolvedIndex"
                $unresolvedIndex++
            }

            # Add folder profile data into the hashtable
            $MergedProfiles[$mergeKey] = [pscustomobject]@{
                SID              = $folderProfile.SID
                UserName         = $folderProfile.UserName
                FolderPath       = $folderProfile.ProfilePath  # Capture FolderPath for folder profile
                ProfilePath      = $null  # Keep ProfilePath empty until registry item is processed
                LastLogonDate    = $folderProfile.LastLogonDate
                HasUserFolder    = $folderProfile.HasUserFolder
                ComputerName     = $folderProfile.ComputerName
                IsSpecial        = $folderProfile.IsSpecial
                Domain           = $folderProfile.Domain
                HasRegistryEntry = $false  # Will be updated if registry entry exists
                ProfileState     = $null   # To be updated by registry profile if present
                IsLoaded         = $null   # To be updated by registry profile if present
                LastLogOffDate   = $null   # To be updated by registry profile if present
                ErrorAccess      = $folderProfile.ErrorAccess
                FolderMissing    = $false  # To track if folder is missing but exists in registry
                UnresolvedSID    = (-not $folderProfile.SID)  # Flag if SID is unresolved
            }
        }
    }

    # Process registry profiles, even if FolderProfiles is empty
    foreach ($registryProfile in $RegistryProfiles)
    {
        $mergeKey = $registryProfile.SID

        # Use a placeholder key if SID is missing
        if (-not $mergeKey)
        {
            $mergeKey = "UnknownSID-$unresolvedIndex"
            $unresolvedIndex++
        }

        if ($MergedProfiles.ContainsKey($mergeKey))
        {
            # We found a matching SID, now merge the profile details
            $MergedProfiles[$mergeKey].HasRegistryEntry = $true
            $MergedProfiles[$mergeKey].ProfileState = $registryProfile.ProfileState
            $MergedProfiles[$mergeKey].IsLoaded = $registryProfile.IsLoaded
            $MergedProfiles[$mergeKey].LastLogOffDate = $registryProfile.LastLogOffDate
            $MergedProfiles[$mergeKey].LastLogonDate = $registryProfile.LastLogonDate

            # If ProfilePath is null in the registry, use FolderPath, otherwise use ProfilePath
            if (-not $registryProfile.ProfilePath)
            {
                $MergedProfiles[$mergeKey].ProfilePath = $null
            }
            else
            {
                if (-not $registryProfile.HasUserFolder)
                {
                    $MergedProfiles[$mergeKey].ProfilePath = $registryProfile.ProfilePath
                    $MergedProfiles[$mergeKey].FolderMissing = $true
                }
                else
                {
                    $MergedProfiles[$mergeKey].ProfilePath = $registryProfile.ProfilePath
                }
            }

            # Override additional details from the registry
            $MergedProfiles[$mergeKey].UserName = $registryProfile.UserName
            $MergedProfiles[$mergeKey].Domain = $registryProfile.Domain
            $MergedProfiles[$mergeKey].IsSpecial = $registryProfile.IsSpecial
            $MergedProfiles[$mergeKey].HasUserFolder = $MergedProfiles[$mergeKey].HasUserFolder
            $MergedProfiles[$mergeKey].UnresolvedSID = (-not $registryProfile.SID)
        }
        else
        {
            # Add registry profile directly if no folder profile match is found or FolderProfiles is empty
            $MergedProfiles[$mergeKey] = [pscustomobject]@{
                SID              = $registryProfile.SID
                UserName         = $registryProfile.UserName
                FolderPath       = $null  # No folder match found
                ProfilePath      = $registryProfile.ProfilePath
                LastLogonDate    = $registryProfile.LastLogonDate
                HasUserFolder    = $registryProfile.HasUserFolder
                ComputerName     = $registryProfile.ComputerName
                IsSpecial        = $registryProfile.IsSpecial
                Domain           = $registryProfile.Domain
                HasRegistryEntry = $true
                ProfileState     = $registryProfile.ProfileState
                IsLoaded         = $registryProfile.IsLoaded
                LastLogOffDate   = $registryProfile.LastLogOffDate
                ErrorAccess      = $registryProfile.ErrorAccess
                FolderMissing    = $false  # Assume folder is not missing if HasUserFolder is true
                UnresolvedSID    = (-not $registryProfile.SID)  # Flag if SID is unresolved
            }
        }
    }

    # Return the merged profiles as an array
    return $MergedProfiles.Values | Sort-Object SID
}
