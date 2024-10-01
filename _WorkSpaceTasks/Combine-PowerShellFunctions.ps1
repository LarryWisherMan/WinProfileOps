param(
    [string]$FolderPath, # Accept a folder path
    [string]$ExportTo     # Export to a single destination file
)

# Ensure the export folder exists if exporting to a directory
$exportFolderPath = Split-Path $ExportTo
if (-not (Test-Path -Path $exportFolderPath))
{
    New-Item -Path $exportFolderPath -ItemType Directory
}

# If the export file doesn't exist, create an empty file
if (-not (Test-Path -Path $ExportTo))
{
    New-Item -Path $ExportTo -ItemType File
}

$combinedContent = ""

# Get all .ps1 files in the folder
$FunctionFiles = Get-ChildItem -Path $FolderPath -Filter *.ps1

foreach ($FunctionFile in $FunctionFiles)
{
    # Read the contents of the function file
    $functionsContent = Get-Content -Path $FunctionFile.FullName -Raw

    # Use a regular expression to match each function in the file
    $functionPattern = 'function\s+([^\s]+)\s*{[^{}]*((?>[^{}]+|(?<open>{)|(?<-open>}))*(?(open)(?!)))\s*}'
    $matches = [regex]::Matches($functionsContent, $functionPattern)

    foreach ($match in $matches)
    {
        # Capture the function name and its entire content
        $functionName = $match.Groups[1].Value
        $functionBody = $match.Value

        # Append each function to the combined content
        $combinedContent += "`n`n# Function: $functionName from file $($FunctionFile.FullName)`n"
        $combinedContent += $functionBody
    }
}

# Export all functions to the single export file
Set-Content -Path $ExportTo -Value $combinedContent -Force  # Force overwrites existing file

Write-Host "Exported all functions from provided folder to $ExportTo"
