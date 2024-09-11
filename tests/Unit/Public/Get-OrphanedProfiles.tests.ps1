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

Describe 'Get-OrphanedProfiles' -Tag 'Public' {

    Context 'When there are orphaned profiles' {

        BeforeEach {
            # Mock Invoke-UserProfileAudit to return some orphaned profiles
            Mock Invoke-UserProfileAudit {
                return @(
                    [PSCustomObject]@{
                        SID          = 'S-1-5-21-1001'
                        ProfilePath  = 'C:\Users\User1'
                        IsOrphaned   = $true
                        OrphanReason = 'MissingRegistryEntry'
                        ComputerName = 'Server01'
                        IsSpecial    = $false
                    },
                    [PSCustomObject]@{
                        SID          = 'S-1-5-21-1002'
                        ProfilePath  = 'C:\Users\User2'
                        IsOrphaned   = $true
                        OrphanReason = 'MissingProfileFolder'
                        ComputerName = 'Server01'
                        IsSpecial    = $false
                    }
                )
            }
        }

        It 'Should return orphaned profiles from the audit' {
            $result = Get-OrphanedProfiles -ComputerName 'Server01'

            # Validate result
            $result | Should -HaveCount 2
            $result[0].SID | Should -Be 'S-1-5-21-1001'
            $result[0].ProfilePath | Should -Be 'C:\Users\User1'
            $result[0].IsOrphaned | Should -Be $true
            $result[0].OrphanReason | Should -Be 'MissingRegistryEntry'
            $result[1].SID | Should -Be 'S-1-5-21-1002'
            $result[1].ProfilePath | Should -Be 'C:\Users\User2'
            $result[1].IsOrphaned | Should -Be $true
            $result[1].OrphanReason | Should -Be 'MissingProfileFolder'

            # Assert that Invoke-UserProfileAudit was called
            Assert-MockCalled Invoke-UserProfileAudit -Exactly 1
        }
    }

    Context 'When there are no orphaned profiles' {

        BeforeEach {
            # Mock Invoke-UserProfileAudit to return profiles that are not orphaned
            Mock Invoke-UserProfileAudit {
                return @(
                    [PSCustomObject]@{
                        SID          = 'S-1-5-21-1001'
                        ProfilePath  = 'C:\Users\User1'
                        IsOrphaned   = $false
                        OrphanReason = $null
                        ComputerName = 'Server01'
                        IsSpecial    = $false
                    },
                    [PSCustomObject]@{
                        SID          = 'S-1-5-21-1002'
                        ProfilePath  = 'C:\Users\User2'
                        IsOrphaned   = $false
                        OrphanReason = $null
                        ComputerName = 'Server01'
                        IsSpecial    = $false
                    }
                )
            } -ModuleName $script:dscModuleName

            # Mock Write-Verbose to capture verbose output
            Mock Write-Verbose
        }

        It 'Should return an empty result when no orphaned profiles are found' {
            $result = Get-OrphanedProfiles -ComputerName 'Server01' -Verbose

            # Validate the result is empty
            $result | Should -BeNullOrEmpty

            # Ensure verbose message was logged
            Assert-MockCalled Write-Verbose -Exactly 1
        }
    }
}
