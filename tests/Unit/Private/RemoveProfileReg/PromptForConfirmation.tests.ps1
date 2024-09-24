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

Describe 'PromptForConfirmation' -Tags 'Private', 'Helpers' {

    BeforeEach {
        InModuleScope -ScriptBlock {
            # Mock the ShouldContinueWrapper for testing user confirmation
            Mock ShouldContinueWrapper {
                param($Context, $QueryMessage, $CaptionMessage)
                return $true  # Simulate that the user confirms
            }
        }
    }

    # Test: AuditOnly switch skips the confirmation
    Context 'When AuditOnly is used' {
        It 'Should skip confirmation and return $true' {
            InModuleScope -ScriptBlock {
                # Call the function with AuditOnly switch
                $result = PromptForConfirmation -ComputerName 'Server01' -ItemCount 5 -AuditOnly

                # Validate that the result is true and confirmation is skipped
                $result | Should -Be $true

                # Ensure ShouldContinueWrapper was not called
                Assert-MockCalled ShouldContinueWrapper -Exactly 0 -Scope It
            }
        }
    }

    # Test: Confirm switch prompts for confirmation
    Context 'When Confirm is specified' {
        It 'Should prompt the user for confirmation' {
            InModuleScope -ScriptBlock {

                $mockContext = New-Object -TypeName PSObject

                # Call the function with Confirm switch
                $result = PromptForConfirmation -ComputerName 'Server01' -ItemCount 5 -Confirm -context $mockContext

                # Validate that the result is true, assuming the user confirms
                $result | Should -Be $true

                # Ensure ShouldContinueWrapper was called with the correct parameters
                Assert-MockCalled ShouldContinueWrapper -Exactly 1 -Scope It -ParameterFilter {
                    $QueryMessage -eq "Are you sure you want to delete 5 profiles from Server01's registry?" -and
                    $CaptionMessage -eq "Confirm Deletion"
                }
            }
        }
    }

    # Test: User declines the confirmation
    Context 'When user declines the confirmation' {
        It 'Should return $false when the user declines the prompt' {
            InModuleScope -ScriptBlock {
                # Mock ShouldContinueWrapper to simulate user declining
                Mock ShouldContinueWrapper {
                    return $false  # Simulate that the user declines
                }

                $mockContext = New-Object -TypeName PSObject

                # Call the function with Confirm switch
                $result = PromptForConfirmation -ComputerName 'Server01' -ItemCount 5 -Confirm -context $mockContext
                # Validate that the result is false, since the user declined
                $result | Should -Be $false

                # Ensure ShouldContinueWrapper was called
                Assert-MockCalled ShouldContinueWrapper -Exactly 1 -Scope It
            }
        }
    }

    # Test: No Confirm or AuditOnly specified, should proceed without prompt
    Context 'When neither AuditOnly nor Confirm are specified' {
        It 'Should proceed without prompting and return $true' {
            InModuleScope -ScriptBlock {

                $mockContext = New-Object -TypeName PSObject

                # Call the function without AuditOnly or Confirm
                $result = PromptForConfirmation -ComputerName 'Server01' -ItemCount 5 -context $mockContext

                # Validate that the result is true, proceeding without confirmation
                $result | Should -Be $true

                # Ensure ShouldContinueWrapper was not called
                Assert-MockCalled ShouldContinueWrapper -Exactly 0 -Scope It
            }
        }
    }

    # Test: Confirm is false, should proceed without prompting
    Context 'When Confirm is explicitly set to $false' {
        It 'Should proceed without prompting and return $true' {
            InModuleScope -ScriptBlock {

                $mockContext = New-Object -TypeName PSObject

                # Call the function with Confirm set to false
                $result = PromptForConfirmation -ComputerName 'Server01' -ItemCount 5 -Confirm:$false -context $mockContext

                # Validate that the result is true, proceeding without confirmation
                $result | Should -Be $true

                # Ensure ShouldContinueWrapper was not called
                Assert-MockCalled ShouldContinueWrapper -Exactly 0 -Scope It
            }
        }
    }
}
