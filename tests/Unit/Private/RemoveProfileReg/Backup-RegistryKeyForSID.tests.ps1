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

Describe 'Backup-RegistryKeyForSID' -Tag 'Private', "RemoveUserProfileReg" {


    BeforeEach {
        InModuleScope -ScriptBlock {
            # Mock dependencies
            Mock -CommandName New-DirectoryIfNeeded
            Mock -CommandName New-RegistryKeyValuesObject
            Mock -CommandName Update-JsonFile
            Mock -CommandName Write-Error
        }
    }

    # Test: Backup success case
    Context 'When the backup is successful' {
        It 'Should create a backup of the registry key and return $true' {
            InModuleScope -ScriptBlock {
                # Mock the directory creation to succeed
                Mock New-DirectoryIfNeeded { return $true }

                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"

                # Mock registry key backup to return a valid object
                Mock New-RegistryKeyValuesObject {
                    return @{ BackUpDate = (Get-Date) }
                }

                # Call the function with mock data
                $result = Backup-RegistryKeyForSID -SID 'S-1-5-21-12345' -BaseKey $BaseKey -RegBackUpDirectory 'C:\Backups' -ComputerName 'Server01'

                # Assert that the registry key was backed up
                Assert-MockCalled Update-JsonFile -Exactly 1 -Scope It

                # Ensure the function returned true
                $result | Should -Be $true
            }
        }
    }

    # Test: Backup directory creation failure
    Context 'When the backup directory cannot be created' {
        It 'Should return $false and write an error' {
            InModuleScope -ScriptBlock {
                # Mock directory creation to fail
                Mock New-DirectoryIfNeeded { return $false }

                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"

                # Call the function with mock data
                $result = Backup-RegistryKeyForSID -SID 'S-1-5-21-12345' -BaseKey $BaseKey -RegBackUpDirectory 'C:\Backups' -ComputerName 'Server01'

                # Ensure it wrote an error message
                Assert-MockCalled Write-Error -Exactly 1 -Scope It

                # Ensure the function returned false
                $result | Should -Be $false
            }
        }
    }

    # Test: Registry key backup failure
    Context 'When the registry key backup fails' {
        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                # Mock directory creation to succeed
                Mock New-DirectoryIfNeeded { return $true }

                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"

                # Mock registry key backup to throw an error
                Mock New-RegistryKeyValuesObject { throw "Registry key backup failed" }

                # Call the function with mock data
                $result = Backup-RegistryKeyForSID -SID 'S-1-5-21-12345' -BaseKey $BaseKey -RegBackUpDirectory 'C:\Backups' -ComputerName 'Server01'

                # Ensure an error was written
                Assert-MockCalled Write-Error -Exactly 1 -Scope It

                # Ensure the function returned false
                $result | Should -Be $false
            }
        }
    }

    # Test: Exception handling
    Context 'When an unexpected error occurs' {
        It 'Should catch the exception and return $false' {
            InModuleScope -ScriptBlock {
                # Mock directory creation to succeed
                Mock New-DirectoryIfNeeded { return $true }

                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"

                # Mock registry key backup to succeed
                Mock New-RegistryKeyValuesObject { return @{ BackUpDate = (Get-Date) } }

                # Mock Update-JsonFile to throw an exception
                Mock Update-JsonFile { throw "Unexpected error" }

                # Call the function with mock data
                $result = Backup-RegistryKeyForSID -SID 'S-1-5-21-12345' -BaseKey $BaseKey -RegBackUpDirectory 'C:\Backups' -ComputerName 'Server01'

                # Ensure an error was written
                Assert-MockCalled Write-Error -Exactly 1 -Scope It

                # Ensure the function returned false
                $result | Should -Be $false
            }
        }
    }

    Context 'When using a network path for the backup directory' {
        It 'Should successfully create a backup on a network path' {
            InModuleScope -ScriptBlock {
                # Mock directory creation to succeed
                Mock New-DirectoryIfNeeded { return $true }

                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"

                # Mock registry key backup to return a valid object
                Mock New-RegistryKeyValuesObject {
                    return @{ BackUpDate = (Get-Date) }
                }

                # Call the function with a network path
                $result = Backup-RegistryKeyForSID -SID 'S-1-5-21-12345' -BaseKey $BaseKey -RegBackUpDirectory '\\Server01\Backups' -ComputerName 'Server01'

                # Assert that the registry key was backed up
                Assert-MockCalled Update-JsonFile -Exactly 1 -Scope It

                # Ensure the function returned true
                $result | Should -Be $true
            }
        }
    }


    Context 'When the registry key data is empty or null' {
        It 'Should return $false and write an error' {
            InModuleScope -ScriptBlock {
                # Mock directory creation to succeed
                Mock New-DirectoryIfNeeded { return $true }

                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"

                # Mock registry key backup to return null or empty data
                Mock New-RegistryKeyValuesObject { return $null }

                # Call the function with mock data
                $result = Backup-RegistryKeyForSID -SID 'S-1-5-21-12345' -BaseKey $BaseKey -RegBackUpDirectory 'C:\Backups' -ComputerName 'Server01'

                # Ensure an error was written
                Assert-MockCalled Write-Error -Exactly 1 -Scope It

                # Ensure the function returned false
                $result | Should -Be $false
            }
        }
    }

    Context 'When the backup directory exists but is not writable' {
        It 'Should return $false and write an error' {
            InModuleScope -ScriptBlock {
                # Mock directory creation to succeed
                Mock New-DirectoryIfNeeded { return $true }

                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"

                # Mock Update-JsonFile to throw a permission error
                Mock Update-JsonFile { throw "Permission denied" }

                # Call the function with mock data
                $result = Backup-RegistryKeyForSID -SID 'S-1-5-21-12345' -BaseKey $BaseKey -RegBackUpDirectory 'C:\Backups' -ComputerName 'Server01'

                # Ensure an error was written
                Assert-MockCalled Write-Error -Exactly 1 -Scope It

                # Ensure the function returned false
                $result | Should -Be $false
            }
        }
    }

    Context 'When an invalid or empty SID is provided' {
        It 'Should throw a ParameterBindingValidationException' {
            InModuleScope -ScriptBlock {
                # Call the function with an empty SID and verify it throws the expected error
                { Backup-RegistryKeyForSID -SID '' -BaseKey $null -RegBackUpDirectory 'C:\Backups' -ComputerName 'Server01' } | Should -Throw
            }
        }
    }

    Context 'When backing up the registry key with New-RegistryKeyValuesObject' {
        It 'Should call New-RegistryKeyValuesObject and set BackUpDate in ISO 8601 format' {
            InModuleScope -ScriptBlock {
                # Mock the directory creation to succeed
                Mock New-DirectoryIfNeeded { return $true }

                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey"

                # Mock New-RegistryKeyValuesObject to return a mock object with a BackUpDate property
                Mock New-RegistryKeyValuesObject {
                    return [pscustomobject]@{ BackUpDate = (Get-Date) }
                }

                # Call the function
                Backup-RegistryKeyForSID -SID 'S-1-5-21-12345' -BaseKey $BaseKey -RegBackUpDirectory 'C:\Backups' -ComputerName 'Server01'

                # Verify that New-RegistryKeyValuesObject was called with the correct parameters
                Assert-MockCalled New-RegistryKeyValuesObject -Exactly 1 -Scope It -ParameterFilter {
                    $RegistryKey -eq $BaseKey -and $ComputerName -eq 'Server01' -and $SubKeyName -eq 'S-1-5-21-12345'
                }

                # Verify that the BackUpDate was set correctly in ISO 8601 format
                $expectedDate = (Get-Date).ToString("o")
                Mock Update-JsonFile -MockWith {
                    param ($OutputFile, $RegistryData)
                    $RegistryData.BackUpDate | Should -Be $expectedDate
                }

                # Call the function again to test the BackupDate
                Backup-RegistryKeyForSID -SID 'S-1-5-21-12345' -BaseKey $BaseKey -RegBackUpDirectory 'C:\Backups' -ComputerName 'Server01'
            }
        }
    }


}
