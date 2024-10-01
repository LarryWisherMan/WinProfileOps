# Your functions

# Check if the current user is an administrator
# Check if the current user is an administrator
$windowsIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$windowsPrincipal = New-Object Security.Principal.WindowsPrincipal($windowsIdentity)
$env:WinProfileOps_IsAdmin = $windowsPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Prepopulate other environment variables if they don't already exist

if (-not $env:WinProfileOps_RegistryPath)
{
    $env:WinProfileOps_RegistryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
}
if (-not $env:WinProfileOps_RegistryHive)
{
    $env:WinProfileOps_RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
}
if (-not $env:WinProfileOps_RegBackUpDirectory)
{
    $env:WinProfileOps_RegBackUpDirectory = "C:\LHStuff\RegBackUp"
}
if (-not $env:WinProfileOps_ProfileFolderPath)
{
    $env:WinProfileOps_ProfileFolderPath = $env:SystemDrive + "\Users"
}

# Prepopulate IgnoredAccounts, IgnoredSIDs, and IgnoredPaths if they aren't set
if (-not $env:WinProfileOps_IgnoredAccounts)
{
    $env:WinProfileOps_IgnoredAccounts = "defaultuser0;DefaultAppPool;servcm12;Public;PBIEgwService;Default;All Users;win2kpro"
}

if (-not $env:WinProfileOps_IgnoredSIDs)
{
    $env:WinProfileOps_IgnoredSIDs = "S-1-5-18;S-1-5-19;S-1-5-20"

}

if (-not $env:WinProfileOps_IgnoredPaths)
{
    $env:WinProfileOps_IgnoredPaths = "C:\WINDOWS\system32\config\systemprofile;C:\WINDOWS\ServiceProfiles\LocalService;C:\WINDOWS\ServiceProfiles\NetworkService"
}


[scriptblock]$SB = {
    Get-ChildItem "Env:\WinProfileOps*" | ForEach-Object {
        Remove-Item "Env:\$($_.Name)" -ErrorAction SilentlyContinue
    }
}

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    $sb.Invoke()
}

# Define the OnRemove script block for the module
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    $sb.Invoke()
}
