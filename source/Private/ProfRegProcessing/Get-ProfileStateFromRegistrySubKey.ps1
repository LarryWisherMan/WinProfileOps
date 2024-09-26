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
