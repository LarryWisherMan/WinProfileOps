<#
.SYNOPSIS
Resolves a list of usernames to their corresponding Security Identifiers (SIDs).

.DESCRIPTION
The `Resolve-UsernamesToSIDs` function resolves each provided username to its corresponding Security Identifier (SID) using the .NET `System.Security.Principal.NTAccount` class. For each username in the input array, the function attempts to resolve the username locally. If a username cannot be resolved, a warning is logged, and the function continues processing the next username.

.PARAMETER Usernames
Specifies an array of usernames to resolve to SIDs. This parameter is mandatory.

.EXAMPLE
Resolve-UsernamesToSIDs -Usernames 'user1', 'user2'

Description:
Resolves the SIDs for 'user1' and 'user2' on the local computer.

.OUTPUTS
Array of SIDs corresponding to the provided usernames. If a username cannot be resolved, it will not be included in the output array, and a warning will be logged.

.NOTES
This function uses the `Get-SIDFromUsername` function, which internally uses the .NET `System.Security.Principal.NTAccount` class for resolving SIDs. It does not support resolving SIDs from remote computers and works only on the local system.
#>
function Resolve-UsernamesToSIDs
{
    param (
        [string[]]$Usernames
    )

    $SIDs = @()

    foreach ($Username in $Usernames)
    {
        try
        {
            $SID = Get-SIDFromUsername -Username $Username
        }
        catch {}
        if ($Null -ne $SID -and $Null -ne $SID)
        {
            $SIDs += $SID
        }
        else
        {
            Write-Warning "Could not resolve SID for username $Username."
        }

    }

    return $SIDs
}
