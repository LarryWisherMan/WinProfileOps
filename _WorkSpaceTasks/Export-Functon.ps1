param(
    [string]$FunctionFile,
    [string]$ExportTo
)

# Ensure the export folder exists if exporting to a directory
if (-not (Test-Path -Path $ExportTo))
{
    $exportFolderPath = Split-Path $ExportTo
    if (-not (Test-Path -Path $exportFolderPath))
    {
        New-Item -Path $exportFolderPath -ItemType Directory
    }
}

# Read the contents of the function file
$functionsContent = Get-Content -Path $FunctionFile -Raw

# Use a regular expression to match each function in the file
$functionPattern = 'function\s+([^\s]+)\s*{[^{}]*((?>[^{}]+|(?<open>{)|(?<-open>}))*(?(open)(?!)))\s*}'
$matches = [regex]::Matches($functionsContent, $functionPattern)

$combinedContent = ""

foreach ($match in $matches)
{
    # Capture the function name and its entire content
    $functionName = $match.Groups[1].Value
    $functionBody = $match.Value

    # Append each function to the combined content
    $combinedContent += "`n`n# Function: $functionName`n"
    $combinedContent += $functionBody
}

# Export all functions to the single export file
Set-Content -Path $ExportTo -Value $combinedContent

Write-Host "Exported all functions to $ExportTo"
