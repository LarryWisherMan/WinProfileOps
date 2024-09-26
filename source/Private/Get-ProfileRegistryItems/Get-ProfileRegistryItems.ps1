<#
.SYNOPSIS
Retrieves profile registry items from a specified registry path on a remote computer.

.DESCRIPTION
The Get-ProfileRegistryItems function connects to a remote computer and retrieves profile registry items from a specified registry path. It supports specifying the registry hive and handles opening and closing registry keys.

.PARAMETER RegistryPath
The registry path to retrieve profile items from. This parameter is mandatory and must not be null or empty.

.PARAMETER ComputerName
The name of the remote computer to connect to. This parameter is mandatory and must not be null or empty.

.PARAMETER RegistryHive
The registry hive to use. Defaults to 'LocalMachine'. This parameter is optional.

.EXAMPLE
Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName 'RemotePC'

This example retrieves profile registry items from the specified registry path on the remote computer 'RemotePC'.

.EXAMPLE
'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | Get-ProfileRegistryItems -ComputerName 'RemotePC'

This example retrieves profile registry items from the specified registry path on the remote computer 'RemotePC', using pipeline input for the registry path.
.NOTES
#>
function Get-ProfileRegistryItems
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RegistryPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,

        [Parameter()]
        [string]$RegistryHive = 'LocalMachine'
    )

    begin
    {

        # Explicitly check if the RegistryPath is of type string
        if (-not $RegistryPath -is [string])
        {
            throw "The parameter 'RegistryPath' must be a string."
        }

        $ProfileRegistryItems = @()  # Initialize an empty array to store profile items

        Write-Verbose "Opening HKEY_USERS hive on $ComputerName"
        $HKEYUsers = Open-RegistryKey -RegistryHive Users -ComputerName $ComputerName -Writable $false
        if (-not $HKEYUsers)
        {
            throw "Failed to open HKEY_USERS on $ComputerName."
        }

        # Get subkeys of HKEY_USERS once
        $HKEYUsersSubkeyNames = $HKEYUsers.GetSubKeyNames()
    }


    process
    {
        Write-Verbose "Processing registry path: $RegistryPath on $ComputerName"

        # Open the registry path on the target computer
        $ProfileListKey = Open-RegistryKey -RegistryPath $RegistryPath -ComputerName $ComputerName -Writable $false -RegistryHive $RegistryHive
        if (-not $ProfileListKey)
        {
            Write-Error "Failed to open registry path: $RegistryPath on $ComputerName."
            return
        }

        # Retrieve the list of SIDs from the registry key
        $subKeyNames = $ProfileListKey.GetSubKeyNames()
        if (-not $subKeyNames -or $subKeyNames.Count -eq 0)
        {
            Write-Verbose "No SIDs found in the registry key on $ComputerName."
            return
        }

        $subKeyNames | Invoke-ProfileRegistryItemProcessing -ComputerName $ComputerName -ProfileListKey $ProfileListKey -HKEYUsersSubkeyNames $HKEYUsersSubkeyNames
    }

    end
    {
        Write-Verbose "Returning profile registry items for $ComputerName"
        # Close Keys
        $ProfileListKey.Close()
        $HKEYUsers.Close()
    }
}
