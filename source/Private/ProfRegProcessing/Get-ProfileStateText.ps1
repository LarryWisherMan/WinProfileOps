function Get-ProfileStateText
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$state
    )

    $stateText = @()

    Write-Verbose "Profile state: $state"

    # Special case for state = 0 (Standard local profile)
    if ($state -eq 0)
    {
        return "StandardLocal"
    }

    # Bitwise checks for each state flag
    if ($state -band 1)
    {
        $stateText += "Mandatory"
    }
    if ($state -band 2)
    {
        $stateText += "UseCache"
    }
    if ($state -band 4)
    {
        $stateText += "NewLocal"
    }
    if ($state -band 8)
    {
        $stateText += "NewCentral"
    }
    if ($state -band 16)
    {
        $stateText += "UpdateCentral"
    }
    if ($state -band 32)
    {
        $stateText += "DeleteCache"
    }
    if ($state -band 64)
    {
        $stateText += "Upgrade"
    }
    if ($state -band 128)
    {
        $stateText += "GuestUser"
    }
    if ($state -band 256)
    {
        $stateText += "AdminUser"
    }
    if ($state -band 512)
    {
        $stateText += "DefaultNetReady"
    }
    if ($state -band 1024)
    {
        $stateText += "SlowLink"
    }
    if ($state -band 2048)
    {
        $stateText += "TempAssigned"
    }

    # If no flags matched, return "Unknown"
    if (-not $stateText)
    {
        return "Unknown"
    }

    # Return the state descriptions joined by commas
    return $stateText -join ','
}
