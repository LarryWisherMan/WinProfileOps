BeforeAll {
    $script:dscModuleName = "WinProfileOps"

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Invoke-UserProfileAudit' -Tag 'Public' {

    # Test for profiles from a reachable computer
    Context 'When the computer is reachable' {
        BeforeEach {
            # Mock Test-ComputerReachability to simulate a reachable computer
            Mock Test-ComputerReachability { return $true } -ModuleName $Script:dscModuleName

            # Mock Get-UserProfilesFromFolders to return a list of folder profiles
            Mock Get-UserProfilesFromFolders {
                return @(
                    [PSCustomObject]@{ FolderName = 'User1'; ProfilePath = 'C:\Users\User1'; ComputerName = 'Server01' },
                    [PSCustomObject]@{ FolderName = 'User2'; ProfilePath = 'C:\Users\User2'; ComputerName = 'Server01' }
                )
            }

            # Mock Get-UserProfilesFromRegistry to return a list of registry profiles
            Mock Get-UserProfilesFromRegistry {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1'; ComputerName = 'Server01' },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2'; ComputerName = 'Server01' }
                )
            }

            # Mock Process-RegistryProfiles to process the registry profiles
            Mock Process-RegistryProfiles {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1'; IsOrphaned = $false },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2'; IsOrphaned = $false }
                )
            }  -ModuleName $Script:dscModuleName

            # Mock Process-FolderProfiles to process the folder profiles
            Mock Process-FolderProfiles {
                return @(
                    [PSCustomObject]@{ SID = $null; ProfilePath = 'C:\Users\User1'; IsOrphaned = $false },
                    [PSCustomObject]@{ SID = $null; ProfilePath = 'C:\Users\User2'; IsOrphaned = $false }
                )
            }  -ModuleName $Script:dscModuleName
        }

        It 'Should return profiles from both the registry and the file system' {
            $result = Invoke-UserProfileAudit -ComputerName 'Server01'

            # Validate that the result contains both profiles
            $result | Should -HaveCount 4
            $result[0].ProfilePath | Should -Be 'C:\Users\User1'
            $result[1].ProfilePath | Should -Be 'C:\Users\User2'

            # Ensure that the mocked functions were called correctly
            Assert-MockCalled Test-ComputerReachability -Exactly 1
            Assert-MockCalled Get-UserProfilesFromFolders -Exactly 1
            Assert-MockCalled Get-UserProfilesFromRegistry -Exactly 1
            Assert-MockCalled Process-RegistryProfiles -Exactly 1
            Assert-MockCalled Process-FolderProfiles -Exactly 1
        }
    }

    # Test when the computer is unreachable
    Context 'When the computer is unreachable' {
        BeforeEach {
            # Mock Test-ComputerReachability to simulate an unreachable computer
            Mock Test-ComputerReachability { return $false }  -ModuleName $Script:dscModuleName

            Mock Get-UserProfilesFromFolders
            Mock Get-UserProfilesFromRegistry

            # Mock Process-RegistryProfiles and Process-FolderProfiles to return empty results
            Mock Process-RegistryProfiles { }  -ModuleName $Script:dscModuleName
            Mock Process-FolderProfiles { }  -ModuleName $Script:dscModuleName
        }

        It 'Should not attempt to retrieve profiles and should return an empty array' {
            $result = Invoke-UserProfileAudit -ComputerName 'UnreachablePC'

            # Validate that the result is an empty array
            $result | Should -BeNullOrEmpty

            # Ensure that no further processing occurs when the computer is unreachable
            Assert-MockCalled Test-ComputerReachability -Exactly 1
            Assert-MockCalled Get-UserProfilesFromFolders -Exactly 0
            Assert-MockCalled Get-UserProfilesFromRegistry -Exactly 0
            Assert-MockCalled Process-RegistryProfiles -Exactly 0
            Assert-MockCalled Process-FolderProfiles -Exactly 0
        }
    }

    # Test when there are no profiles
    Context 'When no profiles are found' {
        BeforeEach {
            # Mock Test-ComputerReachability to simulate a reachable computer
            Mock Test-ComputerReachability { return $true }  -ModuleName $Script:dscModuleName

            # Mock Get-UserProfilesFromFolders to return an empty list of folder profiles
            Mock Get-UserProfilesFromFolders { return @() }

            # Mock Get-UserProfilesFromRegistry to return an empty list of registry profiles
            Mock Get-UserProfilesFromRegistry { return @() }

            # Mock Process-RegistryProfiles and Process-FolderProfiles to return empty results
            Mock Process-RegistryProfiles { return @() }  -ModuleName $Script:dscModuleName
            Mock Process-FolderProfiles { return @() }  -ModuleName $Script:dscModuleName
        }

        It 'Should return an empty array when no profiles are found' {
            $result = Invoke-UserProfileAudit -ComputerName 'Server01'

            # Validate that the result is an empty array
            $result | Should -BeNullOrEmpty

            # Ensure that the functions were called as expected
            Assert-MockCalled Test-ComputerReachability -Exactly 1  -ModuleName $Script:dscModuleName
            Assert-MockCalled Get-UserProfilesFromFolders -Exactly 1
            Assert-MockCalled Get-UserProfilesFromRegistry -Exactly 1
            Assert-MockCalled Process-RegistryProfiles -Exactly 1
            Assert-MockCalled Process-FolderProfiles -Exactly 1
        }
    }

    # Test when Process-RegistryProfiles or Process-FolderProfiles fail
    Context 'When Process-RegistryProfiles or Process-FolderProfiles fail' {
        BeforeEach {
            # Mock Test-ComputerReachability to simulate a reachable computer
            Mock Test-ComputerReachability { return $true } -ModuleName $script:dscModuleName

            # Mock Get-UserProfilesFromFolders to return valid folder profiles
            Mock Get-UserProfilesFromFolders {
                return @(
                    [PSCustomObject]@{ FolderName = 'User1'; ProfilePath = 'C:\Users\User1'; ComputerName = 'Server01' },
                    [PSCustomObject]@{ FolderName = 'User2'; ProfilePath = 'C:\Users\User2'; ComputerName = 'Server01' }
                )
            }

            # Mock Get-UserProfilesFromRegistry to return valid registry profiles
            Mock Get-UserProfilesFromRegistry {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1'; ComputerName = 'Server01' },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2'; ComputerName = 'Server01' }
                )
            }

            # Mock Process-RegistryProfiles to throw an error
            Mock Process-RegistryProfiles { throw "Error processing registry profiles" } -ModuleName $script:dscModuleName

            # Mock Write-Error to capture the error
            Mock Write-Error
        }

        It 'Should log an error and return nothing if Process-RegistryProfiles fails' {
            $result = Invoke-UserProfileAudit -ComputerName 'Server01'

            # Validate that the result is empty
            $result | Should -BeNullOrEmpty

            # Assert that Write-Error was called once
            Assert-MockCalled Write-Error -Exactly 1 -ModuleName $script:dscModuleName

            # Ensure the mocked functions were called correctly
            Assert-MockCalled Test-ComputerReachability -Exactly 1 -ModuleName $script:dscModuleName
            Assert-MockCalled Process-RegistryProfiles -Exactly 1 -ModuleName $script:dscModuleName
        }
    }

}
