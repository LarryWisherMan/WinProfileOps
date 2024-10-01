<#
.SYNOPSIS
    Validates whether a given string follows the correct SID (Security Identifier) format.

.DESCRIPTION
    The Validate-SIDFormat function checks if a given string matches the standard SID format.
    SIDs typically start with 'S-1-' followed by a series of digits separated by hyphens.
    This function returns $true if the SID format is valid and $false if it is not.

.PARAMETER SID
    The SID string to validate. This should follow the typical format: 'S-1-' followed by
    a series of digits and hyphens.

.OUTPUTS
    [bool]
    Returns $true if the SID format is valid; otherwise, returns $false.

.EXAMPLE
    PS> Validate-SIDFormat -SID 'S-1-5-18'
    True

    This example checks if the SID 'S-1-5-18' is valid.

.EXAMPLE
    PS> Validate-SIDFormat -SID 'Invalid-SID'
    WARNING: Invalid SID format encountered: 'Invalid-SID'.
    False

    This example demonstrates how the function handles an invalid SID format by returning $false
    and issuing a warning.

.NOTES

.LINK
    https://docs.microsoft.com/en-us/windows/win32/secauthz/security-identifiers

#>
function Validate-SIDFormat
{
    param (
        [OutPutType([bool])]
        [CmdletBinding()]
        [Parameter(Mandatory = $true)]
        [string]$SID
    )

    # Regular expression pattern for validating the SID format
    $sidPattern = '^S-1-\d+(-\d+)+$'

    if ($SID -notmatch $sidPattern)
    {
        Write-Warning "Invalid SID format encountered: '$SID'."
        return $false
    }

    return $true
}
