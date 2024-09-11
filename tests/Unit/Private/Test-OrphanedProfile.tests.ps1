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

# Import the module if necessary
# Import-Module YourModule

Describe "Test-OrphanedProfile" -Tag 'Private' {

    Context "When ProfilePath is null" {
        It "Should return a profile object with IsOrphaned set to true and reason 'MissingProfileImagePath'" {

            InModuleScope -ScriptBlock {

                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = $null
                $folderExists = $true
                $ignoreSpecial = $false
                $isSpecial = $false
                $computerName = "Server01"

                # Act
                $result = Test-OrphanedProfile -SID $sid -ProfilePath $profilePath -FolderExists $folderExists `
                    -IgnoreSpecial $ignoreSpecial -IsSpecial $isSpecial -ComputerName $computerName

                # Assert
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -BeNullOrEmpty
                $result.IsOrphaned | Should -Be $true
                $result.OrphanReason | Should -Be "MissingProfileImagePath"
                $result.ComputerName | Should -Be $computerName

            }
        }
    }

    Context "When Profile folder does not exist" {
        It "Should return a profile object with IsOrphaned set to true and reason 'MissingFolder'" {

            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"
                $folderExists = $false
                $ignoreSpecial = $false
                $isSpecial = $false
                $computerName = "Server01"

                # Act
                $result = Test-OrphanedProfile -SID $sid -ProfilePath $profilePath -FolderExists $folderExists `
                    -IgnoreSpecial $ignoreSpecial -IsSpecial $isSpecial -ComputerName $computerName

                # Assert
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -Be $profilePath
                $result.IsOrphaned | Should -Be $true
                $result.OrphanReason | Should -Be "MissingFolder"
                $result.ComputerName | Should -Be $computerName
            }
        }
    }

    Context "When Profile folder exists and profile is not orphaned" {
        It "Should return a profile object with IsOrphaned set to false" {

            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"
                $folderExists = $true
                $ignoreSpecial = $false
                $isSpecial = $false
                $computerName = "Server01"

                # Act
                $result = Test-OrphanedProfile -SID $sid -ProfilePath $profilePath -FolderExists $folderExists `
                    -IgnoreSpecial $ignoreSpecial -IsSpecial $isSpecial -ComputerName $computerName

                # Assert
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -Be $profilePath
                $result.IsOrphaned | Should -Be $false
                $result.OrphanReason | Should -BeNullOrEmpty
                $result.ComputerName | Should -Be $computerName
            }
        }
    }

    Context "When Profile is a special account and IgnoreSpecial is set" {
        It "Should return a profile object with IsOrphaned set to false" {

            InModuleScope -ScriptBlock {

                # Arrange
                $sid = "S-1-5-18"  # Local System SID
                $profilePath = "C:\Users\SystemProfile"
                $folderExists = $true
                $ignoreSpecial = $true
                $isSpecial = $true
                $computerName = "Server01"

                # Act
                $result = Test-OrphanedProfile -SID $sid -ProfilePath $profilePath -FolderExists $folderExists `
                    -IgnoreSpecial $ignoreSpecial -IsSpecial $isSpecial -ComputerName $computerName

                # Assert
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -Be $profilePath
                $result.IsOrphaned | Should -Be $false
                $result.OrphanReason | Should -BeNullOrEmpty
                $result.ComputerName | Should -Be $computerName

            }
        }
    }

    Context "When Profile is a special account and IgnoreSpecial is not set" {
        It "Should return a profile object with IsOrphaned set to false but IsSpecial should be true" {

            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-18"  # Local System SID
                $profilePath = "C:\Users\SystemProfile"
                $folderExists = $true
                $ignoreSpecial = $false
                $isSpecial = $true
                $computerName = "Server01"

                # Act
                $result = Test-OrphanedProfile -SID $sid -ProfilePath $profilePath -FolderExists $folderExists `
                    -IgnoreSpecial $ignoreSpecial -IsSpecial $isSpecial -ComputerName $computerName

                # Assert
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -Be $profilePath
                $result.IsOrphaned | Should -Be $false
                $result.OrphanReason | Should -BeNullOrEmpty
                $result.IsSpecial | Should -Be $true
                $result.ComputerName | Should -Be $computerName
            }
        }
    }
}
