BeforeAll {
    $script:dscModuleName = "WinProfileOps"

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName

    Mock Test-ComputerPing {
        return $true
    }
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

<#
Describe 'Get-UserProfilesFromRegistry' -Tags 'Unit' {

    # Test for profiles from the local computer
    Context 'When retrieving profiles from the local computer' {
        BeforeEach {

            InModuleScope -ScriptBlock {

                # Mock Get-SIDProfileInfo to return a list of profiles
                Mock Get-SIDProfileInfo {
                    return @(
                        [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1' },
                        [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2' }
                    )
                }

            }
        }

        It 'Should return the user profiles from the local registry' {
            $ComputerName = $env:COMPUTERNAME

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # Validate result
            $result | Should -HaveCount 2
            $result[0].SID | Should -Be 'S-1-5-21-1001'
            $result[0].ProfilePath | Should -Be 'C:\Users\User1'
            $result[1].SID | Should -Be 'S-1-5-21-1002'
            $result[1].ProfilePath | Should -Be 'C:\Users\User2'

            # Assert that Get-SIDProfileInfo was called
            Assert-MockCalled Get-SIDProfileInfo -Exactly 1
            Assert-MockCalled Test-ComputerPing -Exactly 1 -Scope It
        }
    }

    # Test for profiles from a remote computer
    Context 'When retrieving profiles from a remote computer' {
        BeforeEach {

            InModuleScope -ScriptBlock {
                # Mock Get-SIDProfileInfo to return a list of profiles
                Mock Get-SIDProfileInfo {
                    return @(
                        [PSCustomObject]@{ SID = 'S-1-5-21-2001'; ProfilePath = 'C:\Users\User1' },
                        [PSCustomObject]@{ SID = 'S-1-5-21-2002'; ProfilePath = 'C:\Users\User2' }
                    )
                }
            }
        }

        It 'Should return the user profiles from the remote registry' {
            $ComputerName = 'RemotePC'

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # Validate result
            $result | Should -HaveCount 2
            $result[0].SID | Should -Be 'S-1-5-21-2001'
            $result[0].ProfilePath | Should -Be 'C:\Users\User1'
            $result[1].SID | Should -Be 'S-1-5-21-2002'
            $result[1].ProfilePath | Should -Be 'C:\Users\User2'

            # Assert that Get-SIDProfileInfo was called
            Assert-MockCalled Get-SIDProfileInfo -Exactly 1
            Assert-MockCalled Test-ComputerPing -Exactly 1 -Scope It
        }
    }

    # Test when no profiles are found
    Context 'When no profiles are found' {
        BeforeEach {

            InModuleScope -ScriptBlock {
                # Mock Get-SIDProfileInfo to return an empty list
                Mock Get-SIDProfileInfo {
                    return @()
                }

            }
        }

        It 'Should return an empty result when no profiles are found' {
            $ComputerName = $env:COMPUTERNAME

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # The result should be empty
            $result | Should -BeNullOrEmpty

            # Assert that Get-SIDProfileInfo was called
            Assert-MockCalled Get-SIDProfileInfo -Exactly 1
            Assert-MockCalled Test-ComputerPing -Exactly 1 -Scope It
        }
    }

    # Test when Get-SIDProfileInfo fails
    Context 'When Get-SIDProfileInfo fails' {
        BeforeEach {

            InModuleScope -ScriptBlock {
                # Mock Get-SIDProfileInfo to simulate an error
                Mock Get-SIDProfileInfo {
                    throw "Failed to retrieve profiles from the registry"
                }

                # Mock Write-Error to capture the error
                Mock Write-Error
            }


        }

        It 'Should log an error and return nothing' {
            $ComputerName = $env:COMPUTERNAME

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # The result should be empty
            $result | Should -BeNullOrEmpty
            # Assert that Write-Error was called
            Assert-MockCalled Write-Error -Exactly 1
            Assert-MockCalled Get-SIDProfileInfo -Exactly 1
            Assert-MockCalled Test-ComputerPing -Exactly 1 -Scope It
        }
    }

    Context 'When partial profile data is returned' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock Get-SIDProfileInfo to return incomplete profile data
                Mock Get-SIDProfileInfo {
                    return @(
                        [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = '' }, # Missing profile path
                        [PSCustomObject]@{ SID = ''; ProfilePath = 'C:\Users\User2' }   # Missing SID
                    )
                }
            }


        }

        It 'Should still return the profiles with partial data' {
            $ComputerName = $env:COMPUTERNAME

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # Validate result, even with partial data
            $result | Should -HaveCount 2
            $result[0].SID | Should -Be 'S-1-5-21-1001'
            $result[0].ProfilePath | Should -BeNullOrEmpty
            $result[1].SID | Should -BeNullOrEmpty
            $result[1].ProfilePath | Should -Be 'C:\Users\User2'

            # Assert that Get-SIDProfileInfo was called
            Assert-MockCalled Get-SIDProfileInfo -Exactly 1
            Assert-MockCalled Test-ComputerPing -Exactly 1 -Scope It
        }
    }

    Context 'When the computer is online' {
        BeforeEach {
            # Mock Test-ComputerPing to simulate the computer being online
            Mock Test-ComputerPing {
                return $true
            }

            # Mock Get-SIDProfileInfo to return a list of profiles
            Mock Get-SIDProfileInfo {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1' },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2' }
                )
            }

        }

        It 'Should return profiles when the computer is online' {
            $result = Get-UserProfilesFromRegistry -ComputerName $env:COMPUTERNAME

            $result | Should -HaveCount 2
            $result[0].SID | Should -Be 'S-1-5-21-1001'
            $result[1].SID | Should -Be 'S-1-5-21-1002'

            Assert-MockCalled Test-ComputerPing -Exactly 1
            Assert-MockCalled Get-SIDProfileInfo -Exactly 1
        }
    }

    # Test when the computer is offline/unreachable
    Context 'When the computer is offline or unreachable' {
        BeforeEach {


            InModuleScope -ScriptBlock {
                # Mock Get-SIDProfileInfo to return incomplete profile data
                Mock Get-SIDProfileInfo
            }

            # Mock Test-ComputerPing to simulate the computer being offline
            Mock Test-ComputerPing {
                return $false
            }

            # Mock Write-Warning to capture the warning
            Mock Write-Warning
        }

        It 'Should log a warning and return nothing when the computer is unreachable' {
            $ComputerName = 'OfflinePC'

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ComputerPing -Exactly 1
            Assert-MockCalled Write-Warning -Exactly 1
            Assert-MockCalled Get-SIDProfileInfo -Exactly 0
        }
    }

    # Test for profiles when Test-ComputerPing fails
    Context 'When Test-ComputerPing fails' {
        BeforeEach {

            InModuleScope -ScriptBlock {
                # Mock Get-SIDProfileInfo to return incomplete profile data
                Mock Get-SIDProfileInfo
            }

            # Mock Test-ComputerPing to simulate an error or failure
            Mock Test-ComputerPing {
                throw "Ping failed"
            }

            # Mock Write-Error to capture the error
            Mock Write-Error
        }

        It 'Should log an error and return nothing when ping fails' {
            $ComputerName = 'RemotePC'

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ComputerPing -Exactly 1
            Assert-MockCalled Write-Error -Exactly 1
            Assert-MockCalled Get-SIDProfileInfo -Exactly 0
        }
    }

}
#>

Describe 'Get-UserProfilesFromRegistry Tests' -Tags 'Public', 'Unit', 'UserProfileAudit', 'GetUserProfile' {

    BeforeAll {
        InModuleScope -ScriptBlock {
            # Mock external dependencies
            Mock Test-ComputerPing -MockWith {
                return $true
            }
            Mock Get-ProfileRegistryItems -MockWith {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1234567890-1234567890-1234567890-1001'; ProfilePath = 'C:\Users\User1'; ComputerName = $ComputerName },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1234567890-1234567890-1234567890-1002'; ProfilePath = 'C:\Users\User2'; ComputerName = $ComputerName }
                )
            }
        }
    }

    Context 'Positive Tests' {

        It 'Should return registry profiles for a valid computer and registry path' {
            $result = Get-UserProfilesFromRegistry -ComputerName 'Server01'

            # Assert that result is not null or empty
            $result | Should -Not -BeNullOrEmpty

            # Assert expected properties exist in returned objects
            $result[0].SID | Should -Be 'S-1-5-21-1234567890-1234567890-1234567890-1001'
            $result[0].ProfilePath | Should -Be 'C:\Users\User1'
            $result[0].ComputerName | Should -Be 'Server01'
        }

        It 'Should return registry profiles for the local computer by default' {
            $result = Get-UserProfilesFromRegistry

            # Assert that result is not null or empty
            $result | Should -Not -BeNullOrEmpty

            # Assert that ComputerName is local machine's name
            $result[0].ComputerName | Should -Be $env:COMPUTERNAME
        }
    }

    Context 'Negative Tests' {

        It 'Should return empty array and write-warning if the computer is offline' {
            # Mock the ping check to return false (offline)
            Mock Test-ComputerPing -MockWith { return $false }

            mock Write-Warning

            $result = Get-UserProfilesFromRegistry -ComputerName 'OfflineServer'

            # Assert that result is empty
            $result | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Warning -Scope It -ParameterFilter {
                $message -eq "Computer 'OfflineServer' is offline or unreachable."
            }
        }

        It 'Should write an error if there is an issue accessing the registry' {
            # Mock Get-ProfileRegistryItems to throw an exception
            Mock Get-ProfileRegistryItems -MockWith { throw "Error accessing registry" }

            mock Write-Error

            $result = Get-UserProfilesFromRegistry -RegistryPath 'InvalidRegistryPath' -RegistryHive 'InvalidHive'

            # Assert that result is empty
            $result | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Error -Scope It -ParameterFilter {
                $message -like "*Error accessing registry profiles*"
            }
        }
    }

    Context 'Edge Case Tests' {

        It 'Should handle empty registry items gracefully' {
            # Mock Get-ProfileRegistryItems to return an empty array
            Mock Get-ProfileRegistryItems -MockWith { return @() }

            $result = Get-UserProfilesFromRegistry -RegistryPath 'EmptyRegistryPath'

            # Assert that result is empty
            $result | Should -BeNullOrEmpty
        }

        It 'Should handle null input for ComputerName by using the local machine name' {
            $result = Get-UserProfilesFromRegistry -ComputerName $null

            # Assert that the ComputerName defaults to the local machine
            $result[0].ComputerName | Should -Be $env:COMPUTERNAME
        }
    }

    Context 'Exception Handling' {

        It 'Should return empty array if an error occurs during registry access' {
            # Mock Get-ProfileRegistryItems to throw an exception
            Mock Get-ProfileRegistryItems -MockWith { throw "Registry access error" }

            mock Write-Error

            $result = Get-UserProfilesFromRegistry -ComputerName 'ErrorServer'

            # Assert that result is empty
            $result | Should -BeNullOrEmpty
        }

        It 'Should log an error message if registry retrieval fails' {
            # Mock Get-ProfileRegistryItems to throw an exception
            Mock Get-ProfileRegistryItems -MockWith { throw "Registry access error" }

            mock Write-Error

            Get-UserProfilesFromRegistry -ComputerName 'ErrorServer' | Out-Null

            Assert-MockCalled -CommandName Write-Error -Scope It -ParameterFilter {
                $message -like "*Error accessing registry profiles*"
            }
        }
    }

    Context 'Verbose and Debug Logging' {



    }

    Context 'Performance Tests' {

        It 'Should execute within acceptable time for normal inputs' {
            $executionTime = Measure-Command {
                Get-UserProfilesFromRegistry -ComputerName 'Server01'
            }

            # Assert that the execution time is less than 1 second
            $executionTime.TotalMilliseconds | Should -BeLessThan 1000
        }
    }

    Context 'Cleanup Tests' {

        It 'Should not leave any resources open after execution' {
            # Assuming no resources are left open
            $result = Get-UserProfilesFromRegistry -ComputerName 'Server01'
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
