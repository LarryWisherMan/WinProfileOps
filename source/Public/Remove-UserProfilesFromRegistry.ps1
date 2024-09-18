function Remove-UserProfilesFromRegistry
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$SIDs, # Array of SIDs to be removed

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME, # Target computer

        [switch]$AuditOnly # If set, function will only audit and not remove profiles
    )

    Begin
    {

        $RegistryPath = $env:GetSIDProfileInfo_RegistryPath
        $ProfileFolderPath = $env:GetSIDProfileInfo_ProfileFolderPath
        $RegistryHive = $env:GetSIDProfile_RegistryHive

        # Validate Registry Path Variables
        if (-not $env:GetSIDProfileInfo_RegistryPath -or -not $env:GetSIDProfileInfo_ProfileFolderPath)
        {
            throw "Missing registry or profile folder path environment variables."
        }

        try
        {
            # Set up for registry backup - Get the directory path, and create if it doesn't exist
            $RegBackUpDirectory = Get-DirectoryPath -basePath $env:WinProfileOps_RegBackUpDirectory -ComputerName $ComputerName -IsLocal ($ComputerName -eq $env:COMPUTERNAME)
            $null = Test-DirectoryExistence -Directory $RegBackUpDirectory

            # Open the registry key and audit user profiles
            $BaseKey = Open-RegistryKey -RegistryHive $RegistryHive -RegistryPath $RegistryPath -ComputerName $ComputerName
            $userProfileAudit = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath -IgnoreSpecial

            if (-not $BaseKey)
            {
                throw "Failed to open registry key at path: $RegistryPath"
            }
        }
        catch
        {
            throw "Error in Begin block: $_"
        }

        $deletionResults = @() # Initialize results array
    }

    Process
    {
        foreach ($SID in $SIDs)
        {

            $SelectedProfile = $userProfileAudit | Where-Object { $_.SID -eq $SID }

            if ($null -eq $SelectedProfile)
            {
                $deletionResults += New-ProfileDeletionResult -SID $SID -ProfilePath $null -DeletionSuccess $false -DeletionMessage "Profile not found." -ComputerName $ComputerName
                continue
            }

            if ($AuditOnly)
            {
                $deletionResults += New-ProfileDeletionResult -SID $SID -ProfilePath $SelectedProfile.ProfilePath -DeletionSuccess $true -DeletionMessage "Audit only, no deletion performed." -ComputerName $ComputerName
                continue
            }

            if ($PSCmdlet.ShouldProcess($SID, "Remove Profile"))
            {
                $deletionResults += Invoke-ProcessProfileRemoval -SID $SID -BaseKey $BaseKey -RegBackUpDirectory $RegBackUpDirectory -ComputerName $ComputerName -selectedProfile $SelectedProfile
            }
        }
    }

    End
    {
        return $deletionResults
    }
}
