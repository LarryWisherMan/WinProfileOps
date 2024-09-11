BeforeAll {
    $script:dscModuleName = "WinProfileOps"

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName

    # Mock Test-ComputerPing to return true (computer is online)
    Mock Test-ComputerPing {
        return $true
    }

}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Get-UserProfilesFromFolders' -Tags 'Unit', 'Public' {

    # Test for profiles from the local computer
    Context 'When retrieving profiles from the local computer' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock Get-UserFolders to return a list of user folders
                Mock Get-UserFolders {
                    return @(
                        [PSCustomObject]@{ FolderName = 'User1'; ProfilePath = 'C:\Users\User1'; ComputerName = $env:COMPUTERNAME },
                        [PSCustomObject]@{ FolderName = 'User2'; ProfilePath = 'C:\Users\User2'; ComputerName = $env:COMPUTERNAME }
                    )
                }
            }
        }

        It 'Should return user profile folders from the local computer' {
            $ComputerName = $env:COMPUTERNAME

            $result = Get-UserProfilesFromFolders -ComputerName $ComputerName

            # Validate result
            $result | Should -HaveCount 2
            $result[0].FolderName | Should -Be 'User1'
            $result[0].ProfilePath | Should -Be 'C:\Users\User1'
            $result[1].FolderName | Should -Be 'User2'
            $result[1].ProfilePath | Should -Be 'C:\Users\User2'

            # Assert that Test-ComputerPing and Get-UserFolders were called
            Assert-MockCalled Test-ComputerPing -Exactly 1
            Assert-MockCalled Get-UserFolders -Exactly 1
        }
    }

    # Test for profiles from a remote computer
    Context 'When retrieving profiles from a remote computer' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock Get-UserFolders to return a list of user folders
                Mock Get-UserFolders {
                    return @(
                        [PSCustomObject]@{ FolderName = 'User1'; ProfilePath = '\\RemotePC\Users\User1'; ComputerName = 'RemotePC' },
                        [PSCustomObject]@{ FolderName = 'User2'; ProfilePath = '\\RemotePC\Users\User2'; ComputerName = 'RemotePC' }
                    )
                }
            }
        }

        It 'Should return user profile folders from the remote computer' {
            $ComputerName = 'RemotePC'

            $result = Get-UserProfilesFromFolders -ComputerName $ComputerName

            # Validate result
            $result | Should -HaveCount 2
            $result[0].FolderName | Should -Be 'User1'
            $result[0].ProfilePath | Should -Be '\\RemotePC\Users\User1'
            $result[1].FolderName | Should -Be 'User2'
            $result[1].ProfilePath | Should -Be '\\RemotePC\Users\User2'

            # Assert that Test-ComputerPing and Get-UserFolders were called
            Assert-MockCalled Test-ComputerPing -Exactly 1
            Assert-MockCalled Get-UserFolders -Exactly 1
        }
    }

    # Test when the computer is unreachable
    Context 'When the computer is offline or unreachable' {
        BeforeEach {
            # Mock Test-ComputerPing to return false (computer is offline)
            Mock Test-ComputerPing {
                return $false
            }

            mock -ModuleName $script:dscModuleName Get-UserFolders

            # Mock Write-Warning to capture the warning
            Mock Write-Warning
        }

        It 'Should log a warning and return an empty result when the computer is offline' {
            $ComputerName = 'RemotePC'

            $result = Get-UserProfilesFromFolders -ComputerName $ComputerName

            # The result should be empty
            $result | Should -BeNullOrEmpty

            # Assert that Test-ComputerPing and Write-Warning were called
            Assert-MockCalled Test-ComputerPing -Exactly 1
            Assert-MockCalled Write-Warning -Exactly 1
            Assert-MockCalled Get-UserFolders -Exactly 0  # Get-UserFolders should not be called
        }
    }

    # Test when Get-UserFolders fails
    Context 'When Get-UserFolders fails' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock Get-UserFolders to throw an error
                Mock Get-UserFolders {
                    throw "Failed to retrieve folders"
                }
            }

            # Mock Write-Error to capture the error
            Mock Write-Error
        }

        It 'Should log an error and return nothing when Get-UserFolders fails' {
            $ComputerName = 'RemotePC'

            $result = Get-UserProfilesFromFolders -ComputerName $ComputerName

            # The result should be empty
            $result | Should -BeNullOrEmpty

            # Assert that Test-ComputerPing and Write-Error were called
            Assert-MockCalled Test-ComputerPing -Exactly 1
            Assert-MockCalled Write-Error -Exactly 1
            Assert-MockCalled Get-UserFolders -Exactly 1
        }
    }

    # Test when no user folders are found
    Context 'When no user folders are found' {
        BeforeEach {

            InModuleScope -ScriptBlock {
                # Mock Get-UserFolders to return an empty list
                Mock Get-UserFolders {
                    return @()
                }
            }
        }

        It 'Should return an empty result when no user folders are found' {
            $ComputerName = $env:COMPUTERNAME

            $result = Get-UserProfilesFromFolders -ComputerName $ComputerName

            # The result should be empty
            $result | Should -BeNullOrEmpty

            # Assert that Test-ComputerPing and Get-UserFolders were called
            Assert-MockCalled Test-ComputerPing -Exactly 1
            Assert-MockCalled Get-UserFolders -Exactly 1
        }
    }
}
