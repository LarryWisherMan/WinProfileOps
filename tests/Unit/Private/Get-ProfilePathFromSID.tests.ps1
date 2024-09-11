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

Describe "Get-ProfilePathFromSID" -Tag 'Private' {

    Context "When the ProfileImagePath exists" {

        It "Should return the correct ProfileImagePath" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sidKey = New-MockObject -type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = 'S-1-5-21-123456789-1001' }

                Mock Get-RegistryValue {
                    return "C:\Users\John"
                }

                # Act
                $result = Get-ProfilePathFromSID -SidKey $sidKey

                # Assert
                $result | Should -Be "C:\Users\John"
                Assert-MockCalled Get-RegistryValue -Exactly 1 -Scope It
            }
        }
    }

    Context "When the ProfileImagePath does not exist" {

        It "Should return $null and write a verbose message" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sidKey = New-MockObject -type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = 'S-1-5-21-123456789-1001' }

                Mock Get-RegistryValue {
                    return $null
                }

                Mock Write-Verbose

                # Act
                $result = Get-ProfilePathFromSID -SidKey $sidKey

                # Assert
                $result | Should -Be $null
                Assert-MockCalled Get-RegistryValue -Exactly 1 -Scope It
                Assert-MockCalled Write-Verbose -Exactly 1 -Scope It
            }
        }
    }

    Context "When an error occurs while retrieving ProfileImagePath" {

        It "Should return $null and write an error message" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sidKey = New-MockObject -type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = 'S-1-5-21-123456789-1001' }

                Mock Get-RegistryValue { throw "Registry access error" }

                Mock Write-Error

                # Act
                $result = Get-ProfilePathFromSID -SidKey $sidKey

                # Assert
                $result | Should -Be $null
                Assert-MockCalled Get-RegistryValue -Exactly 1 -Scope It
                Assert-MockCalled Write-Error -Exactly 1 -Scope It
            }
        }
    }
}
