<#
.SYNOPSIS
Processes a user profile registry item based on the provided SID and registry information.

.DESCRIPTION
The `Invoke-ProfileRegistryItemProcessing` function processes a user profile from the Windows registry, gathering information such as logon and logoff times, profile state, profile path, and special account status. It also verifies if the profile is loaded and if the user's folder exists on the specified computer. The function outputs a custom profile object to the pipeline containing the gathered data.

.PARAMETER Sid
Specifies the Security Identifier (SID) of the profile to process. This parameter is mandatory and accepts input from the pipeline.

.PARAMETER ComputerName
The name of the computer where the profile resides. This parameter is mandatory.

.PARAMETER ProfileListKey
The registry key that holds the profile information. This is typically the "ProfileList" key in the registry.

.PARAMETER HKEYUsersSubkeyNames
An array of subkey names from HKEY_USERS, used to determine if the profile SID is currently loaded. This parameter is optional.

.EXAMPLE
$SIDs = 'S-1-5-21-1234567890-123456789-1234567890-1001'
$computerName = 'TestComputer'
$profileListKey = Open-RegistrySubKey -BaseKey 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -Writable $false
$subkeyNames = Get-SubkeyNamesFromHKEYUsers

$SIDs | Invoke-ProfileRegistryItemProcessing -ComputerName $computerName -ProfileListKey $profileListKey -HKEYUsersSubkeyNames $subkeyNames

Description:
This example processes a single user profile on the specified computer by providing the SID, computer name, profile list registry key, and subkey names from HKEY_USERS. The function outputs a profile object to the pipeline.

.EXAMPLE
Get-ADUser -Filter * | ForEach-Object {
    Invoke-ProfileRegistryItemProcessing -Sid $_.SID -ComputerName 'TestComputer' -ProfileListKey $ProfileListKey
}

Description:
This example retrieves all Active Directory users and processes their corresponding profile registry entries on a specific computer, outputting profile objects to the pipeline.

.INPUTS
[string] - The SID of the user profile (pipeline input is accepted).
[string] - The computer name where the profile resides.
[Microsoft.Win32.RegistryKey] - The profile list registry key.
[string[]] - An array of HKEY_USERS subkey names.

.OUTPUTS
[PSCustomObject] - The processed profile object containing information about the user profile, including logon/logoff times, profile path, and special account status.

.NOTES
- The function handles exceptions like unauthorized access when accessing registry keys.
- It checks for the existence of a user folder and whether the profile is loaded.
- This function is designed to work both locally and remotely by providing the correct computer name and registry key information.

#>
function Invoke-ProfileRegistryItemProcessing
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Sid,

        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        $ProfileListKey,

        [Parameter(Mandatory = $false)]
        [string[]]$HKEYUsersSubkeyNames
    )

    process
    {
        Write-Verbose "Processing SID: $Sid"

        if (-not (Validate-SIDFormat -SID $Sid))
        {
            Write-Warning "Invalid SID format: $Sid"
            return
        }

        $subKey = Open-RegistrySubKey -BaseKey $ProfileListKey -Name $Sid -Writable $false
        if (-not $subKey)
        {
            Write-Warning "Registry key for SID '$Sid' could not be opened."
            return
        }

        # Initialize the parameter hashtable
        $ParameterHash = @{
            SID          = $Sid
            ComputerName = $ComputerName
            ErrorAccess  = $false
        }

        try
        {
            # Test and gather information
            $LogonDates = Get-LogonLogoffDatesFromRegistry -SubKey $subKey
            $ParameterHash.LastLogOnDate = $LogonDates.logonDate
            $ParameterHash.LastLogOffDate = $LogonDates.logoffDate

            $ProfileState = Get-ProfileStateFromRegistrySubKey -SubKey $subKey
            $ParameterHash.ProfileState = $ProfileState.StateText

            $profilePathResults = Get-ProfilePathFromSID -SidKey $subKey
            $ProfilePath = $profilePathResults.ProfileImagePath
            $ParameterHash.ProfilePath = $profilePath

            # Use $HKEYUsersSubkeyNames to determine if the SID is loaded
            $isLoaded = $HKEYUsersSubkeyNames -contains $Sid
            $ParameterHash.IsLoaded = $isLoaded

            # Check for user folder existence
            Write-Verbose "Checking for user folder existence: $profilePath"
            $HasUserFolder = Test-FolderExists -ProfilePath $ParameterHash.ProfilePath -ComputerName $ComputerName -ErrorAction Stop
            $ParameterHash.HasUserFolder = $HasUserFolder
        }
        catch [UnauthorizedAccessException]
        {
            Write-Warning "Access denied when processing SID '$Sid'."
            $ParameterHash.ErrorAccess = $true
            $ParameterHash.HasUserFolder = $true
        }
        catch
        {
            Write-Warning "Failed to retrieve registry data for SID '$Sid'. Error: $_"
            return
        }

        # Special account test
        $TestSpecialParams = @{ SID = $Sid }
        if ($profilePath)
        {
            $TestSpecialParams.Add("FolderName", (Split-Path -Path $profilePath -Leaf))
            $TestSpecialParams.Add("ProfilePath", $profilePath)
        }

        $IsSpecialResults = Test-SpecialAccount @TestSpecialParams
        $ParameterHash.IsSpecial = $IsSpecialResults.IsSpecial

        # Translate SID to user account information
        $accountInfo = Get-UserAccountFromSID -SID $Sid -ComputerName $ComputerName
        $ParameterHash.Domain = $accountInfo.Domain
        $ParameterHash.UserName = $accountInfo.Username

        # Invoke New-ProfileRegistryItemObject using the hashtable and output to the pipeline
        $ProfileRegistryItem = New-ProfileRegistryItemObject @ParameterHash

        $subKey.Close()
        # Output the item directly to the pipeline
        $ProfileRegistryItem
    }

}
