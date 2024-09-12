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

Describe 'Process-FolderProfiles.tests.ps1 Tests' -Tag 'Private' {

    Context 'When processing folder profiles' {

        BeforeEach {
            # Mock Test-SpecialAccount to simulate handling of special accounts
            Mock Test-SpecialAccount {
                param ($FolderName, $SID, $ProfilePath)
                return $false # Simulate that the account is not special
            } -ModuleName $script:dscModuleName

            # Mock New-UserProfileObject to create user profile objects
            Mock New-UserProfileObject {
                param ($SID, $ProfilePath, $IsOrphaned, $OrphanReason, $ComputerName, $IsSpecial)
                return [PSCustomObject]@{
                    SID          = $SID
                    ProfilePath  = $ProfilePath
                    IsOrphaned   = $IsOrphaned
                    OrphanReason = $OrphanReason
                    ComputerName = $ComputerName
                    IsSpecial    = $IsSpecial
                }
            }  -ModuleName $script:dscModuleName
        }

        It 'Should create user profiles for folders that are not in the registry' {

            InModuleScope -ScriptBlock {

                $UserFolders = @(
                    [PSCustomObject]@{ FolderName = 'User1'; ProfilePath = 'C:\Users\User1'; ComputerName = 'Server01' },
                    [PSCustomObject]@{ FolderName = 'User2'; ProfilePath = 'C:\Users\User2'; ComputerName = 'Server01' }
                )
                $RegistryProfiles = @()  # No matching profiles in the registry

                $result = Process-FolderProfiles -UserFolders $UserFolders -RegistryProfiles $RegistryProfiles -ComputerName 'Server01'

                # Validate result
                $result | Should -HaveCount 2
                $result[0].ProfilePath | Should -Be 'C:\Users\User1'
                $result[0].IsOrphaned | Should -Be $true
                $result[0].OrphanReason | Should -Be 'MissingRegistryEntry'
                $result[1].ProfilePath | Should -Be 'C:\Users\User2'
                $result[1].IsOrphaned | Should -Be $true
                $result[1].OrphanReason | Should -Be 'MissingRegistryEntry'

                # Assert that New-UserProfileObject was called
                Assert-MockCalled New-UserProfileObject -Exactly 2

            }
        }

        It 'Should skip special accounts if IgnoreSpecial is set' {
            InModuleScope -ScriptBlock {

                Mock Test-SpecialAccount {
                    param ($FolderName, $SID, $ProfilePath)
                    if ($FolderName -eq 'SpecialUser')
                    {
                        return $true # Simulate the account is special
                    }
                    else
                    {
                        return $false # Simulate the account is not special
                    }
                }

                $UserFolders = @(
                    [PSCustomObject]@{ FolderName = 'SpecialUser'; ProfilePath = 'C:\Users\SpecialUser'; ComputerName = 'Server01' },
                    [PSCustomObject]@{ FolderName = 'User2'; ProfilePath = 'C:\Users\User2'; ComputerName = 'Server01' }
                )
                $RegistryProfiles = @()  # No matching profiles in the registry

                $result = Process-FolderProfiles -UserFolders $UserFolders -RegistryProfiles $RegistryProfiles -ComputerName 'Server01' -IgnoreSpecial

                # Validate result
                $result | Should -HaveCount 1
                $result[0].ProfilePath | Should -Be 'C:\Users\User2'
                $result[0].IsOrphaned | Should -Be $true
                $result[0].OrphanReason | Should -Be 'MissingRegistryEntry'

                # Assert that New-UserProfileObject was called once (only for the non-special account)
                Assert-MockCalled New-UserProfileObject -Exactly 1

            }
        }

        It 'Should not create profiles for folders that exist in the registry' {
            InModuleScope -ScriptBlock {


                $UserFolders = @(
                    [PSCustomObject]@{ FolderName = 'User1'; ProfilePath = 'C:\Users\User1'; ComputerName = 'Server01' },
                    [PSCustomObject]@{ FolderName = 'User2'; ProfilePath = 'C:\Users\User2'; ComputerName = 'Server01' }
                )
                $RegistryProfiles = @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1001'; ProfilePath = 'C:\Users\User1'; ComputerName = 'Server01' }
                )

                $result = Process-FolderProfiles -UserFolders $UserFolders -RegistryProfiles $RegistryProfiles -ComputerName 'Server01'

                # Validate result (only User2 should be orphaned)
                $result | Should -HaveCount 1
                $result[0].ProfilePath | Should -Be 'C:\Users\User2'
                $result[0].IsOrphaned | Should -Be $true
                $result[0].OrphanReason | Should -Be 'MissingRegistryEntry'

                # Assert that New-UserProfileObject was called once (only for User2)
                Assert-MockCalled New-UserProfileObject -Exactly 1
            }
        }

        It 'Should return an empty result when no user folders are passed' {
            InModuleScope -ScriptBlock {
                $UserFolders = @()  # No folders
                $RegistryProfiles = @()  # No registry profiles

                $result = Process-FolderProfiles -UserFolders $UserFolders -RegistryProfiles $RegistryProfiles -ComputerName 'Server01'

                # Validate result
                $result | Should -BeNullOrEmpty
            }
        }

        It 'Should return an empty result when both registry and folder profiles are empty' {
            InModuleScope -ScriptBlock {
                $UserFolders = @()  # No folders
                $RegistryProfiles = @()  # No registry profiles

                $result = Process-FolderProfiles -UserFolders $UserFolders -RegistryProfiles $RegistryProfiles -ComputerName 'Server01'

                # Validate result
                $result | Should -BeNullOrEmpty
            }
        }

        It 'Should skip all special accounts if IgnoreSpecial is set' {
            InModuleScope -ScriptBlock {

                Mock Test-SpecialAccount {
                    param ($FolderName, $SID, $ProfilePath)
                    if ($FolderName -in @('SpecialUser1', 'SpecialUser2'))
                    {
                        return $true # Simulate special accounts
                    }
                    else
                    {
                        return $false
                    }
                }

                $UserFolders = @(
                    [PSCustomObject]@{ FolderName = 'SpecialUser1'; ProfilePath = 'C:\Users\SpecialUser1'; ComputerName = 'Server01' },
                    [PSCustomObject]@{ FolderName = 'SpecialUser2'; ProfilePath = 'C:\Users\SpecialUser2'; ComputerName = 'Server01' },
                    [PSCustomObject]@{ FolderName = 'User3'; ProfilePath = 'C:\Users\User3'; ComputerName = 'Server01' }
                )
                $RegistryProfiles = @()  # No matching profiles in the registry

                $result = Process-FolderProfiles -UserFolders $UserFolders -RegistryProfiles $RegistryProfiles -ComputerName 'Server01' -IgnoreSpecial

                # Validate result (only User3 should be processed)
                $result | Should -HaveCount 1
                $result[0].ProfilePath | Should -Be 'C:\Users\User3'
                $result[0].IsOrphaned | Should -Be $true
                $result[0].OrphanReason | Should -Be 'MissingRegistryEntry'

                # Assert that New-UserProfileObject was called only for User3
                Assert-MockCalled New-UserProfileObject -Exactly 1
            }
        }

        It 'Should handle error if Test-SpecialAccount fails' {
            InModuleScope -ScriptBlock {

                Mock Test-SpecialAccount {
                    throw "Error testing special account"
                }

                $UserFolders = @(
                    [PSCustomObject]@{ FolderName = 'User1'; ProfilePath = 'C:\Users\User1'; ComputerName = 'Server01' }
                )
                $RegistryProfiles = @()  # No matching profiles in the registry

                $result = { Process-FolderProfiles -UserFolders $UserFolders -RegistryProfiles $RegistryProfiles -ComputerName 'Server01' } | Should -Throw
            }
        }



    }
}
