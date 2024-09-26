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
