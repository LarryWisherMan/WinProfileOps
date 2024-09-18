class ProfileDeletionResult
{
    [string]$SID
    [string]$ProfilePath = $null
    [bool]$DeletionSuccess
    [string]$DeletionMessage
    [string]$ComputerName

    # Constructor to initialize the properties
    ProfileDeletionResult([string]$sid, [string]$profilePath, [bool]$deletionSuccess, [string]$deletionMessage, [string]$computerName)
    {
        $this.SID = $sid
        $this.ProfilePath = $profilePath
        $this.DeletionSuccess = $deletionSuccess
        $this.DeletionMessage = $deletionMessage
        $this.ComputerName = $computerName
    }
}
