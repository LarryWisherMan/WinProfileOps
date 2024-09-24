<#
.SYNOPSIS
Removes user profiles from the Windows registry based on SIDs, Usernames, or UserProfile objects.

.DESCRIPTION
The Remove-UserProfilesFromRegistry function allows you to remove user profiles from the Windows registry.
It supports three parameter sets: UserProfileSet, SIDSet, and UserNameSet. The function can be used in
audit-only mode, where no actual removal is performed, or in deletion mode where profiles are removed.

If AuditOnly is specified, the function will simply output the profiles to be removed without actually performing
any deletions. The function can prompt for confirmation before deletion if required, or use the Force switch
to bypass confirmation.

.PARAMETER UserProfiles
An array of UserProfile objects to remove from the registry. This parameter is mandatory in the "UserProfileSet"
parameter set. UserProfiles should include the necessary information such as SID, ProfilePath, and ComputerName.

.PARAMETER SIDs
An array of SIDs of user profiles to remove from the registry. This parameter is mandatory in the "SIDSet"
parameter set.

.PARAMETER Usernames
An array of usernames to resolve into SIDs and remove from the registry. This parameter is mandatory in the
"UserNameSet" parameter set.

.PARAMETER ComputerName
Specifies the computer name from which the user profiles should be removed. If not provided, it defaults to
the local computer.

.PARAMETER AuditOnly
When specified, the function only audits the user profiles and does not perform actual deletion. It will output
information about the profiles that would have been removed.

.PARAMETER Force
Forces the removal of the user profiles without prompting for confirmation.

.Outputs
ProfileDeletionResult objects that contain information about the deletion results.

.EXAMPLE
Remove-UserProfilesFromRegistry -SIDs "S-1-5-21-1234567890-1", "S-1-5-21-1234567890-2"

Removes user profiles associated with the provided SIDs from the registry of the local computer.

.EXAMPLE
Remove-UserProfilesFromRegistry -Usernames "john.doe", "jane.smith" -ComputerName "SERVER01" -Force

Removes the profiles associated with the specified usernames on the "SERVER01" machine without prompting for confirmation.

.EXAMPLE
Remove-UserProfilesFromRegistry -UserProfiles $userProfileList -AuditOnly

Audits the profiles in the $userProfileList and outputs what would have been removed without performing actual deletions.

.NOTES
Requires administrative privileges to remove profiles from the registry.

.LINK
Get-Help about_Registry
Get-Help about_Profiles
#>
function Remove-UserProfilesFromRegistry
{
    [outputType([ProfileDeletionResult])]
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "UserProfileSet")]
        [UserProfile[]]$UserProfiles,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "SIDSet")]
        [string[]]$SIDs,


        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = "UserNameSet")]
        [string[]]$Usernames,

        [string]$ComputerName = $env:COMPUTERNAME,
        [switch]$AuditOnly,
        [switch]$Force
        # Default confirm behavior to true
    )

    Begin
    {
        # Retrieve necessary environment variables
        $RegistryPath = Test-EnvironmentVariable -Name 'WinProfileOps_RegistryPath'
        $ProfileFolderPath = Test-EnvironmentVariable -Name 'WinProfileOps_ProfileFolderPath'
        $RegistryHive = Test-EnvironmentVariable -Name 'WinProfileOps_RegistryHive'

        # Resolve SIDs if Usernames are provided
        if ($PSCmdlet.ParameterSetName -eq 'UserNameSet')
        {
            $SIDs = Resolve-UsernamesToSIDs -Usernames $Usernames

            # If no SIDs were resolved, return early
            if (-not $SIDs)
            {
                Write-Error "No SIDs could be resolved for the provided usernames."
                return
            }
        }

        # Group UserProfiles by computer name if using UserProfileSet
        if ($PSCmdlet.ParameterSetName -eq 'UserProfileSet')
        {
            $profilesByComputer = $UserProfiles | Group-Object -Property ComputerName
        }

        # Handle confirmation: default behavior should be prompting unless explicitly set to false
        $Confirm = if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Confirm'))
        {
            $PSCmdlet.MyInvocation.BoundParameters['Confirm']
        }
        else
        {
            $true # Default to true, always prompt unless explicitly overridden
        }
    }
    Process
    {
        # Process UserProfileSet - prompt per computer
        if ($PSCmdlet.ParameterSetName -eq 'UserProfileSet')
        {
            foreach ($profileGroup in $profilesByComputer)
            {
                $thisComputerName = $profileGroup.Name
                $SIDs = $profileGroup.Group.GetEnumerator().SID
                $profileCount = $profileGroup.Count

                try
                {
                    # Call the confirmation prompt and skip this group if the user does not confirm
                    if (-not (PromptForConfirmation -ComputerName $thisComputerName -ItemCount $profileCount -AuditOnly:$AuditOnly -Context $PSCmdlet -confirm:$Confirm))
                    {
                        Write-Verbose "User chose not to continue for $thisComputerName, skipping."
                        continue
                    }

                    # Process the profiles for this computer
                    $SIDs | Invoke-UserProfileRegRemoval -ComputerName $thisComputerName `
                        -RegistryPath $RegistryPath -ProfileFolderPath $ProfileFolderPath `
                        -RegistryHive $RegistryHive -Force:$Force -AuditOnly:$AuditOnly -Confirm:$Confirm
                }
                catch
                {
                    # Handle any errors that occur during processing of this computer
                    Write-Error "Failed to process $thisComputerName. Error: $_.Exception.Message"
                    continue  # Move to the next computer in the loop
                }
            }
        }

        # Process SIDSet and UserNameSet - prompt once for the given computer name
        if ($PSCmdlet.ParameterSetName -eq 'SIDSet' -or $PSCmdlet.ParameterSetName -eq 'UserNameSet')
        {
            $itemCount = $SIDs.Count

            # Call the confirmation prompt and stop if the user does not confirm
            if (-not (PromptForConfirmation -ComputerName $ComputerName -ItemCount $itemCount -AuditOnly:$AuditOnly -Context $PSCmdlet -confirm:$Confirm))
            {
                Write-Verbose "User chose not to continue for $thisComputerName, skipping."
                return
            }

            # Process the SIDs for this computer name
            $SIDs | Invoke-UserProfileRegRemoval -ComputerName $ComputerName `
                -RegistryPath $RegistryPath -ProfileFolderPath $ProfileFolderPath `
                -RegistryHive $RegistryHive -Force:$Force -AuditOnly:$AuditOnly -Confirm:$Confirm
        }
    }

    End
    {
        # No need to manually return results; PowerShell will output naturally
    }
}
