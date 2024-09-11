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

Describe "Remove-RegistryKeyForSID" -Tag 'Private' {

    Context "When the SID registry key is successfully removed" {

        It "Should delete the registry key when confirmed" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = "ProfileList" }
                $computerName = "Server01"

                Mock Remove-RegistrySubKey {
                    return $true
                }

                # Act
                $result = Remove-RegistryKeyForSID -SID $sid -ProfileListKey $profileListKey -ComputerName $computerName -Confirm:$false

                # Assert
                $result | Should -Be $true
                Assert-MockCalled Remove-RegistrySubKey -Exactly 1 -Scope It -ParameterFilter {
                    $ParentKey -eq $profileListKey -and $SubKeyName -eq $sid -and $ComputerName -eq $computerName
                }
            }
        }
    }

    Context "When using -WhatIf parameter" {

        It "Should simulate deletion and not call Remove-RegistrySubKey" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = "ProfileList" }
                $computerName = "Server01"

                Mock Remove-RegistrySubKey

                # Act
                Remove-RegistryKeyForSID -SID $sid -ProfileListKey $profileListKey -ComputerName $computerName -WhatIf

                # Assert
                Assert-MockCalled Remove-RegistrySubKey -Exactly 0 -Scope It
            }
        }
    }

    Context "When an error occurs while deleting the registry key" {

        It "Should return $false and log an error" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = "ProfileList" }
                $computerName = "Server01"

                Mock Remove-RegistrySubKey { throw "Registry access error" }

                Mock Write-Error

                # Act
                $result = Remove-RegistryKeyForSID -SID $sid -ProfileListKey $profileListKey -ComputerName $computerName -Confirm:$false

                # Assert
                $result | Should -Be $false
                Assert-MockCalled Remove-RegistrySubKey -Exactly 1 -Scope It
                Assert-MockCalled Write-Error -Exactly 1 -Scope It
            }
        }
    }

    Context "When SID does not exist in the registry" {

        It "Should return $false if the registry key is not found" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = "ProfileList" }
                $computerName = "Server01"

                Mock Remove-RegistrySubKey { return $false }

                # Act
                $result = Remove-RegistryKeyForSID -SID $sid -ProfileListKey $profileListKey -ComputerName $computerName -Confirm:$false

                # Assert
                $result | Should -Be $false
                Assert-MockCalled Remove-RegistrySubKey -Exactly 1 -Scope It
            }
        }
    }
}
