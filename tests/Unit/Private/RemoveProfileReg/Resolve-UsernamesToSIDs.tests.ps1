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

Describe 'Resolve-UsernamesToSIDs' -Tags 'Private', 'RemoveProfileReg' {

    BeforeEach {
        InModuleScope -ScriptBlock {
            # Mocking the Get-SIDFromUsername function
            Mock -CommandName Get-SIDFromUsername
            Mock -CommandName Write-Warning
        }
    }

    # Test: Resolving valid usernames to SIDs
    Context 'When all usernames are valid' {
        It 'Should return an array of corresponding SIDs' {
            InModuleScope -ScriptBlock {
                # Mock Get-SIDFromUsername to return valid SIDs
                Mock Get-SIDFromUsername {
                    param($Username)
                    switch ($Username)
                    {
                        'user1'
                        {
                            return 'S-1-5-21-1001' 
                        }
                        'user2'
                        {
                            return 'S-1-5-21-1002' 
                        }
                    }
                }

                # Call the function with valid usernames
                $result = Resolve-UsernamesToSIDs -Usernames 'user1', 'user2'

                # Validate that the returned array contains the correct SIDs
                $result | Should -Be @('S-1-5-21-1001', 'S-1-5-21-1002')

                # Ensure that Write-Warning was not called
                Assert-MockCalled Write-Warning -Exactly 0 -Scope It
            }
        }
    }

    # Test: Resolving usernames with some unresolved
    Context 'When some usernames cannot be resolved' {
        It 'Should return SIDs for valid usernames and log warnings for unresolved ones' {
            InModuleScope -ScriptBlock {
                # Mock Get-SIDFromUsername to return SIDs for some usernames and $null for others
                Mock Get-SIDFromUsername {
                    param($Username)
                    switch ($Username)
                    {
                        'user1'
                        {
                            return 'S-1-5-21-1001' 
                        }
                        'invalidUser'
                        {
                            return $null 
                        }
                    }
                }

                # Call the function with a mix of valid and invalid usernames
                $result = Resolve-UsernamesToSIDs -Usernames 'user1', 'invalidUser'

                # Validate that the returned array contains only the valid SID
                $result | Should -Be @('S-1-5-21-1001')

                # Ensure that Write-Warning was called for the unresolved username
                Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter {
                    $Message -eq 'Could not resolve SID for username invalidUser.'
                }
            }
        }
    }

    # Test: Resolving no usernames (empty input)
    Context 'When no usernames are provided' {
        It 'Should return an empty array' {
            InModuleScope -ScriptBlock {
                # Call the function with an empty array of usernames
                $result = Resolve-UsernamesToSIDs -Usernames @()

                # Validate that the result is an empty array
                $result | Should -Be @()

                # Ensure that Get-SIDFromUsername and Write-Warning were not called
                Assert-MockCalled Get-SIDFromUsername -Exactly 0 -Scope It
                Assert-MockCalled Write-Warning -Exactly 0 -Scope It
            }
        }
    }

    # Test: Resolving multiple usernames
    Context 'When resolving multiple usernames' {
        It 'Should return the correct SIDs for each username' {
            InModuleScope -ScriptBlock {
                # Mock Get-SIDFromUsername to return SIDs for multiple usernames
                Mock Get-SIDFromUsername {
                    param($Username)
                    switch ($Username)
                    {
                        'user1'
                        {
                            return 'S-1-5-21-1001' 
                        }
                        'user2'
                        {
                            return 'S-1-5-21-1002' 
                        }
                        'user3'
                        {
                            return 'S-1-5-21-1003' 
                        }
                    }
                }

                # Call the function with multiple usernames
                $result = Resolve-UsernamesToSIDs -Usernames 'user1', 'user2', 'user3'

                # Validate that the returned array contains the correct SIDs
                $result | Should -Be @('S-1-5-21-1001', 'S-1-5-21-1002', 'S-1-5-21-1003')

                # Ensure that Write-Warning was not called
                Assert-MockCalled Write-Warning -Exactly 0 -Scope It
            }
        }
    }

    # Test: Unresolved usernames result in warning
    Context 'When a username cannot be resolved' {
        It 'Should log a warning for unresolved usernames' {
            InModuleScope -ScriptBlock {
                # Mock Get-SIDFromUsername to return $null for unresolved usernames
                Mock Get-SIDFromUsername {
                    return $null
                }

                # Call the function with an unresolved username
                $result = Resolve-UsernamesToSIDs -Usernames 'invalidUser'

                # Validate that the result is an empty array
                $result | Should -Be @()

                # Ensure that Write-Warning was called with the correct message
                Assert-MockCalled Write-Warning -Exactly 1 -Scope It -ParameterFilter {
                    $Message -eq 'Could not resolve SID for username invalidUser.'
                }
            }
        }
    }
}
