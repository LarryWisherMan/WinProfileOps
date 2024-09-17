<#
.SYNOPSIS
    Deletes a registry key associated with a specific SID from the ProfileList.
.DESCRIPTION
    The Remove-RegistryKeyForSID function deletes the registry key corresponding to a specific Security Identifier (SID) from the ProfileList in the Windows registry. It supports confirmation prompts and simulates actions with the -WhatIf parameter.
.PARAMETER SID
    The Security Identifier (SID) for which the registry key should be deleted.
.PARAMETER ProfileListKey
    The opened registry key representing the ProfileList where the profile's SID is located.
.PARAMETER ComputerName
    The name of the computer where the profile registry key resides. By default, this is the current computer.
.EXAMPLE
    Remove-RegistryKeyForSID -SID "S-1-5-21-123456789-1001" -ProfileListKey $profileListKey -ComputerName "Server01"
    Deletes the registry key for the specified SID from the ProfileList on "Server01".
.NOTES
    This function supports 'ShouldProcess', so it can be used in conjunction with the -WhatIf or -Confirm parameters to simulate the deletion.
    It also includes error handling to ensure any failure during the registry key deletion is captured.
#>

function Remove-RegistryKeyForSID
{
    # Deletes a single registry key for a SID.
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$SID,

        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$ProfileListKey,

        [Parameter(Mandatory = $true)]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    try
    {
        # Check if ShouldProcess is approved (with -WhatIf and -Confirm support)
        if ($PSCmdlet.ShouldProcess("SID: $SID on $ComputerName", "Remove registry key"))
        {
            # Use the general Remove-RegistrySubKey function to delete the SID's subkey
            return Remove-RegistrySubKey -ParentKey $ProfileListKey -SubKeyName $SID -Confirm:$false
        }
        else
        {
            Write-Verbose "Removal of registry key for SID '$SID' was skipped."
            return $false
        }
    }
    catch
    {
        Write-Error "Failed to remove the profile registry key for SID '$SID' on $ComputerName. Error: $_"
        return $false
    }
}
