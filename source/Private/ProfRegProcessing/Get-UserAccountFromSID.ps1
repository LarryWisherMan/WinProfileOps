function Get-UserAccountFromSID
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SID
    )

    begin
    {
    }

    process
    {
        try
        {
            $ntAccount = New-Object System.Security.Principal.SecurityIdentifier($SID)
            $userAccount = $ntAccount.Translate([System.Security.Principal.NTAccount])
            $domain, $username = $userAccount.Value.Split('\', 2)
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
