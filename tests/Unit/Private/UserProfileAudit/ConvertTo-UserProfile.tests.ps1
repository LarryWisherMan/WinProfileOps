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

Describe 'ConvertTo-UserProfile.tests.ps1 Tests' -Tag 'Private' {

}


Describe 'ConvertTo-UserProfile Tests' -Tags "Private", "Unit", "UserProfileAudit" {

    BeforeAll {
        InModuleScope -Scriptblock {
            # Mock New-Object to create a mock UserProfile object
            Mock New-Object -ParameterFilter { $args[0] -eq 'UserProfile' } -MockWith {
                return New-MockObject -Type 'UserProfile' -Properties @{
                    SID              = $args[1]
                    UserName         = $args[2]
                    ProfilePath      = $args[3]
                    ProfileState     = $args[4]
                    HasRegistryEntry = $args[5]
                    HasUserFolder    = $args[6]
                    LastLogonDate    = $args[7]
                    LastLogOffDate   = $args[8]
                    IsOrphaned       = $args[9]
                    OrphanReason     = $args[10]
                    ComputerName     = $args[11]
                    IsSpecial        = $args[12]
                    IsLoaded         = $args[13]
                    Domain           = $args[14]
                }
            }
        }
    }

    Context 'Positive Tests' {

        It 'Should handle valid inputs and create UserProfile object' {
            InModuleScope -Scriptblock {
                $profileItems = @(
                    [pscustomobject]@{
                        SID              = 'S-1-5-21-1234-5678'
                        UserName         = 'testuser'
                        ProfilePath      = 'C:\Users\testuser'
                        ProfileState     = 'Active'
                        HasRegistryEntry = $true
                        HasUserFolder    = $true
                        LastLogonDate    = [datetime]::Now.AddDays(-1)
                        LastLogOffDate   = [datetime]::Now.AddDays(-2)
                        IsSpecial        = $false
                        ComputerName     = 'TestComputer'
                        IsLoaded         = $true
                        Domain           = 'Domain'
                    }
                )

                $result = $profileItems | ConvertTo-UserProfile

                # Validate the results
                $result.SID | Should -Be 'S-1-5-21-1234-5678'
                $result.UserName | Should -Be 'testuser'
                $result.ProfilePath | Should -Be 'C:\Users\testuser'
                $result.ProfileState | Should -Be 'Active'
            }
        }

        It 'Should apply OrphanDetails view type' {
            InModuleScope -Scriptblock {
                $profileItems = @(
                    [pscustomobject]@{
                        SID              = 'S-1-5-21-1234-5678'
                        UserName         = 'testuser'
                        ProfilePath      = 'C:\Users\testuser'
                        ProfileState     = 'Active'
                        HasRegistryEntry = $true
                        HasUserFolder    = $true
                        LastLogonDate    = [datetime]::Now.AddDays(-1)
                        LastLogOffDate   = [datetime]::Now.AddDays(-2)
                        IsSpecial        = $false
                        ComputerName     = 'TestComputer'
                        IsLoaded         = $true
                        Domain           = 'Domain'
                    }
                )

                $result = $profileItems | ConvertTo-UserProfile -View "OrphanDetails"

                # Check that the TypeName has "UserProfile.OrphanDetails"
                $result.PSObject.TypeNames[0] | Should -Be 'UserProfile.OrphanDetails'
            }
        }
    }


    Context 'Switch Statement Scenarios' {

        It 'Should set IsOrphaned and OrphanReason to "MissingProfileImagePathAndFolder"' {
            InModuleScope -Scriptblock {
                $profileItems = @(
                    [pscustomobject]@{
                        SID           = 'S-1-5-21-1234-5678'
                        UserName      = 'testuser'
                        ProfilePath   = $null
                        HasUserFolder = $false
                    }
                )

                $result = $profileItems | ConvertTo-UserProfile

                $result.IsOrphaned | Should -Be $true
                $result.OrphanReason | Should -Be 'MissingProfileImagePathAndFolder'
            }
        }

        It 'Should set IsOrphaned and OrphanReason to "MissingProfileImagePath"' {
            InModuleScope -Scriptblock {
                $profileItems = @(
                    [pscustomobject]@{
                        SID           = 'S-1-5-21-1234-5678'
                        UserName      = 'testuser'
                        ProfilePath   = $null
                        HasUserFolder = $true
                    }
                )

                $result = $profileItems | ConvertTo-UserProfile

                $result.IsOrphaned | Should -Be $true
                $result.OrphanReason | Should -Be 'MissingProfileImagePath'
            }
        }

        It 'Should set IsOrphaned and OrphanReason to "MissingFolder"' {
            InModuleScope -Scriptblock {
                $profileItems = @(
                    [pscustomobject]@{
                        SID           = 'S-1-5-21-1234-5678'
                        UserName      = 'testuser'
                        ProfilePath   = 'C:\Users\testuser'
                        HasUserFolder = $false
                    }
                )

                $result = $profileItems | ConvertTo-UserProfile

                $result.IsOrphaned | Should -Be $true
                $result.OrphanReason | Should -Be 'MissingFolder'
            }
        }

        It 'Should set OrphanReason to "AccessDenied" but not orphan the profile' {
            InModuleScope -Scriptblock {
                $profileItems = @(
                    [pscustomobject]@{
                        SID           = 'S-1-5-21-1234-5678'
                        UserName      = 'testuser'
                        ProfilePath   = 'C:\Users\testuser'
                        HasUserFolder = $true
                        ErrorAccess   = $true
                        IsSpecial     = $true
                    }
                )

                $result = $profileItems | ConvertTo-UserProfile

                $result.IsOrphaned | Should -Be $false
                $result.OrphanReason | Should -Be 'AccessDenied'
            }
        }

        It 'Should set IsOrphaned and OrphanReason to "MissingRegistryEntry"' {
            InModuleScope -Scriptblock {
                $profileItems = @(
                    [pscustomobject]@{
                        SID              = 'S-1-5-21-1234-5678'
                        UserName         = 'testuser'
                        ProfilePath      = 'C:\Users\testuser'
                        HasUserFolder    = $true
                        HasRegistryEntry = $false
                        IsSpecial        = $false
                    }
                )

                $result = $profileItems | ConvertTo-UserProfile

                $result.IsOrphaned | Should -Be $true
                $result.OrphanReason | Should -Be 'MissingRegistryEntry'
            }
        }

        It 'Should set IsOrphaned to $false and OrphanReason to $null for other cases' {
            InModuleScope -Scriptblock {
                $profileItems = @(
                    [pscustomobject]@{
                        SID              = 'S-1-5-21-1234-5678'
                        UserName         = 'testuser'
                        ProfilePath      = 'C:\Users\testuser'
                        HasUserFolder    = $true
                        HasRegistryEntry = $true
                        IsSpecial        = $false
                    }
                )

                $result = $profileItems | ConvertTo-UserProfile

                $result.IsOrphaned | Should -Be $false
                $result.OrphanReason | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Edge Case Tests' {
        It 'Should handle empty ProfileRegistryItems input' {
            InModuleScope -Scriptblock {
                $result = @() | ConvertTo-UserProfile
                $result | Should -BeNullOrEmpty
            }
        }

        It 'Should handle profiles with minimum required properties' {
            InModuleScope -Scriptblock {
                $profileItems = @(
                    [pscustomobject]@{
                        SID      = 'S-1-5-21-1234-5678'
                        UserName = 'testuser'
                    }
                )

                $result = $profileItems | ConvertTo-UserProfile

                $result.SID | Should -Be 'S-1-5-21-1234-5678'
                $result.UserName | Should -Be 'testuser'
            }
        }
    }

    Context 'Verbose Logging Tests' {
    }

    Context 'Performance Tests' {
        It 'Should complete within acceptable time frame' {
            InModuleScope -Scriptblock {
                $profileItems = @(
                    [pscustomobject]@{
                        SID              = 'S-1-5-21-1234-5678'
                        UserName         = 'testuser'
                        ProfilePath      = 'C:\Users\testuser'
                        ProfileState     = 'Active'
                        HasRegistryEntry = $true
                        HasUserFolder    = $true
                    }
                )

                $elapsedTime = Measure-Command { $profileItems | ConvertTo-UserProfile }
                $elapsedTime.TotalMilliseconds | Should -BeLessThan 1000
            }
        }
    }
}
