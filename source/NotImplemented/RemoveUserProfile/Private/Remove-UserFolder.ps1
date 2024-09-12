function Remove-UserFolder
{
    param (
        [PSCustomObject]$ProfileDetails,
        [switch]$Force
    )

    if ($PSCmdlet.ShouldProcess($ProfileDetails.ProfilePath, "Remove user profile folder"))
    {
        try
        {
            if (Test-Path -Path $ProfileDetails.ProfilePath)
            {
                Remove-Item -Path $ProfileDetails.ProfilePath -Recurse -Force -Confirm:$Force
                return [ProfileDeletionResult]::new($ProfileDetails.SID, $ProfileDetails.ProfilePath, $true, "Profile folder removed successfully.", $env:COMPUTERNAME)
            }
            else
            {
                Write-Warning "Profile folder not found: $($ProfileDetails.ProfilePath)"
                return [ProfileDeletionResult]::new($ProfileDetails.SID, $ProfileDetails.ProfilePath, $false, "Profile folder not found.", $env:COMPUTERNAME)
            }
        }
        catch
        {
            Write-Error "Error removing profile folder: $_"
            return [ProfileDeletionResult]::new($ProfileDetails.SID, $ProfileDetails.ProfilePath, $false, "Error removing profile folder: $_", $env:COMPUTERNAME)
        }
    }
}
