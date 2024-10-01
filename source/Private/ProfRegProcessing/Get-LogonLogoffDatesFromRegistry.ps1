<#
.SYNOPSIS
    Retrieves logon and logoff dates from a registry subkey.

.DESCRIPTION
    The Get-LogonLogoffDatesFromRegistry function reads the `LocalProfileLoadTimeLow`, `LocalProfileLoadTimeHigh`, `LocalProfileUnloadTimeLow`, and `LocalProfileUnloadTimeHigh`
    values from a specified registry subkey. These values are used to calculate the logon and logoff dates for a user profile.
    If the values are not found, the function uses a default value of `DateTime::MinValue`.

.PARAMETER SubKey
    The registry subkey from which to retrieve the logon and logoff dates. This parameter is mandatory and must be an object of type [Microsoft.Win32.RegistryKey].

.OUTPUTS
    PSCustomObject
    Returns a custom object containing the following properties:
    - Success: [bool] Indicates whether the operation was successful.
    - LogonDate: [DateTime] The calculated logon date (or MinValue if not found).
    - LogoffDate: [DateTime] The calculated logoff date (or MinValue if not found).
    - Error: [string] Error message in case of failure (only present if the operation fails).

.EXAMPLE
    $subKey = Get-RegistrySubKey -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\S-1-5-21-1234567890-1001'
    Get-LogonLogoffDatesFromRegistry -SubKey $subKey
    Retrieves the logon and logoff dates for the specified user profile from the registry.

.EXAMPLE
    Get-LogonLogoffDatesFromRegistry -SubKey $subKey | Format-Table -AutoSize
    Retrieves and formats the logon and logoff dates for easier viewing.

.NOTES
    - This function assumes that the registry values `LocalProfileLoadTimeLow`, `LocalProfileLoadTimeHigh`, `LocalProfileUnloadTimeLow`, and `LocalProfileUnloadTimeHigh`
      exist in the provided subkey. If any of these values are missing, default values will be returned, and a verbose message will be logged.
    - If any error occurs during the process, the function logs a warning and returns an object with `Success = $false` and the error message.
    - The logon and logoff dates are calculated using the FromFileTime method, which converts the registry's 64-bit timestamp into a readable DateTime format.

#>
function Get-LogonLogoffDatesFromRegistry
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$SubKey
    )

    begin
    {
        Write-Verbose "Starting function Get-LogonLogoffDatesFromRegistry"
    }

    process
    {
        try
        {
            Write-Verbose "Retrieving logon and logoff dates from subkey: $($SubKey.Name)"

            # Get the LocalProfileLoadTimeLow and LocalProfileLoadTimeHigh values from the registry
            $lowLoadTime = Get-RegistryValue -BaseKey $SubKey -ValueName "LocalProfileLoadTimeLow" -DefaultValue $null
            $highLoadTime = Get-RegistryValue -BaseKey $SubKey -ValueName "LocalProfileLoadTimeHigh" -DefaultValue $null

            # Get the LocalProfileUnloadTimeLow and LocalProfileUnloadTimeHigh values from the registry
            $lowUnloadTime = Get-RegistryValue -BaseKey $SubKey -ValueName "LocalProfileUnloadTimeLow" -DefaultValue $null
            $highUnloadTime = Get-RegistryValue -BaseKey $SubKey -ValueName "LocalProfileUnloadTimeHigh" -DefaultValue $null

            # Initialize logon and logoff dates as MinValue in case they're not found
            $logonDate = [DateTime]::MinValue
            $logoffDate = [DateTime]::MinValue

            # Calculate Logon Date (Load Time)
            if ($lowLoadTime -ne $null -and $highLoadTime -ne $null)
            {
                [uint64]$logonTimestamp = "0X{0:X8}{1:X8}" -f $highLoadTime, $lowLoadTime
                $logonDate = [datetime]::FromFileTime($logonTimestamp)
            }
            else
            {
                Write-Verbose "LocalProfileLoadTimeLow or LocalProfileLoadTimeHigh not found for subkey: $($SubKey.Name). Using MinValue for logon date."
            }

            # Calculate Logoff Date (Unload Time)
            if ($lowUnloadTime -ne $null -and $highUnloadTime -ne $null)
            {
                [uint64]$logoffTimestamp = "0X{0:X8}{1:X8}" -f $highUnloadTime, $lowUnloadTime
                $logoffDate = [datetime]::FromFileTime($logoffTimestamp)
            }
            else
            {
                Write-Verbose "LocalProfileUnloadTimeLow or LocalProfileUnloadTimeHigh not found for subkey: $($SubKey.Name). Using MinValue for logoff date."
            }

            return [pscustomobject]@{
                Success    = $true
                LogonDate  = $logonDate
                LogoffDate = $logoffDate
            }
        }
        catch
        {
            Write-Warning "Error retrieving Logon and Logoff dates from subkey: $($SubKey.Name). Error: $_"
            return [pscustomobject]@{
                Success    = $false
                LogonDate  = $null
                LogoffDate = $null
                Error      = $_.Exception.Message
            }
        }
    }

    end
    {
        Write-Verbose "Completed function Get-LogonLogoffDatesFromRegistry"
    }
}
