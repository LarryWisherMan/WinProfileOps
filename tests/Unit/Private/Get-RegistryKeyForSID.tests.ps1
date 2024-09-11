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

Describe "Get-RegistryKeyForSID" -Tag 'Private' {

    Context "When the SID registry key exists" {

        It "Should return the correct SID registry key" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profileListKey = New-MockObject -type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = "ProfileList" }
                $sidKey = New-MockObject -type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = $sid }

                Mock Open-RegistrySubKey {
                    return $sidKey
                }

                # Act
                $result = Get-RegistryKeyForSID -SID $sid -ProfileListKey $profileListKey

                # Assert
                $result | Should -Be $sidKey
                Assert-MockCalled Open-RegistrySubKey -Exactly 1 -Scope It
            }
        }
    }

    Context "When the SID registry key does not exist" {

        It "Should return $null and write a warning" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profileListKey = New-MockObject -type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = "ProfileList" }

                Mock Open-RegistrySubKey {
                    return $null
                }

                Mock Write-Warning

                # Act
                $result = Get-RegistryKeyForSID -SID $sid -ProfileListKey $profileListKey

                # Assert
                $result | Should -Be $null
                Assert-MockCalled Open-RegistrySubKey -Exactly 1 -Scope It
                Assert-MockCalled Write-Warning -Exactly 1 -Scope It
            }
        }
    }

    Context "When an error occurs while accessing the SID registry key" {

        It "Should return $null and write an error" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profileListKey = New-MockObject -type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = "ProfileList" }

                Mock Open-RegistrySubKey { throw "Registry access error" }

                Mock Write-Error

                # Act
                $result = Get-RegistryKeyForSID -SID $sid -ProfileListKey $profileListKey

                # Assert
                $result | Should -Be $null
                Assert-MockCalled Open-RegistrySubKey -Exactly 1 -Scope It
                Assert-MockCalled Write-Error -Exactly 1 -Scope It
            }
        }
    }
}
