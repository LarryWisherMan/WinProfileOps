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

Describe 'Process-RegistryProfiles Tests' -Tag 'Private' {

    Context 'When processing registry profiles' {

        BeforeEach {
            # Mock Test-FolderExists to simulate checking if the profile folder exists
            Mock Test-FolderExists {
                param ($ProfilePath, $ComputerName)
                return $true  # Simulate that the folder exists
            } -ModuleName $script:dscModuleName

            # Mock Test-SpecialAccount to simulate handling of special accounts
            Mock Test-SpecialAccount {
                param ($FolderName, $SID, $ProfilePath)
                return $false  # Simulate that the account is not special
            } -ModuleName $script:dscModuleName

            # Mock Test-OrphanedProfile to simulate orphaned profile checks
            Mock Test-OrphanedProfile {
                param ($SID, $ProfilePath, $FolderExists, $IgnoreSpecial, $IsSpecial, $ComputerName)
                return [PSCustomObject]@{
                    SID          = $SID
                    ProfilePath  = $ProfilePath
                    IsOrphaned   = -not $FolderExists
                    ComputerName = $ComputerName
                    IsSpecial    = $IsSpecial
                }
            } -ModuleName $script:dscModuleName
        }

        It 'Should process profiles from the registry' {
            InModuleScope -ScriptBlock {

                $RegistryProfiles = @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1'; ComputerName = 'Server01' },
                    [PSCustomObject]@{ SID = 'S-1-5-21-1002'; ProfilePath = 'C:\Users\User2'; ComputerName = 'Server01' }
                )

                $result = Process-RegistryProfiles -RegistryProfiles $RegistryProfiles -ComputerName 'Server01'

                # Validate result
                $result | Should -HaveCount 2
                $result[0].SID | Should -Be 'S-1-5-21-1001'
                $result[0].ProfilePath | Should -Be 'C:\Users\User1'
                $result[0].IsOrphaned | Should -Be $false
                $result[1].SID | Should -Be 'S-1-5-21-1002'
                $result[1].ProfilePath | Should -Be 'C:\Users\User2'
                $result[1].IsOrphaned | Should -Be $false

                # Ensure the mocked functions were called
                Assert-MockCalled Test-FolderExists -Exactly 2
                Assert-MockCalled Test-OrphanedProfile -Exactly 2
            }
        }

        It 'Should skip special accounts if IgnoreSpecial is set' {
            InModuleScope -ScriptBlock {

                # Mock Test-SpecialAccount to simulate the account is special
                Mock Test-SpecialAccount {
                    param ($FolderName, $SID, $ProfilePath)
                    return $true  # Simulate that the account is special
                }

                $RegistryProfiles = @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\SpecialUser'; ComputerName = 'Server01' }
                )

                $result = Process-RegistryProfiles -RegistryProfiles $RegistryProfiles -ComputerName 'Server01' -IgnoreSpecial

                # Validate result should be empty because special account was skipped
                $result | Should -BeNullOrEmpty

                # Ensure the mocked functions were called
                Assert-MockCalled Test-SpecialAccount -Exactly 1
                Assert-MockCalled Test-OrphanedProfile -Exactly 0
            }
        }

        It 'Should detect orphaned profiles' {
            InModuleScope -ScriptBlock {

                # Mock Test-FolderExists to simulate the folder does not exist
                Mock Test-FolderExists {
                    param ($ProfilePath, $ComputerName)
                    return $false  # Simulate that the folder does not exist
                }

                $RegistryProfiles = @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\OrphanedUser'; ComputerName = 'Server01' }
                )

                $result = Process-RegistryProfiles -RegistryProfiles $RegistryProfiles -ComputerName 'Server01'

                # Validate result
                $result | Should -HaveCount 1
                $result[0].SID | Should -Be 'S-1-5-21-1001'
                $result[0].ProfilePath | Should -Be 'C:\Users\OrphanedUser'
                $result[0].IsOrphaned | Should -Be $true

                # Ensure the mocked functions were called
                Assert-MockCalled Test-FolderExists -Exactly 1
                Assert-MockCalled Test-OrphanedProfile -Exactly 1
            }
        }
    }
}
