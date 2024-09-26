<#
.SYNOPSIS
    Retrieves the profile path associated with a specific SID from the registry.

.DESCRIPTION
    The Get-ProfilePathFromSID function retrieves the "ProfileImagePath" registry value for the provided Security Identifier (SID) registry key. The ProfileImagePath indicates the location of the user profile associated with the SID.
    If the ProfileImagePath is not found, the function returns a custom object with the Success property set to $true and the ProfileImagePath property set to $null.
    If an error occurs during retrieval, an error message is logged, and the function returns a custom object with the Success property set to $false and the Error property containing the error message.

.PARAMETER SidKey
    The registry key representing the Security Identifier (SID) from which to retrieve the profile path.
    This parameter is mandatory and must be a valid [Microsoft.Win32.RegistryKey] object.

.OUTPUTS
    [pscustomobject]
    A custom object with the following properties:
    - Success: [bool] Indicates whether the operation was successful.
    - ProfileImagePath: [string] The path to the user profile associated with the SID.
    - Error: [string] (Only present if an error occurs) The error message, if any.

.EXAMPLE
    $sidKey = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\S-1-5-21-1234567890-1234567890-1234567890-1001"
    Get-ProfilePathFromSID -SidKey $sidKey

    Description:
    Retrieves the profile path for the specified SID from the registry key and returns the result.

.EXAMPLE
    $sidKey = Get-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\S-1-5-21-987654321-987654321-987654321-1001"
    $result = Get-ProfilePathFromSID -SidKey $sidKey
    if (-not $result.ProfileImagePath) {
        Write-Host "Profile path not found."
    }

    Description:
    This example retrieves the profile path for a given SID, checks if the ProfileImagePath was found, and prints a message if it is not found.

.NOTES
    This function requires appropriate access to the registry in order to retrieve the ProfileImagePath.
    If the "ProfileImagePath" value does not exist, the function will log a verbose message and return a custom object where ProfileImagePath is $null.
    The function handles errors gracefully by logging a warning and returning a custom object with the error details.
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
