<#
.SYNOPSIS
    Retrieves the profile path associated with a specific SID from the registry.
.DESCRIPTION
    The Get-ProfilePathFromSID function retrieves the "ProfileImagePath" registry value for the provided SID registry key. This path indicates the location of the user profile associated with the SID.
.PARAMETER SidKey
    The registry key representing the Security Identifier (SID) from which to retrieve the profile path.
.EXAMPLE
    Get-ProfilePathFromSID -SidKey $sidKey
    Retrieves the profile path for the given SID from the registry.
.NOTES
    If the "ProfileImagePath" cannot be found, the function will return `$null` and a verbose message will indicate the issue.
    In case of an error during retrieval, an error message is logged and the function returns `$null`.
#>
function Get-ProfilePathFromSID
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$SidKey
    )

    begin
    {
        Write-Verbose "Starting function Get-ProfilePathFromSID"
    }

    process
    {
        try
        {
            Write-Verbose "Retrieving ProfileImagePath for SID: $($SidKey.Name)"

            # Use Get-RegistryValue to retrieve the "ProfileImagePath"
            $profileImagePath = Get-RegistryValue -BaseKey $SidKey -ValueName "ProfileImagePath"

            if (-not $profileImagePath)
            {
                Write-Verbose "ProfileImagePath not found for SID: $($SidKey.Name)"
            }

            return [pscustomobject]@{
                Success          = $true
                ProfileImagePath = $profileImagePath
            }
        }
        catch
        {
            Write-Warning "Failed to retrieve ProfileImagePath for SID: $($SidKey.Name). Error: $_"
            return [pscustomobject]@{
                Success          = $false
                Error            = $_.Exception.Message
                ProfileImagePath = $null
            }
        }
    }

    end
    {
        Write-Verbose "Completed function Get-ProfilePathFromSID"
    }
}
