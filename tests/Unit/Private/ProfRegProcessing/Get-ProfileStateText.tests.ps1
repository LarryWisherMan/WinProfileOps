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

Describe 'Get-ProfileStateText Tests' -Tags "Private", "Unit", "ProfileRegProcessing" {

    BeforeAll {
        InModuleScope -Scriptblock {
            # No external dependencies to mock in this case
        }
    }

    Context 'Positive Tests' {
        It 'Should return "StandardLocal" for state = 0' {
            InModuleScope -Scriptblock {
                $result = Get-ProfileStateText -state 0
                $result | Should -Be 'StandardLocal'
            }
        }

        It 'Should return "Mandatory" for state = 1' {
            InModuleScope -Scriptblock {
                $result = Get-ProfileStateText -state 1
                $result | Should -Be 'Mandatory'
            }
        }

        It 'Should return "Mandatory,UseCache" for state = 3' {
            InModuleScope -Scriptblock {
                $result = Get-ProfileStateText -state 3
                $result | Should -Be 'Mandatory,UseCache'
            }
        }

        It 'Should return "AdminUser" for state = 256' {
            InModuleScope -Scriptblock {
                $result = Get-ProfileStateText -state 256
                $result | Should -Be 'AdminUser'
            }
        }

        It 'Should return multiple flags as a comma-separated string for complex state' {
            InModuleScope -Scriptblock {
                $result = Get-ProfileStateText -state 287  # 256 + 16 + 8 + 4 + 2 + 1
                $result | Should -Be 'Mandatory,UseCache,NewLocal,NewCentral,UpdateCentral,AdminUser'
            }
        }
    }

    Context 'Negative Tests' {
        It 'Should return an StandardLocal for null input' {
            InModuleScope -Scriptblock {
                $result = Get-ProfileStateText -state $null
                $result | Should -Be 'StandardLocal'
            }
        }

        It 'Should return an StandardLocal for negative input' {
            InModuleScope -Scriptblock {
                $result = Get-ProfileStateText -state -1
                $result | Should -Be 'StandardLocal'
            }
        }

        It 'Should return correct flags for state with multiple matching flags (999)' {
            InModuleScope -Scriptblock {
                $result = Get-ProfileStateText -state 999
                $result | Should -Be 'Mandatory,UseCache,NewLocal,DeleteCache,Upgrade,GuestUser,AdminUser,DefaultNetReady'
            }
        }
    }

    Context 'Edge Case Tests' {
        It 'Should handle maximum allowed integer value (2048)' {
            InModuleScope -Scriptblock {
                $result = Get-ProfileStateText -state 2048
                $result | Should -Be 'TempAssigned'
            }
        }

        It 'Should handle state values with all known flags set' {
            InModuleScope -Scriptblock {
                $result = Get-ProfileStateText -state 2047  # All known flags combined
                $out = $result.split(',')
                $out | Should -Contain 'Mandatory'
                $out | Should -Contain 'AdminUser'
                $out | Should -Contain 'SlowLink'
                $out | Should -Contain 'Upgrade'
            }
        }

        It 'Should handle state value 2049 and return "Mandatory,TempAssigned"' {
            InModuleScope -Scriptblock {
                $result = Get-ProfileStateText -state 2049
                $result | Should -Be 'Mandatory,TempAssigned'
            }
        }
    }

    Context 'Verbose Logging Tests' {
        It 'Should write verbose messages when -Verbose is enabled' {
            InModuleScope -Scriptblock {
                $VerbosePreference = 'Continue'
                Mock Write-Verbose

                Get-ProfileStateText -state 0 -Verbose | Out-Null

                Assert-MockCalled -CommandName Write-Verbose -Scope It -Times 1 -ParameterFilter {
                    $Message -eq 'Profile state: 0'
                }
            }
        }
    }

    Context 'Performance Tests' {
        It 'Should complete within acceptable time frame' {
            InModuleScope -Scriptblock {
                $elapsedTime = Measure-Command { Get-ProfileStateText -state 3 }
                $elapsedTime.TotalMilliseconds | Should -BeLessThan 1000
            }
        }
    }
}
