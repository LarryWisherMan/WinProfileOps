function Join-UserProfiles
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$FolderProfiles,

        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$RegistryProfiles
    )

    # Create a hashtable to store the merged profiles by SID and ProfilePath
    $MergedProfiles = @{}

    # Process folder profiles first
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

    # Process registry profiles and merge them with folder profiles by SID and ProfilePath
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

    # Return the merged profiles as an array
    return $MergedProfiles.Values | Sort-Object SID, ProfilePath
}
