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

Describe 'Invoke-UserProfileRegRemoval' -Tags 'Private', 'UserProfileReg' {

    BeforeEach {
        InModuleScope -ScriptBlock {
            # Mocking necessary dependencies
            Mock -CommandName Invoke-UserProfileAudit
            Mock -CommandName Remove-ProfileRegistryKey
            Mock -CommandName Write-Error
            Mock ShouldContinueWrapper {
                param($Context, $QueryMessage, $CaptionMessage)
                return $true
            }
        }
    }

    Context 'When confirmation is required' {
        It 'Should call ShouldContinueWrapper before removing profile' {
            InModuleScope -ScriptBlock {

                Mock -CommandName Remove-UserProfileRegistryEntry {}

                # Mock the registry key opening to succeed
                Mock Open-RegistryKey { return New-MockObject -Type "Microsoft.Win32.RegistryKey" -Methods @{ Close = {} } }

                # Mock profile audit results using New-UserProfileObject
                Mock Invoke-UserProfileAudit {
                    $mockAuditResults = @()
                    $mockAuditResults += New-UserProfileObject -SID 'S-1-5-21-12345' -ProfilePath 'C:\Users\Test1' -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false
                    $mockAuditResults += New-UserProfileObject -SID 'S-1-5-21-12346' -ProfilePath 'C:\Users\Test2' -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false
                    return $mockAuditResults
                }

                # Call the function with the Confirm switch
                Invoke-UserProfileRegRemoval -ComputerName 'Server01' -SID 'S-1-5-21-12345' -RegistryPath 'Path' -ProfileFolderPath 'C:\Users' -RegistryHive 'LocalMachine'

                # Ensure ShouldContinueWrapper was called
                Assert-MockCalled ShouldContinueWrapper -Exactly 1 -Scope It -ParameterFilter {
                    $QueryMessage -like '*S-1-5-21-12345*'
                }

                # Ensure that Remove-UserProfileRegistryEntry was called after confirmation
                Assert-MockCalled Remove-UserProfileRegistryEntry -Exactly 1 -Scope It
            }
        }
    }

    # Test: When in audit mode (AuditOnly switch is used)
    Context 'When in audit mode' {
        It 'Should perform an audit and not remove the profiles' {
            InModuleScope -ScriptBlock {
                # Mock the registry key opening to succeed
                Mock Open-RegistryKey { return New-MockObject -Type "Microsoft.Win32.RegistryKey" -Methods @{ Close = {} } }

                Mock Remove-UserProfileRegistryEntry {
                    param($SelectedProfile, $BaseKey, $AuditOnly)
                    $deletionResultParams = @{
                        SID             = $SelectedProfile.SID
                        ProfilePath     = $SelectedProfile.ProfilePath
                        ComputerName    = $SelectedProfile.ComputerName
                        DeletionSuccess = $false
                        DeletionMessage = "Profile not removed."
                    }

                    # If in audit mode, output an audit-only result directly to the pipeline and return
                    if ($AuditOnly)
                    {
                        $deletionResultParams.DeletionSuccess = $true
                        $deletionResultParams.DeletionMessage = "Audit only, no deletion performed."
                        New-ProfileDeletionResult @deletionResultParams
                        return  # Return to allow pipeline to continue with the next item
                    }

                }

                # Mock profile audit results using New-UserProfileObject
                Mock Invoke-UserProfileAudit {
                    $mockAuditResults = @()
                    $mockAuditResults += New-UserProfileObject -SID 'S-1-5-21-12345' -ProfilePath 'C:\Users\Test1' -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false
                    $mockAuditResults += New-UserProfileObject -SID 'S-1-5-21-12346' -ProfilePath 'C:\Users\Test2' -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false
                    return $mockAuditResults
                }

                # Call the function with AuditOnly switch
                $result = Invoke-UserProfileRegRemoval -ComputerName 'Server01' -SID 'S-1-5-21-12345' -RegistryPath 'Path' -ProfileFolderPath 'C:\Users' -RegistryHive 'LocalMachine' -AuditOnly

                # Ensure that Remove-UserProfileRegistryEntry was NOT called
                Assert-MockCalled Remove-UserProfileRegistryEntry -Times 1 -Scope It -ParameterFilter {
                    $AuditOnly -eq $true
                }
            }
        }
    }

    # Test: When using Force switch
    Context 'When using Force switch' {
        It 'Should remove the profile without confirmation' {
            InModuleScope -ScriptBlock {

                Mock -CommandName Remove-UserProfileRegistryEntry {}


                # Mock the registry key opening to succeed
                Mock Open-RegistryKey { return New-MockObject -Type "Microsoft.Win32.RegistryKey" -Methods @{ Close = {} } }

                # Mock profile audit results using New-UserProfileObject
                Mock Invoke-UserProfileAudit {
                    $mockAuditResults = @()
                    $mockAuditResults += New-UserProfileObject -SID 'S-1-5-21-12345' -ProfilePath 'C:\Users\Test1' -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false
                    return $mockAuditResults
                }

                # Call the function with the Force switch
                Invoke-UserProfileRegRemoval -ComputerName 'Server01' -SID 'S-1-5-21-12345' -RegistryPath 'Path' -ProfileFolderPath 'C:\Users' -RegistryHive 'LocalMachine' -Force

                # Ensure that ShouldContinueWrapper was not called (no confirmation)
                Assert-MockCalled ShouldContinueWrapper -Exactly 0 -Scope It

                # Ensure Remove-UserProfileRegistryEntry was called
                Assert-MockCalled Remove-UserProfileRegistryEntry -Exactly 1 -Scope It
            }
        }
    }

    # Test: When registry key cannot be opened
    Context 'When registry key cannot be opened' {
        It 'Should write an error and exit' {
            InModuleScope -ScriptBlock {

                Mock -CommandName Remove-UserProfileRegistryEntry {}
                # Mock the registry key opening to fail
                Mock Open-RegistryKey {
                    param($ComputerName, $RegistryHive, $RegistryPath)
                    $Out = $Null
                    return $Out
                }

                # Call the function
                Invoke-UserProfileRegRemoval -ComputerName 'Server01' -SID 'S-1-5-21-12345' -RegistryPath 'Path' -ProfileFolderPath 'C:\Users' -RegistryHive 'LocalMachine'

                # Ensure Write-Error was called
                Assert-MockCalled Write-Error -Exactly 1 -Scope It

                # Ensure Remove-UserProfileRegistryEntry was not called
                Assert-MockCalled Remove-UserProfileRegistryEntry -Exactly 0  -Scope It
            }
        }
    }

    # Test: When processing multiple SIDs from the pipeline
    Context 'When processing multiple SIDs' {
        It 'Should handle multiple SIDs from the pipeline' {
            InModuleScope -ScriptBlock {

                Mock -CommandName Remove-UserProfileRegistryEntry {}

                # Mock the registry key opening to succeed
                Mock Open-RegistryKey { return New-MockObject -Type "Microsoft.Win32.RegistryKey" -Methods @{ Close = {} } }

                # Mock profile audit results using New-UserProfileObject
                Mock Invoke-UserProfileAudit {
                    $mockAuditResults = @()
                    $mockAuditResults += New-UserProfileObject -SID 'S-1-5-21-12345' -ProfilePath 'C:\Users\Test1' -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false
                    $mockAuditResults += New-UserProfileObject -SID 'S-1-5-21-12346' -ProfilePath 'C:\Users\Test2' -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false
                    return $mockAuditResults
                }

                # Call the function with multiple SIDs from the pipeline
                'S-1-5-21-12345', 'S-1-5-21-12346' | Invoke-UserProfileRegRemoval -ComputerName 'Server01' -RegistryPath 'Path' -ProfileFolderPath 'C:\Users' -RegistryHive 'LocalMachine' -Force

                # Ensure that Remove-UserProfileRegistryEntry was called for each SID
                Assert-MockCalled Remove-UserProfileRegistryEntry -Exactly 2 -Scope It
            }
        }
    }

    # Test: When profile removal fails
    Context 'When profile removal fails' {
        It 'Should return deletion object with failure message' {
            InModuleScope -ScriptBlock {
                # Mock the registry key opening to succeed
                Mock Open-RegistryKey { return New-MockObject -Type "Microsoft.Win32.RegistryKey" }

                Mock Backup-RegistryKeyForSID { return $true }

                Mock Remove-ProfileRegistryKey { return $false }

                # Mock profile audit results using New-UserProfileObject
                Mock Invoke-UserProfileAudit {
                    $mockAuditResults = @()
                    $mockAuditResults += New-UserProfileObject -SID 'S-1-5-21-12345' -ProfilePath 'C:\Users\Test1' -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $false
                    return $mockAuditResults
                }

                # Call the function
                $result = Invoke-UserProfileRegRemoval -ComputerName 'Server01' -SID 'S-1-5-21-12345' -RegistryPath 'Path' -ProfileFolderPath 'C:\Users' -RegistryHive 'LocalMachine'

                # Ensure an error was written
                $result.DeletionMessage | Should -Be "Failed to remove profile registry key."

            }
        }
    }

    Context 'When a special profile is encountered' {
        It 'Should handle the special profile appropriately' {
            InModuleScope -ScriptBlock {

                Mock Remove-UserProfileRegistryEntry {}

                # Mock the registry key opening to succeed
                Mock Open-RegistryKey { return New-MockObject -Type "Microsoft.Win32.RegistryKey" -Methods @{ Close = {} } }

                # Mock profile audit results with a special profile
                Mock Invoke-UserProfileAudit {
                    param($ignoreSpecial)

                    if ($ignoreSpecial)
                    {
                        return @()
                    }
                    else
                    {
                        return @(
                            New-UserProfileObject -SID 'S-1-5-21-12345' -ProfilePath 'C:\Users\Test1' -IsOrphaned $false -ComputerName 'Server01' -IsSpecial $true
                        )
                    }
                }

                # Call the function with the special profile
                Invoke-UserProfileRegRemoval -ComputerName 'Server01' -SID 'S-1-5-21-12345' -RegistryPath 'Path' -ProfileFolderPath 'C:\Users' -RegistryHive 'LocalMachine'

                # Ensure Remove-UserProfileRegistryEntry was not called for special profile
                Assert-MockCalled Remove-UserProfileRegistryEntry -Exactly 0 -Scope It
            }
        }
    }

}
