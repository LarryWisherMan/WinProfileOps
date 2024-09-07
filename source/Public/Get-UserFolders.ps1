function Get-UserFolders {
    [CmdletBinding()]
    param (
        [string]$ComputerName,
        [string]$ProfileFolderPath = "C:\Users"
    )

    $IsLocal = ($ComputerName -eq $env:COMPUTERNAME)
    $FolderPath = Get-DirectoryPath -BasePath $ProfileFolderPath -ComputerName $ComputerName -IsLocal $IsLocal

    # Get list of all folders in the user profile directory
    $ProfileFolders = Get-ChildItem -Path $FolderPath -Directory | ForEach-Object {
        [PSCustomObject]@{
            FolderName   = $_.Name
            ProfilePath  = Get-DirectoryPath -basepath $_.FullName -ComputerName $ComputerName -IsLocal $true
            ComputerName = $ComputerName
        }
    }

    return $ProfileFolders
}
