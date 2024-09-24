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

Describe 'Remove-UserProfileRegistryEntry' -Tags 'Private', 'UserProfileReg' {

    BeforeEach {
        InModuleScope -ScriptBlock {
            # Mock functions used in the Remove-UserProfileRegistryEntry function
            Mock -CommandName Backup-RegistryKeyForSID
            Mock -CommandName Remove-ProfileRegistryKey
            Mock -CommandName Confirm-ProfileRemoval
            Mock -CommandName New-ProfileDeletionResult

        }
    }

    # Test: Audit mode (AuditOnly switch is used)
    Context 'When in audit mode' {
        It 'Should return a ProfileDeletionResult with audit-only message and success' {
            InModuleScope -ScriptBlock {

                # Use New-UserProfileObject to mock UserProfile objects
                $mockUserProfile = New-UserProfileObject -SID 'S-1-5-21-1001' -ProfilePath "C:\Users\TestUser1" -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false

                # Mock the base registry key
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"


                # Call the function in AuditOnly mode
                $result = Remove-UserProfileRegistryEntry -SelectedProfile $mockUserProfile -BaseKey $BaseKey -AuditOnly

                # Ensure the audit result is returned with success and audit message
                Assert-MockCalled New-ProfileDeletionResult -Exactly 1 -Scope It -ParameterFilter {
                    $DeletionMessage -eq 'Audit only, no deletion performed.' -and
                    $DeletionSuccess -eq $true
                }
            }
        }
    }

    # Test: Backup failure
    Context 'When backup of the profile fails' {
        It 'Should return a ProfileDeletionResult indicating backup failure' {
            InModuleScope -ScriptBlock {

                # Use New-UserProfileObject to mock UserProfile objects
                $mockUserProfile = New-UserProfileObject -SID 'S-1-5-21-1001' -ProfilePath "C:\Users\TestUser1" -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false

                # Mock the base registry key
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"

                # Mock Backup-RegistryKeyForSID to return false (backup failure)
                Mock Backup-RegistryKeyForSID { return $false }

                # Call the function
                $result = Remove-UserProfileRegistryEntry -SelectedProfile $mockUserProfile -BaseKey $BaseKey

                # Ensure the result indicates backup failure
                Assert-MockCalled New-ProfileDeletionResult -Exactly 1 -Scope It -ParameterFilter {
                    $DeletionMessage -eq 'Failed to backup profile.' -and
                    $DeletionSuccess -eq $false
                }

                # Ensure no attempt was made to remove the profile if the backup failed
                Assert-MockCalled Remove-ProfileRegistryKey -Exactly 0 -Scope It
            }
        }
    }

    # Test: Successful profile removal
    Context 'When profile removal is successful' {
        It 'Should return a ProfileDeletionResult indicating success' {
            InModuleScope -ScriptBlock {

                # Use New-UserProfileObject to mock UserProfile objects
                $mockUserProfile = New-UserProfileObject -SID 'S-1-5-21-1001' -ProfilePath "C:\Users\TestUser1" -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false

                # Mock the base registry key
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"


                # Mock Backup-RegistryKeyForSID and Remove-ProfileRegistryKey to succeed
                Mock Backup-RegistryKeyForSID { return $true }
                Mock Remove-ProfileRegistryKey { return $true }

                # Mock Confirm-ProfileRemoval to return true (successful removal)
                Mock Confirm-ProfileRemoval { return $true }

                # Call the function
                $result = Remove-UserProfileRegistryEntry -SelectedProfile $mockUserProfile -BaseKey $BaseKey

                # Ensure the result indicates successful removal
                Assert-MockCalled New-ProfileDeletionResult -Exactly 1 -Scope It -ParameterFilter {
                    $DeletionMessage -eq 'Profile removed successfully.' -and
                    $DeletionSuccess -eq $true
                }
            }
        }
    }

    # Test: Confirm-ProfileRemoval succeeds after backup and registry removal
    Context 'When profile is successfully backed up, removed, and confirmed' {
        It 'Should return a ProfileDeletionResult indicating full success' {
            InModuleScope -ScriptBlock {

                # Use New-UserProfileObject to mock UserProfile objects
                $mockUserProfile = New-UserProfileObject -SID 'S-1-5-21-1001' -ProfilePath "C:\Users\TestUser1" -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false

                # Mock the base registry key
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"

                # Mock Backup-RegistryKeyForSID and Remove-ProfileRegistryKey to succeed
                Mock Backup-RegistryKeyForSID { return $true }
                Mock Remove-ProfileRegistryKey { return $true }

                # Mock Confirm-ProfileRemoval to succeed
                Mock Confirm-ProfileRemoval { return $true }

                # Call the function
                $result = Remove-UserProfileRegistryEntry -SelectedProfile $mockUserProfile -BaseKey $BaseKey

                # Ensure the result indicates full success
                Assert-MockCalled New-ProfileDeletionResult -Exactly 1 -Scope It -ParameterFilter {
                    $DeletionMessage -eq "Profile removed successfully." -and
                    $DeletionSuccess -eq $true
                }
            }
        }
    }


    # Test: Failed profile removal
    Context 'When profile removal fails after a successful backup' {
        It 'Should return a ProfileDeletionResult indicating removal failure' {
            InModuleScope -ScriptBlock {

                # Use New-UserProfileObject to mock UserProfile objects
                $mockUserProfile = New-UserProfileObject -SID 'S-1-5-21-1001' -ProfilePath "C:\Users\TestUser1" -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false

                # Mock the base registry key
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"

                # Mock Backup-RegistryKeyForSID to succeed
                Mock Backup-RegistryKeyForSID { return $true }

                # Mock Remove-ProfileRegistryKey to fail
                Mock Remove-ProfileRegistryKey { return $false }

                # Call the function
                $result = Remove-UserProfileRegistryEntry -SelectedProfile $mockUserProfile -BaseKey $BaseKey

                # Ensure the result indicates profile removal failure
                Assert-MockCalled New-ProfileDeletionResult -Exactly 1 -Scope It -ParameterFilter {
                    $DeletionMessage -eq 'Failed to remove profile registry key.' -and
                    $DeletionSuccess -eq $false
                }
            }
        }
    }

    # Test: Failed profile removal confirmation
    Context 'When profile removal is successful but confirmation fails' {
        It 'Should return a ProfileDeletionResult indicating removal failure' {
            InModuleScope -ScriptBlock {

                # Use New-UserProfileObject to mock UserProfile objects
                $mockUserProfile = New-UserProfileObject -SID 'S-1-5-21-1001' -ProfilePath "C:\Users\TestUser1" -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false

                # Mock the base registry key
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"

                # Mock Backup-RegistryKeyForSID and Remove-ProfileRegistryKey to succeed
                Mock Backup-RegistryKeyForSID { return $true }
                Mock Remove-ProfileRegistryKey { return $true }

                # Mock Confirm-ProfileRemoval to fail
                Mock Confirm-ProfileRemoval { return $false }

                # Call the function
                $result = Remove-UserProfileRegistryEntry -SelectedProfile $mockUserProfile -BaseKey $BaseKey

                # Ensure the result indicates profile removal failure despite registry key removal
                Assert-MockCalled New-ProfileDeletionResult -Exactly 1 -Scope It -ParameterFilter {
                    $DeletionMessage -eq "Profile removal verification failed." -and
                    $DeletionSuccess -eq $false
                }
            }
        }
    }


    # Test: No BaseKey provided
    Context 'When no base registry key is provided' {
        It 'Should return a ProfileDeletionResult indicating failure due to missing BaseKey' {
            InModuleScope -ScriptBlock {

                # Use New-UserProfileObject to mock UserProfile objects
                $mockUserProfile = New-UserProfileObject -SID 'S-1-5-21-1001' -ProfilePath "C:\Users\TestUser1" -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false

                # Call the function with a null BaseKey
                $result = Remove-UserProfileRegistryEntry -SelectedProfile $mockUserProfile -BaseKey $null

                # Ensure the result indicates failure due to missing BaseKey
                Assert-MockCalled New-ProfileDeletionResult -Exactly 1 -Scope It -ParameterFilter {
                    $DeletionMessage -eq "Failed: BaseKey is null, cannot remove the profile." -and
                    $DeletionSuccess -eq $false
                }

                # Ensure no backup or profile removal was attempted
                Assert-MockCalled Backup-RegistryKeyForSID -Exactly 0 -Scope It
                Assert-MockCalled Remove-ProfileRegistryKey -Exactly 0 -Scope It
            }
        }
    }


}
