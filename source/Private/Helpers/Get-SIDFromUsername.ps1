<#
.SYNOPSIS
Retrieves the Security Identifier (SID) for a given username from a specified computer, defaulting to the local computer if no computer name is provided.

.DESCRIPTION
The `Get-SIDFromUsername` function queries the specified computer using WMI (CIM) to retrieve the SID associated with a given username. If the `ComputerName` parameter is not provided, the function defaults to the local computer. The function uses the `Get-CimInstance` cmdlet to perform the lookup on the remote or local computer. If the user exists and the SID is found, it is returned. If no SID is found or an error occurs, a warning message is displayed, and the function returns `$null`.

.PARAMETER Username
Specifies the username for which to retrieve the SID. This parameter is mandatory.

.PARAMETER ComputerName
Specifies the name of the computer where the user account exists. This parameter is optional and defaults to the local computer (`localhost`). You can specify either a local or remote computer.

.EXAMPLE
Get-SIDFromUsername -Username 'JohnDoe' -ComputerName 'Server01'

Description:
This command retrieves the SID for the user 'JohnDoe' from the computer 'Server01'. If the user exists on the computer and has a SID, it will be returned; otherwise, a warning will be displayed.

.EXAMPLE
Get-SIDFromUsername -Username 'LocalAdmin'

Description:
This command retrieves the SID for the user 'LocalAdmin' from the local computer (localhost) since no `ComputerName` is provided. If the user exists on the local computer and has a SID, it will be returned; otherwise, a warning will be displayed.

.EXAMPLE
Get-SIDFromUsername -Username 'DomainUser' -ComputerName 'DomainController'

Description:
This command retrieves the SID for the user 'DomainUser' from the remote computer 'DomainController'. If the user exists on the specified computer and has a SID, it will be returned; otherwise, a warning will be displayed.

.NOTES
If the `ComputerName` is not provided, it defaults to the local computer.
#>

function Get-SIDFromUsername
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try
    {
        # Query WMI to get the SID for the given username
        $userAccount = Get-CimInstance -Class Win32_UserAccount -ComputerName $ComputerName -Filter "Name = '$Username'"

        if ($userAccount -and $userAccount.SID)
        {
            return $userAccount.SID
        }
        else
        {
            Write-Warning "Could not find SID for username $Username on $ComputerName."
            return $null
        }
    }
    catch
    {
        Write-Warning "An error occurred while trying to resolve SID for username $Username on $ComputerName. Error: $_"
        return $null
    }
}
