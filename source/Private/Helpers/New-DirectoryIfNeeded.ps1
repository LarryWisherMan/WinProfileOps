function New-DirectoryIfNeeded
{
    param (
        [Parameter(Mandatory = $true)]
        [string]$Directory
    )

    try
    {
        if (-not (Test-Path -Path $Directory))
        {
            # Attempt to create the directory if it doesn't exist
            $newDirectory = New-Item -Path $Directory -ItemType Directory -Force -ErrorAction Stop
            return $newDirectory
        }
        return $true
    }
    catch
    {
        Write-Error "Failed to create directory: $Directory. Error: $_"
        return $false
    }
}
