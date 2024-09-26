class UserProfile
{
    [datetime]$Created
    [string]$UserName
    [string]$SID
    [string]$ProfilePath
    [string]$ProfileState
    [bool]$HasRegistryEntry
    [bool]$HasUserFolder
    [datetime]$LastLogonDate
    [datetime]$LastLogOffDate
    [bool]$IsOrphaned
    [string]$OrphanReason
    [string]$ComputerName
    [bool]$IsSpecial
    [bool]$IsLoaded
    [string]$Domain

    UserProfile(
        [string]$SID,
        [string]$UserName,
        [string]$ProfilePath,
        [string]$ProfileState,
        [bool]$HasRegistryEntry,
        [bool]$HasUserFolder,
        [datetime]$LastLogonDate,
        [datetime]$LastLogOffDate,
        [bool]$IsOrphaned,
        [string]$OrphanReason,
        [string]$ComputerName,
        [bool]$IsSpecial,
        [bool]$IsLoaded,
        [string]$Domain
    )
    {
        $this.Created = [DateTime]::Now
        $this.SID = $SID
        $this.UserName = $UserName
        $this.ProfilePath = $ProfilePath
        $this.ProfileState = $ProfileState
        $this.HasRegistryEntry = $HasRegistryEntry
        $this.HasUserFolder = $HasUserFolder
        $this.LastLogonDate = if ($LastLogonDate -eq $null) { [datetime]::MinValue } else { $LastLogonDate }
        $this.LastLogOffDate = if ($LastLogOffDate -eq $null) { [datetime]::MinValue } else { $LastLogOffDate }
        $this.IsOrphaned = $IsOrphaned
        $this.OrphanReason = $OrphanReason
        $this.ComputerName = $ComputerName
        $this.IsSpecial = $IsSpecial
        $this.IsLoaded = $IsLoaded
        $this.Domain = $Domain
    }
}
