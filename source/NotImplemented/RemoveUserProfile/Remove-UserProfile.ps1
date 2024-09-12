function Remove-UserProfile
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([ProfileDeletionResult[]])]
    param (
        [PSCustomObject]$UserProfile,
        [string]$UserName,
        [string]$SID,
        [switch]$RemoveFolder,
        [switch]$RemoveRegistry,
        [switch]$Force,
        [string]$ComputerName = $env:COMPUTERNAME
    )

    begin
    {
        $deletionResults = @()
        if (-not $RemoveFolder -and -not $RemoveRegistry)
        {
            Write-Error "Specify either -RemoveFolder or -RemoveRegistry."
            return
        }
    }

    process
    {
        # Resolve profile details
        $profileDetails = Resolve-ProfileDetails -UserProfile $UserProfile -UserName $UserName -SID $SID
        if (-not $profileDetails)
        {
            Write-Error "Profile details could not be resolved."
            return
        }

        # Check if it's a special profile
        if (Is-SpecialProfile -FolderName $profileDetails.FolderName -SID $profileDetails.SID -ProfilePath $profileDetails.ProfilePath)
        {
            Write-Error "Cannot remove critical or special profile: $($profileDetails.SID)"
            return
        }

        # Remove folder
        if ($RemoveFolder)
        {
            $deletionResults += Remove-UserFolder -ProfileDetails $profileDetails -Force $Force
        }

        # Remove registry entry
        if ($RemoveRegistry)
        {
            $deletionResults += Remove-UserRegistryEntry -ProfileDetails $profileDetails
        }
    }

    end
    {
        return $deletionResults
    }
}
