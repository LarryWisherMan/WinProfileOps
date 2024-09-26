function Get-LogonLogoffDatesFromRegistry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$SubKey
    )

    begin {
        Write-Verbose "Starting function Get-LogonLogoffDatesFromRegistry"
    }

    process {
        try {
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
            if ($lowLoadTime -ne $null -and $highLoadTime -ne $null) {
                [uint64]$logonTimestamp = "0X{0:X8}{1:X8}" -f $highLoadTime, $lowLoadTime
                $logonDate = [datetime]::FromFileTime($logonTimestamp)
            }
            else {
                Write-Verbose "LocalProfileLoadTimeLow or LocalProfileLoadTimeHigh not found for subkey: $($SubKey.Name). Using MinValue for logon date."
            }

            # Calculate Logoff Date (Unload Time)
            if ($lowUnloadTime -ne $null -and $highUnloadTime -ne $null) {
                [uint64]$logoffTimestamp = "0X{0:X8}{1:X8}" -f $highUnloadTime, $lowUnloadTime
                $logoffDate = [datetime]::FromFileTime($logoffTimestamp)
            }
            else {
                Write-Verbose "LocalProfileUnloadTimeLow or LocalProfileUnloadTimeHigh not found for subkey: $($SubKey.Name). Using MinValue for logoff date."
            }

            return [pscustomobject]@{
                Success    = $true
                LogonDate  = $logonDate
                LogoffDate = $logoffDate
            }
        }
        catch {
            Write-Warning "Error retrieving Logon and Logoff dates from subkey: $($SubKey.Name). Error: $_"
            return [pscustomobject]@{
                Success    = $false
                LogonDate  = $null
                LogoffDate = $null
                Error      = $_.Exception.Message
            }
        }
    }

    end {
        Write-Verbose "Completed function Get-LogonLogoffDatesFromRegistry"
    }
}
