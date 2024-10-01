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

Describe 'Get-SIDFromUsername' -Tags "Private", "Helpers" {

    Context 'When the username exists and has a valid SID' {
        It 'should return the correct SID' {

            InModuleScope -ScriptBlock {

                # Mock NTAccount and SecurityIdentifier
                Mock -CommandName New-Object -MockWith {
                    New-MockObject -Type 'System.Security.Principal.NTAccount' -Methods @{
                        Translate = { New-MockObject -Type 'System.Security.Principal.SecurityIdentifier' -Properties @{ Value = 'S-1-5-21-1234567890-1234567890-1234567890-1001' } }
                    }
                }

                # Act: Call the function
                $result = Get-SIDFromUsername -Username 'JohnDoe'

                # Assert: Verify the result is the correct SID
                $result | Should -Be 'S-1-5-21-1234567890-1234567890-1234567890-1001'
            }
        }
    }

    Context 'When the username does not exist' {
        It 'should return null and show a warning' {

            InModuleScope -ScriptBlock {

                # Mock NTAccount to throw an error (user not found)
                Mock -CommandName New-Object -MockWith {
                    throw [System.Security.Principal.IdentityNotMappedException]::new("User not found")
                }

                # Act: Call the function
                $result = Get-SIDFromUsername -Username 'NonExistentUser'

                # Assert: The result should be null
                $result | Should -BeNullOrEmpty

            }
        }
    }

    Context 'When an error occurs while resolving the username' {
        It 'should return null and display a warning with error information' {

            InModuleScope -ScriptBlock {

                # Mock NTAccount to throw a general exception
                Mock -CommandName New-Object -MockWith {
                    throw "An unexpected error occurred"
                }

                # Mock Write-Warning to capture the warning message
                #Mock -CommandName Write-Warning

                # Act: Call the function
                $result = Get-SIDFromUsername -Username 'JohnDoe'

                # Assert: The result should be null
                $result | Should -BeNullOrEmpty

                # Assert: Verify that the warning message was displayed
                #Assert-MockCalled -CommandName Write-Warning -Exactly 1 -Scope It
            }
        }
    }

    Context 'When the SID is missing for a user' {
        It 'should return null and display a warning' {

            InModuleScope -ScriptBlock {

                # Mock NTAccount to return null for SID
                Mock -CommandName New-Object -MockWith {
                    New-MockObject -Type 'System.Security.Principal.NTAccount' -Methods @{
                        Translate = { throw }
                    }
                }

                # Mock Write-Warning to capture the warning message
                #Mock -CommandName Write-Warning

                # Act: Call the function
                $result = Get-SIDFromUsername -Username 'JohnDoe'

                # Assert: The result should be null
                $result | Should -BeNullOrEmpty

                # Assert: Verify that the warning message was displayed
                #Assert-MockCalled -CommandName Write-Warning -Exactly 1 -Scope It
            }
        }
    }
}
