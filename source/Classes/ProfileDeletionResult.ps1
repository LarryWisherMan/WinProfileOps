class ProfileDeletionResult
{
    [string]$SID
    [string]$ProfilePath
    [bool]$DeletionSuccess
    [string]$DeletionMessage
    [string]$ComputerName

    # Constructor 1: Full constructor
    ProfileDeletionResult([string]$sid, [string]$profilePath, [bool]$deletionSuccess, [string]$deletionMessage, [string]$computerName)
    {
        $this.SID = $sid
        $this.ProfilePath = $profilePath
        $this.DeletionSuccess = $deletionSuccess
        $this.DeletionMessage = $deletionMessage
        $this.ComputerName = $computerName
    }

    # Constructor 2: Only SID and DeletionSuccess, with default values for others
    ProfileDeletionResult([string]$sid, [bool]$deletionSuccess)
    {
        $this.SID = $sid
        $this.ProfilePath = $null
        $this.DeletionSuccess = $deletionSuccess
        if ($deletionSuccess)
        {
            $this.DeletionMessage = "Operation successful"
        }
        else
        {
            $this.DeletionMessage = "Operation failed"
        }
        $this.ComputerName = $env:COMPUTERNAME
    }

    # Constructor 3: Minimal constructor with defaults for all except SID
    ProfileDeletionResult([string]$sid)
    {
        $this.SID = $sid
        $this.ProfilePath = $null
        $this.DeletionSuccess = $false
        $this.DeletionMessage = "No action performed"
        $this.ComputerName = $env:COMPUTERNAME
    }

    # Optional method
    [string] ToString()
    {
        return "[$($this.SID)] DeletionSuccess: $($this.DeletionSuccess), Message: $($this.DeletionMessage)"
    }
}
