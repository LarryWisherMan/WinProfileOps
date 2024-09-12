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
                # Mock Test-ComputerPing to always return true
                Mock Test-ComputerPing {
                    return $true
                }
            }
        }

        It 'Should return the user profiles from the local registry when user has admin privileges' {
            # Mock admin environment variable
            $ENV:WinProfileOps_IsAdmin = $true

            # Mock Get-SIDProfileInfo to return a list of profiles
            Mock Get-SIDProfileInfo {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1' },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2' }
                )
            }

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

        It 'Should return the user profiles from the local computer using fallback when user lacks admin privileges' {
            # Mock non-admin environment variable
            $ENV:WinProfileOps_IsAdmin = $false

            # Mock Get-SIDProfileInfoFallback to return a list of profiles
            Mock Get-SIDProfileInfoFallback {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1' },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2' }
                )
            }

            $ComputerName = $env:COMPUTERNAME

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # Validate result
            $result | Should -HaveCount 2
            $result[0].SID | Should -Be 'S-1-5-21-1001'
            $result[0].ProfilePath | Should -Be 'C:\Users\User1'
            $result[1].SID | Should -Be 'S-1-5-21-1002'
            $result[1].ProfilePath | Should -Be 'C:\Users\User2'

            # Assert that the fallback method was called
            Assert-MockCalled Get-SIDProfileInfoFallback -Exactly 1
            Assert-MockCalled Test-ComputerPing -Exactly 1 -Scope It
        }
    }

    # Test for profiles from a remote computer
    Context 'When retrieving profiles from a remote computer' {


        It 'Should return the user profiles from a remote registry when user has admin privileges' {
            InModuleScope -ScriptBlock {
                # Mock admin environment variable
                $ENV:WinProfileOps_IsAdmin = $true

                # Mock Get-SIDProfileInfo to return a list of profiles
                Mock Get-SIDProfileInfo {
                    return @(
                        [PSCustomObject]@{ SID = 'S-1-5-21-2001'; ProfilePath = 'C:\Users\User1' },
                        [PSCustomObject]@{ SID = 'S-1-5-21-2002'; ProfilePath = 'C:\Users\User2' }
                    )
                }
            }

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
            Assert-MockCalled Test-ComputerPing -Exactly 1
        }

        It 'Should return the user profiles from a remote computer when user lacks admin privileges' {

            InModuleScope -ScriptBlock {
                # Change the environment to simulate non-admin
                $ENV:WinProfileOps_IsAdmin = $false

                # Mock the fallback method to return profiles
                Mock Get-SIDProfileInfoFallback {
                    return @(
                        [PSCustomObject]@{ SID = 'S-1-5-21-2001'; ProfilePath = 'C:\Users\User1' },
                        [PSCustomObject]@{ SID = 'S-1-5-21-2002'; ProfilePath = 'C:\Users\User2' }
                    )
                }
            }

            $ComputerName = 'RemotePC'

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # Validate result
            $result | Should -HaveCount 2
            $result[0].SID | Should -Be 'S-1-5-21-2001'
            $result[0].ProfilePath | Should -Be 'C:\Users\User1'
            $result[1].SID | Should -Be 'S-1-5-21-2002'
            $result[1].ProfilePath | Should -Be 'C:\Users\User2'

            # Assert that the fallback method was called
            Assert-MockCalled Get-SIDProfileInfoFallback -Exactly 1
            Assert-MockCalled Test-ComputerPing -Exactly 1
        }
    }


    # Test when no profiles are found
    Context 'When no profiles are found' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock admin environment variable
                $ENV:WinProfileOps_IsAdmin = $true

                # Mock Get-SIDProfileInfo to return an empty list
                Mock Get-SIDProfileInfo {
                    return @()
                }
            }
        }

        It 'Should return an empty result when no profiles are found (admin)' {
            $ComputerName = $env:COMPUTERNAME

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # The result should be empty
            $result | Should -BeNullOrEmpty

            # Assert that Get-SIDProfileInfo was called
            Assert-MockCalled Get-SIDProfileInfo -Exactly 1
            Assert-MockCalled Test-ComputerPing -Exactly 1
        }

        It 'Should return an empty result when no profiles are found (non-admin)' {
            # Change the environment to simulate non-admin
            $ENV:WinProfileOps_IsAdmin = $false

            # Mock the fallback method to return an empty list
            Mock Get-SIDProfileInfoFallback {
                return @()
            } -ModuleName $Script:dscModuleName

            $ComputerName = $env:COMPUTERNAME

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # The result should be empty
            $result | Should -BeNullOrEmpty

            # Assert that the fallback method was called
            Assert-MockCalled Get-SIDProfileInfoFallback -Exactly 1
            Assert-MockCalled Test-ComputerPing -Exactly 1
        }
    }


    # Test when Get-SIDProfileInfo fails
    Context 'When both registry and fallback profile retrieval methods fail' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock Test-ComputerPing to simulate the computer being online
                Mock Test-ComputerPing {
                    return $true
                }

                # Mock Write-Error to capture the error
                Mock Write-Error
            }
        }

        It 'Should log an error and return nothing when Get-SIDProfileInfo fails (admin)' {
            # Simulate user has admin privileges
            $ENV:WinProfileOps_IsAdmin = $true

            InModuleScope -ScriptBlock {

                # Mock Write-Error to capture the error
                Mock Write-Error

                # Mock Test-ComputerPing to simulate the computer being online
                Mock Test-ComputerPing {
                    return $true
                }

                # Mock Get-SIDProfileInfoFallback to simulate an error
                Mock Get-SIDProfileInfoFallback

                # Mock Get-SIDProfileInfo to simulate an error
                Mock Get-SIDProfileInfo {
                    throw "Failed to retrieve profiles from the registry"
                }

            }

            $ComputerName = $env:COMPUTERNAME

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # The result should be empty
            $result | Should -BeNullOrEmpty

            # Assert that Write-Error was called to log the error
            Assert-MockCalled Write-Error -Exactly 1

            # Assert that Get-SIDProfileInfo was called once
            Assert-MockCalled Get-SIDProfileInfo -Exactly 1

            # Assert that Test-ComputerPing was called once
            Assert-MockCalled Test-ComputerPing -Exactly 1 -Scope It

            # Ensure the fallback function was not called
            Assert-MockCalled Get-SIDProfileInfoFallback -Exactly 0
        }

        It 'Should log an error and return nothing when Get-SIDProfileInfoFallback fails (non-admin)' {
            # Simulate user lacks admin privileges
            $ENV:WinProfileOps_IsAdmin = $false

            InModuleScope -ScriptBlock {

                # Mock Write-Error to capture the error
                Mock Write-Error

                # Mock Test-ComputerPing to simulate the computer being online
                Mock Test-ComputerPing {
                    return $true
                }

                # Mock Get-SIDProfileInfoFallback to simulate an error
                Mock Get-SIDProfileInfoFallback {
                    throw "Failed to retrieve profiles via fallback method"
                }

                mock Get-SIDProfileInfo {
                    return @()
                }

            }



            $ComputerName = $env:COMPUTERNAME

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # The result should be empty
            $result | Should -BeNullOrEmpty

            # Assert that Write-Error was called to log the error
            Assert-MockCalled Write-Error -Exactly 1

            # Assert that Get-SIDProfileInfoFallback was called once
            Assert-MockCalled Get-SIDProfileInfoFallback -Exactly 1

            # Assert that Test-ComputerPing was called once
            Assert-MockCalled Test-ComputerPing -Exactly 1 -Scope It

            # Ensure the admin function was not called
            Assert-MockCalled Get-SIDProfileInfo -Exactly 0
        }
    }


    Context 'When partial profile data is returned' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock admin environment variable
                $ENV:WinProfileOps_IsAdmin = $true

                # Mock Get-SIDProfileInfo to return partial data
                Mock Get-SIDProfileInfo {
                    return @(
                        [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = '' }, # Missing profile path
                        [PSCustomObject]@{ SID = ''; ProfilePath = 'C:\Users\User2' }   # Missing SID
                    )
                }
            }
        }

        It 'Should still return the profiles with partial data when user has admin privileges' {
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
            Assert-MockCalled Test-ComputerPing -Exactly 1
        }

        It 'Should still return the profiles with partial data when user lacks admin privileges' {
            # Change the environment to simulate non-admin
            $ENV:WinProfileOps_IsAdmin = $false

            # Mock the fallback method to return partial data
            Mock Get-SIDProfileInfoFallback {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = '' },
                    [PSCustomObject]@{ SID = ''; ProfilePath = 'C:\Users\User2' }
                )
            } -ModuleName $script:dscModuleName

            $ComputerName = $env:COMPUTERNAME
            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # Validate result, even with partial data
            $result | Should -HaveCount 2
            $result[0].SID | Should -Be 'S-1-5-21-1001'
            $result[0].ProfilePath | Should -BeNullOrEmpty
            $result[1].SID | Should -BeNullOrEmpty
            $result[1].ProfilePath | Should -Be 'C:\Users\User2'

            # Assert that the fallback method was called
            Assert-MockCalled Get-SIDProfileInfoFallback -Exactly 1
            Assert-MockCalled Test-ComputerPing -Exactly 1
        }
    }

    Context 'When the computer is online' {
        BeforeEach {
            # Mock Test-ComputerPing to simulate the computer being online
            Mock Test-ComputerPing {
                return $true
            }
        }

        It 'Should return profiles when the computer is online and user has admin privileges' {
            # Mock admin environment variable
            $ENV:WinProfileOps_IsAdmin = $true

            # Mock Get-SIDProfileInfo to return a list of profiles
            Mock Get-SIDProfileInfo {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1' },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2' }
                )
            }

            $result = Get-UserProfilesFromRegistry -ComputerName $env:COMPUTERNAME

            # Validate result
            $result | Should -HaveCount 2
            $result[0].SID | Should -Be 'S-1-5-21-1001'
            $result[1].SID | Should -Be 'S-1-5-21-1002'

            # Assert that Test-ComputerPing and Get-SIDProfileInfo were called
            Assert-MockCalled Test-ComputerPing -Exactly 1
            Assert-MockCalled Get-SIDProfileInfo -Exactly 1
        }

        It 'Should return profiles when the computer is online and user lacks admin privileges' {
            # Mock non-admin environment variable
            $ENV:WinProfileOps_IsAdmin = $false

            # Mock Get-SIDProfileInfoFallback to return a list of profiles
            Mock Get-SIDProfileInfoFallback {
                return @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1' },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2' }
                )
            } -ModuleName $Script:dscModuleName

            $result = Get-UserProfilesFromRegistry -ComputerName $env:COMPUTERNAME

            # Validate result
            $result | Should -HaveCount 2
            $result[0].SID | Should -Be 'S-1-5-21-1001'
            $result[1].SID | Should -Be 'S-1-5-21-1002'

            # Assert that Test-ComputerPing and Get-SIDProfileInfoFallback were called
            Assert-MockCalled Test-ComputerPing -Exactly 1
            Assert-MockCalled Get-SIDProfileInfoFallback -Exactly 1
        }
    }


    # Test when the computer is offline/unreachable
    Context 'When the computer is offline or unreachable' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock Get-SIDProfileInfo to ensure it is not called
                Mock Get-SIDProfileInfo
                # Mock Get-SIDProfileInfoFallback to ensure it is not called
                Mock Get-SIDProfileInfoFallback

                # Mock Test-ComputerPing to simulate the computer being offline
                Mock Test-ComputerPing {
                    return $false
                }

                # Mock Write-Warning to capture the warning
                Mock Write-Warning
            }
        }

        It 'Should log a warning and return nothing when the computer is unreachable' {
            $ComputerName = 'OfflinePC'


            $env:WinProfileOps_IsAdmin = $true

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # Validate that the result is empty since the computer is unreachable
            $result | Should -BeNullOrEmpty

            # Assert that Test-ComputerPing was called
            Assert-MockCalled Test-ComputerPing -Exactly 1

            # Assert that Write-Warning was called to log the unreachable computer
            Assert-MockCalled Write-Warning -Exactly 1

            # Assert that neither Get-SIDProfileInfo nor Get-SIDProfileInfoFallback was called
            Assert-MockCalled Get-SIDProfileInfo -Exactly 0
            Assert-MockCalled Get-SIDProfileInfoFallback -Exactly 0
        }
    }

    # Test for profiles when Test-ComputerPing fails
    Context 'When Test-ComputerPing fails' {

        It 'Should log an error and return nothing when ping fails' {
            InModuleScope -ScriptBlock {
                # Mock Get-SIDProfileInfo to return incomplete profile data
                Mock Get-SIDProfileInfo


                # Mock Test-ComputerPing to simulate an error or failure
                Mock Test-ComputerPing {
                    throw "Ping failed"
                }

            }

            $env:WinProfileOps_IsAdmin = $true

            # Mock Write-Error to capture the error
            Mock Write-Error


            $ComputerName = 'RemotePC'

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            $result | Should -BeNullOrEmpty
            Assert-MockCalled Test-ComputerPing -Exactly 1
            Assert-MockCalled Write-Error -Exactly 1
            Assert-MockCalled Get-SIDProfileInfo -Exactly 0
        }
    }

    Context 'When user has administrator privileges' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock admin environment variable
                $ENV:WinProfileOps_IsAdmin = $true

                # Mock Get-SIDProfileInfo to return a list of profiles
                Mock Get-SIDProfileInfo {
                    return @(
                        [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1' },
                        [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2' }
                    )
                }
            }
        }

        It 'Should use registry-based method when user has admin privileges' {
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

    # Test for profiles when the user does not have admin privileges
    Context 'When user lacks administrator privileges' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock non-admin environment variable
                $ENV:WinProfileOps_IsAdmin = $false

                # Mock Get-SIDProfileInfoFallback to return a list of profiles
                Mock Get-SIDProfileInfoFallback {
                    return @(
                        [PSCustomObject]@{ SID = 'S-1-5-21-2001'; ProfilePath = 'C:\Users\User1' },
                        [PSCustomObject]@{ SID = 'S-1-5-21-2002'; ProfilePath = 'C:\Users\User2' }
                    )
                }
            }
        }

        It 'Should use fallback method when user lacks admin privileges' {
            $ComputerName = $env:COMPUTERNAME

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # Validate result
            $result | Should -HaveCount 2
            $result[0].SID | Should -Be 'S-1-5-21-2001'
            $result[0].ProfilePath | Should -Be 'C:\Users\User1'
            $result[1].SID | Should -Be 'S-1-5-21-2002'
            $result[1].ProfilePath | Should -Be 'C:\Users\User2'

            # Assert that Get-SIDProfileInfoFallback was called
            Assert-MockCalled Get-SIDProfileInfoFallback -Exactly 1
            Assert-MockCalled Test-ComputerPing -Exactly 1 -Scope It
        }
    }

    # Test when Get-SIDProfileInfoFallback fails
    Context 'When Get-SIDProfileInfoFallback fails' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock non-admin environment variable
                $ENV:WinProfileOps_IsAdmin = $false

                # Mock Get-SIDProfileInfoFallback to simulate an error
                Mock Get-SIDProfileInfoFallback {
                    throw "Failed to retrieve profiles via fallback method"
                }

                # Mock Write-Error to capture the error
                Mock Write-Error
            }
        }

        It 'Should log an error and return nothing when fallback method fails' {
            $ComputerName = $env:COMPUTERNAME

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # The result should be empty
            $result | Should -BeNullOrEmpty
            # Assert that Write-Error was called
            Assert-MockCalled Write-Error -Exactly 1
            Assert-MockCalled Get-SIDProfileInfoFallback -Exactly 1
            Assert-MockCalled Test-ComputerPing -Exactly 1 -Scope It
        }
    }

    # Test for when the computer is unreachable
    Context 'When the computer is unreachable' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock Test-ComputerPing to simulate the computer being unreachable
                Mock Test-ComputerPing {
                    return $false
                }

                # Mock Write-Warning to capture the warning
                Mock Write-Warning

                Mock Get-SIDProfileInfoFallback

                Mock Get-SIDProfileInfo
            }
        }

        It 'Should log a warning and return nothing when the computer is unreachable' {
            $ComputerName = 'OfflinePC'

            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName

            # The result should be empty
            $result | Should -BeNullOrEmpty

            # Assert that Test-ComputerPing and Write-Warning were called
            Assert-MockCalled Test-ComputerPing -Exactly 1
            Assert-MockCalled Write-Warning -Exactly 1
            Assert-MockCalled Get-SIDProfileInfoFallback -Exactly 0
            Assert-MockCalled Get-SIDProfileInfo -Exactly 0
        }
    }

}
