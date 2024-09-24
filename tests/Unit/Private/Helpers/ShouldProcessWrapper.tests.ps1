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

# Unit Tests for ShouldProcessWrapper
Describe 'ShouldProcessWrapper' {

    # Context: When the user chooses to proceed
    Context 'When the user chooses to proceed' {
        It 'should return true when user confirms action' {
            InModuleScope -ScriptBlock {
                # Create a mock context and add the ShouldProcess method
                $mockContext = New-Object -TypeName PSObject
                $mockContext | Add-Member -MemberType ScriptMethod -Name ShouldProcess -Value {
                    param($target, $actionMessage)
                    return $true
                }

                # Act: Call the function
                $result = ShouldProcessWrapper -Context $mockContext -Target "Server01" -ActionMessage "Delete profiles"

                # Assert: Should return $true
                $result | Should -Be $true
            }
        }
    }

    # Context: When the user chooses NOT to proceed
    Context 'When the user chooses not to proceed' {
        It 'should return false when user declines action' {
            InModuleScope -ScriptBlock {
                # Create a mock context and add the ShouldProcess method
                $mockContext = New-Object -TypeName PSObject
                $mockContext | Add-Member -MemberType ScriptMethod -Name ShouldProcess -Value {
                    param($target, $actionMessage)
                    return $false
                }

                # Act: Call the function
                $result = ShouldProcessWrapper -Context $mockContext -Target "Server01" -ActionMessage "Delete profiles"

                # Assert: Should return $false
                $result | Should -Be $false
            }
        }
    }

    # Context: Ensure parameters are passed correctly
    Context 'When parameters are passed correctly' {
        It 'should pass the Target and ActionMessage to ShouldProcess' {
            InModuleScope -ScriptBlock {
                # Setup environment variables to capture the passed parameters
                $env:capturedTarget = $null
                $env:capturedActionMessage = $null

                # Create a mock context and add the ShouldProcess method
                $mockContext = New-Object -TypeName PSObject
                $mockContext | Add-Member -MemberType ScriptMethod -Name ShouldProcess -Value {
                    param($target, $actionMessage)
                    $env:capturedTarget = $target
                    $env:capturedActionMessage = $actionMessage
                    return $true
                }

                # Act: Call the function
                $result = ShouldProcessWrapper -Context $mockContext -Target "C:\Temp\File.txt" -ActionMessage "Remove the file"

                # Assert: Should return $true
                $result | Should -Be $true

                # Assert: Verify that the parameters were passed correctly
                $env:capturedTarget | Should -Be "C:\Temp\File.txt"
                $env:capturedActionMessage | Should -Be "Remove the file"

                # Cleanup: Remove the environment variables
                Remove-Item Env:capturedTarget, Env:capturedActionMessage -ErrorAction SilentlyContinue
            }
        }
    }
}
