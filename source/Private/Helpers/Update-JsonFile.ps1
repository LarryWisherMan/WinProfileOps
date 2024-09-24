<#
.SYNOPSIS
Updates an existing JSON file with new registry data or creates a new file if one doesn't exist.

.DESCRIPTION
The `Update-JsonFile` function checks if a specified JSON file exists and either updates it with new registry data or creates a new file. If the file exists, it reads the current data, appends the new registry data, and writes it back to the file. If the file does not exist, it creates a new file with the provided data. The function handles registry data in a generic array format.

.PARAMETER OutputFile
Specifies the path to the JSON file that should be updated or created. This parameter is mandatory.

.PARAMETER RegistryData
Specifies the new registry data to add to the JSON file. This should be passed as an array. The function will append this data to any existing data in the file, or it will create a new file with this data if the file doesn't exist.

.EXAMPLE
$registryData = @(
    @{ Name = 'HKEY_LOCAL_MACHINE\Software\TestKey'; Value = 'TestValue1' },
    @{ Name = 'HKEY_LOCAL_MACHINE\Software\AnotherKey'; Value = 'TestValue2' }
)
Update-JsonFile -OutputFile 'C:\Temp\RegistryData.json' -RegistryData $registryData

Description:
This example updates the file `RegistryData.json` in `C:\Temp` with the provided `$registryData`. If the file doesn't exist, it will be created.

.EXAMPLE
Update-JsonFile -OutputFile 'C:\Config\Settings.json' -RegistryData @(@{ Name = 'HKEY_CURRENT_USER\Software\MyApp'; Value = 'UserSetting' })

Description:
This command appends the new registry data to the `Settings.json` file located in `C:\Config`. If the file doesn't exist, a new file is created with the registry data.

.OUTPUTS
None. This function writes updated data back to the file specified in the `OutputFile` parameter.

.NOTES
- The function automatically handles appending new data to existing arrays in the JSON file.
- JSON files are written with a depth of 10 to ensure nested objects are properly serialized.

#>
function Update-JsonFile
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $true)]
        [array]$RegistryData  # Generic data for registry keys
    )

    if (Test-Path $OutputFile)
    {
        # Get the existing data and convert it from JSON
        $existingData = Get-Content -Path $OutputFile -Raw | ConvertFrom-Json

        # Ensure existing data is an array, wrap in an array if necessary
        if (-not ($existingData -is [System.Collections.IEnumerable]))
        {
            $existingData = @($existingData)
        }

        # Ensure the existing data is an array of objects
        if ($existingData -isnot [array])
        {
            $existingData = @($existingData)
        }

        # Concatenate the existing data and the new data
        $combinedData = @($existingData + $RegistryData)

        # Write the updated data back to the file
        $combinedData | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile -Confirm:$false
    }
    else
    {
        # Create a new JSON file with the provided registry data
        $RegistryData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile
    }
}
