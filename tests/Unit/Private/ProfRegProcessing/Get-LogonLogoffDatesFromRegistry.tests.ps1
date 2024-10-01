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

Describe 'Get-LogonLogoffDatesFromRegistry Tests' -Tag  "Private", "Unit", "ProfileRegProcessing" {

    BeforeAll {
        InModuleScope -Scriptblock {

            # Mock external function Get-RegistryValue to simulate the behavior of registry lookups
            Mock Get-RegistryValue -MockWith {
                param ($BaseKey, $ValueName)
                switch ($valueName)
                {
                    "LocalProfileLoadTimeLow" { return -1457393592 }    # Example low value
                    "LocalProfileLoadTimeHigh" { return 31112838 }   # Example high value
                    "LocalProfileUnloadTimeLow" { return -776345871 } # Example low value
                    "LocalProfileUnloadTimeHigh" { return 31114160 }# Example high value
                    default { return $null }
                }
            }
        }
    }


    Context 'Positive Tests' {
        It 'Should correctly calculate logon and logoff dates when registry values are present' {
            InModuleScope -Scriptblock {
                $subKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                $result = Get-LogonLogoffDatesFromRegistry -SubKey $subKeyMock

                $result | Should -Not -BeNullOrEmpty
                $result.Success | Should -Be $true
                $result.LogonDate | Should -BeOfType 'DateTime'
                $result.LogoffDate | Should -BeOfType 'DateTime'
                $result.LogonDate | Should -Not -Be [DateTime]::MinValue
                $result.LogoffDate | Should -Not -Be [DateTime]::MinValue
            }
        }
    }

    Context 'Negative Tests' {
        It 'Should return MinValue for logon/logoff when registry values are not present' {
            InModuleScope -Scriptblock {

                Mock Get-RegistryValue -MockWith { return $null } # Simulating missing registry values

                $subKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }
                $result = Get-LogonLogoffDatesFromRegistry -SubKey $subKeyMock

                $MinValue = [DateTime]::MinValue
                $result.Success | Should -Be $true
                $result.LogonDate | Should -Be $MinValue
                $result.LogoffDate | Should -Be $MinValue
            }
        }

        It 'Should throw an error when SubKey parameter is null' {
            InModuleScope -Scriptblock {
                { Get-LogonLogoffDatesFromRegistry -SubKey $null } | Should -Throw
            }
        }
    }

    Context 'Edge Case Tests' {
        It 'Should handle an invalid registry key gracefully' {
            InModuleScope -Scriptblock {
                Mock Get-RegistryValue -MockWith { throw "Registry key not found" }

                $subKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-InvalidKey'
                }

                $result = Get-LogonLogoffDatesFromRegistry -SubKey $subKeyMock

                $result.Success | Should -Be $false
                $result.Error | Should -Match 'Registry key not found'
                $result.LogonDate | Should -BeNull
                $result.LogoffDate | Should -BeNull
            }
        }

        It 'Should handle missing Low/High values for logon date' {
            InModuleScope -Scriptblock {
                Mock Get-RegistryValue -MockWith {
                    param ($BaseKey, $ValueName)
                    switch ($valueName)
                    {
                        "LocalProfileLoadTimeLow" { return $null }    # Example low value
                        "LocalProfileLoadTimeHigh" { return $null }   # Example high value
                        "LocalProfileUnloadTimeLow" { return -776345871 } # Example low value
                        "LocalProfileUnloadTimeHigh" { return 31114160 }# Example high value
                        default { return $null }
                    }
                }

                $subKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                $result = Get-LogonLogoffDatesFromRegistry -SubKey $subKeyMock

                $minValue = [DateTime]::MinValue
                $result.LogonDate | Should -Be $minValue
                $result.LogoffDate | Should -Not -Be $minValue
            }
        }
    }

    Context 'Exception Handling Tests' {
        It 'Should return a meaningful error when an exception occurs' {
            InModuleScope -Scriptblock {
                Mock Get-RegistryValue -MockWith { throw 'Registry access failed' }

                $subKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                $result = Get-LogonLogoffDatesFromRegistry -SubKey $subKeyMock

                $result.Success | Should -Be $false
                $result.Error | Should -Be 'Registry access failed'
                $result.LogonDate | Should -BeNull
                $result.LogoffDate | Should -BeNull
            }
        }
    }

    Context 'Verbose Logging Tests' {
        It 'Should write verbose messages when -Verbose is enabled' {
            InModuleScope -Scriptblock {
                $VerbosePreference = 'Continue'

                mock Write-Verbose

                $subKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                $results = Get-LogonLogoffDatesFromRegistry -SubKey $subKeyMock -Verbose

                Assert-MockCalled -CommandName Write-Verbose -Scope It -Times 1 -ParameterFilter {
                    $Message -eq 'Retrieving logon and logoff dates from subkey: HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }
            }
        }
    }

    Context 'Performance Tests' {
        It 'Should execute within acceptable time' {
            InModuleScope -Scriptblock {
                $subKeyMock = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{} -Properties @{
                    Name = 'HKEY_USERS\S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                $elapsedTime = Measure-Command { Get-LogonLogoffDatesFromRegistry -SubKey $subKeyMock }
                $elapsedTime.TotalMilliseconds | Should -BeLessThan 1000
            }
        }
    }
}
