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

Describe 'New-ProfileDeletionResult' -Tags 'Private', 'UserProfile', 'RemoveUserProfileReg' {

    BeforeEach {
        # Setup any common prerequisites or mocks
        InModuleScope -ScriptBlock {
            # Clear any mocks or global variables if needed
        }
    }

    # Test: Full parameter set
    Context 'When creating a full ProfileDeletionResult object' {
        It 'Should create a ProfileDeletionResult object with all properties' {
            InModuleScope -ScriptBlock {
                # Call the function with all parameters
                $result = New-ProfileDeletionResult -SID 'S-1-5-21-12345' -ProfilePath 'C:\Users\Test1' -DeletionSuccess $true -DeletionMessage 'Profile removed successfully.' -ComputerName 'Server01'

                # Validate the result object
                $result.SID | Should -Be 'S-1-5-21-12345'
                $result.ProfilePath | Should -Be 'C:\Users\Test1'
                $result.DeletionSuccess | Should -Be $true
                $result.DeletionMessage | Should -Be 'Profile removed successfully.'
                $result.ComputerName | Should -Be 'Server01'
            }
        }
    }

    # Test: SuccessOnly parameter set
    Context 'When creating a ProfileDeletionResult with SuccessOnly parameter set' {
        It 'Should create a ProfileDeletionResult object with only SID and DeletionSuccess' {
            InModuleScope -ScriptBlock {
                # Call the function with SID and DeletionSuccess only
                $result = New-ProfileDeletionResult -SID 'S-1-5-21-67890' -DeletionSuccess $false

                # Validate the result object
                $result.SID | Should -Be 'S-1-5-21-67890'
                $result.DeletionSuccess | Should -Be $false
                $result.ProfilePath | Should -BeNullOrEmpty
                $result.DeletionMessage | Should -Be 'Operation failed'
                $result.ComputerName | Should -Be $env:COMPUTERNAME
            }
        }
    }

    # Test: Minimal parameter set
    Context 'When creating a minimal ProfileDeletionResult object' {
        It 'Should create a ProfileDeletionResult object with only SID' {
            InModuleScope -ScriptBlock {
                # Call the function with only SID
                $result = New-ProfileDeletionResult -SID 'S-1-5-21-99999'

                # Validate the result object
                $result.SID | Should -Be 'S-1-5-21-99999'
                $result.DeletionSuccess | Should -Be $false
                $result.ProfilePath | Should -BeNullOrEmpty
                $result.DeletionMessage | Should -Be 'No action performed'
                $result.ComputerName | Should -Be $env:COMPUTERNAME
            }
        }
    }
    # Test: Edge case with no SID provided
    Context 'When creating a ProfileDeletionResult without SID' {
        It 'Should throw an error because SID is mandatory' {
            InModuleScope -ScriptBlock {
                { New-ProfileDeletionResult -DeletionSuccess $true } | Should -Throw -ErrorId 'AmbiguousParameterSet,New-ProfileDeletionResult'
            }
        }
    }
}
