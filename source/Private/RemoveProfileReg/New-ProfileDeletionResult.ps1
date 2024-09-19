function New-ProfileDeletionResult
{
    [CmdletBinding(DefaultParameterSetName = 'Minimal')]
    param (
        # Parameter set 1: Full constructor with all parameters
        [Parameter(Mandatory = $true, ParameterSetName = 'Full')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SuccessOnly')]
        [string]$SID,

        [Parameter(ParameterSetName = 'Full')]
        [string]$ProfilePath = $null,

        [Parameter(Mandatory = $true, ParameterSetName = 'Full')]
        [Parameter(Mandatory = $true, ParameterSetName = 'SuccessOnly')]
        [bool]$DeletionSuccess = $false,

        [Parameter(ParameterSetName = 'Full')]
        [string]$DeletionMessage = $null,

        [Parameter(ParameterSetName = 'Full')]
        [string]$ComputerName = $env:COMPUTERNAME
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
