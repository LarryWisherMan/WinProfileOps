<#
.SYNOPSIS
Backs up a registry key associated with a specific SID to a specified directory.

.DESCRIPTION
The `Backup-RegistryKeyForSID` function creates a backup of the registry key associated with the provided SID from a remote or local machine. It ensures that the backup directory exists before proceeding, creates a JSON representation of the registry data, and appends the backup to an existing JSON file.

.PARAMETER SID
Specifies the Security Identifier (SID) for which the registry key backup is created.

.PARAMETER BaseKey
Specifies the base registry key under which the SID subkey exists.

.PARAMETER RegBackUpDirectory
Specifies the directory where the registry backup will be saved.

.PARAMETER ComputerName
Specifies the name of the computer from which the registry key is being backed up.

.EXAMPLE
Backup-RegistryKeyForSID -SID 'S-1-5-21-...' -BaseKey $RegistryKey -RegBackUpDirectory 'C:\Backups' -ComputerName 'Server01'

Description:
Backs up the registry key for the specified SID from Server01 to the 'C:\Backups' directory.

.OUTPUTS
Boolean indicating success or failure.

.NOTES
This function relies on helper functions like `New-DirectoryIfNeeded` and `New-RegistryKeyValuesObject` to handle registry operations.
#>

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
