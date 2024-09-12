<#
.SYNOPSIS
    Tests whether a specified computer is reachable by performing a network ping.

.DESCRIPTION
    The Test-ComputerReachability function checks whether a specified computer is reachable by using a ping
    test. If the computer is unreachable, the function logs a warning message and returns `$false`. If the
    computer is reachable, it returns `$true`.

.PARAMETER ComputerName
    The name of the computer to test for network reachability.

.OUTPUTS
    [bool]
    Returns `$true` if the computer is reachable, `$false` if the computer is offline or unreachable.

.EXAMPLE
    Test-ComputerReachability -ComputerName "Server01"

    Tests the reachability of "Server01" and returns `$true` if it is reachable, `$false` otherwise.

.NOTES
    This function uses Test-ComputerPing to perform the ping test. If the computer is offline or unreachable,
    a warning is logged and the function returns `$false`.
#>
function Test-ComputerReachability
{
    [OutputType ([bool])]
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    if ($ComputerName -eq $null)
    {
        Write-Warning "No computer name provided."
        return $false
    }

    if (-not (Test-ComputerPing -ComputerName $ComputerName))
    {
        Write-Warning "Computer '$ComputerName' is offline or unreachable."
        return $false
    }
    return $true
}
