# Your functions

# Check if the current user is an administrator
$windowsIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$windowsPrincipal = New-Object Security.Principal.WindowsPrincipal($windowsIdentity)
$env:WinProfileOps_IsAdmin = $windowsPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$env:GetSIDProfileInfo_RegistryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
$env:GetSIDProfile_RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
$env:WinProfileOps_RegBackUpDirectory = "C:\LHStuff\RegBackUp"
$env:GetSIDProfileInfo_ProfileFolderPath = $env:SystemDrive + "\Users"


[scriptblock]$SB = {
    if (Test-Path Env:\WinProfileOps_IsAdmin)
    {
        Remove-Item Env:\WinProfileOps_IsAdmin -errorAction SilentlyContinue
        Remove-Item Env:\GetSIDProfileInfo_RegistryPath -ErrorAction SilentlyContinue
        Remove-Item Env:\GetSIDProfile_RegistryHive -ErrorAction SilentlyContinue
        Remove-Item Env:\WinProfileOps_RegBackUpDirectory -ErrorAction SilentlyContinue
        Remove-Item Env:\GetSIDProfileInfo_ProfileFolderPath -ErrorAction SilentlyContinue
    }
}

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    $sb.Invoke()
}

# Define the OnRemove script block for the module
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    $sb.Invoke()
}
