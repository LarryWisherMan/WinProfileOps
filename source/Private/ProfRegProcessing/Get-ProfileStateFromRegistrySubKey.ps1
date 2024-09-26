<#
.SYNOPSIS
    Retrieves the profile state associated with a specific registry subkey.

.DESCRIPTION
    The Get-ProfileStateFromRegistrySubKey function retrieves the "State" value from the specified registry subkey, which represents the status of a user profile.
    It also decodes the profile state into a human-readable text using the Get-ProfileStateText function.
    If the "State" value cannot be found, the function returns a custom object with Success set to $false and StateText set to "Unknown". In case of errors, the function returns error details and logs a warning.

.PARAMETER SubKey
    The registry subkey that contains the "State" value for the profile.
    This parameter is mandatory and must be a valid [Microsoft.Win32.RegistryKey] object.

.OUTPUTS
    [pscustomobject] - A custom object containing:
    - Success   : [bool] Indicates whether the operation was successful.
    - State     : [int] The numeric profile state retrieved from the registry.
    - StateText : [string] The decoded profile state as a human-readable string.
    - Error     : [string] (Only present if an error occurs) The error message, if any.

.EXAMPLE
    $subKey = Get-Item 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\S-1-5-21-1234567890-1234567890-1234567890-1001'
    Get-ProfileStateFromRegistrySubKey -SubKey $subKey

    Description:
    Retrieves the profile state for the specified SID from the registry and returns the profile state and its decoded text.

.EXAMPLE
    $subKey = Get-Item 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\S-1-5-21-1234567890-1234567890-1234567890-1001'
    $result = Get-ProfileStateFromRegistrySubKey -SubKey $subKey
    if (-not $result.Success) {
        Write-Host "Failed to retrieve profile state."
    }

    Description:
    This example retrieves the profile state and checks if the retrieval was successful. It prints a message if the profile state could not be found.

.NOTES
    - This function depends on Get-RegistryValue to retrieve the "State" value and Get-ProfileStateText to decode the state.
    - Ensure the calling user has appropriate permissions to access the registry.
    - The function handles errors by logging a warning and returning an error message if any exceptions occur.

#>
function Get-ProfileStateFromRegistrySubKey
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$SubKey
    )

    begin
    {
        Write-Verbose "Starting function Get-ProfileStateFromRegistrySubKey"
    }

    process
    {
        try
        {
            Write-Verbose "Retrieving 'State' value from subkey: $($SubKey.Name)"

            # Retrieve the 'State' value from the subkey
            $profileState = Get-RegistryValue -BaseKey $SubKey -ValueName "State" -DefaultValue $null

            # Check if the state was found
            if ($profileState -ne $null)
            {
                Write-Verbose "Profile state found: $profileState"
                # Call Get-ProfileStateText to decode the state
                $stateText = Get-ProfileStateText -state $profileState
                return [pscustomobject]@{
                    Success   = $true
                    State     = $profileState
                    StateText = $stateText
                }
            }
            else
            {
                Write-Warning "The 'State' value was not found in subkey: $($SubKey.Name)"
                return [pscustomobject]@{
                    Success   = $false
                    State     = $null
                    StateText = "Unknown"
                }
            }
        }
        catch
        {
            Write-Warning "Error retrieving profile state from subkey: $($SubKey.Name). Error: $_"
            return [pscustomobject]@{
                Success   = $false
                State     = $null
                StateText = "Unknown"
                Error     = $_.Exception.Message
            }
        }
    }

    end
    {
        Write-Verbose "Completed function Get-ProfileStateFromRegistrySubKey"
    }
}
