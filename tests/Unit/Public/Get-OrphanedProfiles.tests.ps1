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

Describe 'Get-OrphanedProfiles Tests' -Tags 'Public', 'Unit', 'UserProfileAudit', 'OrphanedProfiles' {

    BeforeAll {

        # Mock external dependencies
        Mock Invoke-UserProfileAudit -MockWith {
            return @(
                [PSCustomObject]@{
                    SID          = 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                    ProfilePath  = 'C:\Users\User1'
                    IsOrphaned   = $true
                    OrphanReason = 'No registry entry'
                    ComputerName = $ComputerName
                    IsSpecial    = $false
                },
                [PSCustomObject]@{
                    SID          = 'S-1-5-21-1234567890-1234567890-1234567890-1002'
                    ProfilePath  = 'C:\Users\User2'
                    IsOrphaned   = $false
                    OrphanReason = ''
                    ComputerName = $ComputerName
                    IsSpecial    = $false
                }
            )
        }

    }

    Context 'Positive Tests' {

        It 'Should return orphaned profiles for a valid computer' {
            $result = Get-OrphanedProfiles -ComputerName 'Server01' -ProfileFolderPath 'C:\Users'

            # Assert that result is not null or empty
            $result | Should -Not -BeNullOrEmpty

            # Assert that only orphaned profiles are returned
            $result | Should -HaveCount 1
            $result[0].IsOrphaned | Should -Be $true
            $result[0].OrphanReason | Should -Be 'No registry entry'
        }

        It 'Should return orphaned profiles for the local computer by default' {
            $result = Get-OrphanedProfiles

            # Assert that result is not null or empty
            $result | Should -Not -BeNullOrEmpty

            # Assert that the ComputerName is local machine's name
            $result[0].ComputerName | Should -Be $env:COMPUTERNAME
        }

        It 'Should respect the IgnoreSpecial switch and exclude special profiles' {
            Mock Invoke-UserProfileAudit -MockWith {
                return @(
                    [PSCustomObject]@{
                        SID          = 'S-1-5-18'
                        ProfilePath  = 'C:\Windows\System32\Config\SystemProfile'
                        IsOrphaned   = $false
                        OrphanReason = ''
                        ComputerName = $ComputerName
                        IsSpecial    = $true
                    }
                )
            }

            $result = Get-OrphanedProfiles -IgnoreSpecial

            # Assert that result is empty since all profiles are special
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Negative Tests' {

        It 'Should handle invalid ComputerName input' {
            { Get-OrphanedProfiles -ComputerName $null } | Should -Throw
        }

        It 'Should return empty array if no orphaned profiles are found' {
            Mock Invoke-UserProfileAudit -MockWith {
                return @(
                    [PSCustomObject]@{
                        SID          = 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                        ProfilePath  = 'C:\Users\User1'
                        IsOrphaned   = $false
                        OrphanReason = ''
                        ComputerName = $ComputerName
                        IsSpecial    = $false
                    }
                )
            }

            $result = Get-OrphanedProfiles -ComputerName 'Server01'

            # Assert that result is empty
            $result | Should -BeNullOrEmpty
        }
    }

    Context 'Edge Case Tests' {

        It 'Should handle empty array from Invoke-UserProfileAudit' {
            Mock Invoke-UserProfileAudit -MockWith { return @() }

            $result = Get-OrphanedProfiles -ComputerName 'Server01'

            # Assert that result is empty
            $result | Should -BeNullOrEmpty
        }

        It 'Should handle no input for ComputerName by using the local machine name' {
            $result = Get-OrphanedProfiles

            # Assert that the ComputerName defaults to the local machine
            $result[0].ComputerName | Should -Be $env:COMPUTERNAME
        }
    }

    Context 'Exception Handling' {

        It 'Should handle errors thrown by Invoke-UserProfileAudit' {
            Mock Invoke-UserProfileAudit -MockWith { throw "Error retrieving profiles" }

            mock Write-Error

            Get-OrphanedProfiles -ComputerName 'ErrorServer' | out-null

            Assert-MockCalled -CommandName Write-Error -Exactly 1 -ParameterFilter {
                $message -like "*Error retrieving profiles*"
            }

        }
    }

    Context 'Verbose and Debug Logging' {

        It 'Should log verbose message if no orphaned profiles are found' {
            Mock Invoke-UserProfileAudit -MockWith {
                return @(
                    [PSCustomObject]@{
                        SID          = 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                        ProfilePath  = 'C:\Users\User1'
                        IsOrphaned   = $false
                        OrphanReason = ''
                        ComputerName = $ComputerName
                        IsSpecial    = $false
                    }
                )
            }

            mock Write-Verbose

            Get-OrphanedProfiles -ComputerName 'Server01' -Verbose

            Assert-MockCalled -CommandName Write-Verbose -Exactly 1 -ParameterFilter {
                $message -like "No orphaned profiles found on computer 'Server01'."
            }
        }
    }

    Context 'Performance Tests' {

        It 'Should execute within acceptable time for normal inputs' {
            $executionTime = Measure-Command {
                Get-OrphanedProfiles -ComputerName 'Server01'
            }

            # Assert that the execution time is less than 1 second
            $executionTime.TotalMilliseconds | Should -BeLessThan 1000
        }
    }
}
