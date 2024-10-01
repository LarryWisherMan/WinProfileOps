<#
.SYNOPSIS
Resolves a list of usernames to their corresponding Security Identifiers (SIDs).

.DESCRIPTION
The `Resolve-UsernamesToSIDs` function resolves each provided username to its corresponding Security Identifier (SID) on a specified computer or the local machine. It uses the `Get-SIDFromUsername` function, which can resolve usernames to SIDs either locally or remotely. For each username, the function attempts to resolve the username on the specified computer. If a username cannot be resolved, a warning is logged, and the function continues processing the next username.

.PARAMETER Usernames
Specifies an array of usernames to resolve to SIDs. This parameter is mandatory.

.PARAMETER ComputerName
Specifies the name of the computer on which to resolve the usernames to SIDs. If not provided, the function defaults to the local computer.

.EXAMPLE
Resolve-UsernamesToSIDs -Usernames 'user1', 'user2'

Description:
Resolves the SIDs for 'user1' and 'user2' on the local computer.

.EXAMPLE
Resolve-UsernamesToSIDs -Usernames 'user1', 'user2' -ComputerName 'Server01'

Description:
Resolves the SIDs for 'user1' and 'user2' on the remote computer 'Server01'.

.OUTPUTS
Array of custom objects containing the username and the corresponding SID. If a username cannot be resolved, the SID will be null, and a warning will be logged.

.NOTES
This function supports resolving SIDs on remote computers using the `ComputerName` parameter.
#>
function Resolve-UsernamesToSIDs
{
    param (
        [string[]]$Usernames,
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $SIDs = @()

    foreach ($Username in $Usernames)
    {
        try
        {
            $SID = Get-SIDFromUsername -Username $Username -ComputerName $ComputerName
        }
        catch {}

        # Ensure $SID is not $null before adding to $SIDs array
        if ($SID)
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
