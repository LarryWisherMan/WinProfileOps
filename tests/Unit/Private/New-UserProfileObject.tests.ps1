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

Describe "New-UserProfileObject" -Tag 'Private' {

    Context "When creating a new UserProfile object" {

        It "Should return a valid UserProfile object with all properties set" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"
                $isOrphaned = $true
                $orphanReason = "MissingRegistryEntry"
                $computerName = "Server01"
                $isSpecial = $false

                # Act
                $result = New-UserProfileObject -SID $sid -ProfilePath $profilePath -IsOrphaned $isOrphaned -OrphanReason $orphanReason -ComputerName $computerName -IsSpecial $isSpecial

                # Assert
                $result.GetType().name | Should -Be 'UserProfile'
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -Be $profilePath
                $result.IsOrphaned | Should -Be $isOrphaned
                $result.OrphanReason | Should -Be $orphanReason
                $result.ComputerName | Should -Be $computerName
                $result.IsSpecial | Should -Be $isSpecial
            }
        }

        It "Should return a UserProfile object with a null OrphanReason if not provided" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"
                $isOrphaned = $false
                $computerName = "Server01"
                $isSpecial = $false

                # Act
                $result = New-UserProfileObject -SID $sid -ProfilePath $profilePath -IsOrphaned $isOrphaned -ComputerName $computerName -IsSpecial $isSpecial

                # Assert
                $result.GetType().name  | Should -Be 'UserProfile'
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -Be $profilePath
                $result.IsOrphaned | Should -Be $isOrphaned
                $result.OrphanReason | Should -BeNullOrEmpty
                $result.ComputerName | Should -Be $computerName
                $result.IsSpecial | Should -Be $isSpecial
            }
        }

        It "Should handle special accounts properly" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-18"  # Local system SID
                $profilePath = "C:\WINDOWS\system32\config\systemprofile"
                $isOrphaned = $false
                $computerName = "Server01"
                $isSpecial = $true

                # Act
                $result = New-UserProfileObject -SID $sid -ProfilePath $profilePath -IsOrphaned $isOrphaned -ComputerName $computerName -IsSpecial $isSpecial

                # Assert
                $result.GetType().name  | Should -Be 'UserProfile'
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -Be $profilePath
                $result.IsOrphaned | Should -Be $isOrphaned
                $result.OrphanReason | Should -BeNullOrEmpty
                $result.ComputerName | Should -Be $computerName
                $result.IsSpecial | Should -Be $isSpecial
            }
        }
    }
}
