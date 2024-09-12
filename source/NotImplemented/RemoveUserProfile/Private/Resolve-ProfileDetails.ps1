function Resolve-ProfileDetails
{
    param (
        [PSCustomObject]$UserProfile,
        [string]$UserName,
        [string]$SID
    )

    if ($UserProfile)
    {
        return [PSCustomObject]@{
            SID         = $UserProfile.SID
            ProfilePath = $UserProfile.ProfilePath
            FolderName  = Split-Path -Path $UserProfile.ProfilePath -Leaf
        }
    }
    elseif ($UserName)
    {
        $sid = (Get-WmiObject -Class Win32_UserAccount -Filter "Name='$UserName'" | Select-Object -ExpandProperty SID)
        $profilePath = [System.IO.Path]::Combine("$env:SystemDrive\Users", $UserName)
        return [PSCustomObject]@{
            SID         = $sid
            ProfilePath = $profilePath
            FolderName  = $UserName
        }
    }
    elseif ($SID)
    {
        $profilePath = (Get-WmiObject -Class Win32_UserProfile -Filter "SID='$SID'" | Select-Object -ExpandProperty LocalPath)
        return [PSCustomObject]@{
            SID         = $SID
            ProfilePath = $profilePath
            FolderName  = Split-Path -Path $profilePath -Leaf
        }
    }
    return $null
}
