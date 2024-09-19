function Get-UserProfileLastUseTime
{
    [CmdletBinding()]
    param (
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$SystemDrive = $env:SystemDrive,
        [switch]$UseCitrixLog
    )

    if ($UseCitrixLog)
    {
        $basePath = "$SystemDrive\Users\*\AppData\Local\Citrix\Receiver\Toaster_.log"
    }
    else
    {
        $BasePath = "$SystemDrive\Users\*\AppData\Local\Microsoft\Windows\UsrClass.dat"

    }

    # Check if we are querying a local or remote computer
    $isLocal = ($ComputerName -eq $env:COMPUTERNAME)

    # Define user name expression based on whether it's local or remote
    if ($isLocal)
    {
        $UserNameExpression = @{Label = "User"; Expression = { ($_.directory).tostring().split("\")[2] } }
    }
    else
    {
        $UserNameExpression = @{Label = "User"; Expression = { ($_.directory).tostring().split("\")[5] } }
    }

    # Get the correct directory path (local or remote)
    $Path = Get-DirectoryPath -BasePath $BasePath -ComputerName $ComputerName -IsLocal:$isLocal

    # Define a ComputerName column for output
    $ComputerNameExpression = @{Label = "ComputerName"; Expression = { $ComputerName } }

    # Retrieve the UsrClass.dat file's last write time for each user profile
    Get-ChildItem -Path $Path -Force | Select-Object $UserNameExpression, LastWriteTime, $ComputerNameExpression
}
