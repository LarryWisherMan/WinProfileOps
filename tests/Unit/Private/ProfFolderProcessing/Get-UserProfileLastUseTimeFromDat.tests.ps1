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

Describe 'Get-UserProfileLastUseTimeFromDat Tests' -Tags "Private", "Unit", "ProfFolderProcessing" {

    BeforeAll {
        InModuleScope -Scriptblock {

            # Mocking external dependencies
            Mock Get-DirectoryPath -MockWith {
                "C:\Users\TestUser\AppData\Local\Microsoft\Windows\UsrClass.dat"
            }

            Mock Get-ChildItem -MockWith {
                @([pscustomobject]@{FullName = 'C:\Users\TestUser\AppData\Local\Microsoft\Windows\UsrClass.dat'; LastWriteTime = (Get-Date).AddDays(-1) },
                    [pscustomobject]@{FullName = 'C:\Users\AdminUser\AppData\Local\Microsoft\Windows\UsrClass.dat'; LastWriteTime = (Get-Date).AddDays(-5) })
            }
        }
    }

    Context 'Positive Tests' {
        It 'Should retrieve UsrClass.dat information from local computer' {
            InModuleScope -Scriptblock {
                $result = Get-UserProfileLastUseTimeFromDat -ComputerName 'TestComputer'

                $result | Should -Not -BeNullOrEmpty
                $result.UserPath | Should -Contain 'C:\Users\TestUser'
                $result[0].LastLogon | Should -BeOfType 'DateTime'
                $result[0].Success | Should -Be $true
            }
        }

        It 'Should retrieve UsrClass.dat information from remote computer' {
            InModuleScope -Scriptblock {
                $result = Get-UserProfileLastUseTimeFromDat -ComputerName 'RemoteComputer'

                $result | Should -Not -BeNullOrEmpty
                $result.UserPath | Should -Contain  'C:\Users\AdminUser'
                $result[1].LastLogon | Should -BeOfType 'DateTime'
                $result[1].Success | Should -Be $true
            }
        }
    }

    Context 'Negative Tests' {
        It 'Should return error message for invalid ComputerName' {
            InModuleScope -Scriptblock {
                Mock Get-DirectoryPath -MockWith { throw 'Invalid path' }

                { Get-UserProfileLastUseTimeFromDat -ComputerName 'InvalidComputer' } | Should -Throw
            }
        }

        It 'Should throw error if $SystemDrive is not set' {
            InModuleScope -Scriptblock {
                { Get-UserProfileLastUseTimeFromDat -SystemDrive $null } | Should -Throw
            }
        }
    }

    Context 'Edge Case Tests' {
        It 'Should handle empty UserFolders gracefully' {
            InModuleScope -Scriptblock {
                Mock Get-ChildItem -MockWith { @() }

                mock Write-Warning

                $result = Get-UserProfileLastUseTimeFromDat -ComputerName 'TestComputer'
                $result | Should -Not -BeNullOrEmpty
                $result[0].Success | Should -Be $false
                $result[0].Message | Should -Be 'No UsrClass.dat files found.'

                Assert-MockCalled -CommandName Write-Warning -Times 1 -ParameterFilter {
                    $Message -eq 'No UsrClass.dat files found in path: C:\Users\TestUser\AppData\Local\Microsoft\Windows\UsrClass.dat'
                }
            }
        }

        It 'Should handle missing LastLogon' {
            InModuleScope -Scriptblock {
                Mock Get-ChildItem -MockWith {
                    @([pscustomobject]@{FullName = 'C:\Users\TestUser\AppData\Local\Microsoft\Windows\UsrClass.dat'; LastWriteTime = $null })
                }

                $result = Get-UserProfileLastUseTimeFromDat -ComputerName 'TestComputer'
                $result[0].LastLogon | Should -BeNull
            }
        }
    }

    Context 'Exception Handling Tests' {
        It 'Should handle exception when accessing UsrClass.dat' {
            InModuleScope -Scriptblock {
                Mock Get-ChildItem -MockWith { throw 'Access denied' }

                mock Write-Warning

                $result = Get-UserProfileLastUseTimeFromDat -ComputerName 'TestComputer'

                $result.Success | Should -Be $false
                $result.Error | Should -Be 'Access denied'

                Assert-MockCalled -CommandName Write-Warning -Times 1 -ParameterFilter {
                    $Message -eq 'An error occurred while processing UsrClass.dat files: Access denied'
                }
            }
        }
    }

    Context 'Verbose and Debug Logging Tests' {
        It 'Should log verbose messages when -Verbose is used' {
            InModuleScope -Scriptblock {
                $VerbosePreference = 'Continue'

                Mock Write-Verbose
                Get-UserProfileLastUseTimeFromDat -ComputerName 'TestComputer' -Verbose | Out-Null

                Assert-MockCalled -CommandName Write-Verbose -Scope It -Times 1 -ParameterFilter {
                    $Message -eq 'Starting function Get-UserProfileLastUseTimeFromDat for computer: TestComputer'
                }

                Assert-MockCalled -CommandName Write-Verbose -Scope It -Times 1 -ParameterFilter {
                    $Message -eq 'Resolved path: C:\Users\TestUser\AppData\Local\Microsoft\Windows\UsrClass.dat'
                }

            }
        }
    }

    Context 'Performance Tests' {
        It 'Should complete within acceptable time' {
            InModuleScope -Scriptblock {
                $elapsedTime = Measure-Command { Get-UserProfileLastUseTimeFromDat -ComputerName 'TestComputer' }
                $elapsedTime.TotalMilliseconds | Should -BeLessThan 1000
            }
        }
    }

}
