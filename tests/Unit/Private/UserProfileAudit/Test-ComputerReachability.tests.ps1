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

Describe 'Test-ComputerReachability Tests' -Tag 'Private' {

    Context 'When checking computer reachability' {

        BeforeEach {
            # Mock Test-ComputerPing to simulate pinging a computer
            Mock Test-ComputerPing {
                param ($ComputerName)
                return $true  # Simulate the computer is reachable
            } -ModuleName $script:dscModuleName

            # Mock Write-Warning to verify warning messages
            Mock Write-Warning -ModuleName $script:dscModuleName
        }

        It 'Should return true when the computer is reachable' {
            InModuleScope -ScriptBlock {
                $result = Test-ComputerReachability -ComputerName 'Server01'

                # Validate result is true
                $result | Should -Be $true

                # Ensure that Test-ComputerPing was called once
                Assert-MockCalled Test-ComputerPing -Exactly 1
                Assert-MockCalled Write-Warning -Exactly 0
            }
        }

        It 'Should return false and log a warning when the computer is unreachable' {
            InModuleScope -ScriptBlock {

                # Override Test-ComputerPing to simulate the computer is unreachable
                Mock Test-ComputerPing {
                    return $false
                }

                Mock Write-Warning

                $result = Test-ComputerReachability -ComputerName 'Server01'

                # Validate result is false
                $result | Should -Be $false

                # Ensure that Test-ComputerPing was called once
                Assert-MockCalled Test-ComputerPing -Exactly 1

                # Ensure that Write-Warning was called once
                Assert-MockCalled Write-Warning -Exactly 1
            }
        }

        It 'Should throw if no computer name is provided' {
            InModuleScope -ScriptBlock {

                # Override Test-ComputerPing to simulate failure
                Mock Test-ComputerPing {
                    return $false
                }

                Mock Write-Warning

                { Test-ComputerReachability -ComputerName '' } | should -throw

                # Ensure that Test-ComputerPing was called once (with $null ComputerName)
                Assert-MockCalled Test-ComputerPing -Exactly 0

                # Ensure that Write-Warning was called once
                Assert-MockCalled Write-Warning -Exactly 0
            }
        }

        It 'Should use localhost if computername not specified' {
            InModuleScope -ScriptBlock {

                # Override Test-ComputerPing to simulate successful ping
                Mock Test-ComputerPing {
                    param ($ComputerName)
                    if ($ComputerName -eq $env:COMPUTERNAME)
                    {
                        return $true
                    }
                    return $false
                } -ModuleName $script:dscModuleName

                # Call the function without specifying a ComputerName
                $result = Test-ComputerReachability

                # Validate result is true (because localhost is reachable)
                $result | Should -Be $true

                # Ensure that Test-ComputerPing was called with 'localhost'
                Assert-MockCalled Test-ComputerPing -Exactly 1 -ParameterFilter { $ComputerName -eq $env:COMPUTERNAME }
            }
        }
    }
}
