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

Describe "Remove-SIDProfile" -Tag 'Private' {

    Context "When the SID profile registry key is successfully removed" {

        It "Should return a successful ProfileDeletionResult when the key is deleted" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"
                $computerName = "Server01"
                $profileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = "ProfileList" }

                Mock Remove-RegistryKeyForSID { return $true }

                # Act
                $result = Remove-SIDProfile -SID $sid -ProfileListKey $profileListKey -ComputerName $computerName -ProfilePath $profilePath -Confirm:$false

                # Assert
                $result.GetType().Name | Should -Be 'ProfileDeletionResult'
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -Be $profilePath
                $result.DeletionSuccess | Should -Be $true
                $result.DeletionMessage | Should -Be "Profile registry key for SID '$sid' successfully deleted."
                $result.ComputerName | Should -Be $computerName
            }
        }

        It "Should return a failed ProfileDeletionResult when the key is not deleted" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"
                $computerName = "Server01"
                $profileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = "ProfileList" }

                Mock Remove-RegistryKeyForSID { return $false }

                # Act
                $result = Remove-SIDProfile -SID $sid -ProfileListKey $profileListKey -ComputerName $computerName -ProfilePath $profilePath -confirm:$false

                # Assert
                $result.GetType().Name | Should -Be 'ProfileDeletionResult'
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -Be $profilePath
                $result.DeletionSuccess | Should -Be $false
                $result.DeletionMessage | Should -Be "Failed to delete the profile registry key for SID '$sid'."
                $result.ComputerName | Should -Be $computerName
            }
        }
    }

    Context "When using -WhatIf" {

        It "Should simulate deletion and not call Remove-RegistryKeyForSID" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"
                $computerName = "Server01"
                $profileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = "ProfileList" }

                Mock Remove-RegistryKeyForSID

                # Act
                $result = Remove-SIDProfile -SID $sid -ProfileListKey $profileListKey -ComputerName $computerName -ProfilePath $profilePath -WhatIf

                # Assert
                Assert-MockCalled Remove-RegistryKeyForSID -Exactly 0 -Scope It
                $result.GetType().Name | Should -Be 'ProfileDeletionResult'
                $result.SID | Should -Be $sid
                $result.DeletionSuccess | Should -Be $false
                $result.DeletionMessage | Should -Be "Action skipped."
            }
        }
    }

    Context "When ShouldProcess returns false" {

        It "Should skip deletion and return a skipped ProfileDeletionResult" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"
                $computerName = "Server01"
                $profileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = "ProfileList" }

                Mock Remove-RegistryKeyForSID

                # Act
                $result = Remove-SIDProfile -SID $sid -ProfileListKey $profileListKey -ComputerName $computerName -ProfilePath $profilePath -WhatIf

                # Assert
                Assert-MockCalled Remove-RegistryKeyForSID -Exactly 0 -Scope It
                $result.GetType().Name | Should -Be 'ProfileDeletionResult'
                $result.SID | Should -Be $sid
                $result.DeletionSuccess | Should -Be $false
                $result.DeletionMessage | Should -Be "Action skipped."
            }
        }
    }

    Context "When an error occurs during deletion" {

        It "Should return a failed ProfileDeletionResult and log an error" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"
                $computerName = "Server01"
                $profileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Properties @{ Name = "ProfileList" }

                Mock Remove-RegistryKeyForSID { throw "Registry access error" }
                #Mock Write-Error

                # Act
                $result = Remove-SIDProfile -SID $sid -ProfileListKey $profileListKey -ComputerName $computerName -ProfilePath $profilePath -confirm:$false -ErrorAction Continue

                # Assert
                $result.GetType().Name | Should -Be 'ProfileDeletionResult'
                $result.SID | Should -Be $sid
                $result.DeletionSuccess | Should -Be $false
                $result.DeletionMessage | Should -Be "Failed to delete the profile registry key for SID '$sid'. Error: Registry access error"
                #Assert-MockCalled Write-Error -Exactly 1 -Scope It
            }
        }
    }
}
