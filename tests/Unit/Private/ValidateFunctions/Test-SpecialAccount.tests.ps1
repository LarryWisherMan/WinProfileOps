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

Describe "Test-SpecialAccount" -Tag 'Private' {

    Context "When Testing Special Folder Names" {

        It "Should return $true for a special folder name" {
            InModuleScope -ScriptBlock {
                # Arrange
                $folderName = "defaultuser0"
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"

                # Act
                $result = Test-SpecialAccount -FolderName $folderName -SID $sid -ProfilePath $profilePath

                # Assert
                $result | Should -BeTrue
            }
        }

        It "Should return $false for a non-special folder name" {
            InModuleScope -ScriptBlock {
                # Arrange
                $folderName = "John"
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"

                # Act
                $result = Test-SpecialAccount -FolderName $folderName -SID $sid -ProfilePath $profilePath

                # Assert
                $result | Should -BeFalse
            }
        }
    }

    Context "When Testing Special SIDs" {

        It "Should return $true for a special SID" {
            InModuleScope -ScriptBlock {
                # Arrange
                $folderName = "John"
                $sid = "S-1-5-18" # Local System SID
                $profilePath = "C:\Users\John"

                # Act
                $result = Test-SpecialAccount -FolderName $folderName -SID $sid -ProfilePath $profilePath

                # Assert
                $result | Should -BeTrue
            }
        }

        It "Should return $false for a non-special SID" {
            InModuleScope -ScriptBlock {
                # Arrange
                $folderName = "John"
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"

                # Act
                $result = Test-SpecialAccount -FolderName $folderName -SID $sid -ProfilePath $profilePath

                # Assert
                $result | Should -BeFalse
            }
        }
    }

    Context "When Testing Special Profile Paths" {

        It "Should return $true for a special profile path" {
            InModuleScope -ScriptBlock {
                # Arrange
                $folderName = "John"
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\WINDOWS\system32\config\systemprofile"

                # Act
                $result = Test-SpecialAccount -FolderName $folderName -SID $sid -ProfilePath $profilePath

                # Assert
                $result | Should -BeTrue
            }
        }

        It "Should return $false for a non-special profile path" {
            InModuleScope -ScriptBlock {
                # Arrange
                $folderName = "John"
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"

                # Act
                $result = Test-SpecialAccount -FolderName $folderName -SID $sid -ProfilePath $profilePath

                # Assert
                $result | Should -BeFalse
            }
        }
    }

    Context "When Testing Combined Conditions" {

        It "Should return $true if any condition (folder name, SID, or profile path) is special" {
            InModuleScope -ScriptBlock {
                # Arrange
                $folderName = "John"
                $sid = "S-1-5-19"  # Local Service SID (special)
                $profilePath = "C:\Users\John"

                # Act
                $result = Test-SpecialAccount -FolderName $folderName -SID $sid -ProfilePath $profilePath

                # Assert
                $result | Should -BeTrue
            }
        }

        It "Should return $false if none of the conditions are special" {
            InModuleScope -ScriptBlock {
                # Arrange
                $folderName = "John"
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"

                # Act
                $result = Test-SpecialAccount -FolderName $folderName -SID $sid -ProfilePath $profilePath

                # Assert
                $result | Should -BeFalse
            }
        }
    }
}
