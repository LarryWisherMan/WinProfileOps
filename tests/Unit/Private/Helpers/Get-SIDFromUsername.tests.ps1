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
        It 'should return the correct SID for local execution' {

            InModuleScope -ScriptBlock {

                # Mock Invoke-Command for local execution
                Mock -CommandName Invoke-Command -MockWith {
                    return 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                # Act: Call the function
                $result = Get-SIDFromUsername -Username 'JohnDoe'

                # Assert: Verify the result is the correct SID
                $result | Should -Be 'S-1-5-21-1234567890-1234567890-1234567890-1001'

                # Ensure Invoke-Command was called once
                Assert-MockCalled Invoke-Command -Exactly 1
            }
        }

        It 'should return the correct SID for remote execution' {

            InModuleScope -ScriptBlock {

                # Mock Invoke-Command for remote execution
                Mock -CommandName Invoke-Command -MockWith {
                    return 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                # Act: Call the function with a remote ComputerName
                $result = Get-SIDFromUsername -Username 'JohnDoe' -ComputerName 'RemoteComputer'

                # Assert: Verify the result is the correct SID
                $result | Should -Be 'S-1-5-21-1234567890-1234567890-1234567890-1001'

                # Ensure Invoke-Command was called once with remote ComputerName
                Assert-MockCalled Invoke-Command -Exactly 1 -ParameterFilter {
                    $ComputerName -eq 'RemoteComputer'
                }
            }
        }
    }

    Context 'When the username does not exist' {
        It 'should return null and show a warning' {

            InModuleScope -ScriptBlock {

                # Mock Invoke-Command to simulate user not found
                Mock -CommandName Invoke-Command -MockWith {
                    return $null
                }

                # Act: Call the function
                $result = Get-SIDFromUsername -Username 'NonExistentUser'

                # Assert: The result should be null
                $result | Should -BeNullOrEmpty

                # Ensure Invoke-Command was called once
                Assert-MockCalled Invoke-Command -Exactly 1
            }
        }
    }

    Context 'When an error occurs during SID resolution' {
        It 'should return null and display a warning' {

            InModuleScope -ScriptBlock {

                # Mock Invoke-Command to simulate an error
                Mock -CommandName Invoke-Command -MockWith {
                    throw "An unexpected error occurred"
                }

                # Mock Write-Warning to capture the warning
                Mock Write-Warning

                # Act: Call the function
                $result = Get-SIDFromUsername -Username 'JohnDoe'

                # Assert: The result should be null
                $result | Should -BeNullOrEmpty

                # Ensure Write-Warning was called once
                Assert-MockCalled Write-Warning -Exactly 1
            }
        }
    }

    Context 'When SID is missing for the user' {
        It 'should return null and display a warning' {

            InModuleScope -ScriptBlock {

                # Mock Invoke-Command to simulate a user with no SID
                Mock -CommandName Invoke-Command -MockWith {
                    return $null
                }

                # Act: Call the function
                $result = Get-SIDFromUsername -Username 'JohnDoe'

                # Assert: The result should be null
                $result | Should -BeNullOrEmpty

                # Ensure Invoke-Command was called once
                Assert-MockCalled Invoke-Command -Exactly 1
            }
        }
    }

    Context 'When executing for performance' {
        It 'should complete within the acceptable time frame' {

            InModuleScope -ScriptBlock {

                # Mock Invoke-Command for local execution
                Mock -CommandName Invoke-Command -MockWith {
                    return 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                }

                # Act: Measure the time taken for function execution
                $elapsedTime = Measure-Command { Get-SIDFromUsername -Username 'JohnDoe' }

                # Assert: Ensure execution time is less than 1000 milliseconds
                $elapsedTime.TotalMilliseconds | Should -BeLessThan 1000
            }
        }
    }
}
