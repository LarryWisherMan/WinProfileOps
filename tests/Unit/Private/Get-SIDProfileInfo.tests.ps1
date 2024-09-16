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

Describe 'Get-SIDProfileInfo' -Tags 'Private' {

    # General behavior: Testing normal function execution
    Context 'General Behavior' {

        # Test when the registry key is successfully opened
        Context 'When the registry key is successfully opened' {
            It 'Should return profile information for all SIDs in the registry' {
                InModuleScope -ScriptBlock {
                    Mock Open-RegistryKey {
                        New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                            GetSubKeyNames = { return @('S-1-5-21-1001', 'S-1-5-21-1002') }
                        }
                    }
                    Mock Open-RegistrySubKey {
                        param ($BaseKey, $Name)
                        if ($Name -eq 'S-1-5-21-1001')
                        {
                            New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                                GetValue = { param($valueName) if ($valueName -eq 'ProfileImagePath')
                                    {
                                        return 'C:\Users\TestUser1'
                                    } }
                            } -Properties @{ Name = 'S-1-5-21-1001' }
                        }
                        elseif ($Name -eq 'S-1-5-21-1002')
                        {
                            New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                                GetValue = { param($valueName) if ($valueName -eq 'ProfileImagePath')
                                    {
                                        return 'C:\Users\TestUser2'
                                    } }
                            } -Properties @{ Name = 'S-1-5-21-1002' }
                        }
                    }
                    Mock Get-ProfilePathFromSID { param ($SidKey) return $SidKey.GetValue('ProfileImagePath') }

                    $result = Get-SIDProfileInfo -ComputerName $env:COMPUTERNAME

                    $result | Should -Not -BeNullOrEmpty
                    $result[0].SID | Should -Be "S-1-5-21-1001"
                    $result[0].ProfilePath | Should -Be "C:\Users\TestUser1"
                    $result[1].SID | Should -Be "S-1-5-21-1002"
                    $result[1].ProfilePath | Should -Be "C:\Users\TestUser2"

                    Assert-MockCalled Open-RegistryKey -Exactly 1
                    Assert-MockCalled Get-RegistrySubKey -Exactly 2
                    Assert-MockCalled Get-ProfilePathFromSID -Exactly 2
                }
            }
        }

    }

    # Error Handling: Handling missing subkeys, invalid SIDs, or failure to open the registry key
    Context 'Error Handling' {

        Context 'When a registry subkey cannot be opened' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    Mock Open-RegistryKey {
                        New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                            GetSubKeyNames = { return @('S-1-5-21-1001', 'S-1-5-21-1002') }
                        }
                    }
                    Mock Open-RegistrySubKey {
                        param ($BaseKey, $Name)
                        if ($Name -eq 'S-1-5-21-1001')
                        {
                            return $null
                        }
                        else
                        {
                            New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                                GetValue = { param($valueName) if ($valueName -eq 'ProfileImagePath')
                                    {
                                        return 'C:\Users\TestUser2'
                                    } }
                            } -Properties @{ Name = 'S-1-5-21-1002' }
                        }
                    }
                    Mock Get-ProfilePathFromSID { param ($SidKey) return $SidKey.GetValue('ProfileImagePath') }
                    Mock Write-Warning
                }
            }

            It 'Should log a warning and continue processing other SIDs' {
                InModuleScope -ScriptBlock {
                    $result = Get-SIDProfileInfo -ComputerName $env:COMPUTERNAME

                    $result | Should -HaveCount 1
                    $result[0].SID | Should -Be "S-1-5-21-1002"
                    $result[0].ProfilePath | Should -Be "C:\Users\TestUser2"

                    Assert-MockCalled Open-RegistryKey -Exactly 1
                    Assert-MockCalled Open-RegistrySubKey -Exactly 2
                    Assert-MockCalled Get-ProfilePathFromSID -Exactly 1
                    Assert-MockCalled Write-Warning -Exactly 1 -Scope It
                }
            }
        }

        Context 'When the registry key cannot be opened' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    Mock Open-RegistryKey { $null }
                }
                Mock Write-Error
            }

            It 'Should write an error and return nothing' {
                InModuleScope -ScriptBlock {
                    $result = Get-SIDProfileInfo -ComputerName $env:COMPUTERNAME
                    $result | Should -BeNullOrEmpty

                    Assert-MockCalled Open-RegistryKey -Exactly 1
                    Assert-MockCalled Write-Error -Exactly 1 -Scope It
                }
            }
        }

        Context 'When an invalid SID format is encountered' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    Mock Open-RegistryKey {
                        New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                            GetSubKeyNames = { return @('Invalid-SID') }
                        }
                    }
                    Mock Open-RegistrySubKey {
                        New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                            GetValue = { return 'C:\Users\InvalidUser' }
                        }
                    }
                    Mock Get-ProfilePathFromSID { param ($SidKey) return $SidKey.GetValue('ProfileImagePath') }
                    Mock Write-Warning
                }
            }

            It 'Should log a warning for the invalid SID and continue' {
                InModuleScope -ScriptBlock {
                    $result = Get-SIDProfileInfo -ComputerName $env:COMPUTERNAME
                    $result | Should -BeNullOrEmpty
                    Assert-MockCalled Write-Warning -Exactly 1 -Scope It
                }
            }
        }

    }

    # Edge Cases: Handling scenarios like missing SIDs or missing profile paths
    Context 'Edge Cases' {

        Context 'When no SIDs are found in the registry key' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    Mock Open-RegistryKey {
                        New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                            GetSubKeyNames = { return @() }
                        }
                    }
                    Mock Open-RegistrySubKey
                    Mock Get-ProfilePathFromSID
                    Mock write-Verbose
                }
            }

            It 'Should return an empty result when no SIDs are found' {
                InModuleScope -ScriptBlock {
                    $result = Get-SIDProfileInfo -ComputerName $env:COMPUTERNAME
                    $result | Should -BeNullOrEmpty
                    Assert-MockCalled Open-RegistryKey -Exactly 1 -Scope It
                    Assert-MockCalled write-Verbose -Exactly 1 -Scope It
                    Assert-MockCalled Open-RegistrySubKey -Exactly 0 -Scope It
                    Assert-MockCalled Get-ProfilePathFromSID -Exactly 0 -Scope It
                }
            }
        }

        Context 'When a SID exists but has no ProfileImagePath' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    Mock Open-RegistryKey {
                        New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                            GetSubKeyNames = { return @('S-1-5-21-1001') }
                        }
                    }
                    Mock Open-RegistrySubKey {
                        New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                            GetValue = { return $null }
                        }
                    }
                    Mock Get-ProfilePathFromSID { param ($SidKey) return $SidKey.GetValue('ProfileImagePath') }
                    Mock Write-Verbose
                }
            }

            It 'Should log a verbose message and return the SID with a null ProfilePath' {
                InModuleScope -ScriptBlock {
                    $result = Get-SIDProfileInfo -ComputerName $env:COMPUTERNAME
                    $result | Should -HaveCount 1
                    $result[0].SID | Should -Be "S-1-5-21-1001"
                    $result[0].ProfilePath | Should -BeNullOrEmpty
                    Assert-MockCalled Write-Verbose -Exactly 1 -Scope It
                }
            }
        }

        Context 'When a mix of valid and invalid subkeys are encountered' {
            BeforeEach {
                InModuleScope -ScriptBlock {
                    Mock Open-RegistryKey {
                        New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                            GetSubKeyNames = { return @('S-1-5-21-1001', 'Invalid-SID') }
                        }
                    }
                    Mock Open-RegistrySubKey {
                        param ($BaseKey, $Name)
                        if ($Name -eq 'S-1-5-21-1001')
                        {
                            New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                                GetValue = { return 'C:\Users\TestUser1' }
                            }
                        }
                        else
                        {
                            return $null
                        }
                    }
                    Mock Get-ProfilePathFromSID { param ($SidKey) return $SidKey.GetValue('ProfileImagePath') }
                    Mock Write-Warning
                }
            }

            It 'Should return the valid SID and log a warning for the invalid one' {
                InModuleScope -ScriptBlock {
                    $result = Get-SIDProfileInfo -ComputerName $env:COMPUTERNAME
                    $result | Should -HaveCount 1
                    $result[0].SID | Should -Be "S-1-5-21-1001"
                    $result[0].ProfilePath | Should -Be "C:\Users\TestUser1"
                    Assert-MockCalled Write-Warning -Exactly 1 -Scope It
                }
            }
        }

    }

}
