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


Describe 'Get-ProfilePathFromSID Tests' -Tags "Private", "Unit", "ProfileRegProcessing" {

    BeforeAll {
        InModuleScope -Scriptblock {

            # Mock external function Get-RegistryValue to simulate reading from the registry
            Mock Get-RegistryValue -MockWith {
                if ($args[1] -eq "ProfileImagePath")
                {
                    return "C:\Users\TestUser"
                }
                else
                {
                    return $null
                }
            }
        }
    }

    Context 'Positive Tests' {
        It 'Should retrieve valid ProfileImagePath when registry value exists' {
            InModuleScope -Scriptblock {
                $sidKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                $result = Get-ProfilePathFromSID -SidKey $sidKeyMock

                $result | Should -Not -BeNullOrEmpty
                $result.Success | Should -Be $true
                $result.ProfileImagePath | Should -Be 'C:\Users\TestUser'
            }
        }
    }

    Context 'Negative Tests' {
        It 'Should return null for ProfileImagePath if the registry value does not exist' {
            InModuleScope -Scriptblock {
                # Mock Get-RegistryValue to return null (simulating missing registry value)
                Mock Get-RegistryValue -MockWith { return $null }


                $sidKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1002'
                }


                $result = Get-ProfilePathFromSID -SidKey $sidKeyMock

                $result.Success | Should -Be $true
                $result.ProfileImagePath | Should -Be $null
            }
        }

        It 'Should throw an error if SidKey parameter is not provided' {
            InModuleScope -Scriptblock {
                { Get-ProfilePathFromSID -SidKey $null } | Should -Throw
            }
        }
    }

    Context 'Edge Case Tests' {
        It 'Should handle empty ProfileImagePath gracefully' {
            InModuleScope -Scriptblock {
                # Mock to simulate empty ProfileImagePath
                Mock Get-RegistryValue -MockWith { return "" }


                $sidKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1003'
                }


                $result = Get-ProfilePathFromSID -SidKey $sidKeyMock

                $result.Success | Should -Be $true
                $result.ProfileImagePath | Should -Be ""
            }
        }
    }

    Context 'Exception Handling Tests' {
        It 'Should handle errors gracefully and return meaningful error message' {
            InModuleScope -Scriptblock {
                # Mock Get-RegistryValue to throw an exception
                Mock Get-RegistryValue -MockWith { throw "Registry read error" }

                mock Write-Warning

                $sidKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1004'

                }

                $result = Get-ProfilePathFromSID -SidKey $sidKeyMock

                $result.Success | Should -Be $false
                $result.Error | Should -Be 'Registry read error'
                $result.ProfileImagePath | Should -BeNull

                Assert-MockCalled -CommandName Write-Warning -Scope It -Times 1 -ParameterFilter {
                    $message -eq "Failed to retrieve ProfileImagePath for SID: HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1004. Error: Registry read error"
                }
            }
        }
    }

    Context 'Verbose Logging Tests' {
        It 'Should log verbose messages when -Verbose is enabled' {
            InModuleScope -Scriptblock {
                $VerbosePreference = 'Continue'

                mock Write-Verbose

                $sidKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                Get-ProfilePathFromSID -SidKey $sidKeyMock -Verbose | Out-Null

                Assert-MockCalled -CommandName Write-Verbose -Scope It -Times 1 -ParameterFilter {
                    $Message -eq 'Retrieving ProfileImagePath for SID: HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }
            }
        }
    }

    Context 'Performance Tests' {
        It 'Should execute within acceptable time' {
            InModuleScope -Scriptblock {
                $sidKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                $elapsedTime = Measure-Command { Get-ProfilePathFromSID -SidKey $sidKeyMock }
                $elapsedTime.TotalMilliseconds | Should -BeLessThan 1000
            }
        }
    }

}
