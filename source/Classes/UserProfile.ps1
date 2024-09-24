class UserProfile
{
    [string]$SID
    [string]$ProfilePath
    [bool]$IsOrphaned
    [string]$OrphanReason = $null
    [string]$ComputerName
    [bool]$IsSpecial
    [string] GetUserNameFromPath() {
        return [System.IO.Path]::GetFileName($this.ProfilePath) # Extract the leaf (username) from the ProfilePath
    }


    # Constructor to initialize the properties
    UserProfile([string]$sid, [string]$profilePath, [bool]$isOrphaned, [string]$orphanReason, [string]$computerName, [bool]$isSpecial)
    {
        $this.SID = $sid
        $this.ProfilePath = $profilePath
        $this.IsOrphaned = $isOrphaned
        $this.OrphanReason = $orphanReason
        $this.ComputerName = $computerName
        $this.IsSpecial = $isSpecial
    }
}
