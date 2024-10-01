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


Describe 'Get-ProfileStateFromRegistrySubKey Tests' -Tags "Private", "Unit", "ProfileRegProcessing" {

    BeforeAll {
        InModuleScope -Scriptblock {

            # Mock external function Get-RegistryValue to simulate reading from the registry
            Mock Get-RegistryValue -MockWith {
                param($BaseKey, $ValueName)
                if ($ValueName -eq "State")
                {
                    return 1  # Example state value
                }
                else
                {
                    return $null
                }
            }

            # Mock external function Get-ProfileStateText to simulate decoding the state
            Mock Get-ProfileStateText -MockWith {
                return "Active"
            }
        }
    }

    Context 'Positive Tests' {
        It 'Should return profile state and state text when valid inputs are provided' {
            InModuleScope -Scriptblock {
                # Create a mocked registry subkey with Name property set
                $subKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                $result = Get-ProfileStateFromRegistrySubKey -SubKey $subKeyMock

                $result | Should -Not -BeNullOrEmpty
                $result.Success | Should -Be $true
                $result.State | Should -Be 1
                $result.StateText | Should -Be 'Active'
            }
        }
    }

    Context 'Negative Tests' {
        It 'Should return $false and unknown state text when State is not found in registry' {
            InModuleScope -Scriptblock {
                # Mock Get-RegistryValue to return null (State not found)
                Mock Get-RegistryValue -MockWith { return $null }
                Mock Write-Warning

                # Create a mocked registry subkey with Name property set
                $subKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1002'
                }

                $result = Get-ProfileStateFromRegistrySubKey -SubKey $subKeyMock

                $result.Success | Should -Be $false
                $result.State | Should -Be $null
                $result.StateText | Should -Be 'Unknown'

                Assert-MockCalled -CommandName Write-Warning -Scope It -Times 1 -ParameterFilter {
                    $Message -eq "The 'State' value was not found in subkey: HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1002"
                }
            }
        }

        It 'Should throw an error if SubKey parameter is null' {
            InModuleScope -Scriptblock {
                { Get-ProfileStateFromRegistrySubKey -SubKey $null } | Should -Throw
            }
        }
    }

    Context 'Edge Case Tests' {
        It 'Should handle unknown state gracefully' {
            InModuleScope -Scriptblock {
                # Mock Get-RegistryValue to return a state value that does not have a known state text
                Mock Get-RegistryValue -MockWith { return 999 }

                # Create a mocked registry subkey with Name property set
                $subKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1003'
                }

                # Simulate that the state is unknown
                Mock Get-ProfileStateText -MockWith { return "Unknown" }

                $result = Get-ProfileStateFromRegistrySubKey -SubKey $subKeyMock

                $result.Success | Should -Be $true
                $result.State | Should -Be 999
                $result.StateText | Should -Be 'Unknown'


            }
        }
    }

    Context 'Exception Handling Tests' {
        It 'Should return meaningful error message when an exception occurs' {
            InModuleScope -Scriptblock {
                # Mock Get-RegistryValue to throw an exception
                Mock Get-RegistryValue -MockWith { throw "Registry access error" }

                mock Write-Warning
                # Create a mocked registry subkey with Name property set
                $subKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1004'
                }

                $result = Get-ProfileStateFromRegistrySubKey -SubKey $subKeyMock

                $result.Success | Should -Be $false
                $result.Error | Should -Be 'Registry access error'
                $result.State | Should -BeNull
                $result.StateText | Should -Be 'Unknown'

                Assert-MockCalled -CommandName Write-Warning -Scope It -Times 1 -ParameterFilter {
                    $Message -eq "Error retrieving profile state from subkey: HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1004. Error: Registry access error"
                }
            }
        }
    }

    Context 'Verbose Logging Tests' {
        It 'Should write verbose messages when -Verbose is enabled' {
            InModuleScope -Scriptblock {
                $VerbosePreference = 'Continue'

                # Mock Write-Verbose
                Mock Write-Verbose

                # Create a mocked registry subkey with Name property set
                $subKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                Get-ProfileStateFromRegistrySubKey -SubKey $subKeyMock -Verbose | Out-Null

                Assert-MockCalled -CommandName Write-Verbose -Scope It -Times 1 -ParameterFilter {
                    $Message -eq "Profile state found: 1"
                }
            }
        }
    }

    Context 'Performance Tests' {
        It 'Should complete within acceptable time frame' {
            InModuleScope -Scriptblock {
                # Create a mocked registry subkey with Name property set
                $subKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                $elapsedTime = Measure-Command { Get-ProfileStateFromRegistrySubKey -SubKey $subKeyMock }
                $elapsedTime.TotalMilliseconds | Should -BeLessThan 1000
            }
        }
    }


}
