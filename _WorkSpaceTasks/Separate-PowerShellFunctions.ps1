param(
    [string]$FunctionFile, # The input file containing multiple functions
    [string]$ExportTo       # The export folder for individual function files
)

# Ensure the export folder exists
if (-not (Test-Path -Path $ExportTo))
{
    New-Item -Path $ExportTo -ItemType Directory -Force
}

# Read the contents of the function file
$functionsContent = Get-Content -Path $FunctionFile -Raw

# Use a regular expression to match each function in the file
$functionPattern = 'function\s+([^\s]+)\s*{[^{}]*((?>[^{}]+|(?<open>{)|(?<-open>}))*(?(open)(?!)))\s*}'
$matches = [regex]::Matches($functionsContent, $functionPattern)

foreach ($match in $matches)
{
    # Capture the function name and its entire content
    $functionName = $match.Groups[1].Value
    $functionBody = $match.Value

    # Define the export file path for each function
    $exportFilePath = Join-Path -Path $ExportTo -ChildPath "$functionName.ps1"

    # Ensure the directory exists for the file path (especially if nested directories are involved)
    $exportFolder = Split-Path -Path $exportFilePath -Parent
    if (-not (Test-Path -Path $exportFolder))
    {
        New-Item -Path $exportFolder -ItemType Directory -Force
    }

    # Export the function to its own file
    Set-Content -Path $exportFilePath -Value $functionBody

    Write-Host "Exported $functionName to $exportFilePath"
}
