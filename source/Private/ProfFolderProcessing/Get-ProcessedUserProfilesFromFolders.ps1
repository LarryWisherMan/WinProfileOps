<#
.SYNOPSIS
Processes user profile folders on a specified computer and retrieves user profile details including last logon time, SID, and special account status.

.DESCRIPTION
The `Get-ProcessedUserProfilesFromFolders` function processes a list of user profile folders and retrieves information such as last logon time, user name, SID, and whether the account is marked as special. The function accepts a list of user folders and a computer name to resolve profile data. It handles cases where the SID may not be resolvable and returns a custom object containing the processed profile information.

.PARAMETER ComputerName
Specifies the name of the computer where the user profiles are located. By default, this parameter is set to the current computer (`$env:COMPUTERNAME`). This parameter is mandatory.

.PARAMETER UserFolders
A collection of custom objects representing user folders, each containing `ProfilePath` and `FolderName` properties. This parameter is mandatory and must be supplied with folder details to process.

.EXAMPLE
$folders = @(
    [pscustomobject]@{ ProfilePath = 'C:\Users\TestUser'; FolderName = 'TestUser' },
    [pscustomobject]@{ ProfilePath = 'C:\Users\AdminUser'; FolderName = 'AdminUser' }
)
$ProcessedProfiles = Get-ProcessedUserProfilesFromFolders -ComputerName 'TestComputer' -UserFolders $folders

Description:
This example processes two user profile folders on the 'TestComputer', gathering information about each profile, such as SID, special account status, and last logon date.

.EXAMPLE
$UserFolders = Get-UserProfileFolders -ComputerName 'TestComputer'
$ProcessedProfiles = Get-ProcessedUserProfilesFromFolders -UserFolders $UserFolders

Description:
This example uses a custom function `Get-UserProfileFolders` to retrieve user profile folders from the 'TestComputer' and then processes the profile information for each folder.

.INPUTS
[string] - The name of the computer where the user profiles reside.
[pscustomobject[]] - A list of user profile folders represented as custom objects with `ProfilePath` and `FolderName` properties.

.OUTPUTS
[PSCustomObject] - A processed user profile object containing:
- `UserName`: The username associated with the profile.
- `ComputerName`: The name of the computer where the profile resides.
- `IsSpecial`: Indicates whether the profile belongs to a special account (e.g., system accounts).
- `LastLogonDate`: The last logon time for the user profile.
- `SID`: The Security Identifier (SID) of the profile, if available.
- `ProfilePath`: The path to the user profile folder.
- `ExistsInRegistry`: Boolean indicating whether the profile exists in the registry.
- `HasUserFolder`: Boolean indicating whether the user folder exists on the computer.
- `Domain`: The domain associated with the user, if available.

.NOTES
- This function relies on external functions such as `Resolve-UsernamesToSIDs`, `Get-UserProfileLastUseTimeFromDat`, and `Test-SpecialAccount`.
- Handles exceptions gracefully when unable to resolve SIDs or retrieve account information.
- If no last logon date is found, it defaults to `[DateTime]::MinValue`.
#>
function Get-ProcessedUserProfilesFromFolders
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [pscustomobject[]]$UserFolders
    )

    # Retrieve LastLogonTime information from computer
    $LastLogonTimes = Get-UserProfileLastUseTimeFromDat -ComputerName $ComputerName

    # Process each folder
    $ProcessedProfiles = $UserFolders | ForEach-Object {
        $profilePath = $_.ProfilePath
        $folderName = $_.FolderName
        $TestSpecialParams = @{}
        $TestSpecialParams.Add('ProfilePath', $profilePath)

        # Extract user name from the folder name
        $userName = $folderName -replace '\..*$', ''
        $TestSpecialParams.Add('FolderName', $userName)

        # Get Last Logon Time
        $lastLogOn = $LastLogonTimes | Where-Object { $_.UserPath -eq $profilePath } | Select-Object -ExpandProperty LastLogon

        # Try to resolve SID
        try
        {
            $SID = Resolve-UsernamesToSIDs -ComputerName -Usernames $userName -WarningAction SilentlyContinue
        }
        catch
        {
            $SID = $null
        }

        # Default values for the existence in the registry and user folder
        $existsInRegistry = $false
        $hasUserFolder = $true

        # If SID is found, gather additional information
        if ($SID)
        {
            try
            {
                $TestSpecialParams.Add('SID', $SID)
                $accountInfo = Get-UserAccountFromSID -SID $SID -WarningAction SilentlyContinue
                $domain = $accountInfo.Domain
                $userName = $accountInfo.Username
            }
            catch
            {
                $domain = $null
                $userName = $null
            }
        }

        # Test if the account is special
        $IsSpecialResults = Test-SpecialAccount @TestSpecialParams
        $IsSpecial = $IsSpecialResults.IsSpecial

        # Return a processed profile object
        [pscustomobject]@{
            UserName         = $userName
            ComputerName     = $ComputerName
            IsSpecial        = $IsSpecial
            LastLogonDate    = if ($lastLogOn) { $lastLogOn } else { [DateTime]::MinValue }
            SID              = $SID
            ProfilePath      = $profilePath
            ExistsInRegistry = $existsInRegistry
            HasUserFolder    = $hasUserFolder
            Domain           = $domain
        }
    }

    # Return processed profiles
    return $ProcessedProfiles
}
