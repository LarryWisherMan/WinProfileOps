<#
.SYNOPSIS
Retrieves the Security Identifier (SID) for a given username.

.DESCRIPTION
The `Get-SIDFromUsername` function resolves the Security Identifier (SID) associated with a given username using the .NET `System.Security.Principal.NTAccount` class. The function translates the provided username into a SID by querying the local system. If the user exists and the SID can be resolved, it is returned. Otherwise, a warning is displayed, and the function returns `$null`.

.PARAMETER Username
Specifies the username for which to retrieve the SID. This parameter is mandatory.

.EXAMPLE
Get-SIDFromUsername -Username 'JohnDoe'

Description:
This command retrieves the SID for the user 'JohnDoe' from the local computer. If the user exists and the SID is found, it is returned; otherwise, a warning will be displayed.

.EXAMPLE
Get-SIDFromUsername -Username 'LocalAdmin'

Description:
This command retrieves the SID for the user 'LocalAdmin' from the local computer. If the user exists and the SID is found, it is returned; otherwise, a warning will be displayed.

.NOTES
This function does not use WMI or CIM for querying user information, but rather the .NET `System.Security.Principal.NTAccount` class, which directly translates the username to a SID. As a result, this function works for both local and domain accounts if the appropriate access is available.
#>

function Get-SIDFromUsername
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username
    )

    try
    {
        # Query WMI to get the SID for the given username
        $ntAccount = New-Object System.Security.Principal.NTAccount($Username)

        $SID = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])

        if ($Null -ne $SID -and $Null -ne $SID.Value)
        {
            return $SID.value
        }
        else
        {
            return $null
        }
    }
    catch
    {
        return $null
    }
}
