function New-UserProfileObject {
    param (
        [string]$SID,
        [string]$ProfilePath,
        [bool]$IsOrphaned,
        [string]$OrphanReason,
        [string]$ComputerName,
        [bool]$IsSpecial
    )

    return [UserProfile]::new(
        $SID,
        $ProfilePath,
        $IsOrphaned,
        $OrphanReason,
        $ComputerName,
        $IsSpecial
    )
}
