function Backup-RegistryKeyForSID
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$SID,

        [Parameter(Mandatory = $true)]
        [Microsoft.Win32.RegistryKey]$BaseKey,

        [Parameter(Mandatory = $true)]
        [string]$RegBackUpDirectory,

        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    try
    {
        # Ensure the backup directory exists
        $directoryCreated = New-DirectoryIfNeeded -Directory $RegBackUpDirectory

        # Check if directory creation failed
        if (-not $directoryCreated)
        {
            Write-Error "Error creating or accessing backup directory: $RegBackUpDirectory"
            return $false
        }

        # Backup the registry key associated with the SID
        $RegBackUpObject = New-RegistryKeyValuesObject -RegistryKey $BaseKey -ComputerName $ComputerName -SubKeyName $SID
        $RegBackUpObjectJson = $RegBackUpObject.psobject.copy()
        $RegBackUpObjectJson.BackUpDate = $RegBackUpObject.BackUpDate.tostring("o")

        # Update the backup JSON file with the registry data
        Update-JsonFile -OutputFile "$RegBackUpDirectory\RegBackUp.json" -RegistryData $RegBackUpObjectJson

        return $true
    }
    catch
    {
        Write-Error "Error backing up registry for SID $SID`: $_"
        return $false
    }
}
