function Test-ComputerReachability
{
    param (
        [string]$ComputerName
    )

    if (-not (Test-ComputerPing -ComputerName $ComputerName))
    {
        Write-Warning "Computer '$ComputerName' is offline or unreachable."
        return $false
    }
    return $true
}
