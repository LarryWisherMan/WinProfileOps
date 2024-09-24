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

# Unit Tests for ShouldContinueWrapper
Describe 'ShouldContinueWrapper' {

    # Context: When the user chooses to continue
    Context 'When the user chooses to continue' {
        It 'should return true' {
            InModuleScope -ScriptBlock {
                # Create a mock context and add the ShouldContinue method
                $mockContext = New-Object -TypeName PSObject
                $mockContext | Add-Member -MemberType ScriptMethod -Name ShouldContinue -Value {
                    param($queryMessage, $captionMessage)
                    return $true
                }

                # Act: Call the function
                $result = ShouldContinueWrapper -Context $mockContext -QueryMessage "Are you sure?" -CaptionMessage "Confirm Action"

                # Assert: Should return $true
                $result | Should -Be $true
            }
        }
    }

    # Context: When the user chooses NOT to continue
    Context 'When the user chooses not to continue' {
        It 'should return false' {
            InModuleScope -ScriptBlock {
                # Create a mock context and add the ShouldContinue method
                $mockContext = New-Object -TypeName PSObject
                $mockContext | Add-Member -MemberType ScriptMethod -Name ShouldContinue -Value {
                    param($queryMessage, $captionMessage)
                    return $false
                }

                # Act: Call the function
                $result = ShouldContinueWrapper -Context $mockContext -QueryMessage "Are you sure?" -CaptionMessage "Confirm Action"

                # Assert: Should return $false
                $result | Should -Be $false
            }
        }
    }

    # Context: Ensure parameters are passed correctly
    Context 'When parameters are passed correctly' {
        It 'should pass the QueryMessage and CaptionMessage to ShouldContinue' {
            InModuleScope -ScriptBlock {
                # Variables to capture the passed parameters
                $env:capturedQueryMessage = $null
                $env:capturedCaptionMessage = $null

                # Create a mock context and add the ShouldContinue method
                $mockContext = New-Object -TypeName PSObject

                # Create a mock context and add the ShouldContinue method
                $mockContext = New-Object -TypeName PSObject
                $mockContext | Add-Member -MemberType ScriptMethod -Name ShouldContinue -Value {
                    param($queryMessage, $captionMessage)
                    $env:capturedQueryMessage = $queryMessage
                    $env:capturedCaptionMessage = $captionMessage
                    return $true
                }

                # Act: Call the function
                $result = ShouldContinueWrapper -Context $mockContext -QueryMessage "Are you sure?" -CaptionMessage "Confirm Deletion"

                # Assert: Verify that the parameters were passed correctly
                $result | Should -Be $true

                # Assert: Verify that the parameters were passed correctly
                $env:capturedQueryMessage | Should -Be "Are you sure?"
                $env:capturedCaptionMessage  | Should -Be "Confirm Deletion"

                # Cleanup: Remove the captured variables
                Remove-Item $env:capturedCaptionMessage -Force -ErrorAction SilentlyContinue
                Remove-Item $env:capturedQueryMessage -Force -ErrorAction SilentlyContinue


            }
        }
    }
}
