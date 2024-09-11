function Invoke-UserProfileAudit
{
    [CmdletBinding()]
    [Alias("Get-AllUserProfiles")]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [string]$ProfileFolderPath = "$env:SystemDrive\Users",
        [switch]$IgnoreSpecial
    )

    begin
    {
        $AllProfiles = @()
    }

    process
    {
        if (-not (Test-ComputerReachability -ComputerName $ComputerName))
        {
            return
        }

        $UserFolders = Get-UserProfilesFromFolders -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath
        $RegistryProfiles = Get-UserProfilesFromRegistry -ComputerName $ComputerName

        $AllProfiles += Process-RegistryProfiles -RegistryProfiles $RegistryProfiles -ComputerName $ComputerName -IgnoreSpecial:$IgnoreSpecial
        $AllProfiles += Process-FolderProfiles -UserFolders $UserFolders -RegistryProfiles $RegistryProfiles -ComputerName $ComputerName -IgnoreSpecial:$IgnoreSpecial
    }

    end
    {
        $AllProfiles
    }
}
