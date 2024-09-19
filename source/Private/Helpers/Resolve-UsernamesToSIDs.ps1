function Resolve-UsernamesToSIDs
{
    param (
        [string[]]$Usernames,
        [string]$ComputerName
    )

    $SIDs = @()
    foreach ($Username in $Usernames)
    {
        $SID = Get-SIDFromUsername -Username $Username -ComputerName $ComputerName
        if ($SID)
        {
            $SIDs += $SID
        }
        else
        {
            Write-Warning "Could not resolve SID for username $Username on $ComputerName."
        }
    }
    return $SIDs
}
