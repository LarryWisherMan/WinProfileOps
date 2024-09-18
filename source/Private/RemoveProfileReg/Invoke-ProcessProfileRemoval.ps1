function Invoke-ProcessProfileRemoval
{
    param (
        [string]$SID,
        [Microsoft.Win32.RegistryKey]$BaseKey,
        [string]$RegBackUpDirectory,
        [string]$ComputerName,
        [object]$SelectedProfile
    )

    try
    {
        # Backup the registry key associated with the SID
        $RegBackUpObject = New-RegistryKeyValuesObject -RegistryKey $BaseKey -ComputerName $ComputerName -SubKeyName $SID
        Remove-RegistrySubKey -ParentKey $BaseKey -SubKeyName $SID -ThrowOnMissingSubKey $false

        $VerifyDeletion = ($BaseKey.GetSubKeyNames() -notcontains $SID)

        if ($VerifyDeletion)
        {
            Update-JsonFile -OutputFile "$RegBackUpDirectory\RegBackUp.json" -RegistryData $RegBackUpObject
            return New-ProfileDeletionResult -SID $SID -ProfilePath $SelectedProfile.ProfilePath -DeletionSuccess $true -DeletionMessage "Profile removed successfully." -ComputerName $ComputerName
        }
        else
        {
            return New-ProfileDeletionResult -SID $SID -ProfilePath $SelectedProfile.ProfilePath -DeletionSuccess $false -DeletionMessage "Profile not removed." -ComputerName $ComputerName
        }
    }
    catch
    {
        Write-Error "Error removing profile for SID $SID`: $_"
        return New-ProfileDeletionResult -SID $SID -ProfilePath $SelectedProfile.ProfilePath -DeletionSuccess $false -DeletionMessage "Error during removal." -ComputerName $ComputerName
    }
}
