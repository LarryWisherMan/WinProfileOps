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

Describe 'Confirm-ProfileRemoval' -Tag 'Private', "RemoveUserProfileReg" {

    BeforeEach {
        InModuleScope -ScriptBlock {
            # Mock Write-Error
            Mock -CommandName Write-Error
        }
    }

    # Test: Registry key exists (SID is found in subkeys)
    Context 'When the SID exists in the registry subkeys' {
        It 'Should return $false' {
            InModuleScope -ScriptBlock {
                # Create a mock RegistryKey object with GetSubKeyNames() returning an array that contains the SID
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey" -Methods @{
                    GetSubKeyNames = { return @('S-1-5-21-12345', 'S-1-5-21-67890') }
                }

                # Call the function
                $result = Confirm-ProfileRemoval -SID 'S-1-5-21-12345' -BaseKey $BaseKey

                # Ensure the function returns $false because the SID exists
                $result | Should -Be $false
            }
        }
    }

    # Test: Registry key does not exist (SID is not found in subkeys)
    Context 'When the SID does not exist in the registry subkeys' {
        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                # Create a mock RegistryKey object with GetSubKeyNames() returning an array that does not contain the SID
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey" -Methods @{
                    GetSubKeyNames = { return @('S-1-5-21-67890', 'S-1-5-21-99999') }
                }

                # Call the function
                $result = Confirm-ProfileRemoval -SID 'S-1-5-21-12345' -BaseKey $BaseKey

                # Ensure the function returns $true because the SID does not exist
                $result | Should -Be $true
            }
        }
    }

    # Test: Exception occurs while accessing registry
    Context 'When there is an error accessing the registry' {
        It 'Should return $false and write an error' {
            InModuleScope -ScriptBlock {
                # Create a mock RegistryKey object that throws an error when GetSubKeyNames() is called
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey" -Methods @{
                    GetSubKeyNames = { throw "Registry access error" }
                }

                # Call the function
                $result = Confirm-ProfileRemoval -SID 'S-1-5-21-12345' -BaseKey $BaseKey

                # Ensure an error was written
                Assert-MockCalled Write-Error -Exactly 1 -Scope It

                # Ensure the function returns $false due to the exception
                $result | Should -Be $false
            }
        }
    }

    # Test: When BaseKey is empty or null
    Context 'When BaseKey is null' {
        It 'Should return an False and write an error' {
            InModuleScope -ScriptBlock {

                Mock Write-Error {}

                # Call the function with a null BaseKey
                $Return = Confirm-ProfileRemoval -SID 'S-1-5-21-12345' -BaseKey $null

                #Assert Return is false
                $Return | Should -Be $false

                # Ensure an error was written
                Assert-MockCalled Write-Error -Exactly 1 -Scope It
            }
        }
    }

    # Test: Empty array from GetSubKeyNames (No subkeys)
    Context 'When the registry key has no subkeys' {
        It 'Should return $true because there are no subkeys' {
            InModuleScope -ScriptBlock {
                # Create a mock RegistryKey object with GetSubKeyNames() returning an empty array
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey" -Methods @{
                    GetSubKeyNames = { return @() }
                }

                # Call the function
                $result = Confirm-ProfileRemoval -SID 'S-1-5-21-12345' -BaseKey $BaseKey

                # Ensure the function returns $true because there are no subkeys
                $result | Should -Be $true
            }
        }
    }

    # Test: Multiple subkeys but none matching the SID
    Context 'When there are multiple subkeys but none match the SID' {
        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                # Create a mock RegistryKey object with GetSubKeyNames() returning several subkeys, but none match the SID
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey" -Methods @{
                    GetSubKeyNames = { return @('S-1-5-21-67890', 'S-1-5-21-99999', 'S-1-5-21-11111') }
                }

                # Call the function
                $result = Confirm-ProfileRemoval -SID 'S-1-5-21-12345' -BaseKey $BaseKey

                # Ensure the function returns $true because the SID does not exist among the subkeys
                $result | Should -Be $true
            }
        }
    }

    # Test: When the SID is a non-standard or invalid format
    Context 'When an invalid or malformed SID is provided' {
        It 'Should return $true' {
            InModuleScope -ScriptBlock {
                # Create a mock RegistryKey object with GetSubKeyNames() returning a list of subkeys
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey" -Methods @{
                    GetSubKeyNames = { return @('S-1-5-21-67890') }
                }

                # Call the function with an invalid SID
                $result = Confirm-ProfileRemoval -SID 'INVALID-SID' -BaseKey $BaseKey

                # Ensure the function returns $false since it's an invalid SID
                $result | Should -Be $true
            }
        }
    }

    # Test: Case sensitivity for SID matching
    Context 'When the SID is provided in a different case' {
        It 'Should still return the correct result regardless of case sensitivity' {
            InModuleScope -ScriptBlock {
                # Create a mock RegistryKey object with GetSubKeyNames() returning a list of subkeys
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey" -Methods @{
                    GetSubKeyNames = { return @('S-1-5-21-12345') }
                }

                # Call the function with a lower-case SID
                $result = Confirm-ProfileRemoval -SID 's-1-5-21-12345' -BaseKey $BaseKey

                # Ensure the function returns $false because the SID exists, regardless of case
                $result | Should -Be $false
            }
        }
    }

    # Test: Handle large number of subkeys
    Context 'When there is a very large number of subkeys' {
        It 'Should return $true or $false depending on SID existence' {
            InModuleScope -ScriptBlock {
                # Generate a large list of SIDs
                $subKeys = 1..100 | ForEach-Object { "S-1-5-21-$_" }

                # Create a mock RegistryKey object with GetSubKeyNames() returning a large array of subkeys
                $BaseKey = New-MockObject -Type "Microsoft.Win32.RegistryKey" -Methods @{
                    GetSubKeyNames = { return $subKeys }
                }

                # Call the function with a SID that does not exist in the large array
                $result = Confirm-ProfileRemoval -SID 'S-1-5-21-110' -BaseKey $BaseKey

                # Ensure the function returns $true because the SID does not exist
                $result | Should -Be $true

                # Call the function with a SID that exists in the large array
                $result = Confirm-ProfileRemoval -SID 'S-1-5-21-99' -BaseKey $BaseKey

                # Ensure the function returns $false because the SID exists
                $result | Should -Be $false
            }
        }
    }




}
