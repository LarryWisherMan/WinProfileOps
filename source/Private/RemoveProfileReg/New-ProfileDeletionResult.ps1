function New-ProfileDeletionResult
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$SID,

        [Parameter(Mandatory = $false)]
        [string]$ProfilePath = $null,

        [Parameter(Mandatory = $true)]
        [bool]$DeletionSuccess,

        [Parameter(Mandatory = $true)]
        [string]$DeletionMessage,

        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    return [ProfileDeletionResult]::new($SID, $ProfilePath, $DeletionSuccess, $DeletionMessage, $ComputerName)
}
