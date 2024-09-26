<#
.SYNOPSIS
    Audits user profiles on a specified computer by comparing profiles found in the registry and file system.

.DESCRIPTION
    The Invoke-UserProfileAudit function retrieves user profile information from both the file system (user folders)
    and the registry on a specified computer. It compares these profiles to identify orphaned profiles,
    profiles that exist in one location but not the other, and optionally ignores special or default profiles.
    This function is useful for auditing user profiles and detecting inconsistencies across the registry and file system.

.PARAMETER ComputerName
    The name of the computer from which to audit user profiles. Defaults to the local computer.

.PARAMETER ProfileFolderPath
    The path to the folder where user profiles are stored. Defaults to "$env:SystemDrive\Users".

.PARAMETER IgnoreSpecial
    Switch to ignore special or default profiles (such as system accounts or service accounts) during the audit process.

.OUTPUTS
    [UserProfile[]]
    Returns an array of UserProfile objects that represent the profiles found during the audit. Each UserProfile object contains the following properties:
    - SID: [string] The security identifier of the user profile.
    - ProfilePath: [string] The file system path of the user profile.
    - IsOrphaned: [bool] Whether the profile is considered orphaned.
    - OrphanReason: [string] The reason for orphaned status if applicable.
    - ComputerName: [string] The name of the computer where the audit was performed.
    - IsSpecial: [bool] Whether the profile is considered special or a system account.

.EXAMPLE
    Invoke-UserProfileAudit -ComputerName "Server01"
    Audits all user profiles from both the file system and the registry on "Server01".

.EXAMPLE
    Invoke-UserProfileAudit -ProfileFolderPath "D:\UserProfiles" -IgnoreSpecial
    Audits user profiles from the "D:\UserProfiles" folder on the local computer, ignoring special or default profiles.

.EXAMPLE
    Get-AllUserProfiles -ComputerName "Server01"
    This alias performs the same audit as Invoke-UserProfileAudit, returning all user profiles for "Server01".

.NOTES
    This function performs a profile audit by comparing user profiles in the file system and registry.
    It supports pipeline input for multiple computer names and includes an alias `Get-AllUserProfiles`.
#>

function Invoke-UserProfileAudit
{
    [OutputType([UserProfile[]])]
    [CmdletBinding()]
    [Alias("Get-AllUserProfiles")]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [string]$ProfileFolderPath = $env:WinProfileOps_ProfileFolderPath,

        [string]$RegistryPath = $Env:WinProfileOps_RegistryPath,
        [string]$RegistryHive = $env:WinProfileOps_RegistryHive,

        [switch]$IgnoreSpecial
    )

    begin
    {
        $AllProfiles = @()
        if ($null -eq $ComputerName)
        {
            $ComputerName = $env:COMPUTERNAME
        }
    }

    process
    {
        if (-not (Test-ComputerReachability -ComputerName $ComputerName))
        {
            Write-Warning "Computer '$ComputerName' is not reachable."
            return
        }

        try
        {
            # Step 1: Gather profile information from the registry
            $RegistryProfiles = Get-UserProfilesFromRegistry -ComputerName $ComputerName -RegistryHive $RegistryHive -RegistryPath $RegistryPath
            $FolderProfiles = Get-UserProfilesFromFolders -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath

            $JoinedProfiles = Join-UserProfiles -FolderProfiles $FolderProfiles -RegistryProfiles $RegistryProfiles


            # Step 5: Optionally filter out special profiles if IgnoreSpecial is set
            if ($IgnoreSpecial)
            {
                $JoinedProfiles = $JoinedProfiles | Where-Object { -not $_.IsSpecial }
            }

            $JoinedProfiles | ConvertTo-UserProfile -View OrphanDetails

        }
        catch
        {
            Write-Error "Error processing profiles for computer '$ComputerName'. Error: $_"
        }
    }

    end
    {

    }
}
