function Test-FolderExists {
    param (
        [string]$ProfilePath,
        [string]$ComputerName
    )

    $IsLocal = $ComputerName -eq $env:COMPUTERNAME
    $pathToCheck = Get-DirectoryPath -BasePath $ProfilePath -ComputerName $ComputerName -IsLocal $IsLocal
    return Test-Path $pathToCheck
}
