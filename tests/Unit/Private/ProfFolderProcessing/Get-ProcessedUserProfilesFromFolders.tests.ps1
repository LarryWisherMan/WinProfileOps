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

Describe 'Get-ProcessedUserProfilesFromFolders Tests' -Tags "Private", "Unit", "ProfFolderProcessing" {

    BeforeAll {
        InModuleScope -Scriptblock {

            # Mock external dependencies
            Mock Get-UserProfileLastUseTimeFromDat -MockWith {
                @([pscustomobject]@{UserPath = 'C:\Users\TestUser'; LastLogon = (Get-Date).AddDays(-1) },
                    [pscustomobject]@{UserPath = 'C:\Users\AdminUser'; LastLogon = (Get-Date).AddDays(-5) })
            }

            Mock Resolve-UsernamesToSIDs -MockWith {
                'S-1-5-21-1234567890-1234567890-1234567890-1001'
            }

            Mock Get-UserAccountFromSID -MockWith {
                [pscustomobject]@{Username = 'TestUser'; Domain = 'DOMAIN' }
            }

            Mock Test-SpecialAccount -MockWith {
                [pscustomobject]@{IsSpecial = $true }
            }

        }
    }

    Context 'Positive Tests' {
        It 'Should process valid user folders and return profile details' {
            InModuleScope -Scriptblock {
                $folders = @(
                    [pscustomobject]@{ ProfilePath = 'C:\Users\TestUser'; FolderName = 'TestUser' },
                    [pscustomobject]@{ ProfilePath = 'C:\Users\AdminUser'; FolderName = 'AdminUser' }
                )
                $result = Get-ProcessedUserProfilesFromFolders -ComputerName 'TestComputer' -UserFolders $folders

                $result | Should -Not -BeNullOrEmpty
                $result[0].UserName | Should -Be 'TestUser'
                $result[0].LastLogonDate | Should -BeOfType 'DateTime'
                $result[0].SID | Should -Be 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                $result[0].IsSpecial | Should -Be $true
            }
        }
    }

    Context 'Negative Tests' {
        It 'Should throw error if UserFolders parameter is missing' {
            InModuleScope -Scriptblock {
                { Get-ProcessedUserProfilesFromFolders -UserFolders $null -ComputerName 'TestComputer' } | Should -Throw
            }
        }

        It 'Should throw empty UserFolders collection gracefully' {
            InModuleScope -Scriptblock {
                $folders = @()
                { Get-ProcessedUserProfilesFromFolders -ComputerName 'TestComputer' -UserFolders $folders } | Should -Throw


            }
        }

        It 'Should handle failure to resolve SID' {
            InModuleScope -Scriptblock {
                Mock Test-SpecialAccount -MockWith {
                    [pscustomobject]@{IsSpecial = $false }
                }

                Mock Resolve-UsernamesToSIDs -MockWith { throw 'Unable to resolve SID' }



                $folders = @([pscustomobject]@{ ProfilePath = 'C:\Users\InvalidUser'; FolderName = 'InvalidUser' })
                $result = Get-ProcessedUserProfilesFromFolders -ComputerName 'TestComputer' -UserFolders $folders

                $result[0].SID | Should -BeNullOrEmpty
                $result[0].IsSpecial | Should -Be $false
            }
        }
    }

    Context 'Edge Case Tests' {

        It 'Should handle missing LastLogon time' {
            InModuleScope -Scriptblock {
                Mock Get-UserProfileLastUseTimeFromDat -MockWith { @() }

                $folders = @([pscustomobject]@{ ProfilePath = 'C:\Users\TestUser'; FolderName = 'TestUser' })
                $result = Get-ProcessedUserProfilesFromFolders -ComputerName 'TestComputer' -UserFolders $folders
                $minValue = [DateTime]::MinValue
                $result[0].LastLogonDate | Should -Be $minValue
            }
        }
    }

    Context 'Exception Handling Tests' {
        It 'Should catch and handle exception from Get-UserAccountFromSID' {
            InModuleScope -Scriptblock {
                Mock Get-UserAccountFromSID -MockWith { throw 'Account not found' }

                $folders = @([pscustomobject]@{ ProfilePath = 'C:\Users\TestUser'; FolderName = 'TestUser' })
                $result = Get-ProcessedUserProfilesFromFolders -ComputerName 'TestComputer' -UserFolders $folders

                $result | Should -Not -BeNullOrEmpty
                $result[0].Domain | Should -BeNullOrEmpty
                $result[0].UserName | Should -BeNullOrEmpty
            }
        }
    }


    Context 'Performance Tests' {
        It 'Should complete within acceptable time' {
            InModuleScope -Scriptblock {
                $folders = @(
                    [pscustomobject]@{ ProfilePath = 'C:\Users\TestUser'; FolderName = 'TestUser' },
                    [pscustomobject]@{ ProfilePath = 'C:\Users\AdminUser'; FolderName = 'AdminUser' }
                )

                $elapsedTime = Measure-Command { Get-ProcessedUserProfilesFromFolders -ComputerName 'TestComputer' -UserFolders $folders }
                $elapsedTime.TotalMilliseconds | Should -BeLessThan 1000
            }
        }
    }
}
