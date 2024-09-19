function Remove-UserProfilesFromRegistry
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "SIDSet")]
        [string[]]$SIDs,

        [Parameter(Mandatory = $true, ParameterSetName = "UserNameSet")]
        [string[]]$Usernames,

        [Parameter(Mandatory = $true, ParameterSetName = "UserProfileSet")]
        [UserProfile[]]$UserProfiles,

        [string]$ComputerName = $env:COMPUTERNAME,
        [switch]$AuditOnly,
        [switch]$Force
    )

    Begin
    {
        # Retrieve and validate necessary paths
        $RegistryPath = Test-EnvironmentVariable -Name 'GetSIDProfileInfo_RegistryPath'
        $ProfileFolderPath = Test-EnvironmentVariable -Name 'GetSIDProfileInfo_ProfileFolderPath'
        $RegistryHive = $env:GetSIDProfile_RegistryHive

        $deletionResults = @()

        # Convert Usernames to SIDs if needed
        if ($PSCmdlet.ParameterSetName -eq 'UserNameSet')
        {
            $SIDs = Resolve-UsernamesToSIDs -Usernames $Usernames -ComputerName $ComputerName
        }

        # Group user profiles by computer for UserProfileSet
        if ($PSCmdlet.ParameterSetName -eq 'UserProfileSet')
        {
            $profilesByComputer = $UserProfiles | Group-Object -Property ComputerName
        }

    }

    Process
    {
        # Invoke processing based on the parameter set
        switch ($PSCmdlet.ParameterSetName)
        {
            'UserProfileSet'
            {
                foreach ($profileGroup in $profilesByComputer)
                {
                    Invoke-UserProfileProcessing -ComputerName $profileGroup.Name -Profiles $profileGroup.Group `
                        -RegistryPath $RegistryPath -ProfileFolderPath $ProfileFolderPath -RegistryHive $RegistryHive `
                        -Force:$Force -AuditOnly:$AuditOnly -Confirm:$PSCmdlet.MyInvocation.BoundParameters['Confirm']
                }
            }
            'SIDSet'
            {
                Invoke-UserProfileProcessing -ComputerName $ComputerName -SIDs $SIDs `
                    -RegistryPath $RegistryPath -ProfileFolderPath $ProfileFolderPath -RegistryHive $RegistryHive `
                    -Force:$Force -AuditOnly:$AuditOnly -Confirm:$PSCmdlet.MyInvocation.BoundParameters['Confirm']
            }
        }
    }

    End
    {
        return $deletionResults
    }
}
