function Test-SpecialAccount {
    param (
        [string]$FolderName,
        [string]$SID,
        [string]$ProfilePath
    )

    # List of default or special accounts to ignore
    $IgnoredAccounts = @(
        "defaultuser0", "DefaultAppPool", "servcm12", "Public", "PBIEgwService", "Default",
        "All Users", "win2kpro"
    )
    $IgnoredSIDs = @(
        "S-1-5-18", # Local System
        "S-1-5-19", # Local Service
        "S-1-5-20"  # Network Service
    )
    $IgnoredPaths = @(
        "C:\WINDOWS\system32\config\systemprofile",  # System profile
        "C:\WINDOWS\ServiceProfiles\LocalService",   # Local service profile
        "C:\WINDOWS\ServiceProfiles\NetworkService"  # Network service profile
    )

    # Check if the account is special based on the folder name, SID, or profile path
    return ($IgnoredAccounts -contains $FolderName) -or ($IgnoredSIDs -contains $SID) -or ($IgnoredPaths -contains $ProfilePath)
}
