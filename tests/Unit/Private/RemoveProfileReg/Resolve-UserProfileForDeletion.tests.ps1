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

Describe 'Resolve-UserProfileForDeletion' -Tags 'Private', 'UserProfileReg' {

    BeforeEach {
        InModuleScope -ScriptBlock {
            # Mock the Validate-SIDFormat and New-ProfileDeletionResult functions
            Mock -CommandName Validate-SIDFormat
            Mock -CommandName Write-Warning
        }
    }

    # Test: Successfully finding a profile
    Context 'When the profile exists in the audit results' {
        It 'Should return the UserProfile object' {
            InModuleScope -ScriptBlock {
                # Mock audit results with valid UserProfile objects
                $mockAuditResults = @()
                $mockAuditResults += New-UserProfileObject -SID 'S-1-5-21-1001' -ProfilePath 'C:\Users\Test1' -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false
                $mockAuditResults += New-UserProfileObject -SID 'S-1-5-21-1002' -ProfilePath 'C:\Users\Test1' -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false


                # Call the function with a valid SID
                $result = Resolve-UserProfileForDeletion -SID 'S-1-5-21-1001' -AuditResults $mockAuditResults -ComputerName 'Server01'

                # Validate that the correct UserProfile object is returned
                $result.SID | Should -Be 'S-1-5-21-1001'

                # Ensure that Write-Warning was not called
                Assert-MockCalled Write-Warning -Exactly 0 -Scope It
            }
        }
    }

    # Test: Profile not found, valid SID format
    Context 'When the profile is not found but the SID is valid' {
        It 'Should return a ProfileDeletionResult indicating failure and log a warning' {
            InModuleScope -ScriptBlock {
                # Mock audit results with no matching SID
                $mockAuditResults = @()

                $mockAuditResults += New-UserProfileObject -SID 'S-1-5-21-1002' -ProfilePath $Null -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false

                # Mock Validate-SIDFormat to return true (valid SID format)
                Mock Validate-SIDFormat { return $true }

                # Call the function with a valid but non-existent SID
                $result = Resolve-UserProfileForDeletion -SID 'S-1-5-21-1001' -AuditResults $mockAuditResults -ComputerName 'Server01'

                # Validate that the ProfileDeletionResult indicates failure
                $result.SID | Should -Be 'S-1-5-21-1001'
                $result.DeletionSuccess | Should -Be $false
                $result.DeletionMessage | Should -Be 'Profile not found'

                # Ensure that Write-Warning was called with the correct message
                Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter {
                    $Message -eq 'Profile not found for SID: S-1-5-21-1001 on Server01.'
                }
            }
        }
    }

    # Test: Invalid SID format
    Context 'When the SID format is invalid' {
        It 'Should return a ProfileDeletionResult indicating invalid SID and log a warning' {
            InModuleScope -ScriptBlock {
                # Mock audit results
                $mockAuditResults = @()

                $mockAuditResults += New-UserProfileObject -SID 'S-1-5-21-1002' -ProfilePath $Null -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false

                # Mock Validate-SIDFormat to return false (invalid SID format)
                Mock Validate-SIDFormat { return $false }


                # Call the function with an invalid SID format
                $result = Resolve-UserProfileForDeletion -SID 'Invalid-SID' -AuditResults $mockAuditResults -ComputerName 'Server01'

                # Validate that the ProfileDeletionResult indicates failure due to invalid SID
                $result.SID | Should -Be 'Invalid-SID'
                $result.DeletionSuccess | Should -Be $false
                $result.DeletionMessage | Should -Be 'Invalid SID format encountered'

                # Ensure that Write-Warning was called with the correct message
                Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter {
                    $Message -eq 'Invalid SID format encountered: Invalid-SID on Server01.'
                }
            }
        }
    }

    # Test: No matching profile and invalid SID format
    Context 'When the SID format is invalid and profile is not found' {
        It 'Should log an appropriate warning and return a failure result' {
            InModuleScope -ScriptBlock {
                # Mock Validate-SIDFormat to return false
                Mock Validate-SIDFormat { return $false }

                $mockAuditResults = @()

                $mockAuditResults += New-UserProfileObject -SID 'S-1-5-21-1002' -ProfilePath $Null -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false

                # Call the function with an invalid SID
                $result = Resolve-UserProfileForDeletion -SID 'Invalid-SID' -AuditResults $mockAuditResults -ComputerName 'Server01'

                # Validate that the ProfileDeletionResult indicates failure
                $result.SID | Should -Be 'Invalid-SID'
                $result.DeletionSuccess | Should -Be $false
                $result.DeletionMessage | Should -Be 'Invalid SID format encountered'

                # Ensure that Write-Warning was called with the correct message
                Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter {
                    $Message -eq 'Invalid SID format encountered: Invalid-SID on Server01.'
                }
            }
        }
    }

    # Test: No profiles in the audit results
    Context 'When there are no profiles in the audit results' {
        It 'Should return a ProfileDeletionResult indicating failure and log a warning' {
            InModuleScope -ScriptBlock {
                # Mock an empty audit results array
                $mockAuditResults = @()

                # Mock Validate-SIDFormat to return true
                Mock Validate-SIDFormat { return $true }


                # Call the function with no profiles in the audit results
                $result = Resolve-UserProfileForDeletion -SID 'S-1-5-21-1001' -AuditResults $mockAuditResults -ComputerName 'Server01'

                # Validate that the ProfileDeletionResult indicates failure
                $result.SID | Should -Be 'S-1-5-21-1001'
                $result.DeletionSuccess | Should -Be $false
                $result.DeletionMessage | Should -Be 'Profile not found'

                # Ensure that Write-Warning was called with the correct message
                Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter {
                    $Message -eq 'Profile not found for SID: S-1-5-21-1001 on Server01.'
                }
            }
        }
    }
}
