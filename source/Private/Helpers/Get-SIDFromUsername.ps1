<#
.SYNOPSIS
    Retrieves the Security Identifier (SID) for a given username either locally or remotely.

.DESCRIPTION
    The `Get-SIDFromUsername` function resolves the Security Identifier (SID) associated with a given username by using the .NET `System.Security.Principal.NTAccount` class.
    The function allows execution on a local or remote computer by leveraging PowerShell's `Invoke-Command`.
    If the user exists and the SID can be resolved, the SID is returned; otherwise, a warning is displayed, and the function returns `$null`.

.PARAMETER Username
    Specifies the username for which to retrieve the SID. This parameter is mandatory and must not be null or empty.

.PARAMETER ComputerName
    Specifies the computer from which to retrieve the SID. If this parameter is not provided, the function will default to the local computer.
    When provided, the function will attempt to retrieve the SID from the specified remote computer.

.OUTPUTS
    String - The Security Identifier (SID) associated with the provided username.
    If the SID cannot be resolved, the function returns `$null`.

.NOTES
    This function uses the .NET `System.Security.Principal.NTAccount` class to resolve the username into a SID. It can query either the local system or a remote system (via PowerShell remoting).
    If PowerShell remoting is disabled or the specified remote computer is unreachable, the function will issue a warning and return `$null`.

.EXAMPLE
    Get-SIDFromUsername -Username 'JohnDoe'

    Description:
    Retrieves the SID for the user 'JohnDoe' from the local computer. If the user exists and the SID is found, it will be returned.

.EXAMPLE
    Get-SIDFromUsername -Username 'JohnDoe' -ComputerName 'Server01'

    Description:
    Retrieves the SID for the user 'JohnDoe' from the remote computer 'Server01'. If the user exists and the SID is found, it will be returned.

.EXAMPLE
    Get-SIDFromUsername -Username 'Administrator'

    Description:
    Retrieves the SID for the 'Administrator' account from the local computer. This works for both local and domain accounts.

.EXAMPLE
    Get-SIDFromUsername -Username 'Administrator' -ComputerName 'Server01'

    Description:
    Retrieves the SID for the 'Administrator' account from the remote computer 'Server01'. If the user account exists and the SID can be resolved, it will be returned.

.EXAMPLE
    $sids = @('User1', 'User2') | ForEach-Object { Get-SIDFromUsername -Username $_ }

    Description:
    Retrieves the SIDs for multiple users by passing the usernames through the pipeline and invoking the function for each user.

.EXAMPLE
    Get-SIDFromUsername -Username 'NonExistentUser'

    Warning:
    Failed to retrieve SID for username: NonExistentUser

    Output:
    $null

    Description:
    Attempts to retrieve the SID for a user that does not exist. In this case, the function issues a warning and returns `$null`.

#>
function Get-SIDFromUsername
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME  # Default to the local computer
    )

    try
    {
        # Define the script block for translating Username to SID
        $scriptBlock = {
            param ($Username)
            try
            {
                $ntAccount = New-Object System.Security.Principal.NTAccount($Username)
                $SID = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])

                if ($null -ne $SID -and $null -ne $SID.Value)
                {
                    return $SID.Value
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

        # Use Invoke-Command to run the script block locally or remotely
        $result = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ArgumentList $Username

        return $result
    }
    catch
    {
        Write-Warning "Failed to retrieve SID for username: $Username"
        return $null
    }
}
