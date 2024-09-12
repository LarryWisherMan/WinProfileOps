BeforeAll {
    $script:dscModuleName = "WinProfileOps"

    # Import the module that contains the function being tested
    Import-Module -Name $script:dscModuleName

    # Set default parameters for the module scope in Pester
    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName
}

AfterAll {
    # Remove the default parameters
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module after the tests are completed
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Validate-SIDFormat Tests' -Tag 'Private' {

    Context 'Valid SID Tests' {
        It 'Should return true for a valid SID S-1-5-18' {
            InModuleScope $script:dscModuleName {
                $result = Validate-SIDFormat -SID 'S-1-5-18'
                $result | Should -Be $true
            }
        }

        It 'Should return true for a valid SID with multiple components S-1-5-21-3623811015-3361044348-30300820-1013' {
            InModuleScope $script:dscModuleName {
                $result = Validate-SIDFormat -SID 'S-1-5-21-3623811015-3361044348-30300820-1013'
                $result | Should -Be $true
            }
        }
    }

    Context 'Invalid SID Tests' {
        It 'Should return false for an invalid SID S-1-5' {
            InModuleScope $script:dscModuleName {
                $result = Validate-SIDFormat -SID 'S-1-5'
                $result | Should -Be $false
            }
        }

        It 'Should return false for an invalid SID S-1-XYZ-18' {
            InModuleScope $script:dscModuleName {
                $result = Validate-SIDFormat -SID 'S-1-XYZ-18'
                $result | Should -Be $false
            }
        }

        It 'Should throw for an empty string' {
            InModuleScope $script:dscModuleName {
                { Validate-SIDFormat -SID '' } | Should -Throw "Cannot bind argument to parameter 'SID' because it is an empty string."
            }
        }
    }

    Context 'Warning Messages' {

        BeforeAll {
            Mock Write-Warning
        }

        It 'Should show a warning for an invalid SID' {
            InModuleScope $script:dscModuleName {
                # Call the function directly
                Validate-SIDFormat -SID 'S-1-5'
                # Assert that Write-Warning was invoked
                Should -Invoke Write-Warning -Exactly 1 -Scope It
            }
        }

        It 'Should not show a warning for a valid SID' {
            InModuleScope $script:dscModuleName {
                # Call the function directly
                Validate-SIDFormat -SID 'S-1-5-18'
                # Assert that Write-Warning was not invoked
                Should -Invoke Write-Warning -Exactly 0 -Scope It
            }
        }
    }
}
