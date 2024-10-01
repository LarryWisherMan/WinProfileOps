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


<#
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

             # Mock Join-UserProfiles to simulate the merging of profiles
             Mock Join-UserProfiles {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1'; IsOrphaned = $false; HasUserFolder = $true; HasRegistryEntry = $true },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2'; IsOrphaned = $false; HasUserFolder = $true; HasRegistryEntry = $true }
                )
            } -ModuleName $Script:dscModuleName

            # Mock ConvertTo-UserProfile
            Mock ConvertTo-UserProfile {
                param ($profiles, $view)
                return $profiles
            } -ModuleName $Script:dscModuleName
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
#>


Describe 'Invoke-UserProfileAudit' -Tag 'Public', "Unit", "UserProfileAudit" {

    BeforeAll {
        InModuleScope -scriptblock {
            # Mock common external functions
            Mock Test-ComputerReachability { return $true }
            Mock Get-UserProfilesFromRegistry
            Mock Get-UserProfilesFromFolders
            Mock Join-UserProfiles
            Mock ConvertTo-UserProfile {
                param ($ProfileRegistryItems, $view)
                return $ProfileRegistryItems
            }
        }
    }

    Context 'Positive Tests' {
        BeforeEach {
            # Simulate valid registry and folder profiles
            Mock Get-UserProfilesFromRegistry {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1'; HasRegistryEntry = $true },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2'; HasRegistryEntry = $true }
                )
            }

            Mock Get-UserProfilesFromFolders {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1'; HasUserFolder = $true },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2'; HasUserFolder = $true }
                )
            }

            # Simulate merging of profiles
            Mock Join-UserProfiles {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1'; IsOrphaned = $false },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2'; IsOrphaned = $false }
                )
            } -moduleName $script:dscModuleName
        }


        It 'Should return valid profiles when both registry and folder profiles are found' {
            $result = Invoke-UserProfileAudit -ComputerName 'Server01'

            # Validate the result contains profiles
        ($result | Measure-Object).Count | Should -Be 2
            $result[0].ProfilePath | Should -Be 'C:\Users\User1'
            $result[1].ProfilePath | Should -Be 'C:\Users\User2'

            # Ensure mocks are called
            Assert-MockCalled Test-ComputerReachability -Exactly 1
            Assert-MockCalled Get-UserProfilesFromFolders -Exactly 1
            Assert-MockCalled Get-UserProfilesFromRegistry -Exactly 1
            Assert-MockCalled Join-UserProfiles -Exactly 1
            Assert-MockCalled ConvertTo-UserProfile -Exactly 2
        }

        It 'Should process multiple computers via pipeline' {
            Mock Test-ComputerReachability { return $true }

            $result = 'Server01', 'Server02' | Invoke-UserProfileAudit

            # Validate results for both computers
            $result | Should -Not -BeNullOrEmpty
            ($result | Measure-Object).Count | Should -Be 4
        }

        It 'Should ignore special profiles when IgnoreSpecial switch is used' {
            Mock Join-UserProfiles {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1'; IsSpecial = $false },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2'; IsSpecial = $true }
                )
            }

            $result = Invoke-UserProfileAudit -ComputerName 'Server01' -IgnoreSpecial

            # Ensure the special profile is ignored
            $result | Should -HaveCount 1
            $result.IsSpecial | Should -be $false
            $result.ProfilePath | Should -Be 'C:\Users\User1'
        }


    }

    Context 'Negative Tests' {
        It 'Should write an error if both profiles are empty' {
            Mock Get-UserProfilesFromFolders { return @() }
            Mock Get-UserProfilesFromRegistry { return @() }

            Mock Join-UserProfiles {
                throw "Both FolderProfiles and RegistryProfiles are empty. Cannot proceed."
            } -ModuleName $Script:dscModuleName

            mock write-error

            $result = Invoke-UserProfileAudit -ComputerName 'Server01'

            $result | Should -BeNullOrEmpty
            Assert-MockCalled Get-UserProfilesFromFolders -Exactly 1 -Scope It
            Assert-MockCalled Get-UserProfilesFromRegistry -Exactly 1 -Scope It
            Assert-MockCalled Join-UserProfiles -Exactly 1 -Scope It
            Assert-MockCalled Write-Error -Exactly 1 -Scope It -ParameterFilter { $message -eq "Error processing profiles for computer 'Server01'. Error: Both FolderProfiles and RegistryProfiles are empty. Cannot proceed." }

        }

        It 'Should not retrieve profiles when the computer is unreachable' {
            Mock Test-ComputerReachability { return $false }

            Mock Write-Warning

            $result = Invoke-UserProfileAudit -ComputerName 'UnreachablePC'

            # Validate that no profiles are returned
            $result | Should -BeNullOrEmpty

            # Ensure that no further processing occurs
            Assert-MockCalled Test-ComputerReachability -Exactly 1
            Assert-MockCalled Get-UserProfilesFromFolders -Exactly 0
            Assert-MockCalled Get-UserProfilesFromRegistry -Exactly 0

            Assert-MockCalled Write-Warning -Exactly 1 -ParameterFilter {
                $message -eq "Computer 'UnreachablePC' is not reachable."
            }
        }

        It 'Should handle invalid registry path gracefully' {
            Mock Get-UserProfilesFromRegistry { throw "Invalid registry path" }

            Mock Write-Error

            $result = Invoke-UserProfileAudit -ComputerName 'Server01'

            $result | Should -BeNullOrEmpty
            Assert-MockCalled Write-Error -Exactly 1 -Scope It
        }

    }

    Context 'Edge Case Tests' {
        It 'Should handle empty folder profiles but valid registry profiles' {
            Mock Get-UserProfilesFromFolders { return @() }
            Mock Get-UserProfilesFromRegistry {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1'; HasRegistryEntry = $true }
                )
            }

            Mock Join-UserProfiles {
                param($RegistryProfiles, $FolderProfiles)
                return $RegistryProfiles
            } -moduleName $script:dscModuleName

            Mock ConvertTo-UserProfile {
                param ($ProfileRegistryItems, $view)
                return $ProfileRegistryItems
            } -moduleName $script:dscModuleName

            $result = Invoke-UserProfileAudit -ComputerName 'Server01'

            # Validate that the result is not empty
            $result | Should -HaveCount 1

            # Ensure mocks are called correctly
            Assert-MockCalled Get-UserProfilesFromFolders -Exactly 1
            Assert-MockCalled Get-UserProfilesFromRegistry -Exactly 1
            Assert-MockCalled Join-UserProfiles -Exactly 1
        }

        It 'Should handle empty registry profiles but valid folder profiles' {
            Mock Get-UserProfilesFromRegistry { return @() }
            Mock Get-UserProfilesFromFolders {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1'; HasUserFolder = $true }
                )
            }

            Mock Join-UserProfiles {
                param($RegistryProfiles, $FolderProfiles)
                return $FolderProfiles
            } -moduleName $script:dscModuleName

            Mock ConvertTo-UserProfile {
                param ($ProfileRegistryItems, $view)
                return $ProfileRegistryItems
            } -moduleName $script:dscModuleName

            $result = Invoke-UserProfileAudit -ComputerName 'Server01'

            # Validate that the result is not empty
            $result | Should -HaveCount 1

            # Ensure mocks are called correctly
            Assert-MockCalled Get-UserProfilesFromFolders -Exactly 1
            Assert-MockCalled Get-UserProfilesFromRegistry -Exactly 1
            Assert-MockCalled Join-UserProfiles -Exactly 1
        }

        It 'Should default to the local computer name if no ComputerName is provided' {
            Mock Test-ComputerReachability { return $true }

            $result = Invoke-UserProfileAudit

            # Ensure the default is used
            Assert-MockCalled Test-ComputerReachability -Exactly 1 -ParameterFilter { $ComputerName -eq $env:COMPUTERNAME }
        }

    }

    Context 'Error Handling' {
        It 'Should handle exceptions and write an error' {
            Mock Get-UserProfilesFromRegistry { throw "Error accessing registry profiles" }
            Mock Write-Error

            $result = Invoke-UserProfileAudit -ComputerName 'Server01'

            # Validate that the result is empty
            $result | Should -BeNullOrEmpty

            # Ensure Write-Error was called
            Assert-MockCalled Write-Error -Exactly 1
        }
    }

    Context 'Performance Tests' {
        It 'Should complete execution within acceptable time' {
            Mock Test-ComputerReachability { return $true }

            # Simulate a reasonable delay in execution for performance test
            $elapsedTime = Measure-Command { Invoke-UserProfileAudit -ComputerName 'Server01' }
            $elapsedTime.TotalMilliseconds | Should -BeLessThan 1000
        }
    }

    Context 'Verbose Logging' {
        <#
        It 'Should write verbose messages when verbose is enabled' {
            Mock Test-ComputerReachability { return $true }

            $VerbosePreference = 'Continue'
            #Mock Write-Verbose

            Invoke-UserProfileAudit -ComputerName 'Server01' -Verbose

            #Assert-MockCalled Write-Verbose
        }
            #>
    }
}
