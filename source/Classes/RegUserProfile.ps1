class RegUserProfile {
    [string]$SID
    [string]$ProfilePath
    [bool]$IsOrphaned
    [string]$OrphanReason
    [string]$ComputerName
    [bool]$IsSpecial
    [bool]$IsLoaded
    [string]$UserName
    [string]$Domain
    [datetime]$LastLogonDate
    [long]$ProfileSize
    [string]$ProfileType
    [datetime]$CreatedDate
    [string]$ProfileStatus
    [bool]$IsTemporary
    [bool]$IsCorrupted
    [string[]]$SecurityGroups
    [string]$HomeDirectory
    [bool]$IsEncrypted
    [string]$ProfileState
    [string]$LastUsedApp
    [bool]$HasBackup
    [bool]$IsRoaming
    [datetime]$LastModifiedDate
    [bool]$IsAdminProfile

    # New properties
    [bool]$HasUserFolder  # Indicates if the user's folder exists
    [datetime]$Created  # The DateTime when the object was instantiated

    # Constructor
    RegUserProfile(
        [string]$SID,
        [string]$ProfilePath,
        [bool]$IsOrphaned,
        [string]$OrphanReason = $null,
        [string]$ComputerName,
        [bool]$IsSpecial,
        [bool]$IsLoaded,
        [string]$UserName,
        [string]$Domain,
        [datetime]$LastLogonDate,
        [long]$ProfileSize,
        [string]$ProfileType,
        [datetime]$CreatedDate,
        [string]$ProfileStatus,
        [bool]$IsTemporary,
        [bool]$IsCorrupted,
        [string[]]$SecurityGroups,
        [string]$HomeDirectory,
        [bool]$IsEncrypted,
        [string]$ProfileState,
        [string]$LastUsedApp,
        [bool]$HasBackup,
        [bool]$IsRoaming,
        [datetime]$LastModifiedDate,
        [bool]$IsAdminProfile,
        [bool]$HasUserFolder  # New property
    ) {
        # Initialize all properties
        $this.SID = $SID
        $this.ProfilePath = $ProfilePath
        $this.IsOrphaned = $IsOrphaned
        $this.OrphanReason = $OrphanReason
        $this.ComputerName = $ComputerName
        $this.IsSpecial = $IsSpecial
        $this.IsLoaded = $IsLoaded
        $this.UserName = $UserName
        $this.Domain = $Domain
        $this.LastLogonDate = $LastLogonDate
        $this.ProfileSize = $ProfileSize
        $this.ProfileType = $ProfileType
        $this.CreatedDate = $CreatedDate
        $this.ProfileStatus = $ProfileStatus
        $this.IsTemporary = $IsTemporary
        $this.IsCorrupted = $IsCorrupted
        $this.SecurityGroups = $SecurityGroups
        $this.HomeDirectory = $HomeDirectory
        $this.IsEncrypted = $IsEncrypted
        $this.ProfileState = $ProfileState
        $this.LastUsedApp = $LastUsedApp
        $this.HasBackup = $HasBackup
        $this.IsRoaming = $IsRoaming
        $this.LastModifiedDate = $LastModifiedDate
        $this.IsAdminProfile = $IsAdminProfile
        $this.HasUserFolder = $HasUserFolder
        $this.Created = [DateTime]::Now  # Automatically set when object is created
    }

    # JSON Serialization Example
    [string] ToJson() {
        $properties = @{
            SID               = $this.SID
            ProfilePath       = $this.ProfilePath
            IsOrphaned        = $this.IsOrphaned
            OrphanReason      = $this.OrphanReason
            ComputerName      = $this.ComputerName
            IsSpecial         = $this.IsSpecial
            IsLoaded          = $this.IsLoaded
            UserName          = $this.UserName
            Domain            = $this.Domain
            LastLogonDate     = $this.LastLogonDate
            ProfileSize       = $this.ProfileSize
            ProfileType       = $this.ProfileType
            CreatedDate       = $this.CreatedDate
            ProfileStatus     = $this.ProfileStatus
            IsTemporary       = $this.IsTemporary
            IsCorrupted       = $this.IsCorrupted
            SecurityGroups    = $this.SecurityGroups
            HomeDirectory     = $this.HomeDirectory
            IsEncrypted       = $this.IsEncrypted
            ProfileState      = $this.ProfileState
            LastUsedApp       = $this.LastUsedApp
            HasBackup         = $this.HasBackup
            IsRoaming         = $this.IsRoaming
            LastModifiedDate  = $this.LastModifiedDate
            IsAdminProfile    = $this.IsAdminProfile
            HasUserFolder     = $this.HasUserFolder
            Created           = $this.Created  # Include the new Created DateTime property
        }
        return $properties | ConvertTo-Json
    }
}
