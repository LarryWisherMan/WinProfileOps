function New-ProfileRegistryItemObject
{
    param (
        [string]$SID,
        [string]$ProfilePath,
        [string]$ProfileState,
        [string]$ComputerName,
        [bool]$HasRegistryEntry = $true,
        [bool]$IsLoaded,
        [bool]$HasUserFolder,
        [string]$UserName,
        [string]$Domain,
        [bool]$IsSpecial,
        [DateTime]$LastLogOnDate,
        [DateTime]$LastLogOffDate,
        [bool]$ErrorAccess,
        $errorCapture
    )

    return [pscustomobject]@{
        SID              = $SID
        ProfilePath      = $ProfilePath
        ProfileState     = $ProfileState
        ComputerName     = $ComputerName
        HasRegistryEntry = $HasRegistryEntry
        IsLoaded         = $IsLoaded
        HasUserFolder    = $HasUserFolder
        UserName         = $UserName
        Domain           = $Domain
        IsSpecial        = $IsSpecial
        LastLogOnDate    = $LastLogOnDate
        LastLogOffDate   = $LastLogOffDate
        ErrorAccess      = $ErrorAccess
        ErrorCapture     = $errorCapture
    }
}
