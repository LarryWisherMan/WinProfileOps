<#
.SYNOPSIS
Creates a new `ProfileDeletionResult` object with details of a user profile deletion.

.DESCRIPTION
The `New-ProfileDeletionResult` function generates a new object representing the outcome of a user profile deletion operation. This object can include details such as the SID, profile path, deletion status, and computer name.

.PARAMETER SID
Specifies the Security Identifier (SID) of the user profile.

.PARAMETER ProfilePath
Specifies the path to the user profile that was deleted (optional).

.PARAMETER DeletionSuccess
Specifies whether the profile deletion was successful.

.PARAMETER DeletionMessage
Provides a message regarding the profile deletion result.

.PARAMETER ComputerName
Specifies the name of the computer from which the profile was removed.

.EXAMPLE
New-ProfileDeletionResult -SID 'S-1-5-21-...' -DeletionSuccess $true -DeletionMessage 'Profile removed successfully.'

Description:
Creates a `ProfileDeletionResult` object indicating that the profile for the specified SID was successfully removed.

.OUTPUTS
ProfileDeletionResult object containing the details of the deletion operation.
#>
function New-ProfileDeletionResult
{
    [CmdletBinding(DefaultParameterSetName = 'Minimal')]
    param (
        # SID is mandatory in all parameter sets
        [Parameter(Mandatory = $true, ParameterSetName = 'Full')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SuccessOnly')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Minimal')]
        [string]$SID,

        # Full parameter set properties
        [Parameter(Mandatory = $false, ParameterSetName = 'Full')]
        [string]$ProfilePath =$null,

        [Parameter(Mandatory = $true, ParameterSetName = 'Full')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SuccessOnly')]
        [bool]$DeletionSuccess,

        [Parameter(Mandatory = $true, ParameterSetName = 'Full')]
        [string]$DeletionMessage,

        [Parameter(Mandatory = $true, ParameterSetName = 'Full')]
        [string]$ComputerName
    )

    switch ($PSCmdlet.ParameterSetName)
    {
        'Full'
        {
            return [ProfileDeletionResult]::new($SID, $ProfilePath, $DeletionSuccess, $DeletionMessage, $ComputerName)
        }
        'SuccessOnly'
        {
            return [ProfileDeletionResult]::new($SID, $DeletionSuccess)
        }
        'Minimal'
        {
            return [ProfileDeletionResult]::new($SID)
        }
    }
}
