<#
.SYNOPSIS
    Tests if a user profile is considered a special or default account.
.DESCRIPTION
    The Test-SpecialAccount function checks whether the profile is classified as a special or default account.
    It compares the folder name, Security Identifier (SID), and profile path against predefined lists of ignored
    accounts, SIDs, and paths that are typically used to identify system, default, or service accounts.
    If the profile matches any entry from these predefined configurations, it is marked as a special account.

    The function utilizes a configuration file (in .psd1 format) containing the lists of ignored accounts, SIDs,
    and paths. If the profile matches any of the entries in the configuration file, the account is flagged as special.

.PARAMETER FolderName
    The name of the profile folder being tested (e.g., "DefaultAppPool", "JohnDoe").
.PARAMETER SID
    The Security Identifier (SID) of the profile being tested (e.g., "S-1-5-18", "S-1-5-21-123456789-1001").
.PARAMETER ProfilePath
    The file system path of the profile being tested (e.g., "C:\Users\JohnDoe" or "C:\WINDOWS\system32\config\systemprofile").
.PARAMETER ConfigFilePath
    The path to the configuration file (.psd1) that contains the lists of ignored accounts, SIDs, and paths.
    Defaults to "$PSScriptRoot\Data\WinProfileOpsConfig.psd1".

    The configuration file is expected to contain the following sections:
    - IgnoredAccounts: An array of folder names representing special accounts.
    - IgnoredSIDs: An array of SIDs representing special accounts.
    - IgnoredPaths: An array of file path patterns (wildcards are supported) representing special profile paths.

.EXAMPLE
    Test-SpecialAccount -FolderName "DefaultAppPool" -SID "S-1-5-18" -ProfilePath "C:\WINDOWS\system32\config\systemprofile"
    Checks if the profile with folder name "DefaultAppPool", SID "S-1-5-18", and profile path "C:\WINDOWS\system32\config\systemprofile"
    is classified as a special account based on predefined rules.

.EXAMPLE
    Test-SpecialAccount -FolderName "JohnDoe" -SID "S-1-5-21-123456789-1001" -ProfilePath "C:\Users\JohnDoe"
    Tests whether the profile "JohnDoe" is a special account. Since it doesn't match any predefined special account rules,
    it returns that the profile is not special.

.EXAMPLE
    Test-SpecialAccount -FolderName "Administrator" -SID "S-1-5-21-1234567890-1001" -ProfilePath "C:\Users\Administrator" `
    -ConfigFilePath "C:\CustomConfig\SpecialAccounts.psd1"
    Uses a custom configuration file to test whether the "Administrator" account is considered special.

.NOTES
    This function returns a custom object that includes whether the account is special, along with the folder name,
    SID, and profile path. The result can be used to filter out special accounts when performing user profile audits.

    If the configuration file is not found or cannot be loaded, the function will throw an error.

.OUTPUTS
    PSCustomObject
    Returns a custom object with the following properties:
    - Success: Boolean value indicating whether the function executed successfully.
    - IsSpecial: Boolean value indicating whether the profile is considered a special or default account.
    - FolderName: The folder name of the tested profile.
    - SID: The Security Identifier (SID) of the tested profile.
    - ProfilePath: The profile's file path.
    - Error: (Optional) Contains error message if an issue occurred during processing.

.LINK
    Get-Help about_Profiles
    Get-Help about_Security_Identifiers
#>
function Test-SpecialAccount
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FolderName,

        [Parameter(Mandatory = $false)]
        [string]$SID,

        [Parameter(Mandatory = $false)]
        [string]$ProfilePath,

        [string]$ConfigFilePath = "$PSScriptRoot\Data\WinProfileOpsConfig.psd1"  # Path to the config file
    )

    begin
    {
        Write-Verbose "Starting function Test-SpecialAccount"

        # Load the configuration from the .psd1 file
        if (Test-Path $ConfigFilePath)
        {
            Write-Verbose "Loading configuration file from $ConfigFilePath"
            $config = Import-PowerShellDataFile -Path $ConfigFilePath
        }
        else
        {
            throw "Config file not found at path '$ConfigFilePath'."
        }
    }

    process
    {
        try
        {
            # Check if the account is special based on the folder name, SID, or profile path
            $isSpecialAccount = ($config.IgnoredAccounts -contains $FolderName) -or ($config.IgnoredSIDs -contains $SID)
            Write-Verbose "Checking if account is special based on folder name or SID"

            # Check for wildcard matches in paths
            $isSpecialPath = $false
            foreach ($ignoredPath in $config.IgnoredPaths)
            {
                if ($ProfilePath -like $ignoredPath)
                {
                    Write-Verbose "Profile path matches ignored path pattern: $ignoredPath"
                    $isSpecialPath = $true
                    break
                }
            }

            # Return whether the account or path is special
            $result = $isSpecialAccount -or $isSpecialPath

            return [pscustomobject]@{
                Success     = $true
                IsSpecial   = $result
                FolderName  = $FolderName
                SID         = $SID
                ProfilePath = $ProfilePath
            }
        }
        catch
        {
            Write-Warning "An error occurred while testing if the account is special: $_"
            return [pscustomobject]@{
                Success   = $false
                IsSpecial = $false
                Error     = $_.Exception.Message
            }
        }
    }

    end
    {
        Write-Verbose "Completed function Test-SpecialAccount"
    }
}
