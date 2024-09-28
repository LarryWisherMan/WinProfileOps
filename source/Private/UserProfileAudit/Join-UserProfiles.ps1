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

    # Create a hashtable to store the merged profiles by SID and ProfilePath
    $MergedProfiles = @{}


    # Process folder profiles first if they are not empty
    if ($FolderProfiles.Count -ne 0)
    {
        foreach ($folderProfile in $FolderProfiles)
        {
            $mergeKey = Get-MergeKey -SID $folderProfile.SID -ProfilePath $folderProfile.ProfilePath

            # Add folder profile data into the hashtable
            $MergedProfiles[$mergeKey] = [pscustomobject]@{
                SID              = $folderProfile.SID
                UserName         = $folderProfile.UserName
                ProfilePath      = $folderProfile.ProfilePath
                LastLogonDate    = $folderProfile.LastLogonDate
                HasUserFolder    = $folderProfile.HasUserFolder
                ComputerName     = $folderProfile.ComputerName
                IsSpecial        = $folderProfile.IsSpecial
                Domain           = $folderProfile.Domain
                HasRegistryEntry = $false  # Default to false, will be updated if registry entry exists
                ProfileState     = $null   # To be updated by registry profile if present
                IsLoaded         = $null   # To be updated by registry profile if present
                LastLogOffDate   = $null   # To be updated by registry profile if present
                ErrorAccess      = $folderProfile.ErrorAccess
            }
        }
    }

    # Process registry profiles if they are not empty
    if ($RegistryProfiles.Count -ne 0)
    {
        foreach ($registryProfile in $RegistryProfiles)
        {
            $mergeKey = Get-MergeKey -SID $registryProfile.SID -ProfilePath $registryProfile.ProfilePath

            if ($MergedProfiles.ContainsKey($mergeKey))
            {
                # Override with registry-specific properties since registry takes priority
                $MergedProfiles[$mergeKey].HasRegistryEntry = $true
                $MergedProfiles[$mergeKey].ProfileState = $registryProfile.ProfileState
                $MergedProfiles[$mergeKey].IsLoaded = $registryProfile.IsLoaded
                $MergedProfiles[$mergeKey].LastLogOffDate = $registryProfile.LastLogOffDate
                $MergedProfiles[$mergeKey].LastLogonDate = $registryProfile.LastLogonDate
                $MergedProfiles[$mergeKey].ProfilePath = $registryProfile.ProfilePath
                $MergedProfiles[$mergeKey].UserName = $registryProfile.UserName
                $MergedProfiles[$mergeKey].Domain = $registryProfile.Domain
                $MergedProfiles[$mergeKey].IsSpecial = $registryProfile.IsSpecial
                $MergedProfiles[$mergeKey].HasUserFolder = $registryProfile.HasUserFolder
                $MergedProfiles[$mergeKey].ErrorAccess = $registryProfile.ErrorAccess
            }
            else
            {
                # Add the registry profile if it doesn't exist in the folder profiles
                $MergedProfiles[$mergeKey] = [pscustomobject]@{
                    SID              = $registryProfile.SID
                    UserName         = $registryProfile.UserName
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
                }
            }
        }
    }

    # Return the merged profiles as an array
    return $MergedProfiles.Values | Sort-Object SID, ProfilePath
}
