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

# Pester Unit Test for Get-ProfileRegistryItems function
Describe 'Get-ProfileRegistryItems Function Tests' -Tags "Private", "Unit", "ProfileRegistryItems" {

    # Setup common mocks and in-module scope for all tests
    BeforeAll {
        InModuleScope -scriptblock {

            # Mocking external dependencies using New-MockObject
            Mock Open-RegistryKey {
                param ($RegistryHive, $ComputerName, $Writable, $RegistryPath)
                if ($RegistryHive -eq 'Users')
                {
                    return New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                        GetSubKeyNames = { return @('S-1-5-21-1234567890-1000', 'S-1-5-21-1234567890-1001') }
                        Close          = {}
                    }
                }
                elseif ($RegistryHive -eq 'LocalMachine')
                {
                    return New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                        GetSubKeyNames = { return @('S-1-5-21-1234567890') }
                        Close          = {}
                    }
                }
                return $null
            }

            Mock Invoke-ProfileRegistryItemProcessing {
                param ($ComputerName, $ProfileListKey, $HKEYUsersSubkeyNames)
                return @{
                    SID           = 'S-1-5-21-1234567890-1000'
                    Path          = 'ProfilePath'
                    LastLogonTime = Get-Date
                }
            }
        }
    }

    # Positive Test Context
    Context 'Positive Tests' {
        It 'Should retrieve profile registry items with valid inputs' {
            InModuleScope -scriptblock {
                $result = Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName 'RemotePC'
                $result | Should -Not -BeNullOrEmpty
                $result.SID | Should -Be 'S-1-5-21-1234567890-1000'
            }
        }

        It 'Should retrieve profile registry items using pipeline input' {
            InModuleScope -scriptblock {
                'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' |
                    Get-ProfileRegistryItems -ComputerName 'RemotePC' |
                        Should -Not -BeNullOrEmpty
            }
        }

        It 'Should handle multiple registry paths in pipeline' {
            InModuleScope -scriptblock {
                @('SOFTWARE\Path1', 'SOFTWARE\Path2') | Get-ProfileRegistryItems -ComputerName 'RemotePC' | Should -Not -BeNullOrEmpty
            }
        }

        It 'Should handle retrieving from different registry hives' {
            InModuleScope -scriptblock {
                Mock Open-RegistryKey {
                    param ($RegistryHive)
                    if ($RegistryHive -eq 'CurrentUser')
                    {
                        return New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                            GetSubKeyNames = { return @('S-1-5-21-1234567890-1000') }
                            Close          = {}
                        }
                    }
                    if ($RegistryHive -eq 'Users')
                    {
                        return New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                            GetSubKeyNames = { return @('S-1-5-21-1234567890-1000', 'S-1-5-21-1234567890-1001') }
                            Close          = {}
                        }
                    }
                    return $null
                }

                $result = Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName 'RemotePC' -RegistryHive 'CurrentUser'
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }

    # Negative Test Context
    Context 'Negative Tests' {
        It 'Should throw an error for null or empty RegistryPath' {
            InModuleScope -scriptblock {
                { Get-ProfileRegistryItems -RegistryPath $null -ComputerName 'RemotePC' } | Should -Throw
                { Get-ProfileRegistryItems -RegistryPath '' -ComputerName 'RemotePC' } | Should -Throw
            }
        }

        It 'Should throw an error for null or empty ComputerName' {
            InModuleScope -scriptblock {
                { Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName $null } | Should -Throw
                { Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName '' } | Should -Throw
            }
        }

        It 'Should handle non-existent registry paths' {
            InModuleScope -scriptblock {
                Mock Open-RegistryKey {
                    return $null  # Simulate failed registry key opening
                }

                { Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Invalid\Path' -ComputerName 'RemotePC' } | Should -Throw
            }
        }

        It 'Should throw error when given multiple computer names' {
            InModuleScope -scriptblock {
                { Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName @('PC1', 'PC2') } | Should -Throw
            }
        }
    }

    # Edge Case Test Context
    Context 'Edge Case Tests' {
        It 'Should handle empty subkey collection' {
            InModuleScope -scriptblock {
                Mock Open-RegistryKey {
                    return New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                        GetSubKeyNames = { return @() }
                        Close          = {}
                    }
                }

                $result = Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName 'RemotePC'
                $result | Should -BeNullOrEmpty
            }
        }

        It 'Should handle a registry path with no profile items' {
            InModuleScope -scriptblock {
                Mock Open-RegistryKey {
                    return New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                        GetSubKeyNames = { return @() }
                        Close          = {}
                    }
                }

                $result = Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName 'RemotePC'
                $result | Should -BeNullOrEmpty
            }
        }


        It 'Should handle invalid SIDs during profile processing' {
            InModuleScope -scriptblock {
                Mock Invoke-ProfileRegistryItemProcessing {
                    return @{ SID = $null; Path = 'ProfilePath'; LastLogonTime = Get-Date }
                }

                $result = Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName 'RemotePC'
                $result.SID | Should -BeNullOrEmpty
            }
        }


    }

    # Exception Handling Context
    Context 'Exception Tests' {
        It 'Should throw an error when unable to open HKEY_USERS' {
            InModuleScope -scriptblock {
                Mock Open-RegistryKey { return $null }

                { Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName 'RemotePC' } |
                    Should -Throw
            }
        }

        It 'Should throw error when lacking permissions to open registry key' {
            InModuleScope -scriptblock {
                Mock Open-RegistryKey {
                    throw 'Access denied'  # Simulate access denied
                }

                { Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName 'RemotePC' } | Should -Throw -ErrorId 'Access denied'
            }
        }
    }

    # Logging and Verbose Output Context
    Context 'Logging and Verbose Output Tests' {
        It 'Should log verbose messages during execution' {
            InModuleScope -scriptblock {
                Mock Write-Verbose

                Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName 'RemotePC' -Verbose

                Assert-MockCalled Write-Verbose -ParameterFilter { $Message -eq 'Opening HKEY_USERS hive on RemotePC' }
            }
        }
    }

    # Resource Cleanup Test Context
    Context 'Cleanup Tests' {
        It 'Should properly close registry keys after processing' {
            InModuleScope -scriptblock {
                $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    GetSubKeyNames = { return @('S-1-5-21-1234567890') }
                    Close          = { $global:RegistryKeyClosed = $true }
                }
                Mock Open-RegistryKey { return $mockRegistryKey }

                Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName 'RemotePC'

                $global:RegistryKeyClosed | Should -Be $true
            }
        }
    }

    # Performance Test Context
    Context 'Performance Tests' {
        It 'Should execute within reasonable time' {
            InModuleScope -scriptblock {
                $out = Measure-Command {
                    Get-ProfileRegistryItems -RegistryPath 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' -ComputerName 'RemotePC'
                }


                { $out.Milliseconds -lt 1000 } | Should -Be $true
            }
        }
    }
}
