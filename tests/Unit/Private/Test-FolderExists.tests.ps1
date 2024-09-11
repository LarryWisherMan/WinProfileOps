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

Describe "Test-FolderExists" -Tag "Private" {

    Context "Folder Existence Tests" {

        Context "When Testing Local Folders" {

            It "Should return `$true for an existing local folder" {
                InModuleScope -ScriptBlock {
                    Mock Get-DirectoryPath { return "C:\Users" }
                    Mock Test-Path { return $true }

                    $profilePath = "C:\Users\Public"
                    $computerName = $env:COMPUTERNAME

                    $result = Test-FolderExists -ProfilePath $profilePath -ComputerName $computerName

                    $result | Should -BeTrue
                    Assert-MockCalled Get-DirectoryPath -Exactly 1 -Scope It
                    Assert-MockCalled Test-Path -Exactly 1 -Scope It
                }
            }

            It "Should return `$false for a non-existent local folder" {
                InModuleScope -ScriptBlock {
                    Mock Get-DirectoryPath { return "C:\InvalidFolder" }
                    Mock Test-Path { return $false }

                    $profilePath = "C:\InvalidFolder"
                    $computerName = $env:COMPUTERNAME

                    $result = Test-FolderExists -ProfilePath $profilePath -ComputerName $computerName

                    $result | Should -BeFalse
                    Assert-MockCalled Get-DirectoryPath -Exactly 1 -Scope It
                    Assert-MockCalled Test-Path -Exactly 1 -Scope It
                }
            }
        }

        Context "When Testing Remote Folders" {

            It "Should return `$true for an existing remote folder" {
                InModuleScope -ScriptBlock {
                    Mock Get-DirectoryPath { return "\\RemotePC\Users" }
                    Mock Test-Path { return $true }

                    $profilePath = "\\RemotePC\Users\John"
                    $computerName = "RemotePC"

                    $result = Test-FolderExists -ProfilePath $profilePath -ComputerName $computerName

                    $result | Should -BeTrue
                    Assert-MockCalled Get-DirectoryPath -Exactly 1 -Scope It
                    Assert-MockCalled Test-Path -Exactly 1 -Scope It
                }
            }

            It "Should return `$false for a non-existent remote folder" {
                InModuleScope -ScriptBlock {
                    Mock Get-DirectoryPath { return "\\RemotePC\InvalidFolder" }
                    Mock Test-Path { return $false }

                    $profilePath = "\\RemotePC\InvalidFolder"
                    $computerName = "RemotePC"

                    $result = Test-FolderExists -ProfilePath $profilePath -ComputerName $computerName

                    $result | Should -BeFalse
                    Assert-MockCalled Get-DirectoryPath -Exactly 1 -Scope It
                    Assert-MockCalled Test-Path -Exactly 1 -Scope It
                }
            }
        }
    }

    Context "Computer Identification Tests" {

        It "Should correctly identify the local computer" {
            InModuleScope -ScriptBlock {
                Mock Get-DirectoryPath { return "C:\Users" }
                Mock Test-Path { return $true }

                $profilePath = "C:\Users\John"
                $computerName = $env:COMPUTERNAME

                $result = Test-FolderExists -ProfilePath $profilePath -ComputerName $computerName

                Assert-MockCalled Get-DirectoryPath -ParameterFilter { $IsLocal -eq $true } -Exactly 1
            }
        }

        It "Should correctly identify a remote computer" {
            InModuleScope -ScriptBlock {
                Mock Get-DirectoryPath -ParameterFilter { $IsLocal -eq $false } { return "\\RemotePC\Users" }
                Mock Test-Path { return $true }

                $profilePath = "\\RemotePC\Users\John"
                $computerName = "RemotePC"

                $result = Test-FolderExists -ProfilePath $profilePath -ComputerName $computerName

                Assert-MockCalled Get-DirectoryPath -ParameterFilter { $IsLocal -eq $false } -Exactly 1
            }
        }
    }

    Context "Input Validation Tests" {

        It "Should return `$false and log a warning when ProfilePath is `$null" {
            InModuleScope -ScriptBlock {
                Mock Get-DirectoryPath
                Mock Test-Path

                $profilePath = $null
                $computerName = $env:COMPUTERNAME

                $result = Test-FolderExists -ProfilePath $profilePath -ComputerName $computerName

                $result | Should -BeFalse
                Assert-MockCalled Get-DirectoryPath -Exactly 0
                Assert-MockCalled Test-Path -Exactly 0
            }
        }

        It "Should return `$false and log a warning when ProfilePath is an empty string" {
            InModuleScope -ScriptBlock {
                Mock Get-DirectoryPath
                Mock Test-Path

                $profilePath = ""
                $computerName = $env:COMPUTERNAME

                $result = Test-FolderExists -ProfilePath $profilePath -ComputerName $computerName

                $result | Should -BeFalse
                Assert-MockCalled Get-DirectoryPath -Exactly 0
                Assert-MockCalled Test-Path -Exactly 0
            }
        }

        It "Should default to the local computer when ComputerName is `$null" {
            InModuleScope -ScriptBlock {
                Mock Get-DirectoryPath { return "C:\Users" }
                Mock Test-Path { return $true }

                $profilePath = "C:\Users\John"
                $computerName = $null

                $result = Test-FolderExists -ProfilePath $profilePath -ComputerName $computerName

                $result | Should -BeTrue
                Assert-MockCalled Get-DirectoryPath -ParameterFilter { $ComputerName -eq $env:COMPUTERNAME } -Exactly 1
            }
        }

        It "Should default to the local computer when ComputerName is an empty string" {
            InModuleScope -ScriptBlock {
                Mock Get-DirectoryPath { return "C:\Users" }
                Mock Test-Path { return $true }

                $profilePath = "C:\Users\John"
                $computerName = ""

                $result = Test-FolderExists -ProfilePath $profilePath -ComputerName $computerName

                $result | Should -BeTrue
                Assert-MockCalled Get-DirectoryPath -ParameterFilter { $ComputerName -eq $env:COMPUTERNAME } -Exactly 1
            }
        }
    }

    Context "Error Handling Tests" {

        It "Should return `$false if Get-DirectoryPath throws an error" {
            InModuleScope -ScriptBlock {
                Mock Get-DirectoryPath { throw "Path resolution failed" }

                $profilePath = "C:\Users\John"
                $computerName = $env:COMPUTERNAME

                # Act and Assert
                $result = Test-FolderExists -ProfilePath $profilePath -ComputerName $computerName -ErrorAction Continue
                $result | Should -BeFalse

                Assert-MockCalled Get-DirectoryPath -Exactly 1
            }
        }

        It "Should return `$false if Test-Path throws an error" {
            InModuleScope -ScriptBlock {
                Mock Get-DirectoryPath { return "C:\Users" }
                Mock Test-Path { throw "Test-Path failed" }

                $profilePath = "C:\Users\John"
                $computerName = $env:COMPUTERNAME

                # Act and Assert
                $result = Test-FolderExists -ProfilePath $profilePath -ComputerName $computerName -ErrorAction Continue
                $result | Should -BeFalse

                Assert-MockCalled Get-DirectoryPath -Exactly 1
                Assert-MockCalled Test-Path -Exactly 1
            }
        }
    }
}
