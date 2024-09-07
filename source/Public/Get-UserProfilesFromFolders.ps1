function Get-UserProfilesFromFolders {
    param (
        [string]$ComputerName,
        [string]$ProfileFolderPath = "C:\Users"
    )

    # Get user folders and return them
    $UserFolders = Get-UserFolders -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath
    return $UserFolders
}
