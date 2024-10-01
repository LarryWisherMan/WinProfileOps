<#
.SYNOPSIS
    Retrieves the domain and username associated with a given Security Identifier (SID), locally or remotely.

.DESCRIPTION
    The `Get-UserAccountFromSID` function takes a Security Identifier (SID) as input and translates it into a corresponding user account's domain and username. The function can be executed locally or remotely using PowerShell remoting.

    The function uses .NET's `System.Security.Principal.SecurityIdentifier` class to perform the translation and returns a custom object containing the SID, domain, and username. If the SID cannot be translated, it returns null for the domain and username and issues a warning.

.PARAMETER SID
    The Security Identifier (SID) to be translated. This is a required parameter and must not be null or empty. The function supports pipeline input for the SID.

.PARAMETER ComputerName
    The name of the computer to perform the translation. If not specified, the function defaults to the local computer (`$env:COMPUTERNAME`).
    When a remote computer is specified, the function uses `Invoke-Command` to run the translation remotely.

.OUTPUTS
    PSCustomObject - An object with the following properties:
        - SID: The input SID.
        - Domain: The domain of the user account associated with the SID, if found.
        - Username: The username of the user account associated with the SID, if found.

.NOTES
    This function leverages .NET's `System.Security.Principal.SecurityIdentifier` class to translate the SID into a user account in the format `DOMAIN\Username`.
    If the translation fails, a warning is generated, and the function returns null for both the domain and username.

.EXAMPLE
    Get-UserAccountFromSID -SID 'S-1-5-21-1234567890-1234567890-1234567890-1001'

    Output:
    SID                           Domain   Username
    ---                           ------   --------
    S-1-5-21-1234567890-1234567890-1234567890-1001 DOMAIN   User

    Description:
    This example retrieves the domain and username associated with the given SID on the local computer.

.EXAMPLE
    Get-UserAccountFromSID -SID 'S-1-5-21-1234567890-1234567890-1234567890-1001' -ComputerName 'RemoteServer01'

    Output:
    SID                           Domain   Username
    ---                           ------   --------
    S-1-5-21-1234567890-1234567890-1234567890-1001 DOMAIN   User

    Description:
    This example retrieves the domain and username associated with the given SID from the remote computer 'RemoteServer01'.

.EXAMPLE
    'S-1-5-21-1234567890-1234567890-1234567890-1001' | Get-UserAccountFromSID

    Output:
    SID                           Domain   Username
    ---                           ------   --------
    S-1-5-21-1234567890-1234567890-1234567890-1001 DOMAIN   User

    Description:
    This example demonstrates how to pass the SID as pipeline input to retrieve the associated domain and username.

.EXAMPLE
    $sids = @('S-1-5-21-1234567890-1234567890-1234567890-1001', 'S-1-5-21-0987654321-0987654321-0987654321-1002')
    $sids | Get-UserAccountFromSID

    Output:
    SID                           Domain   Username
    ---                           ------   --------
    S-1-5-21-1234567890-1234567890-1234567890-1001 DOMAIN   User
    S-1-5-21-0987654321-0987654321-0987654321-1002 DOMAIN   User

    Description:
    This example demonstrates how to pass multiple SIDs through the pipeline and retrieve their associated domain and username.

.EXAMPLE
    Get-UserAccountFromSID -SID 'S-1-5-21-1234567890-1234567890-1234567890-1001'

    Warning:
    Failed to translate SID: S-1-5-21-1234567890-1234567890-1234567890-1001

    Output:
    SID                           Domain   Username
    ---                           ------   --------
    S-1-5-21-1234567890-1234567890-1234567890-1001 null     null

    Description:
    This example demonstrates the behavior of the function when it fails to translate the SID. A warning is issued, and the domain and username are returned as null.
#>
function Get-UserAccountFromSID
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({
                if (Validate-SIDFormat -SID $_)
                {
                    $true  # Valid SID format
                }
                else
                {
                    throw "Invalid SID format: $_"
                }
            })]
        [string]$SID,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME  # Default to the local computer
    )

    begin
    {
    }

    process
    {
        try
        {
            # Define the script block that performs the SID-to-account translation
            $scriptBlock = {
                param ($SID)
                try
                {
                    $ntAccount = New-Object System.Security.Principal.SecurityIdentifier($SID)
                    $userAccount = $ntAccount.Translate([System.Security.Principal.NTAccount])
                    $domain, $username = $userAccount.Value.Split('\', 2)
                    return [pscustomobject]@{
                        Domain   = $domain
                        Username = $username
                    }
                }
                catch
                {
                    Write-Warning "Failed to translate SID: $SID"
                    return [pscustomobject]@{
                        Domain   = $null
                        Username = $null
                    }
                }
            }

            # Invoke the command locally or remotely
            $result = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ArgumentList $SID

            # Assign the returned result to variables
            $domain = $result.Domain
            $username = $result.Username
        }
        catch
        {
            Write-Warning "Failed to translate SID: $SID"
            $domain = $null
            $username = $null
        }

        [pscustomobject]@{
            SID      = $SID
            Domain   = $domain
            Username = $username
        }
    }

    end
    {
    }
}
