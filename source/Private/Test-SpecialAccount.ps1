<#
.SYNOPSIS
    Tests if a profile is considered a special or default account.
.DESCRIPTION
    The Test-SpecialAccount function checks whether the profile is a special or default account by comparing the folder name, Security Identifier (SID), and profile path to predefined lists of ignored accounts, SIDs, and paths.
    If the profile matches any of the predefined entries, it is considered a special account.
.PARAMETER FolderName
    The name of the folder representing the profile being tested.
.PARAMETER SID
    The Security Identifier (SID) of the profile being tested.
.PARAMETER ProfilePath
    The file path of the profile being tested.
.EXAMPLE
    Test-SpecialAccount -FolderName "DefaultAppPool" -SID "S-1-5-18" -ProfilePath "C:\WINDOWS\system32\config\systemprofile"
    Checks if the profile associated with the folder "DefaultAppPool", SID "S-1-5-18", and profile path "C:\WINDOWS\system32\config\systemprofile" is a special account.
.EXAMPLE
    Test-SpecialAccount -FolderName "JohnDoe" -SID "S-1-5-21-123456789-1001" -ProfilePath "C:\Users\JohnDoe"
    Tests a non-special account, which does not match any predefined special accounts.
.NOTES
    This function returns $true if the account is considered special, and $false otherwise.
#>
function Test-SpecialAccount
{
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
        "C:\WINDOWS\system32\config\systemprofile", # System profile
        "C:\WINDOWS\ServiceProfiles\LocalService", # Local service profile
        "C:\WINDOWS\ServiceProfiles\NetworkService"  # Network service profile
    )

    # Check if the account is special based on the folder name, SID, or profile path
    return ($IgnoredAccounts -contains $FolderName) -or ($IgnoredSIDs -contains $SID) -or ($IgnoredPaths -contains $ProfilePath)
}
