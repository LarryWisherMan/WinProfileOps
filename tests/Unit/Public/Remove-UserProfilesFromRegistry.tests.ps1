BeforeAll {
    $script:dscModuleName = "WinProfileOps"

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName

    # Set up environment variables used in the function
    $env:WinProfileOps_RegistryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    $env:WinProfileOps_RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
    $env:WinProfileOps_RegBackUpDirectory = "C:\LHStuff\RegBackUp"
    $env:WinProfileOps_ProfileFolderPath = "$env:SystemDrive\Users"
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Remove-UserProfilesFromRegistry Tests' -Tag 'Public', 'Unit' {

    BeforeAll {
        InModuleScope -ScriptBlock {
            # Mock external dependencies
            Mock Test-EnvironmentVariable -MockWith {
                param ($Name)
                switch ($Name)
                {
                    'WinProfileOps_RegistryPath' { return '\Software\Microsoft\Windows NT\CurrentVersion\ProfileList' }
                    'WinProfileOps_ProfileFolderPath' { return 'C:\Users' }
                    'WinProfileOps_RegistryHive' { return [Microsoft.Win32.RegistryHive]::LocalMachine }
                    default { return $null }
                }
            }

            Mock Resolve-UsernamesToSIDs -MockWith {
                param ($Usernames)
                return @('S-1-5-21-1234567890-1', 'S-1-5-21-1234567890-2')
            }

            Mock Invoke-UserProfileRegRemoval -MockWith {
                param ($ComputerName, $SIDs)
                return $SIDs | ForEach-Object {
                    [pscustomobject]@{
                        Success      = $true
                        SID          = $_
                        ComputerName = $ComputerName
                    }
                }
            }

            Mock PromptForConfirmation -MockWith {
                param ($ComputerName, $ItemCount, $AuditOnly, $Context, $Confirm)
                return $true  # Simulate user confirming action
            }

            Mock -CommandName "ShouldContinueWrapper" -MockWith { }
        }
    }

    Context 'Positive Tests' {

        It 'Should handle valid SIDs input and remove profiles' {

            # Arrange
            $SIDs = @('S-1-5-21-1234567890-1', 'S-1-5-21-1234567890-2')

            # Act
            $result = Remove-UserProfilesFromRegistry -SIDs $SIDs -ComputerName 'Server01'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | should -HaveCount 2
            $result.SID | Should -be $SIDs
            $result.ComputerName | Should -Contain 'Server01'
        }

        It 'Should resolve usernames to SIDs and remove profiles' {
            # Arrange
            $usernames = @('john.doe', 'jane.smith')

            # Act
            $result = Remove-UserProfilesFromRegistry -Usernames $usernames -ComputerName 'Server01'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | should -HaveCount 2
            $result.sid | should -Contain "S-1-5-21-1234567890-1"
            $result.sid | should -Contain "S-1-5-21-1234567890-2"
        }

        It 'Should audit profiles without removing them in AuditOnly mode' {
            # Arrange
            $SIDs = @('S-1-5-21-1234567890-1', 'S-1-5-21-1234567890-2')

            # Act
            $result = Remove-UserProfilesFromRegistry -SIDs $SIDs -ComputerName 'Server01' -AuditOnly

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result | ForEach-Object {
                $_.Success | Should -Be $true
                $_.ComputerName | Should -Be 'Server01'
            }

            Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval  -Times 2 -Scope It -ParameterFilter {
                $AuditOnly -eq $true
            }
        }

        It 'Should return profiles for audit and not remove them' {
            InModuleScope -ScriptBlock {
                # Create mock UserProfile objects for auditing
                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1' `
                    -ProfilePath 'C:\Users\JohnDoe' `
                    -IsOrphaned $false `
                    -OrphanReason $null `
                    -ComputerName 'TestComputer' `
                    -IsSpecial $false `
                    -IsLoaded $false `
                    -UserName 'JohnDoe' `
                    -Domain 'TestDomain'

                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-2' `
                    -ProfilePath 'C:\Users\JaneDoe' `
                    -IsOrphaned $true `
                    -OrphanReason 'MissingRegistryEntry' `
                    -ComputerName 'TestComputer' `
                    -IsSpecial $false `
                    -IsLoaded $false `
                    -UserName 'JaneDoe' `
                    -Domain 'TestDomain'



                Mock -CommandName Invoke-UserProfileRegRemoval {
                    param($SID, $ComputerName, $AuditOnly, $Force)

                    # Prepare the deletion result parameters
                    $deletionResultParams = @{
                        SID             = $SID
                        ProfilePath     = "FakeProfilePath"
                        ComputerName    = $ComputerName
                        DeletionSuccess = $false
                        DeletionMessage = "Profile not removed."
                    }

                    # If in audit mode, output an audit-only result directly to the pipeline and return
                    if ($AuditOnly)
                    {
                        $deletionResultParams.DeletionSuccess = $true
                        $deletionResultParams.DeletionMessage = "Audit only, no deletion performed."
                        New-ProfileDeletionResult @deletionResultParams
                    }

                }

                # Run the function in -AuditOnly mode
                $return = Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -AuditOnly


                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 2 -Scope It -ParameterFilter {
                    $AuditOnly -eq $true -and $force -eq $false
                }

                # Assert that profiles were audited but not removed
                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $AuditOnly -eq $true -and $SID -eq 'S-1-5-21-1234567890-1'
                }

                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $AuditOnly -eq $true -and $SID -eq 'S-1-5-21-1234567890-2'
                }

                # Assert that no profiles were actually removed (simulate no action in Audit mode)
                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 0 -Scope It -ParameterFilter {
                    $Force -eq $true
                }

                # Assert that the function returned the correct profiles for auditing
                foreach ($item in $return)
                {
                    $item.GetType().Name | Should -Be 'ProfileDeletionResult'
                }
                $return.Count | Should -Be $MockUserProfileObjects.Count
            }
        }

        It 'Should call Invoke-UserProfileRegRemoval with UserProfiles' {
            InModuleScope -ScriptBlock {
                # Create mock UserProfile objects using New-UserProfileObject
                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\testuser1' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1002' -ProfilePath 'C:\Users\testuser2' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false

                # Run the function
                $return = Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -Force

                $GroupedProfiles = $MockUserProfileObjects | Group-Object -Property ComputerName

                $Profile1 = ($GroupedProfiles.Group)[0]
                $Profile2 = ($GroupedProfiles.Group)[1]



                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 2 -Scope It

                # Assert that Invoke-UserProfileRegRemoval is called with the UserProfiles
                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $SID -eq $Profile1.SID -and $computerName -eq $Profile1.computerName
                }

                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $SID -eq $Profile2.SID -and $computerName -eq $Profile2.computerName
                }

            }
        }

        It 'Should default to local computer if ComputerName is not provided' {
            InModuleScope -ScriptBlock {

                $SIDs = @('S-1-5-21-1234567890-123456789-123456789-1001')

                # Run the function without specifying ComputerName
                Remove-UserProfilesFromRegistry -SIDs $SIDs -Force

                # Assert that Invoke-UserProfileRegRemoval is called with local computer name
                Assert-MockCalled -CommandName 'Invoke-UserProfileRegRemoval' -Exactly -Times 1 -Scope It -ParameterFilter {
                    $ComputerName -eq $env:COMPUTERNAME
                }
            }
        }

    }

    Context 'Negative Tests' {

        It 'Should throw error if no SIDs can be resolved for provided usernames' {
            # Arrange
            Mock Resolve-UsernamesToSIDs -MockWith { return @() }  # Simulate no SIDs resolved

            # Act & Assert
            { Remove-UserProfilesFromRegistry -Usernames @('unknown.user') } | Should -Throw
        }

        It 'Should throw error if no valid parameters are provided' {
            # Act & Assert
            { Remove-UserProfilesFromRegistry } | Should -Throw
        }

        It "Should throw if empty SIDs array is provided" {
            # Arrange
            $SIDs = @()

            # Act & Assert
            { Remove-UserProfilesFromRegistry -SIDs $SIDs -ComputerName 'Server01' } | Should -Throw
        }

        It "Should throw if empty Usernames array is provided" {
            # Arrange
            $Usernames = @()

            # Act & Assert
            { Remove-UserProfilesFromRegistry -Usernames $Usernames -ComputerName 'Server01' } | Should -Throw
        }

        It "Should throw if empty UserProfiles array is provided" {
            # Arrange
            $UserProfiles = @()

            # Act & Assert
            { Remove-UserProfilesFromRegistry -UserProfiles $UserProfiles -ComputerName 'Server01' } | Should -Throw
        }

        It 'Should throw an error when empty lists are provided' {
            InModuleScope -ScriptBlock {
                $EmptySIDs = @()
                $EmptyUsernames = @()
                $EmptyUserProfiles = @()

                # Run the function with empty SIDs
                { Remove-UserProfilesFromRegistry -SIDs $EmptySIDs -AuditOnly -Force } | Should -Throw

                # Run the function with empty Usernames
                { Remove-UserProfilesFromRegistry -Usernames $EmptyUsernames -AuditOnly -Force } | Should -Throw

                # Run the function with empty UserProfiles
                { Remove-UserProfilesFromRegistry -UserProfiles $EmptyUserProfiles -AuditOnly -Force } | Should -Throw
            }

        }
    }

    Context 'Edge Case Tests' {
        It 'Should handle a single SID input correctly' {
            # Arrange
            $SIDs = @('S-1-5-21-1234567890-1')

            # Act
            $result = Remove-UserProfilesFromRegistry -SIDs $SIDs -ComputerName 'Server01'

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.SID | Should -Contain 'S-1-5-21-1234567890-1'
        }

    }

    Context 'Exception Handling' {

        It 'Should handle errors during profile removal' {
            # Arrange
            Mock Invoke-UserProfileRegRemoval -MockWith { throw "Error removing profile" }

            # Act
            { Remove-UserProfilesFromRegistry -SIDs @('S-1-5-21-1234567890-1') -ComputerName 'Server01' } | Should -Throw
        }
    }

    Context 'Verbose and Debug Logging' {

    }

    Context 'Performance Tests' {

        It 'Should execute within acceptable time for normal inputs' {
            # Arrange
            $SIDs = @('S-1-5-21-1234567890-1', 'S-1-5-21-1234567890-2')

            # Act
            $executionTime = Measure-Command {
                Remove-UserProfilesFromRegistry -SIDs $SIDs -ComputerName 'Server01'
            }

            # Assert
            $executionTime.TotalMilliseconds | Should -BeLessThan 1000
        }
    }

    Context 'Cleanup Tests' {

        It 'Should clean up resources properly after execution' {
            # Assuming no resources are left open after execution
            $SIDs = @('S-1-5-21-1234567890-1', 'S-1-5-21-1234567890-2')

            # Act
            $result = Remove-UserProfilesFromRegistry -SIDs $SIDs -ComputerName 'Server01'

            # Assert
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "Confirmation Tests" {
        It 'Should prompt for confirmation with Confirm:$true even if Force:$true' {
            InModuleScope -ScriptBlock {

                $SIDs = @('S-1-5-21-1234567890-123456789-123456789-1001')
                $computerName = 'TestComputer'

                # Mock ShouldContinueWrapper to simulate confirmation prompt
                Mock -CommandName 'ShouldContinueWrapper' -MockWith { return $true }

                # Mock the confirmation prompt
                Mock -CommandName 'PromptForConfirmation' -MockWith {
                    return ShouldContinueWrapper -Context $PSCmdlet -QueryMessage "Are you sure?" -CaptionMessage "Confirm Deletion"
                }

                # Run the function with Confirm enabled and Force true
                Remove-UserProfilesFromRegistry -SIDs $SIDs -ComputerName $computerName -Force:$true -Confirm:$true

                # Assert that PromptForConfirmation was called
                Assert-MockCalled -CommandName 'ShouldContinueWrapper' -Exactly -Times 1 -Scope It

                # Assert that Invoke-UserProfileRegRemoval was called after confirmation
                Assert-MockCalled -CommandName 'Invoke-UserProfileRegRemoval' -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Confirm -eq $true -and $Force -eq $true -and $ComputerName -eq 'TestComputer'
                }
            }
        }

        It 'Should bypass confirmation with Confirm:$false and Force:$true' {
            InModuleScope -ScriptBlock {

                $SIDs = @('S-1-5-21-1234567890-123456789-123456789-1001')
                $computerName = 'TestComputer'

                # Mock the confirmation prompt, but it shouldn't be called
                Mock -CommandName 'PromptForConfirmation' -MockWith {
                    return $true  # Should not be called
                }

                # Run the function with Confirm disabled and Force true
                Remove-UserProfilesFromRegistry -SIDs $SIDs -ComputerName $computerName -Force:$true -Confirm:$false

                # Assert that PromptForConfirmation was NOT called
                Assert-MockCalled -CommandName 'ShouldContinueWrapper' -Exactly -Times 0 -Scope It

                # Assert that Invoke-UserProfileRegRemoval was called after bypassing confirmation
                Assert-MockCalled -CommandName 'Invoke-UserProfileRegRemoval' -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Confirm -eq $false -and $Force -eq $true -and $ComputerName -eq 'TestComputer'
                }
            }
        }

        It 'Should prompt for confirmation before deleting profiles' {
            InModuleScope -ScriptBlock {

                # Create mock user profile objects
                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1' `
                    -ProfilePath 'C:\Users\JohnDoe' `
                    -IsOrphaned $false `
                    -OrphanReason $null `
                    -ComputerName 'TestComputer' `
                    -IsSpecial $false `
                    -IsLoaded $false `
                    -UserName 'JohnDoe' `
                    -Domain 'TestDomain'

                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-2' `
                    -ProfilePath 'C:\Users\JaneDoe' `
                    -IsOrphaned $true `
                    -OrphanReason 'MissingRegistryEntry' `
                    -ComputerName 'TestComputer' `
                    -IsSpecial $false `
                    -IsLoaded $false `
                    -UserName 'JaneDoe' `
                    -Domain 'TestDomain'

                # Mock ShouldContinueWrapper to simulate user saying "yes"
                Mock -CommandName 'ShouldContinueWrapper' -MockWith { return $true }

                # Mock the confirmation prompt (simulating that confirmation happens)
                Mock -CommandName 'PromptForConfirmation' -MockWith {
                    # Ensure ShouldContinueWrapper is triggered when Confirm is true
                    return ShouldContinueWrapper -Context $PSCmdlet -QueryMessage "Are you sure?" -CaptionMessage "Confirm Deletion"
                }

                # Run the function with Confirm enabled
                Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -Confirm:$true

                # Assert that PromptForConfirmation was called once
                Assert-MockCalled -CommandName 'PromptForConfirmation' -Exactly -Times 1 -Scope It

                # Assert that ShouldContinueWrapper was called once as part of confirmation
                Assert-MockCalled -CommandName 'ShouldContinueWrapper' -Exactly -Times 1 -Scope It

                # Assert that Invoke-UserProfileRegRemoval is called after confirmation
                Assert-MockCalled -CommandName 'Invoke-UserProfileRegRemoval' -Exactly -Times 2 -ParameterFilter {
                    $Confirm -eq $true -and $Force -eq $false
                }
            }
        }


    }
}
