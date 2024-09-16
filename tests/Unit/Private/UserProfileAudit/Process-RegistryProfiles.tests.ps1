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

    Remove-Variable -Name capturedParams -Scope Global
}

Describe 'Process-RegistryProfiles Tests' -Tag 'Private' {

    Context 'When processing registry profiles' {


        It 'Should process profiles from the registry' {
            InModuleScope -ScriptBlock {
                # Mock Test-FolderExists to simulate checking if the profile folder exists
                Mock Test-FolderExists {
                    param ($ProfilePath, $ComputerName)
                    return $true  # Simulate that the folder exists
                }

                Mock Test-SpecialAccount {
                    param ($FolderName, $SID, $ProfilePath)
                    return $false  # Simulate that the account is not special
                }

                # Update Mock Test-OrphanedProfile to include AccessError parameter
                Mock Test-OrphanedProfile {
                    param (
                        [string]$SID,
                        [string]$ProfilePath,
                        [bool]$FolderExists,
                        [bool]$AccessError,
                        [bool]$IgnoreSpecial,
                        [bool]$IsSpecial,
                        [string]$ComputerName
                    )
                    return [PSCustomObject]@{
                        SID          = $SID
                        ProfilePath  = $ProfilePath
                        IsOrphaned   = -not $FolderExists -or $AccessError
                        OrphanReason = $(if ($AccessError)
                            {
                                'AccessDenied'
                            }
                            else
                            {
                                $null
                            })
                        ComputerName = $ComputerName
                        IsSpecial    = $IsSpecial
                    }
                }

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

                # Update Mock Test-OrphanedProfile to include AccessError parameter
                Mock Test-OrphanedProfile {
                    param (
                        [string]$SID,
                        [string]$ProfilePath,
                        [bool]$FolderExists,
                        [bool]$AccessError,
                        [bool]$IgnoreSpecial,
                        [bool]$IsSpecial,
                        [string]$ComputerName
                    )
                    return [PSCustomObject]@{
                        SID          = $SID
                        ProfilePath  = $ProfilePath
                        IsOrphaned   = -not $FolderExists -or $AccessError
                        OrphanReason = $(if ($AccessError)
                            {
                                'AccessDenied'
                            }
                            else
                            {
                                $null
                            })
                        ComputerName = $ComputerName
                        IsSpecial    = $IsSpecial
                    }
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

                # Update Mock Test-OrphanedProfile to include AccessError parameter
                Mock Test-OrphanedProfile {
                    param (
                        [string]$SID,
                        [string]$ProfilePath,
                        [bool]$FolderExists,
                        [bool]$AccessError,
                        [bool]$IgnoreSpecial,
                        [bool]$IsSpecial,
                        [string]$ComputerName
                    )
                    return [PSCustomObject]@{
                        SID          = $SID
                        ProfilePath  = $ProfilePath
                        IsOrphaned   = -not $FolderExists -or $AccessError
                        OrphanReason = $(if ($AccessError)
                            {
                                'AccessDenied'
                            }
                            else
                            {
                                $null
                            })
                        ComputerName = $ComputerName
                        IsSpecial    = $IsSpecial
                    }
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

        It 'Should handle access denied errors and continue processing' {
            InModuleScope -ScriptBlock {
                # Mock Test-FolderExists to simulate access denied error
                Mock Test-FolderExists {
                    Throw [UnauthorizedAccessException]::new('Access is denied.')
                }

                # Update Mock Test-OrphanedProfile to include AccessError parameter
                Mock Test-OrphanedProfile {
                    param (
                        [string]$SID,
                        [string]$ProfilePath,
                        [bool]$FolderExists,
                        [bool]$AccessError,
                        [bool]$IgnoreSpecial,
                        [bool]$IsSpecial,
                        [string]$ComputerName
                    )
                    return [PSCustomObject]@{
                        SID          = $SID
                        ProfilePath  = $ProfilePath
                        IsOrphaned   = -not $FolderExists -or $AccessError
                        OrphanReason = $(if ($AccessError)
                            {
                                'AccessDenied'
                            }
                            else
                            {
                                $null
                            })
                        ComputerName = $ComputerName
                        IsSpecial    = $IsSpecial
                    }
                }

                # Capture parameters passed to Test-OrphanedProfile
                $global:capturedParams = $null

                # Mock Test-OrphanedProfile to capture parameters
                Mock Test-OrphanedProfile {
                    param (
                        [string]$SID,
                        [string]$ProfilePath,
                        [bool]$FolderExists,
                        [bool]$AccessError,
                        [bool]$IgnoreSpecial,
                        [bool]$IsSpecial,
                        [string]$ComputerName
                    )
                    $global:capturedParams = @{
                        SID           = $SID
                        ProfilePath   = $ProfilePath
                        FolderExists  = $FolderExists
                        AccessError   = $AccessError
                        IgnoreSpecial = $IgnoreSpecial
                        IsSpecial     = $IsSpecial
                        ComputerName  = $ComputerName
                    }
                    return [PSCustomObject]@{
                        SID          = $SID
                        ProfilePath  = $ProfilePath
                        IsOrphaned   = $false
                        OrphanReason = 'AccessDenied'
                        ComputerName = $ComputerName
                        IsSpecial    = $IsSpecial
                    }
                }

                $RegistryProfiles = @(
                    [PSCustomObject]@{ SID = 'S-1-5-21-1003'; ProfilePath = 'C:\Users\UserWithAccessError'; ComputerName = 'Server01' }
                )

                $result = Process-RegistryProfiles -RegistryProfiles $RegistryProfiles -ComputerName 'Server01'

                # Validate result
                $result | Should -HaveCount 1
                $result[0].SID | Should -Be 'S-1-5-21-1003'
                $result[0].ProfilePath | Should -Be 'C:\Users\UserWithAccessError'
                $result[0].IsOrphaned | Should -Be $false
                $result[0].OrphanReason | Should -Be 'AccessDenied'

                # Ensure the mocked functions were called
                Assert-MockCalled Test-FolderExists -Exactly 1
                Assert-MockCalled Test-OrphanedProfile -Exactly 1

                # Verify that AccessError was set to $true
                $global:capturedParams.AccessError | Should -Be $true
            }
        }
    }
}
