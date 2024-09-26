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

Describe 'Invoke-ProfileRegistryItemProcessing Tests' -Tags "Private", "Unit", "ProfileRegistryItems" {

    BeforeAll {
        InModuleScope -Scriptblock {
            # Mock Validate-SIDFormat to return true by default
            Mock -CommandName Validate-SIDFormat -MockWith {
                param($SID)
                return $true
            }

            # Mock Open-RegistrySubKey to return a mock registry subkey object
            Mock -CommandName Open-RegistrySubKey -MockWith {
                param($BaseKey, $Name, $Writable)
                return New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Properties @{
                    Name    = $Name
                    BaseKey = $BaseKey
                }
            }

            # Mock Get-LogonLogoffDatesFromRegistry to return fixed dates
            Mock -CommandName Get-LogonLogoffDatesFromRegistry -MockWith {
                param($SubKey)
                return @{
                    logonDate  = [datetime]'2023-01-01'
                    logoffDate = [datetime]'2023-01-02'
                }
            }

            # Mock Get-ProfileStateFromRegistrySubKey to return 'Active'
            Mock -CommandName Get-ProfileStateFromRegistrySubKey -MockWith {
                param($SubKey)
                return @{
                    StateText = 'Active'
                }
            }

            # Mock Get-ProfilePathFromSID to return a sample path
            Mock -CommandName Get-ProfilePathFromSID -MockWith {
                param($SidKey)
                return @{
                    ProfileImagePath = 'C:\Users\TestUser'
                }
            }

            # Mock Test-FolderExists to return $true
            Mock -CommandName Test-FolderExists -MockWith {
                param($ProfilePath, $ComputerName)
                return $true
            }

            # Mock Test-SpecialAccount to return IsSpecial = $false
            Mock -CommandName Test-SpecialAccount -MockWith {
                param($SID, $FolderName, $ProfilePath)
                return @{
                    IsSpecial = $false
                }
            }

            # Mock Get-UserAccountFromSID to return sample account info
            Mock -CommandName Get-UserAccountFromSID -MockWith {
                param($SID)
                return @{
                    Domain   = 'TestDomain'
                    Username = 'TestUser'
                }
            }

            # Mock New-ProfileRegistryItemObject to return a PSObject with parameters
            Mock -CommandName New-ProfileRegistryItemObject -MockWith {
                param($SID, $ComputerName, $ErrorAccess, $LastLogOnDate, $LastLogOffDate, $ProfileState, $ProfilePath, $IsLoaded, $HasUserFolder, $IsSpecial, $Domain, $UserName)
                return [PSCustomObject]@{
                    SID            = $SID
                    ComputerName   = $ComputerName
                    ErrorAccess    = $ErrorAccess
                    LastLogOnDate  = $LastLogOnDate
                    LastLogOffDate = $LastLogOffDate
                    ProfileState   = $ProfileState
                    ProfilePath    = $ProfilePath
                    IsLoaded       = $IsLoaded
                    HasUserFolder  = $HasUserFolder
                    IsSpecial      = $IsSpecial
                    Domain         = $Domain
                    UserName       = $UserName
                }
            }
        }
    }

    Context 'Positive Tests' {
        It 'Should process valid SID and return profile registry item' {
            InModuleScope -Scriptblock {
                # Arrange
                $Sid = 'S-1-5-21-3623811015-3361044348-30300820-1013'
                $ComputerName = 'TestComputer'
                $ProfileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    OpenSubKey = { param($Name, $Writable); return $null }
                }
                $HKEYUsersSubkeyNames = @($Sid)

                # Act
                $result = Invoke-ProfileRegistryItemProcessing -Sid $Sid -ComputerName $ComputerName -ProfileListKey $ProfileListKey -HKEYUsersSubkeyNames $HKEYUsersSubkeyNames

                # Assert
                $result | Should -Not -BeNullOrEmpty
                $result.SID | Should -Be $Sid
                $result.ComputerName | Should -Be $ComputerName
                $result.ErrorAccess | Should -BeFalse
                $result.LastLogOnDate | Should -Be ([datetime]'2023-01-01')
                $result.LastLogOffDate | Should -Be ([datetime]'2023-01-02')
                $result.ProfileState | Should -Be 'Active'
                $result.ProfilePath | Should -Be 'C:\Users\TestUser'
                $result.IsLoaded | Should -BeTrue
                $result.HasUserFolder | Should -BeTrue
                $result.IsSpecial | Should -BeFalse
                $result.Domain | Should -Be 'TestDomain'
                $result.UserName | Should -Be 'TestUser'
            }
        }

        It 'Should support pipeline input' {
            InModuleScope -Scriptblock {
                # Arrange
                $Sids = @(
                    'S-1-5-21-3623811015-3361044348-30300820-1001',
                    'S-1-5-21-3623811015-3361044348-30300820-1002'
                )
                $ComputerName = 'TestComputer'
                $ProfileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    OpenSubKey = { param($Name, $Writable); return $null }
                }
                $HKEYUsersSubkeyNames = $Sids

                # Act
                $results = $Sids | Invoke-ProfileRegistryItemProcessing -ComputerName $ComputerName -ProfileListKey $ProfileListKey -HKEYUsersSubkeyNames $HKEYUsersSubkeyNames

                # Assert
                $results | Should -Not -BeNullOrEmpty
                $results.Count | Should -Be 2
            }
        }

        It 'It Should process even if no HkeyUsersSubkeyNames are provided' {
            InModuleScope -Scriptblock {
                # Arrange
                $Sid = 'InvalidSIDFormat'
                $ComputerName = 'TestComputer'
                $ProfileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    OpenSubKey = { param($Name, $Writable); return $null }
                }
                $HKEYUsersSubkeyNames = @()

                # Mock Validate-SIDFormat to return false
                Mock -CommandName Validate-SIDFormat -MockWith { param($SID); return $true }

                # Act
                $result = { Invoke-ProfileRegistryItemProcessing -Sid $Sid -ComputerName $ComputerName -ProfileListKey $ProfileListKey -HKEYUsersSubkeyNames $HKEYUsersSubkeyNames } | Should -Not -throw

            }
        }
    }

    Context 'Negative Tests' {
        It 'Should throw error for null SID' {
            InModuleScope -Scriptblock {
                # Arrange
                $ComputerName = 'TestComputer'
                $ProfileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    OpenSubKey = { param($Name, $Writable); return $null }
                }
                $HKEYUsersSubkeyNames = @()

                # Act & Assert
                { Invoke-ProfileRegistryItemProcessing -Sid $null -ComputerName $ComputerName -ProfileListKey $ProfileListKey -HKEYUsersSubkeyNames $HKEYUsersSubkeyNames } | Should -Throw
            }
        }



        It 'Should warn and return when registry key cannot be opened' {
            InModuleScope -Scriptblock {
                # Arrange
                $Sid = 'S-1-5-21-InvalidSID'
                $ComputerName = 'TestComputer'
                $ProfileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    OpenSubKey = { param($Name, $Writable); return $null }
                }
                $HKEYUsersSubkeyNames = @()

                # Mock Open-RegistrySubKey to return $null
                Mock -CommandName Open-RegistrySubKey -MockWith { param($BaseKey, $Name, $Writable); return $null } -Verifiable
                Mock Write-Warning -Verifiable

                # Act
                $result = Invoke-ProfileRegistryItemProcessing -Sid $Sid -ComputerName $ComputerName -ProfileListKey $ProfileListKey -HKEYUsersSubkeyNames $HKEYUsersSubkeyNames

                # Assert
                Should -InvokeVerifiable
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Edge Case Tests' {
        It 'Should handle empty HKEYUsersSubkeyNames array' {
            InModuleScope -Scriptblock {
                # Arrange
                $Sid = 'S-1-5-21-3623811015-3361044348-30300820-1013'
                $ComputerName = 'TestComputer'
                $ProfileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    OpenSubKey = { param($Name, $Writable); return $null }
                }
                $HKEYUsersSubkeyNames = @()

                # Act
                $result = Invoke-ProfileRegistryItemProcessing -Sid $Sid -ComputerName $ComputerName -ProfileListKey $ProfileListKey -HKEYUsersSubkeyNames $HKEYUsersSubkeyNames

                # Assert
                $result.IsLoaded | Should -BeFalse
            }
        }

        It 'Should handle empty profile path' {
            InModuleScope -Scriptblock {
                # Arrange
                $Sid = 'S-1-5-21-3623811015-3361044348-30300820-1013'
                $ComputerName = 'TestComputer'
                $ProfileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    OpenSubKey = { param($Name, $Writable); return $null }
                }
                $HKEYUsersSubkeyNames = @($Sid)

                # Mock Get-ProfilePathFromSID to return $null
                Mock -CommandName Get-ProfilePathFromSID -MockWith {
                    param($SidKey)
                    return @{ ProfileImagePath = $null }
                } -Verifiable

                # Act
                $result = Invoke-ProfileRegistryItemProcessing -Sid $Sid -ComputerName $ComputerName -ProfileListKey $ProfileListKey -HKEYUsersSubkeyNames $HKEYUsersSubkeyNames

                # Assert
                should -InvokeVerifiable
                $result.ProfilePath | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Exception Handling' {
        It 'Should handle UnauthorizedAccessException in try block' {
            InModuleScope -Scriptblock {
                # Arrange
                $Sid = 'S-1-5-21-3623811015-3361044348-30300820-1013'
                $ComputerName = 'TestComputer'
                $ProfileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    OpenSubKey = { param($Name, $Writable); return $null }
                }
                $HKEYUsersSubkeyNames = @($Sid)

                # Mock Test-FolderExists to throw UnauthorizedAccessException
                Mock -CommandName Test-FolderExists -MockWith { throw [UnauthorizedAccessException] 'Access denied' } -Verifiable
                Mock Write-Warning -Verifiable

                # Act
                $result = Invoke-ProfileRegistryItemProcessing -Sid $Sid -ComputerName $ComputerName -ProfileListKey $ProfileListKey -HKEYUsersSubkeyNames $HKEYUsersSubkeyNames

                # Assert
                should -InvokeVerifiable
                $result.ErrorAccess | Should -BeTrue
                $result.HasUserFolder | Should -BeTrue
            }
        }

        It 'Should handle general exceptions and return' {
            InModuleScope -Scriptblock {
                # Arrange
                $Sid = 'S-1-5-21-3623811015-3361044348-30300820-1013'
                $ComputerName = 'TestComputer'
                $ProfileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    OpenSubKey = { param($Name, $Writable); return $null }
                }
                $HKEYUsersSubkeyNames = @($Sid)

                # Mock Get-LogonLogoffDatesFromRegistry to throw exception
                Mock -CommandName Get-LogonLogoffDatesFromRegistry -MockWith { throw 'Error retrieving dates' } -Verifiable
                Mock Write-Warning -Verifiable

                # Act
                $result = Invoke-ProfileRegistryItemProcessing -Sid $Sid -ComputerName $ComputerName -ProfileListKey $ProfileListKey -HKEYUsersSubkeyNames $HKEYUsersSubkeyNames

                # Assert
                Should -InvokeVerifiable
                $result | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Verbose and Debug Logging' {
        It 'Should output verbose messages when verbose switch is provided' {
            InModuleScope -Scriptblock {
                # Arrange
                $Sid = 'S-1-5-21-3623811015-3361044348-30300820-1013'
                $ComputerName = 'TestComputer'
                $ProfileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    OpenSubKey = { param($Name, $Writable); return $null }
                }
                $HKEYUsersSubkeyNames = @($Sid)
                $verboseMessages = @()

                # Mock Write-Verbose to capture messages
                Mock -CommandName Write-Verbose

                # Act
                Invoke-ProfileRegistryItemProcessing -Sid $Sid -ComputerName $ComputerName -ProfileListKey $ProfileListKey -HKEYUsersSubkeyNames $HKEYUsersSubkeyNames -Verbose

                # Assert
                Assert-MockCalled -CommandName Write-Verbose -Times 1 -Scope It -ParameterFilter {
                    $message -eq "Processing SID: $Sid"
                }

                Assert-MockCalled -CommandName Write-Verbose -Times 1 -Scope It -ParameterFilter {
                    $message -eq "Checking for user folder existence: C:\Users\TestUser"
                }
            }
        }
    }

    Context 'Cleanup Tests' {
        It 'Should close registry key after processing' {
            InModuleScope -Scriptblock {
                # Arrange
                $Sid = 'S-1-5-21-3623811015-3361044348-30300820-1013'
                $ComputerName = 'TestComputer'
                $ProfileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    OpenSubKey = { param($Name, $Writable); return $null }
                }
                $HKEYUsersSubkeyNames = @($Sid)

                $mockRegistryKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    GetSubKeyNames = { return @('S-1-5-21-1234567890') }
                    Close          = { $global:RegistryKeyClosed = $true }
                }

                # Mock Open-RegistrySubKey to return an object with a Close method
                Mock -CommandName Open-RegistrySubKey -MockWith {
                    $mockRegistryKey
                }

                # Act
                Invoke-ProfileRegistryItemProcessing -Sid $Sid -ComputerName $ComputerName -ProfileListKey $ProfileListKey -HKEYUsersSubkeyNames $HKEYUsersSubkeyNames

                # Assert
                should -InvokeVerifiable
                $global:RegistryKeyClosed | Should -BeTrue

                # Cleanup
                Remove-Variable -Name RegistryKeyClosed -Scope Global
            }
        }
    }

    Context 'Performance Tests' {
        It 'Should execute within acceptable time' {
            InModuleScope -Scriptblock {
                # Arrange
                $Sid = 'S-1-5-21-3623811015-3361044348-30300820-1013'
                $ComputerName = 'TestComputer'
                $ProfileListKey = New-MockObject -Type 'Microsoft.Win32.RegistryKey' -Methods @{
                    OpenSubKey = { param($Name, $Writable); return $null }
                }
                $HKEYUsersSubkeyNames = @($Sid)

                # Act
                $executionTime = Measure-Command {
                    Invoke-ProfileRegistryItemProcessing -Sid $Sid -ComputerName $ComputerName -ProfileListKey $ProfileListKey -HKEYUsersSubkeyNames $HKEYUsersSubkeyNames
                }

                # Assert
                $executionTime.TotalMilliseconds | Should -BeLessThan 1000
            }
        }
    }
}
