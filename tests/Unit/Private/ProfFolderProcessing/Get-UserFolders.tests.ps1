BeforeAll {
    $script:dscModuleName = "WinProfileOps"

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName

    Mock Get-DirectoryPath {
        if ($IsLocal)
        {
            # Convert UNC to local format
            $localPath = $BasePath -replace '(?:.+)\\([a-zA-Z])\$\\', '$1:\'
            return $localPath
        }
        else
        {
            # Convert local path to UNC format
            $uncPath = $BasePath -replace '^([a-zA-Z]):\\', "\\$ComputerName\`$1`$\"
            return $uncPath
        }
    }
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Get-UserFolders' -Tags "Private", "Unit", "ProfFolderProcessing" {

    # Test for local computer
    Context 'When running on the local computer' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock Get-ChildItem to return a list of folders
                Mock Get-ChildItem {
                    param ($Path, $Directory)
                    return @(
                        [PSCustomObject]@{ Name = 'User1'; FullName = 'C:\Users\User1' },
                        [PSCustomObject]@{ Name = 'User2'; FullName = 'C:\Users\User2' }
                    )
                }
            }
        }

        It 'Should return folder information for all user profiles on the local computer' {
            InModuleScope -ScriptBlock {
                $ComputerName = $env:COMPUTERNAME

                $result = Get-UserFolders -ComputerName $ComputerName

                $result | Should -HaveCount 2
                $result[0].FolderName | Should -Be 'User1'
                $result[0].ProfilePath | Should -Be 'C:\Users\User1'
                $result[0].ComputerName | Should -Be $ComputerName
                $result[1].FolderName | Should -Be 'User2'
                $result[1].ProfilePath | Should -Be 'C:\Users\User2'
                $result[1].ComputerName | Should -Be $ComputerName

                Assert-MockCalled Get-DirectoryPath -Exactly 3  # Once for basepath and twice for folder paths
                Assert-MockCalled Get-ChildItem -Exactly 1
            }
        }
    }

    # Test for remote computer
    Context 'When running on a remote computer' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock Get-ChildItem to return a list of folders for a remote path
                Mock Get-ChildItem {
                    param ($Path, $Directory)
                    return @(
                        [PSCustomObject]@{ Name = 'User1'; FullName = '\\RemotePC\C$\Users\User1' },
                        [PSCustomObject]@{ Name = 'User2'; FullName = '\\RemotePC\C$\Users\User2' }
                    )
                }
            }
        }

        It 'Should return folder information for all user profiles on a remote computer' {
            InModuleScope -ScriptBlock {
                $ComputerName = 'RemotePC'

                $result = Get-UserFolders -ComputerName $ComputerName

                $result | Should -HaveCount 2
                $result[0].FolderName | Should -Be 'User1'
                $result[0].ProfilePath | Should -Be 'C:\Users\User1'
                $result[0].ComputerName | Should -Be $ComputerName
                $result[1].FolderName | Should -Be 'User2'
                $result[1].ProfilePath | Should -Be 'C:\Users\User2'
                $result[1].ComputerName | Should -Be $ComputerName

                Assert-MockCalled Get-DirectoryPath -Exactly 3  # Once for basepath and twice for folder paths
                Assert-MockCalled Get-ChildItem -Exactly 1
            }
        }
    }

    # Test for empty profile directory
    Context 'When no folders are found in the profile directory' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock Get-ChildItem to return an empty list
                Mock Get-ChildItem {
                    param ($Path, $Directory)
                    return @()
                }
            }
        }

        It 'Should return an empty result when no profile folders are found' {
            InModuleScope -ScriptBlock {
                $ComputerName = $env:COMPUTERNAME

                $result = Get-UserFolders -ComputerName $ComputerName

                # The result should be empty
                $result | Should -BeNullOrEmpty

                Assert-MockCalled Get-DirectoryPath -Exactly 1
                Assert-MockCalled Get-ChildItem -Exactly 1
            }
        }
    }

    # Test when Get-ChildItem fails
    Context 'When Get-ChildItem fails' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                # Mock Get-ChildItem to simulate a failure
                Mock Get-ChildItem {
                    throw "Access denied"
                }

                # Mock Write-Error to capture the error
                Mock Write-Error
            }
        }

        It 'Should log an error and return an empty result' {
            InModuleScope -ScriptBlock {
                $ComputerName = $env:COMPUTERNAME

                $result = Get-UserFolders -ComputerName $ComputerName

                # The result should be empty
                $result | Should -BeNullOrEmpty

                # Ensure Write-Error was called
                Assert-MockCalled Write-Error -Exactly 1
                Assert-MockCalled Get-ChildItem -Exactly 1
            }
        }
    }

    Context 'When the profile folder path does not exist' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Mock Get-DirectoryPath { 'C:\InvalidPath\Users' }
                Mock Get-ChildItem { throw "Path does not exist" }
                Mock Write-Error
            }
        }

        It 'Should log an error and return an empty result' {
            InModuleScope -ScriptBlock {
                $ComputerName = $env:COMPUTERNAME
                $result = Get-UserFolders -ComputerName $ComputerName

                $result | Should -BeNullOrEmpty
                Assert-MockCalled Write-Error -Exactly 1
            }
        }
    }

    Context 'When the profile directory is empty' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Mock Get-ChildItem { return @() }  # Simulate an empty folder
            }
        }

        It 'Should return an empty result when no folders are found' {
            InModuleScope -ScriptBlock {
                $ComputerName = $env:COMPUTERNAME
                $result = Get-UserFolders -ComputerName $ComputerName

                $result | Should -BeNullOrEmpty
                Assert-MockCalled Get-ChildItem -Exactly 1
            }
        }
    }

    Context 'When a custom profile folder path is provided' {
        BeforeEach {
            InModuleScope -ScriptBlock {
                Mock Get-ChildItem {
                    param ($Path, $Directory)
                    return @(
                        [PSCustomObject]@{ Name = 'CustomUser'; FullName = 'D:\CustomProfiles\CustomUser' }
                    )
                }
            }
        }

        It 'Should return user folders from the custom path' {
            InModuleScope -ScriptBlock {
                $ComputerName = $env:COMPUTERNAME
                $ProfileFolderPath = 'D:\CustomProfiles'

                $result = Get-UserFolders -ComputerName $ComputerName -ProfileFolderPath $ProfileFolderPath

                $result | Should -HaveCount 1
                $result[0].FolderName | Should -Be 'CustomUser'
                $result[0].ProfilePath | Should -Be 'D:\CustomProfiles\CustomUser'
            }
        }
    }

}
