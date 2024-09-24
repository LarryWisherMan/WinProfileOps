<#
.SYNOPSIS
Resolves a list of usernames to their corresponding Security Identifiers (SIDs).

.DESCRIPTION
The `Resolve-UsernamesToSIDs` function resolves each provided username to its corresponding SID on the specified computer. If a username cannot be resolved, a warning is logged.

.PARAMETER Usernames
Specifies an array of usernames to resolve to SIDs.

.PARAMETER ComputerName
Specifies the name of the computer on which to resolve the usernames.

.EXAMPLE
Resolve-UsernamesToSIDs -Usernames 'user1', 'user2' -ComputerName 'Server01'

Description:
Resolves the SIDs for 'user1' and 'user2' on Server01.

.OUTPUTS
Array of SIDs corresponding to the provided usernames.
#>

function Resolve-UsernamesToSIDs
{
    param (
        [string[]]$Usernames,
        [string]$ComputerName
    )

    $SIDs = @()
    foreach ($Username in $Usernames)
    {
        $SID = Get-SIDFromUsername -Username $Username -ComputerName $ComputerName
        if ($SID)
        {
            $SIDs += $SID
        }
        else
        {
            Write-Warning "Could not resolve SID for username $Username on $ComputerName."
        }
    }
    return $SIDs
}
