Remove-Module WinProfileOps -ErrorAction SilentlyContinue
Import-Module "D:\1_Code\GithubRepos\WinProfileOps\output\module\WinProfileOps\0.0.1\WinProfileOps.psd1" -Force


$null = Remove-Item -Path $env:WinProfileOps_RegBackUpDirectory -Recurse -Force -ErrorAction SilentlyContinue

$TestDrive = "C:\Temp\TestDirectory"

if (Test-Path "$TestDrive\Users")
{
    $null = Remove-Item -Path "$TestDrive\Users" -Recurse -Force -ErrorAction SilentlyContinue
}

# Create mock profile folders in TestDrive
$MockProfilePath = mkdir "$TestDrive\Users"
$MockUsers = @(
    @{
        Foldername = "User1"
        SID        = "S-1-5-21-1234567890-1"
    },
    @{
        Foldername = "User2"
        SID        = "S-1-5-21-1234567890-2"
    },
    @{
        Foldername = "User3"
        SID        = "S-1-5-21-1234567890-3"
    }
)

$MockUsers | ForEach-Object {
    $null = mkdir "$TestDrive\Users\$($_.Foldername)"
}

# Mock registry entries in TestRegistry
$MockRegistryPath = "HKCU:\Software\Pester\ProfileList"

# Create registry path if it doesn't exist
if (-not (Test-Path $MockRegistryPath))
{
    $null = New-Item -Path $MockRegistryPath -ItemType Directory
}

# Set up the environment variable for the registry path
$env:WinProfileOps_RegistryPath = "Software\Pester\ProfileList"
$env:WinProfileOps_RegistryHive = [Microsoft.Win32.RegistryHive]::CurrentUser
$env:WinProfileOps_ProfileFolderPath = "$TestDrive\Users"

# Create registry items for each mock user
$MockUsers | ForEach-Object {
    $SID = $_.SID
    $FolderName = $_.Foldername
    $RegistryItemPath = "$MockRegistryPath\$SID"

    # Create registry key and set profile path
    if (-not (Test-Path $RegistryItemPath))
    {
        $null = New-Item -Path $RegistryItemPath
    }

    $null = Set-ItemProperty -Path $RegistryItemPath -Name ProfileImagePath -Value "$TestDrive\Users\$FolderName"
}

$ProfileFolderPath = $env:WinProfileOps_ProfileFolderPath
$userProfileAudit = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath -IgnoreSpecial

#$out = Remove-UserProfilesFromRegistry -SIDs "S-1-5-21-1234567890-1", "S-1-5-21-1234567890-2" -Confirm:$false
