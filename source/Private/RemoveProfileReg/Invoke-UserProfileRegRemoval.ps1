<#
.SYNOPSIS
Removes user profile registry entries from local or remote computers, with optional confirmation.

.DESCRIPTION
The `Invoke-UserProfileRegRemoval` function processes user profiles for removal based on Security Identifiers (SIDs). It retrieves profiles from a specified registry path and profile folder, performs an audit, and optionally prompts for confirmation before removal. The `Force` switch can bypass the confirmation prompt, and the `AuditOnly` switch allows auditing without any removal action.

If the registry key cannot be opened or the audit fails, the function terminates early to prevent further processing.

.PARAMETER ComputerName
Specifies the name of the computer where the profile removal is executed. This can be a local or remote machine.

.PARAMETER SID
Specifies the Security Identifier (SID) of the user profile to remove. This parameter accepts pipeline input, allowing multiple SIDs to be processed sequentially.

.PARAMETER RegistryPath
Specifies the registry path where user profile information is stored. For example, `SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList`.

.PARAMETER ProfileFolderPath
Specifies the folder path where user profile data is stored. For example, `C:\Users`.

.PARAMETER RegistryHive
Specifies the registry hive (e.g., HKLM for HKEY_LOCAL_MACHINE or HKCU for HKEY_CURRENT_USER) under which the profile keys are located.

.PARAMETER Force
Forces the removal of profiles without prompting for confirmation. When this switch is used, profiles are removed without any user interaction.

.PARAMETER AuditOnly
Performs an audit without removing any profiles. The audit results are output to the pipeline, and no changes are made to the registry.

.PARAMETER Confirm
If specified, the user is prompted for confirmation before removing each profile. The prompt is skipped if `Force` or `AuditOnly` switches are used.

.EXAMPLE
Get-UserProfiles | Invoke-UserProfileRegRemoval -ComputerName 'Server01' -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ProfileFolderPath 'C:\Users' -RegistryHive 'LocalMachine' -Force

Description:
Removes all user profiles from the registry on Server01 without prompting for confirmation, as the `Force` switch is used.

.EXAMPLE
Get-UserProfiles | Invoke-UserProfileRegRemoval -ComputerName 'Server02' -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ProfileFolderPath 'C:\Users' -RegistryHive 'LocalMachine' -AuditOnly

Description:
Performs an audit of the user profiles on Server02, but does not remove any profiles. The audit results are output to the pipeline.

.EXAMPLE
'S-1-5-21-12345' | Invoke-UserProfileRegRemoval -ComputerName 'Server03' -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ProfileFolderPath 'C:\Users' -RegistryHive 'LocalMachine'

Description:
Processes the specified SID ('S-1-5-21-12345') for removal on Server03. If `Confirm` is specified, the user is prompted before the profile is removed.

.NOTES
- This function uses pipeline input to process multiple SIDs.
- The function handles both local and remote computers.
- Errors during registry key access or audit failure result in early termination.
- If special system profiles are detected during the audit, they can be skipped based on the implementation of the audit function.
#>
function Invoke-UserProfileRegRemoval
{
    [CmdletBinding()]
    param (
        [string]$ComputerName,

        # Accept pipeline input for each SID
        [Parameter(ValueFromPipeline = $true)]
        [string]$SID,

        [string]$RegistryPath,
        [string]$ProfileFolderPath,
        [Microsoft.Win32.RegistryHive]$RegistryHive,
        [switch]$Force,
        [switch]$AuditOnly,
        [bool]$Confirm
    )

    Begin
    {
        # Initialize a flag to determine if processing should continue
        $continueProcessing = $true

        # Perform audit once for the computer
        $BaseKey = Open-RegistryKey -ComputerName $ComputerName -RegistryHive $RegistryHive -RegistryPath $RegistryPath

        # Exit early if the registry key cannot be opened
        if (-not $BaseKey -or $null -eq $BaseKey)
        {
            Write-Error "Failed to open registry key on computer $ComputerName"
            $continueProcessing = $false  # Set the flag to prevent processing
            return  # Stop the function entirely if BaseKey is null
        }

        # Perform the audit once and store the results if BaseKey is valid
        if ($continueProcessing)
        {
            $userProfileAudit = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath -IgnoreSpecial

            if (-not $userProfileAudit)
            {
                Write-Error "Failed to audit user profiles on computer $ComputerName"
                $continueProcessing = $false  # Set the flag to prevent processing
                return  # Stop the function entirely if the audit fails
            }
        }
    }

    Process
    {
        # Only proceed if the flag allows processing
        if ($continueProcessing)
        {
            # Process each SID as it flows through the pipeline
            $SelectedProfile = Resolve-UserProfileForDeletion -SID $SID -AuditResults $userProfileAudit -ComputerName $ComputerName

            if ($SelectedProfile -is [ProfileDeletionResult])
            {
                # Output the ProfileDeletionResult directly to the pipeline
                $SelectedProfile
            }
            else
            {
                # Skip confirmation if AuditOnly is used
                if (-not $AuditOnly)
                {
                    if (-not $Force -and (ShouldContinueWrapper -Context $PSCmdlet -QueryMessage "Do you want to delete SID $SID from $($SelectedProfile.ComputerName)?" -CaptionMessage "Confirm Deletion"))
                    {
                        $result = Remove-UserProfileRegistryEntry -SelectedProfile $SelectedProfile -BaseKey $BaseKey -AuditOnly:$AuditOnly
                        $result
                    }
                    elseif ($Force)
                    {
                        $result = Remove-UserProfileRegistryEntry -SelectedProfile $SelectedProfile -BaseKey $BaseKey -AuditOnly:$AuditOnly
                        $result
                    }
                }
                else
                {
                    # Just process without confirmation
                    $result = Remove-UserProfileRegistryEntry -SelectedProfile $SelectedProfile -BaseKey $BaseKey -AuditOnly:$AuditOnly
                    $result
                }
            }
        }
    }

    End
    {
        # Clean up resources
        if ($BaseKey)
        {
            $BaseKey.Dispose()
        }
    }
}
