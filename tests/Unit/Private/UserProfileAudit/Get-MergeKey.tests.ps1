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

Describe 'Get-MergeKey.tests.ps1 Tests' -Tags "Private", "Unit", "UserProfileAudit" {

}

# Pester Tests for Get-MergeKey function
Describe 'Get-MergeKey Tests' {

    BeforeAll {
        InModuleScope -Scriptblock {
            # Since Get-MergeKey has no external dependencies, no need to mock anything here
        }
    }

    Context 'Positive Tests' {
        It 'Should return a valid composite key for valid SID and ProfilePath' {
            InModuleScope -Scriptblock {
                # Arrange
                $sid = 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                $profilePath = 'C:\Users\John'

                # Act
                $result = Get-MergeKey -SID $sid -ProfilePath $profilePath

                # Assert
                $expected = 'S-1-5-21-1234567890-1234567890-1234567890-1001|C:\Users\John'
                $result | Should -Be $expected
            }
        }

        It 'Should handle valid input with empty ProfilePath' {
            InModuleScope -Scriptblock {
                # Arrange

                $sid = 'S-1-5-21-1234567890-1234567890-1234567890-1002'
                $profilePath = ''

                # Act
                $result = Get-MergeKey -SID $sid -ProfilePath $profilePath

                # Assert
                $expected = 'S-1-5-21-1234567890-1234567890-1234567890-1002|'
                $result | Should -Be $expected
            }
        }

        It 'Should handle valid input with empty SID' {
            InModuleScope -Scriptblock {
                # Arrange
                $sid = ''
                $profilePath = 'C:\Users\Jane'

                # Act
                $result = Get-MergeKey -SID $sid -ProfilePath $profilePath

                # Assert
                $expected = '|C:\Users\Jane'
                $result | Should -Be $expected
            }
        }
    }

    Context 'Negative Tests' {

    }

    Context 'Edge Case Tests' {
        It 'Should return a key with both SID and ProfilePath as empty strings' {
            InModuleScope -Scriptblock {
                # Arrange
                $sid = ''
                $profilePath = ''

                # Act
                $result = Get-MergeKey -SID $sid -ProfilePath $profilePath

                # Assert
                $expected = '|'
                $result | Should -Be $expected
            }
        }

        It 'Should handle long SID and ProfilePath values without error' {
            InModuleScope -Scriptblock {
                # Arrange
                $sid = ('S-1-5-' + ('1234567890' * 5))
                $profilePath = ('C:\Users\' + ('User' * 50))

                # Act
                $result = Get-MergeKey -SID $sid -ProfilePath $profilePath

                # Assert
                $expected = "$sid|$profilePath"
                $result | Should -Be $expected
            }
        }
    }

    Context 'Performance Tests' {
        It 'Should return a result within acceptable time' {
            InModuleScope -Scriptblock {
                # Arrange
                $sid = 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                $profilePath = 'C:\Users\Test'
                # Act & Assert
                $elapsedTime = Measure-Command { Get-MergeKey -SID $sid -ProfilePath $profilePath }
                $elapsedTime.TotalMilliseconds | Should -BeLessThan 100
            }
        }
    }

    Context 'Cleanup Tests' {

    }
}
