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

Describe 'Get-SIDFromUsername' -Tags "Pivate", "Helpers" {
    # Mock the Get-CimInstance cmdlet to simulate different scenarios

    Context 'When the username exists and has a valid SID' {
        It 'should return the correct SID' {

            InModuleScope -ScriptBlock {

                $ComputerName = 'Server01'
                # Mock Get-CimInstance to return a valid SID
                Mock -CommandName Get-CimInstance -MockWith {
                    @{
                        SID = 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                    }
                }

                # Act: Call the function
                $result = Get-SIDFromUsername -Username 'JohnDoe' -ComputerName $ComputerName

                # Assert: Verify the result is the correct SID
                $result | Should -Be 'S-1-5-21-1234567890-1234567890-1234567890-1001'
            }
        }
    }

    Context 'When the username does not exist' {
        It 'should return null and show a warning' {

            InModuleScope -ScriptBlock {
                $ComputerName = 'Server01'

                # Mock Get-CimInstance to return null (user not found)
                Mock -CommandName Get-CimInstance -MockWith { $null }

                # Mock Write-Warning to capture the warning message
                Mock -CommandName Write-Warning

                # Act: Call the function
                $result = Get-SIDFromUsername -Username 'NonExistentUser' -ComputerName $ComputerName

                # Assert: The result should be null
                $result | Should -BeNullOrEmpty

                # Assert: Verify that the warning message was displayed
                Assert-MockCalled -CommandName Write-Warning -Exactly 1 -Scope It
            }
        }
    }

    Context 'When an error occurs while querying' {
        It 'should return null and display a warning with error information' {

            InModuleScope -ScriptBlock {
                $ComputerName = 'Server01'

                # Mock Get-CimInstance to throw an exception
                Mock -CommandName Get-CimInstance -MockWith { throw "WMI query failed" }

                # Mock Write-Warning to capture the warning message
                Mock -CommandName Write-Warning

                # Act: Call the function
                $result = Get-SIDFromUsername -Username 'JohnDoe' -ComputerName $ComputerName

                # Assert: The result should be null
                $result | Should -BeNullOrEmpty

                # Assert: Verify that the warning message was displayed
                Assert-MockCalled -CommandName Write-Warning -Exactly 1 -Scope It

            }
        }
    }

    Context 'When mandatory parameters are missing' {
        It 'should throw a missing parameter error for Username' {

            InModuleScope -ScriptBlock {

                $ComputerName = 'Server01'
                # Act & Assert: Expecting the function to throw an error
                { Get-SIDFromUsername -Username $Null -ComputerName $ComputerName } | Should -Throw

            }
        }

        It 'should default to localhost when ComputerName is missing' {
            InModuleScope -ScriptBlock {
                # Mock Get-CimInstance to return a valid SID when queried with 'localhost'
                Mock -CommandName Get-CimInstance -MockWith {
                    @{
                        SID = 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                    }
                }

                # Act: Call the function without providing ComputerName
                $result = Get-SIDFromUsername -Username 'JohnDoe'

                # Assert: The result should match the mock SID
                $result | Should -Be 'S-1-5-21-1234567890-1234567890-1234567890-1001'

                # Assert: Ensure Get-CimInstance was called with 'localhost'
                Assert-MockCalled -CommandName Get-CimInstance -ParameterFilter { $ComputerName -eq $env:COMPUTERNAME } -Scope It
            }
        }
    }

    Context 'When the SID is missing for a user' {
        It 'should return null and display a warning' {

            InModuleScope -ScriptBlock {


                # Mock Get-CimInstance to return an object without SID
                Mock -CommandName Get-CimInstance -MockWith {
                    @{
                        SID = $null
                    }
                }

                # Mock Write-Warning to capture the warning message
                Mock -CommandName Write-Warning

                $computerName = 'Server01'

                # Act: Call the function
                $result = Get-SIDFromUsername -Username 'JohnDoe' -ComputerName $computerName

                # Assert: The result should be null
                $result | Should -BeNullOrEmpty

                # Assert: Verify that the warning message was displayed
                Assert-MockCalled -CommandName Write-Warning -Exactly 1 -Scope It

            }
        }
    }
}
