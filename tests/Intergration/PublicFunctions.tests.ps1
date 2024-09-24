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
            $env:WinProfileOps_RegistryPath = "Software\Pester\ProfileList"
            $env:WinProfileOps_RegistryHive = [Microsoft.Win32.RegistryHive]::CurrentUser

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
            Remove-Item -Path Env:WinProfileOps_RegistryPath -ErrorAction SilentlyContinue
            Remove-Item -Path Env:WinProfileOps_RegistryHive -ErrorAction SilentlyContinue
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
            $env:WinProfileOps_RegistryPath = "Software\Pester\ProfileList"
            $env:WinProfileOps_RegistryHive = [Microsoft.Win32.RegistryHive]::CurrentUser

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
            Remove-Item -Path Env:WinProfileOps_RegistryPath -ErrorAction SilentlyContinue
            Remove-Item -Path Env:WinProfileOps_RegistryHive -ErrorAction SilentlyContinue
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
            $env:WinProfileOps_RegistryPath = "Software\Pester\ProfileList"
            $env:WinProfileOps_RegistryHive = [Microsoft.Win32.RegistryHive]::CurrentUser

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
            Remove-Item -Path Env:WinProfileOps_RegistryPath -ErrorAction SilentlyContinue
            Remove-Item -Path Env:WinProfileOps_RegistryHive -ErrorAction SilentlyContinue
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

    Context "Remove-UserProfilesFromRegistry" {

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

            # Reset environment variables
            Remove-Item -Path Env:WinProfileOps_RegistryPath -ErrorAction SilentlyContinue
            Remove-Item -Path Env:WinProfileOps_RegistryHive -ErrorAction SilentlyContinue
            Remove-Item -Path Env:WinProfileOps_ProfileFolderPath -ErrorAction SilentlyContinue
        }

        It "Should remove the specified profiles from the registry" {
            $testSID = "S-1-5-21-1234567890-1"
            $profilePath = "$TestDrive\Users"
            $ComputerName = $Env:COMPUTERNAME

            # Validate the registry entry exists before removal
            (Test-Path "HKCU:\Software\Pester\ProfileList\$testSID") | Should -Be $true

            # Call Remove-UserProfilesFromRegistry to remove the profile
            $result = Remove-UserProfilesFromRegistry -SIDs $testSID -Force -Confirm:$false

            # Validate that the profile was removed from the registry
            (Test-Path "HKCU:\Software\Pester\ProfileList\$testSID") | Should -Be $false
            $result.DeletionSuccess | Should -Be $true
        }

        It "Should not remove profiles in AuditOnly mode" {
            $testSID = "S-1-5-21-1234567890-1"
            $profilePath = "$TestDrive\Users"
            $ComputerName = $Env:COMPUTERNAME

            # Validate the registry entry exists before attempting audit
            (Test-Path "HKCU:\Software\Pester\ProfileList\$testSID") | Should -Be $true

            # Call Remove-UserProfilesFromRegistry with -AuditOnly
            $result = Remove-UserProfilesFromRegistry -SIDs $testSID -AuditOnly

            # Validate that the profile was not removed
            (Test-Path "HKCU:\Software\Pester\ProfileList\$testSID") | Should -Be $true
            $result | Should -Not -BeNullOrEmpty
            $result.DeletionMessage | Should -Be "Audit only, no deletion performed."
        }

        It "Should handle missing registry entries gracefully" {
            $missingSID = "S-1-5-21-1234567890-999"  # Non-existing SID
            $profilePath = "$TestDrive\Users"
            $ComputerName = $Env:COMPUTERNAME

            # Call Remove-UserProfilesFromRegistry on a missing profile
            $result = Remove-UserProfilesFromRegistry -SIDs $missingSID -Force -Confirm:$false

            # Validate the result should indicate failure due to missing registry entry
            $result.DeletionSuccess | Should -Be $false
            $result.DeletionMessage | Should -Be "Profile not found"
        }

        It "Should remove multiple profiles from the registry" {
            $testSIDs = @("S-1-5-21-1234567890-1", "S-1-5-21-1234567890-2")
            $profilePath = "$TestDrive\Users"
            $ComputerName = $Env:COMPUTERNAME

            # Validate the registry entries exist before removal
            $testSIDs | ForEach-Object {
                (Test-Path "HKCU:\Software\Pester\ProfileList\$_") | Should -Be $true
            }

            # Call Remove-UserProfilesFromRegistry to remove the profiles
            $result = Remove-UserProfilesFromRegistry -SIDs $testSIDs -Force -Confirm:$false

            # Validate that the profiles were removed from the registry
            $testSIDs | ForEach-Object {
                (Test-Path "HKCU:\Software\Pester\ProfileList\$_") | Should -Be $false
            }

            $result.DeletionSuccess | ForEach-Object { $_ | Should -Be $true }
        }

        It "Should handle profiles with no registry entries" {
            $testSID = "S-1-5-21-1234567890-1"
            $profilePath = "$TestDrive\Users"
            $ComputerName = $Env:COMPUTERNAME

            # Remove registry entry for the test profile
            Remove-Item "HKCU:\Software\Pester\ProfileList\$testSID" -Recurse -Force

            # Call Remove-UserProfilesFromRegistry
            $result = Remove-UserProfilesFromRegistry -SIDs $testSID -Force -Confirm:$false

            # Validate result indicates no registry entry found
            $result.DeletionSuccess | Should -Be $false
            $result.DeletionMessage | Should -Be "Profile not found"
        }

        It "Should handle profiles with missing folders" {
            $testSID = "S-1-5-21-1234567890-1"
            $profilePath = "$TestDrive\Users"
            $ComputerName = $Env:COMPUTERNAME

            # Remove folder for the profile
            Remove-Item "$profilePath\User1" -Recurse -Force

            # Call Remove-UserProfilesFromRegistry
            $result = Remove-UserProfilesFromRegistry -SIDs $testSID -Force -Confirm:$false

            # Validate the registry entry was removed
            (Test-Path "HKCU:\Software\Pester\ProfileList\$testSID") | Should -Be $false
            $result.DeletionSuccess | Should -Be $true
        }

        It "Should prompt for confirmation before removing profiles" {
            $testSID = "S-1-5-21-1234567890-1"
            $profilePath = "$TestDrive\Users"
            $ComputerName = $Env:COMPUTERNAME

            InModuleScope -ScriptBlock {
                mock ShouldContinueWrapper {
                    $false
                }
            }

            # Call Remove-UserProfilesFromRegistry without confirming
            $result = Remove-UserProfilesFromRegistry -SIDs $testSID -Force -Confirm:$true

            # assert ShouldContinueWrapper was called
            Assert-MockCalled ShouldContinueWrapper -Exactly 1 -Scope It

            # Validate that the profile was not removed
            (Test-Path "HKCU:\Software\Pester\ProfileList\$testSID") | Should -Be $true
        }

        It "Should handel UserProfile Types from the Pipeline" {
            $computerName = $Env:COMPUTERNAME
            $userProfileAudit = Invoke-UserProfileAudit -ProfileFolderPath $env:WinProfileOps_ProfileFolderPath -IgnoreSpecial

            if ($userProfileAudit.count -eq 3)
            {
                $result = Remove-UserProfilesFromRegistry -UserProfiles $userProfileAudit -AuditOnly
            }

            $result | Should -Not -BeNullOrEmpty
            $result.count | Should -Be 3
            $result | ForEach-Object {
                $_.DeletionSuccess | Should -Be $true
            }

        }

    }
}
