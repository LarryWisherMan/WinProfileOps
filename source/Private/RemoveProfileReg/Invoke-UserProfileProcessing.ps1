<#
.SYNOPSIS
Processes user profiles for a specific computer, either by SIDs or UserProfile objects.

.DESCRIPTION
The Invoke-UserProfileProcessing function processes profiles for a given computer. It can handle multiple
profiles, identified by their SIDs or as UserProfile objects. The function interacts with the registry and manages profile removal or auditing.

.PARAMETER ComputerName
The name of the computer where the profiles reside.

.PARAMETER SIDs
(Optional) An array of SIDs for the profiles to process.

.PARAMETER Profiles
(Optional) An array of UserProfile objects to process.

.PARAMETER RegistryPath
The path to the registry key where the profiles are stored.

.PARAMETER ProfileFolderPath
The path to the folder where the user profile directories are stored.

.PARAMETER RegistryHive
The registry hive where the profiles are stored.

.EXAMPLE
Invoke-UserProfileProcessing -ComputerName 'RemotePC' -SIDs $sids -RegistryPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ProfileFolderPath 'C:\Users' -RegistryHive 'LocalMachine'

This command processes the profiles on the remote computer, identified by their SIDs, and interacts with the registry.

.OUTPUTS
Array of ProfileDeletionResult objects.

.NOTES
This function is responsible for handling bulk profile processing on a specific computer.
#>
function Invoke-UserProfileProcessing
{
    param (
        [string]$ComputerName,
        [string[]]$SIDs = $null,
        [UserProfile[]]$Profiles = $null,
        [string]$RegistryPath,
        [string]$ProfileFolderPath,
        [Microsoft.Win32.RegistryHive]$RegistryHive,
        [switch]$Force,
        [switch]$AuditOnly,
        [bool]$Confirm
    )

    $BaseKey = Open-RegistryKey -ComputerName $ComputerName -RegistryHive $RegistryHive -RegistryPath $RegistryPath
    if (-not $BaseKey)
    {
        Write-Error "Failed to open registry key on computer $ComputerName"
        return
    }

    try
    {
        $userProfileAudit = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath

        if ($SIDs)
        {
            foreach ($SID in $SIDs)
            {
                Invoke-SingleProfileAction -SID $SID -AuditResults $userProfileAudit -ComputerName $ComputerName `
                    -BaseKey $BaseKey -Force:$Force -AuditOnly:$AuditOnly `
                    -DeletionResults ([ref]$deletionResults) -Confirm:$Confirm
            }
        }

        if ($Profiles)
        {
            foreach ($Profile in $Profiles)
            {
                Invoke-SingleProfileAction -SID $Profile.SID -AuditResults $userProfileAudit -SelectedProfile $Profile -ComputerName $ComputerName `
                    -BaseKey $BaseKey -Force:$Force -AuditOnly:$AuditOnly `
                    -DeletionResults ([ref]$deletionResults) -Confirm:$Confirm
            }
        }
    }
    finally
    {
        $BaseKey.Dispose()
    }
}
