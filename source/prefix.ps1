# Your functions


# Check if the current user is an administrator
$windowsIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$windowsPrincipal = New-Object Security.Principal.WindowsPrincipal($windowsIdentity)
$isAdmin = $windowsPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Set the environment variable based on whether the user is an admin
if ($isAdmin)
{
    $ENV:WinProfileOps_IsAdmin = $true
}
else
{
    $ENV:WinProfileOps_IsAdmin = $false
}

Write-Verbose "User is an administrator: $ENV:WinProfileOps_IsAdmin"

[scriptblock]$SB = {
    if (Test-Path Env:\WinProfileOps_IsAdmin)
    {
        Remove-Item Env:\WinProfileOps_IsAdmin
        Write-Verbose "WinProfileOps: Removed WinProfileOps_IsAdmin environment variable."
    }
}

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    $sb.Invoke()
}

# Define the OnRemove script block for the module
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    $sb.Invoke()
}
