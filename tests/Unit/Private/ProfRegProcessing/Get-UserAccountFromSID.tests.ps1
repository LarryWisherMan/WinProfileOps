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

Describe 'Get-UserAccountFromSID Tests' -Tags "Public", "Unit", "ProfileRegProcessing" {

    BeforeAll {
        InModuleScope -Scriptblock {
            # Mock the System.Security.Principal.SecurityIdentifier .NET class for both local and remote scenarios
            Mock -CommandName New-Object -MockWith {
                New-MockObject -Type 'System.Security.Principal.SecurityIdentifier' -Methods @{
                    Translate = {
                        New-MockObject -Type 'System.Security.Principal.NTAccount' -Properties @{
                            Value = 'DOMAIN\User'
                        }
                    }
                }
            }

            # Mock Invoke-Command to handle local and remote execution
            Mock -CommandName Invoke-Command -MockWith {
                param ($ComputerName, $ScriptBlock, $ArgumentList)

                # Simulate the behavior of the remote execution by returning a mock object
                return [pscustomobject]@{
                    Domain   = 'DOMAIN'
                    Username = 'User'
                }
            }
        }
    }

    Context 'Positive Tests' {
        It 'Should return correct Domain and Username for a valid SID (local execution)' {
            InModuleScope -Scriptblock {
                $result = Get-UserAccountFromSID -SID 'S-1-5-21-1234567890-1234567890-1234567890-1001'

                # Validate the returned PSCustomObject
                $result.SID | Should -Be 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                $result.Domain | Should -Be 'DOMAIN'
                $result.Username | Should -Be 'User'

                # Ensure the mocked Invoke-Command was called for local execution
                Assert-MockCalled -CommandName Invoke-Command -Exactly 1 -ParameterFilter {
                    $ComputerName -eq $env:COMPUTERNAME
                }
            }
        }

        It 'Should return correct Domain and Username for a valid SID (remote execution)' {
            InModuleScope -Scriptblock {
                $result = Get-UserAccountFromSID -SID 'S-1-5-21-1234567890-1234567890-1234567890-1001' -ComputerName 'RemotePC'

                # Validate the returned PSCustomObject
                $result.SID | Should -Be 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                $result.Domain | Should -Be 'DOMAIN'
                $result.Username | Should -Be 'User'

                # Ensure the mocked Invoke-Command was called for remote execution
                Assert-MockCalled -CommandName Invoke-Command -Exactly 1 -ParameterFilter {
                    $ComputerName -eq 'RemotePC'
                }
            }
        }

        It 'Should support pipeline input' {
            InModuleScope -Scriptblock {
                $sids = @('S-1-5-21-1234567890-1234567890-1234567890-1001', 'S-1-5-21-0987654321-0987654321-0987654321-1002')

                $results = $sids | Get-UserAccountFromSID

                # Check the output for each SID
                $results | ForEach-Object {
                    $_.SID | Should -BeIn @('S-1-5-21-1234567890-1234567890-1234567890-1001', 'S-1-5-21-0987654321-0987654321-0987654321-1002')
                    $_.Domain | Should -Be 'DOMAIN'
                    $_.Username | Should -Be 'User'
                }
            }
        }
    }

    Context 'Negative Tests' {
        It 'Should return null for Domain and Username if Invoke-Command fails' {
            InModuleScope -Scriptblock {
                # Mock Invoke-Command to throw an error, simulating a failure
                Mock -CommandName Invoke-Command -MockWith {
                    throw "Invoke-Command failed"
                }

                mock -CommandName Write-Warning

                $result = Get-UserAccountFromSID -SID 'S-1-5-21-1234567890-1234567890-1234567890-1001'

                # Validate the returned PSCustomObject when Invoke-Command fails
                $result.SID | Should -Be 'S-1-5-21-1234567890-1234567890-1234567890-1001'
                $result.Domain | Should -Be $null
                $result.Username | Should -Be $null

                # Ensure that Write-Warning was called with the correct message
                Assert-MockCalled -CommandName Write-Warning -Scope It -Times 1 -ParameterFilter {
                    $Message -eq 'Failed to translate SID: S-1-5-21-1234567890-1234567890-1234567890-1001'
                }
            }
        }

        It 'Should throw an error for null SID input' {
            InModuleScope -Scriptblock {

                { Get-UserAccountFromSID -SID $null } | Should -Throw
            }
        }

        It 'Should throw an error for invalid SID input' {
            InModuleScope -Scriptblock {
                mock Write-Warning
                { Get-UserAccountFromSID -SID "Invalid-SID" } | Should -Throw

                Assert-MockCalled -CommandName Write-Warning -Times 1 -ParameterFilter {
                    $Message -eq "Invalid SID format encountered: 'Invalid-SID'."
                }
            }
        }

        It 'Should throw an error for empty SID input' {
            InModuleScope -Scriptblock {
                { Get-UserAccountFromSID -SID '' } | Should -Throw
            }
        }
    }

    Context 'Edge Case Tests' {
        It 'Should handle a very long SID value' {
            InModuleScope -Scriptblock {
                $longSID = 'S-1-5-21-' + ('1' * 100)  # Very long SID
                $result = Get-UserAccountFromSID -SID $longSID

                $result.SID | Should -Be $longSID
                $result.Domain | Should -Be 'DOMAIN'
                $result.Username | Should -Be 'User'
            }
        }
    }

    Context 'Performance Tests' {
        It 'Should execute within an acceptable time frame' {
            InModuleScope -Scriptblock {
                $elapsedTime = Measure-Command { Get-UserAccountFromSID -SID 'S-1-5-21-1234567890-1234567890-1234567890-1001' }
                $elapsedTime.TotalMilliseconds | Should -BeLessThan 1000
            }
        }
    }
}
