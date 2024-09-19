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

        # Check if existing data is an array; if not, convert it into an array
        if (-not ($existingData -is [System.Collections.IEnumerable]))
        {
            $existingData = @(, $existingData)
        }

        # Concatenate the existing data and the new data
        $existingData += $RegistryData

        # Write the updated data back to the file
        $existingData | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile -Confirm:$false
    }
    else
    {
        # Create a new JSON file with the provided registry data
        $RegistryData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile
    }
}
