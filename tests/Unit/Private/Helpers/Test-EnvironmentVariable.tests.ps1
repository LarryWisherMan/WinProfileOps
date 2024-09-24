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

# Unit Tests for Test-EnvironmentVariable
Describe 'Test-EnvironmentVariable' {

    # Context: When the environment variable exists
    Context 'When the environment variable exists' {
        It 'should return the value of the environment variable' {
            InModuleScope -ScriptBlock {
                # Mock the environment variable
                $env:TestVariable = "TestValue"

                # Act: Call the function
                $result = Test-EnvironmentVariable -Name 'TestVariable'

                # Assert: Should return the value of the environment variable
                $result | Should -Be "TestValue"

                # Cleanup: Remove the environment variable
                Remove-Item Env:TestVariable -ErrorAction SilentlyContinue
            }
        }
    }

    # Context: When the environment variable does not exist
    Context 'When the environment variable does not exist' {
        It 'should throw an error indicating the missing environment variable' {
            InModuleScope -ScriptBlock {
                # Ensure the environment variable does not exist
                Remove-Item Env:NonExistentVariable -ErrorAction SilentlyContinue

                # Act & Assert: Call the function and expect an error
                { Test-EnvironmentVariable -Name 'NonExistentVariable' } | Should -Throw "Missing required environment variable: NonExistentVariable"
            }
        }
    }

    # Context: Ensure correct behavior when checking common environment variables
    Context 'When checking common environment variables' {
        It 'should return the value of the Path environment variable if present' {
            InModuleScope -ScriptBlock {
                # Act: Call the function for 'Path' environment variable
                $result = Test-EnvironmentVariable -Name 'Path'

                # Assert: Path environment variable should exist and return its value
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }
}
