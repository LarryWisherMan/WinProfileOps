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


Describe 'New-DirectoryIfNeeded' -Tags "Private", "Helpers" {
    # Context: When the directory does not exist
    Context 'When the directory does not exist' {
        It 'should create the directory and return the created directory object' {
            InModuleScope -ScriptBlock {
                # Mock Test-Path to return $false (directory does not exist)
                Mock -CommandName Test-Path -MockWith { $false }

                # Mock New-Item to simulate directory creation and return a directory object
                Mock -CommandName New-Item -MockWith {
                    @{
                        PSIsContainer = $true
                        Name          = 'NewDirectory'
                        FullName      = 'C:\Temp\NewDirectory'
                    }
                }

                # Act: Call the function
                $result = New-DirectoryIfNeeded -Directory 'C:\Temp\NewDirectory'

                # Assert: Verify New-Item was called and returned a directory object
                $result.PSIsContainer | Should -Be $true
                $result.FullName | Should -Be 'C:\Temp\NewDirectory'

                # Assert: Ensure Test-Path and New-Item were called
                Assert-MockCalled -CommandName Test-Path -Exactly 1 -Scope It
                Assert-MockCalled -CommandName New-Item -Exactly 1 -Scope It
            }
        }

    }

    # Context: When the directory already exists
    Context 'When the directory already exists' {

        It 'should return true and not create the directory' {
            InModuleScope -ScriptBlock {
                # Mock Test-Path to return $true (directory exists)
                Mock -CommandName Test-Path -MockWith { $true }

                # Mock New-Item to simulate directory creation
                Mock -CommandName New-Item


                # Act: Call the function
                $result = New-DirectoryIfNeeded -Directory 'C:\Temp\ExistingDirectory'

                # Assert: The function should return $true
                $result | Should -Be $true

                # Assert: Ensure New-Item was not called since the directory already exists
                Assert-MockCalled -CommandName New-Item -Exactly 0 -Scope It
            }
        }

    }

    # Context: When an error occurs while creating the directory
    Context 'When an error occurs during directory creation' {

        It 'should return false and display an error' {

            InModuleScope -ScriptBlock {

                # Mock Test-Path to return $false (directory does not exist)
                Mock -CommandName Test-Path -MockWith { $false }

                # Mock New-Item to simulate an error during directory creation
                Mock -CommandName New-Item -MockWith { throw "Unable to create directory" }

                # Mock Write-Error to capture the error message
                Mock -CommandName Write-Error

                # Act: Call the function
                $result = New-DirectoryIfNeeded -Directory 'C:\Temp\NewDirectory'

                # Assert: The function should return $false
                $result | Should -Be $false

                # Assert: Verify Write-Error was called
                Assert-MockCalled -CommandName Write-Error -Exactly 1 -Scope It
            }
        }
    }


    # Context: When a mandatory parameter is missing
    Context 'When the directory parameter is missing' {

        It 'should throw a missing parameter error' {
            InModuleScope -ScriptBlock {
                # Act & Assert: Expect the function to throw a missing parameter error
                { New-DirectoryIfNeeded -Directory $null } | Should -Throw
                { New-DirectoryIfNeeded  -Directory "" } | Should -Throw
            }
        }
    }
}
