param (
    [string]$CurrentFile,
    [string]$WorkspaceFolder
)

# Ensure the file is within the 'source' folder
$sourcePath = Join-Path -Path $WorkspaceFolder -ChildPath "source"
if (-not ($CurrentFile -like "$sourcePath*"))
{
    Write-Warning "The file '$CurrentFile' is not within the 'source' folder. Exiting script."
    exit
}

# Get the directory of the current file
$currentFileDir = Split-Path -Path $CurrentFile

# Determine the relative path based on the file's location within 'source'
$relativePath = $currentFileDir.Substring($sourcePath.Length + 1)
$pathParts = $relativePath.Split("\")
$sourceFolder = $pathParts[0]  # Assumes the first part is the folder name

$Tag = $sourceFolder

# Determine the test subdirectory
if ($pathParts.Length -gt 1)
{
    $subPath = ($pathParts[1..($pathParts.Length - 1)] -join "\")
    $testSubDir = Join-Path -Path $sourceFolder -ChildPath $subPath
}
else
{
    $testSubDir = $sourceFolder
}

# Create the test directory if it doesn't exist
$testDir = Join-Path -Path $WorkspaceFolder -ChildPath "tests/Unit/$testSubDir"
if (-not (Test-Path -Path $testDir))
{
    New-Item -ItemType Directory -Path $testDir -Force | Out-Null
}

# Define the test file name
$testFileName = [System.IO.Path]::GetFileNameWithoutExtension($CurrentFile) + ".tests.ps1"
$testFilePath = Join-Path -Path $testDir -ChildPath $testFileName

# Check if the test file already exists
if (Test-Path -Path $testFilePath)
{
    Write-Warning "Test file '$testFilePath' already exists. Exiting script."
    exit
}

# Define the module name and function name
$moduleName = Get-SamplerProjectName .

# Define the test content
$testContent = @"
BeforeAll {
    `$script:dscModuleName = "$ModuleName"

    Import-Module -Name `$script:dscModuleName

    `$PSDefaultParameterValues['InModuleScope:ModuleName'] = `$script:dscModuleName
    `$PSDefaultParameterValues['Mock:ModuleName'] = `$script:dscModuleName
    `$PSDefaultParameterValues['Should:ModuleName'] = `$script:dscModuleName
}

AfterAll {
    `$PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    `$PSDefaultParameterValues.Remove('Mock:ModuleName')
    `$PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name `$script:dscModuleName -All | Remove-Module -Force
}

Describe '$testFileName Tests' -Tag '$tag' {

}
"@

# Write content to the test file
[System.IO.File]::WriteAllText($testFilePath, $testContent)
Write-Output "Test file '$testFilePath' has been created."
