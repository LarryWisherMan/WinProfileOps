<#
.SYNOPSIS
    Checks if a profile folder exists on a specified computer.
.DESCRIPTION
    The Test-FolderExists function determines whether a given profile folder exists on the specified computer by testing the path.
.PARAMETER ProfilePath
    The file path of the profile folder to check.
.PARAMETER ComputerName
    The name of the computer where the profile folder is located.
.EXAMPLE
    Test-FolderExists -ProfilePath "C:\Users\John" -ComputerName "Server01"
    Checks if the folder "C:\Users\John" exists on "Server01".
#>

function Test-FolderExists
{
    param (
        [string]$ProfilePath,
        [string]$ComputerName
    )

    $IsLocal = $ComputerName -eq $env:COMPUTERNAME
    $pathToCheck = Get-DirectoryPath -BasePath $ProfilePath -ComputerName $ComputerName -IsLocal $IsLocal
    return Test-Path $pathToCheck
}
