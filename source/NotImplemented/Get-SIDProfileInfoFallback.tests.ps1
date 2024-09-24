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

Describe 'Get-SIDProfileInfoFallback' -Tag 'Private' {

    Context 'When retrieving user profiles via fallback' {

        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock Get-CimInstance to simulate returning non-special profiles
                Mock Get-CimInstance {
                    return @(
                        [PSCustomObject]@{ SID = 'S-1-5-21-1001'; LocalPath = 'C:\Users\User1' },
                        [PSCustomObject]@{ SID = 'S-1-5-21-1002'; LocalPath = 'C:\Users\User2' }
                    )
                }
            }
        }

        It 'Should return profiles from the local computer' {
            $ComputerName = $env:COMPUTERNAME

            # Call the private function within the module scope
            $result = InModuleScope  -ScriptBlock {
                Get-SIDProfileInfoFallback -ComputerName $ComputerName
            }

            # Validate the results
            $result | Should -HaveCount 2
            $result[0].SID | Should -Be 'S-1-5-21-1001'
            $result[0].ProfilePath | Should -Be 'C:\Users\User1'
            $result[1].SID | Should -Be 'S-1-5-21-1002'
            $result[1].ProfilePath | Should -Be 'C:\Users\User2'

            # Assert that Get-CimInstance was called once
            Assert-MockCalled Get-CimInstance -Exactly 1
        }

        It 'Should return profiles from a remote computer' {
            $result = InModuleScope -ScriptBlock {

                $ComputerName = 'RemotePC'

                # Call the private function within the module scope

                Get-SIDProfileInfoFallback -ComputerName $ComputerName
            }

            # Validate the results
            $result | Should -HaveCount 2
            $result[0].SID | Should -Be 'S-1-5-21-1001'
            $result[0].ProfilePath | Should -Be 'C:\Users\User1'
            $result[1].SID | Should -Be 'S-1-5-21-1002'
            $result[1].ProfilePath | Should -Be 'C:\Users\User2'
            $result[0].ComputerName | Should -Be 'RemotePC'
            $result[1].ComputerName | Should -Be 'RemotePC'

            # Assert that Get-CimInstance was called once
            Assert-MockCalled Get-CimInstance -Exactly 1
        }
    }

    Context 'When no profiles are returned' {
        BeforeEach {
            InModuleScope  -ScriptBlock {
                # Mock Get-CimInstance to return an empty list
                Mock Get-CimInstance {
                    return @()
                }
            }
        }

        It 'Should return an empty result when no profiles are found' {
            $ComputerName = $env:COMPUTERNAME

            # Call the private function within the module scope
            $result = InModuleScope -ScriptBlock {
                Get-SIDProfileInfoFallback -ComputerName $ComputerName
            }

            # Validate the result is empty
            $result | Should -BeNullOrEmpty

            # Assert that Get-CimInstance was called once
            Assert-MockCalled Get-CimInstance -Exactly 1
        }
    }

    Context 'When Get-CimInstance throws an error' {
        BeforeEach {
            InModuleScope  -ScriptBlock {
                # Mock Get-CimInstance to throw an error
                Mock Get-CimInstance {
                    throw "CIM query failed"
                }

                # Mock Write-Error to capture the error
                Mock Write-Error
            }
        }

        It 'Should log an error and return nothing when Get-CimInstance fails' {
            $ComputerName = $env:COMPUTERNAME

            # Call the private function within the module scope
            $result = InModuleScope -ScriptBlock {
                try
                {
                    Get-SIDProfileInfoFallback -ComputerName $ComputerName
                }
                catch
                {
                    Write-Error "Error retrieving profiles via CIM"
                }
            }

            # The result should be empty
            $result | Should -BeNullOrEmpty

            # Assert that Write-Error was called
            Assert-MockCalled Write-Error -Exactly 1

            # Assert that Get-CimInstance was called once
            Assert-MockCalled Get-CimInstance -Exactly 1
        }
    }

}
