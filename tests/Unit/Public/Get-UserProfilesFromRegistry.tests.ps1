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
