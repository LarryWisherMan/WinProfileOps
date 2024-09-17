BeforeAll {
    $script:dscModuleName = "WinProfileOps"

    # Import the module being tested
    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName



}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    # Clean up environment variables
    Remove-Item -Path Env:Registry_Path -ErrorAction SilentlyContinue
    Remove-Item -Path Env:Export_Path -ErrorAction SilentlyContinue

}

Describe "PublicFuntions Tests" -Tag "Intergration" {

    Context "Get-UserProfilesFromFolders" {

        BeforeEach {
            $MockOutProfilePath = mkdir "$TestDrive\Users"
            $MockeFolderNames = @("User1", "User2", "User3")

            $MockedItems = $MockeFolderNames | ForEach-Object {
                $FolderName = $_
                mkdir "$TestDrive\Users\$folderName"
            }
        }

        AfterEach {
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force
            }
        }

        It "Should return an array of user profile folders" {

            #$MockRegPath = "TestRegistry:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
            #$MockOutRegPath = New-Item -Path $MockRegPath

            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $result = Get-UserProfilesFromFolders -ComputerName $ComputerName -ProfileFolderPath $profilePath

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ProfilePath | Should -Be "$ProfilePath\User1"
        }
    }

    Context "Get-UserProfilesFromRegistry" {

        BeforeEach {
            # Ensure clean-up of TestDrive before creating folders
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force -ErrorAction SilentlyContinue
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
                mkdir "$TestDrive\Users\$($_.Foldername)"
            }

            # Mock registry entries in TestRegistry
            $MockRegistryPath = "HKCU:\Software\Pester\ProfileList"

            # Create registry path if it doesn't exist
            if (-not (Test-Path $MockRegistryPath))
            {
                New-Item -Path $MockRegistryPath -ItemType Directory
            }

            # Set up the environment variable for the registry path
            $env:GetSIDProfileInfo_RegistryPath = "Software\Pester\ProfileList"
            $env:GetSIDProfile_RegistryHive = [Microsoft.Win32.RegistryHive]::CurrentUser

            # Create registry items for each mock user
            $MockUsers | ForEach-Object {
                $SID = $_.SID
                $FolderName = $_.Foldername
                $RegistryItemPath = "$MockRegistryPath\$SID"

                # Create registry key and set profile path
                if (-not (Test-Path $RegistryItemPath))
                {
                    New-Item -Path $RegistryItemPath
                }

                Set-ItemProperty -Path $RegistryItemPath -Name ProfileImagePath -Value "$TestDrive\Users\$FolderName"
            }
        }


        AfterEach {
            # Clean up mock folders and registry items
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force
            }

            if (Test-Path "HKCU:\Software\Pester\ProfileList")
            {
                Remove-Item -Path "HKCU:\Software\Pester\ProfileList" -Recurse
            }

            #resetEnvVariables
            Remove-Item -Path Env:GetSIDProfileInfo_RegistryPath -ErrorAction SilentlyContinue
            Remove-Item -Path Env:GetSIDProfile_RegistryHive -ErrorAction SilentlyContinue
        }

        It "Should return an array of user profiles from the registry" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName
            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ProfilePath | Should -Be "$ProfilePath\User1"
        }


        It "It should return object even if  missing ProfileImagePath in Registry" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Set-ItemProperty -Path "HKCU:\Software\Pester\ProfileList\S-1-5-21-1234567890-1" -Name ProfileImagePath -Value ""

            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Get-UserProfilesFromRegistry $ComputerName

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].profilePath | Should -BeNullOrEmpty
            $result[0].ExistsInRegistry | Should -Be $true
        }

    }

    Context "Ivoke-UserProfileAudit" {

        BeforeEach {
            # Ensure clean-up of TestDrive before creating folders
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force -ErrorAction SilentlyContinue
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
                mkdir "$TestDrive\Users\$($_.Foldername)"
            }

            # Mock registry entries in TestRegistry
            $MockRegistryPath = "HKCU:\Software\Pester\ProfileList"

            # Create registry path if it doesn't exist
            if (-not (Test-Path $MockRegistryPath))
            {
                New-Item -Path $MockRegistryPath -ItemType Directory
            }

            # Set up the environment variable for the registry path
            $env:GetSIDProfileInfo_RegistryPath = "Software\Pester\ProfileList"
            $env:GetSIDProfile_RegistryHive = [Microsoft.Win32.RegistryHive]::CurrentUser

            # Create registry items for each mock user
            $MockUsers | ForEach-Object {
                $SID = $_.SID
                $FolderName = $_.Foldername
                $RegistryItemPath = "$MockRegistryPath\$SID"

                # Create registry key and set profile path
                if (-not (Test-Path $RegistryItemPath))
                {
                    New-Item -Path $RegistryItemPath
                }

                Set-ItemProperty -Path $RegistryItemPath -Name ProfileImagePath -Value "$TestDrive\Users\$FolderName"
            }
        }


        AfterEach {
            # Clean up mock folders and registry items
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force
            }

            if (Test-Path "HKCU:\Software\Pester\ProfileList")
            {
                Remove-Item -Path "HKCU:\Software\Pester\ProfileList" -Recurse
            }

            #resetEnvVariables
            Remove-Item -Path Env:GetSIDProfileInfo_RegistryPath -ErrorAction SilentlyContinue
            Remove-Item -Path Env:GetSIDProfile_RegistryHive -ErrorAction SilentlyContinue
        }

        It "It should return non orphaned Audit Objects" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $profilePath

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ProfilePath | Should -Be "$ProfilePath\User1"
        }

        It "It should return 1 orphaned due to missing folder" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Remove-Item "$profilePath\User1" -Recurse -Force
            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $profilePath

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].OrphanReason | Should -Be "MissingFolder"
            $result[0].IsOrphaned | Should -Be $true
        }


        It "It should return 1 orphaned due to missing registry entry" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Remove-Item "HKCU:\Software\Pester\ProfileList\S-1-5-21-1234567890-1" -Recurse -Force
            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $profilePath

            $selected = $result | Where-Object { $_.ProfilePath -match "User1" }
            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $selected.OrphanReason | Should -Be "MissingRegistryEntry"
            $selected.IsOrphaned | Should -Be $true
        }

        It "It should return 2 orphaned due to missing ProfileImagePath in Registry" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Set-ItemProperty -Path "HKCU:\Software\Pester\ProfileList\S-1-5-21-1234567890-1" -Name ProfileImagePath -Value ""

            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $profilePath


            $Orphaned = $result | Where-Object { $_.IsOrphaned -eq $true }

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 4
            $Orphaned.Count | Should -Be 2
            $Orphaned[0].OrphanReason | Should -Be "MissingProfileImagePath"
            $Orphaned[1].OrphanReason | Should -Be "MissingRegistryEntry"

        }
    }


    Context "Get-OrphanedProfiles" {

        BeforeEach {
            # Ensure clean-up of TestDrive before creating folders
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force -ErrorAction SilentlyContinue
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
                mkdir "$TestDrive\Users\$($_.Foldername)"
            }

            # Mock registry entries in TestRegistry
            $MockRegistryPath = "HKCU:\Software\Pester\ProfileList"

            # Create registry path if it doesn't exist
            if (-not (Test-Path $MockRegistryPath))
            {
                New-Item -Path $MockRegistryPath -ItemType Directory
            }

            # Set up the environment variable for the registry path
            $env:GetSIDProfileInfo_RegistryPath = "Software\Pester\ProfileList"
            $env:GetSIDProfile_RegistryHive = [Microsoft.Win32.RegistryHive]::CurrentUser

            # Create registry items for each mock user
            $MockUsers | ForEach-Object {
                $SID = $_.SID
                $FolderName = $_.Foldername
                $RegistryItemPath = "$MockRegistryPath\$SID"

                # Create registry key and set profile path
                if (-not (Test-Path $RegistryItemPath))
                {
                    New-Item -Path $RegistryItemPath
                }

                Set-ItemProperty -Path $RegistryItemPath -Name ProfileImagePath -Value "$TestDrive\Users\$FolderName"
            }
        }

        AfterEach {
            # Clean up mock folders and registry items
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force
            }

            if (Test-Path "HKCU:\Software\Pester\ProfileList")
            {
                Remove-Item -Path "HKCU:\Software\Pester\ProfileList" -Recurse
            }

            #resetEnvVariables
            Remove-Item -Path Env:GetSIDProfileInfo_RegistryPath -ErrorAction SilentlyContinue
            Remove-Item -Path Env:GetSIDProfile_RegistryHive -ErrorAction SilentlyContinue
        }

        It "Should return null if no orphaned profiles are found" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Get-OrphanedProfiles -ComputerName $ComputerName -ProfileFolderPath $profilePath

            # Validate the result
            $result | Should -BeNullOrEmpty
            $result.Count | Should -Be 0
        }

        It "Should return 1 orphaned profile due to missing folder" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Remove-Item "$profilePath\User1" -Recurse -Force
            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Get-OrphanedProfiles -ComputerName $ComputerName -ProfileFolderPath $profilePath

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result.OrphanReason | Should -Be "MissingFolder"
            $result.IsOrphaned | Should -Be $true
        }

        It "Should return 1 orphaned profile due to missing registry entry" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Remove-Item "HKCU:\Software\Pester\ProfileList\S-1-5-21-1234567890-1" -Recurse -Force
            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Get-OrphanedProfiles -ComputerName $ComputerName -ProfileFolderPath $profilePath

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result.OrphanReason | Should -Be "MissingRegistryEntry"
            $result.IsOrphaned | Should -Be $true
        }

        It "Should return 2 orphaned profile due to missing registry entry and folder" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Remove-Item "HKCU:\Software\Pester\ProfileList\S-1-5-21-1234567890-1" -Recurse -Force
            $null = Remove-Item "$profilePath\User2" -Recurse -Force
            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Get-OrphanedProfiles -ComputerName $ComputerName -ProfileFolderPath $profilePath

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2

            $result[0].OrphanReason | Should -Be "MissingFolder"
            $result[0].IsOrphaned | Should -Be $true

            $result[1].OrphanReason | Should -Be "MissingRegistryEntry"
            $result[1].IsOrphaned | Should -Be $true

        }

    }
}
