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

<#
Describe 'Remove-UserProfilesFromRegistry'  -Tag 'Public' {

    # Mock the environment variables and helper functions
    BeforeEach {

        InModuleScope -ScriptBlock {

            #Mock -CommandName Test-EnvironmentVariable -MockWith { return 'SomePath' }
            Mock -CommandName Invoke-UserProfileRegRemoval {

            }

            Mock -CommandName 'PromptForConfirmation' -MockWith {
                param ($ComputerName, $ItemCount, $AuditOnly, $Confirm)
                return $Confirm
            }

            Mock -CommandName Get-SIDFromUsername -MockWith {
                param($Username, $ComputerName)

                # Simulating behavior: Return SIDs for known users, $null for unknown users
                switch ($Username)
                {
                    'testuser1'
                    {
                        return 'S-1-5-21-1234567890-123456789-123456789-1001'
                    }
                    'testuser2'
                    {
                        return 'S-1-5-21-1234567890-123456789-123456789-1002'
                    }
                    default
                    {
                        return $null
                    }  # Simulate unresolved users
                }
            }

            Mock -CommandName Resolve-UsernamesToSIDs -MockWith {
                param($Usernames, $ComputerName)

                $SIDs = $Usernames | ForEach-Object {
                    Get-SIDFromUsername -Username $_
                }

                return $SIDs
            }

            #Mock -CommandName 'PromptForConfirmation' -MockWith { return $true }

            Mock -CommandName "ShouldContinueWrapper" -MockWith { }

            Mock Invoke-UserProfileAudit {
                param($IgnoreSpecial, $computerName)

                $objects = @()
                $objects += New-UserProfileObject -SID "S-1-5-21-1234567890-1003" -ProfilePath "$env:SystemDrive\Users\TestUserSpecial" -IsOrphaned $false -ComputerName $computerName -IsSpecial $true
                $objects += New-UserProfileObject -SID "S-1-5-21-1234567890-1001" -ProfilePath "$env:SystemDrive\Users\TestUser1" -IsOrphaned $false -ComputerName $computerName -IsSpecial $false
                $objects += New-UserProfileObject -SID "S-1-5-21-1234567890-1002" -ProfilePath "$env:SystemDrive\Users\TestUser2" -IsOrphaned $false -ComputerName $computerName -IsSpecial $false
                if ($IgnoreSpecial)
                {
                    return $objects | Where-Object { $_.IsSpecial -eq $false }
                }
                else
                {
                    return $objects
                }
            }

        } -ModuleName $script:dscModuleName
    }


    ### Input Tests ###
    Context 'Using SIDSet' {
        It 'Should call Invoke-UserProfileRegRemoval when using SIDSet' {
            $SIDs = @('S-1-5-21-1234567890-123456789-123456789-1001')
            $computerName = 'TestComputer'

            # Run the function
            $Return = Remove-UserProfilesFromRegistry -SIDs $SIDs -ComputerName $computerName -Force

            # Assert that Invoke-UserProfileRegRemoval is called with the correct parameters
            Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                $SIDs -contains 'S-1-5-21-1234567890-123456789-123456789-1001'
            }
        }

        It 'Should call Invoke-UserProfileRegRemoval in audit mode when using SIDSet' {
            $SIDs = @('S-1-5-21-1234567890-123456789-123456789-1001')
            $computerName = 'TestComputer'

            # Run the function
            $Return = Remove-UserProfilesFromRegistry -SIDs $SIDs -AuditOnly -ComputerName $computerName -Force

            # Assert that Invoke-UserProfileRegRemoval is called in audit mode
            Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                $AuditOnly -eq $true -and $SIDs -contains 'S-1-5-21-1234567890-123456789-123456789-1001'
            }
        }

        It 'Should process multiple SIDs correctly' {
            InModuleScope -ScriptBlock {

                $SIDs = @('S-1-5-21-1234567890-123456789-123456789-1001', 'S-1-5-21-1234567890-123456789-123456789-1002')
                $computerName = 'TestComputer'

                # Run the function
                Remove-UserProfilesFromRegistry -SIDs $SIDs -ComputerName $computerName -Force

                # Assert that Invoke-UserProfileRegRemoval is called for both SIDs
                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 2 -Scope It -ParameterFilter {
                    $SIDs -contains 'S-1-5-21-1234567890-123456789-123456789-1001' -or $SIDs -contains 'S-1-5-21-1234567890-123456789-123456789-1002' -and $ComputerName -eq 'TestComputer'
                }

            }
        }

        It 'Should prompt for confirmation with Confirm:$true even if Force:$true' {
            InModuleScope -ScriptBlock {

                $SIDs = @('S-1-5-21-1234567890-123456789-123456789-1001')
                $computerName = 'TestComputer'

                # Mock ShouldContinueWrapper to simulate confirmation prompt
                Mock -CommandName 'ShouldContinueWrapper' -MockWith { return $true }

                # Mock the confirmation prompt for both computers
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

                Mock -CommandName 'PromptForConfirmation' -MockWith {
                    return $true
                }

                # Run the function with Confirm disabled and Force true
                Remove-UserProfilesFromRegistry -SIDs $SIDs -ComputerName $computerName -Force:$true -Confirm:$false


                # Assert that PromptForConfirmation was not called
                Assert-MockCalled -CommandName 'ShouldContinueWrapper' -Exactly -Times 0 -Scope It

                # Assert that Invoke-UserProfileRegRemoval was called after bypassing confirmation
                Assert-MockCalled -CommandName 'Invoke-UserProfileRegRemoval' -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Confirm -eq $false -and $Force -eq $true -and $ComputerName -eq 'TestComputer'
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

    Context 'Using UserNameSet' {
        It 'Should resolve usernames to SIDs and call Invoke-UserProfileRegRemoval' {
            $Usernames = @('testuser1', 'testuser2')
            $computerName = 'TestComputer'
            $ExpectedSIDs = @('S-1-5-21-1234567890-123456789-123456789-1001', 'S-1-5-21-1234567890-123456789-123456789-1002')

            # Run the function
            $return = Remove-UserProfilesFromRegistry -Usernames $Usernames -ComputerName $computerName -Force

            # Assert that Resolve-UsernamesToSIDs was called
            should -Invoke -CommandName Resolve-UsernamesToSIDs -Exactly -Times 1 -Scope It -ParameterFilter {
                $Usernames -contains 'testuser1' -and $Usernames -contains 'testuser2'
            }

            # Assert that Invoke-UserProfileRegRemoval is called with resolved SIDs
            should -Invoke -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                $SID -eq 'S-1-5-21-1234567890-123456789-123456789-1001'
            }

            should -Invoke -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                $SID -eq 'S-1-5-21-1234567890-123456789-123456789-1002'
            }

            should -Invoke -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 2 -Scope It

        }

        It 'Should resolve usernames to SIDs and audit profiles without deletion' {
            $Usernames = @('testuser1', 'testuser2')
            $computerName = 'TestComputer'
            $ExpectedSIDs = @('S-1-5-21-1234567890-123456789-123456789-1001', 'S-1-5-21-1234567890-123456789-123456789-1002')

            # Run the function
            $return = Remove-UserProfilesFromRegistry -Usernames $Usernames -AuditOnly -ComputerName $computerName -Force

            # Assert that Resolve-UsernamesToSIDs was called
            should -Invoke -CommandName Resolve-UsernamesToSIDs -Exactly -Times 1 -Scope It -ParameterFilter {
                $Usernames -contains 'testuser1' -and $Usernames -contains 'testuser2'
            }

            # Assert that Invoke-UserProfileRegRemoval was called in audit mode
            should -Invoke -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                $AuditOnly -eq $true -and $SID -eq 'S-1-5-21-1234567890-123456789-123456789-1001'
            }
        }

        It 'Should Call Resolve-UserNamesToSIDs when Usernames are provided' {
            $Usernames = @('testuser1', 'testuser2')
            $computerName = 'TestComputer'
            $ExpectedSIDs = @('S-1-5-21-1234567890-123456789-123456789-1001', 'S-1-5-21-1234567890-123456789-123456789-1002')

            # Run the function
            $return = Remove-UserProfilesFromRegistry -Usernames $Usernames -ComputerName $computerName -Force

            # Assert that Resolve-UsernamesToSIDs was called
            should -Invoke -CommandName Resolve-UsernamesToSIDs -Exactly -Times 1 -Scope It -ParameterFilter {
                $Usernames -contains 'testuser1' -and $Usernames -contains 'testuser2'
            }
        }


        It 'Should handle partial resolution of usernames' {
            $Usernames = @('testuser1', 'unknownuser')
            $computerName = 'TestComputer'
            $ExpectedSIDs = @('S-1-5-21-1234567890-123456789-123456789-1001')

            # Run the function
            $return = Remove-UserProfilesFromRegistry -Usernames $Usernames -ComputerName $computerName -Force

            # Assert that Resolve-UsernamesToSIDs was called
            should -Invoke -CommandName Resolve-UsernamesToSIDs -Exactly -Times 1

            # Assert that Invoke-UserProfileRegRemoval is called with resolved SIDs only
            should -Invoke -CommandName Invoke-UserProfileRegRemoval  -Exactly -Times 1 -Scope It -ParameterFilter {
                $SID -eq 'S-1-5-21-1234567890-123456789-123456789-1001'
            }


            should -Invoke -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 0 -Scope It -ParameterFilter {
                $SID -eq $null
            }

        }

        It 'Should handle invalid usernames gracefully' {
            $Usernames = @('invaliduser1', 'invaliduser2')
            $computerName = 'TestComputer'

            # Mock Resolve-UsernamesToSIDs to return $null for invalid users
            Mock -CommandName Resolve-UsernamesToSIDs -MockWith { return @() }

            # Run the function
            $return = Remove-UserProfilesFromRegistry -Usernames $Usernames -ComputerName $computerName -Force -ErrorAction SilentlyContinue

            # Assert that Resolve-UsernamesToSIDs was called and returned $null
            Assert-MockCalled -CommandName Resolve-UsernamesToSIDs -Exactly -Times 1 -Scope It

            # Assert that Invoke-UserProfileRegRemoval was not called since no SIDs were resolved
            Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 0 -Scope It
        }

        It 'Should throw an error if an empty username array is provided' {
            $Usernames = @()
            $computerName = 'TestComputer'

            # Run the function with an empty username array and ensure it throws
            { Remove-UserProfilesFromRegistry -Usernames $Usernames -ComputerName $computerName -Force } | Should -Throw
        }

        It 'Should prompt for confirmation with Confirm:$true even if Force:$true' {
            InModuleScope -ScriptBlock {
                $Usernames = @('testuser1')
                $computerName = 'TestComputer'
                # Mock ShouldContinueWrapper to simulate confirmation prompt
                Mock -CommandName 'ShouldContinueWrapper' -MockWith { return $true }

                # Mock the confirmation prompt
                Mock -CommandName 'PromptForConfirmation' -MockWith {
                    return ShouldContinueWrapper -Context $PSCmdlet -QueryMessage "Are you sure?" -CaptionMessage "Confirm Deletion"
                }

                # Run the function with Confirm enabled and Force true
                Remove-UserProfilesFromRegistry -Usernames $Usernames -ComputerName $computerName -Force:$true -Confirm:$true

                # Assert that PromptForConfirmation was called
                Assert-MockCalled -CommandName 'PromptForConfirmation' -Exactly -Times 1 -Scope It

                # Assert that Invoke-UserProfileRegRemoval was called after confirmation
                Assert-MockCalled -CommandName 'Invoke-UserProfileRegRemoval' -Exactly -Times 1 -Scope It

            }
        }

        It 'Should bypass confirmation with Confirm:$false and Force:$true' {

            InModuleScope -ScriptBlock {

                $Usernames = @('testuser1')
                $computerName = 'TestComputer'

                # Mock the confirmation prompt to ensure it's not called
                Mock -CommandName 'PromptForConfirmation' -MockWith {
                    param($ComputerName, $ItemCount, $AuditOnly, $Confirm, $context)
                    if ($confirm)
                    {
                        return ShouldContinueWrapper -Context $context -QueryMessage "Are you sure?" -CaptionMessage "Confirm Deletion"
                    }
                    else
                    {
                        return $true
                    }
                }

                # Run the function with Confirm disabled and Force true
                Remove-UserProfilesFromRegistry -Usernames $Usernames -ComputerName $computerName -Force:$true -Confirm:$false

                # Assert that PromptForConfirmation was not called
                Assert-MockCalled -CommandName 'PromptForConfirmation' -Exactly -Times 1 -Scope It

                # Assert that PromptForConfirmation was called
                Assert-MockCalled -CommandName 'ShouldContinueWrapper' -Exactly -Times 0 -Scope It

                # Assert that Invoke-UserProfileRegRemoval was called after bypassing confirmation
                Assert-MockCalled -CommandName 'Invoke-UserProfileRegRemoval' -Exactly -Times 1 -Scope It

            }
        }


        It 'Should default to local computer if ComputerName is not provided' {
            $Usernames = @('testuser1')

            # Run the function without specifying ComputerName
            Remove-UserProfilesFromRegistry -Usernames $Usernames -Force

            # Assert that Invoke-UserProfileRegRemoval is called with local computer name
            Assert-MockCalled -CommandName 'Invoke-UserProfileRegRemoval' -Exactly -Times 1 -Scope It -ParameterFilter {
                $ComputerName -eq $env:COMPUTERNAME
            }
        }



    }

    Context 'Using UserProfileSet' {

        It 'Should prompt for confirmation before deleting profiles' {
            InModuleScope -ScriptBlock {

                # Create mock user profile objects
                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\testuser1' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false

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
                Assert-MockCalled -CommandName 'Invoke-UserProfileRegRemoval' -Exactly -Times 1 -ParameterFilter {
                    $Confirm -eq $true -and $Force -eq $false
                }

            }
        }


        It 'Should bypass confirmation and delete profiles with -Force -Confirm:$false' {
            InModuleScope -ScriptBlock {

                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\testuser1' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false

                Mock -CommandName 'PromptForConfirmation' -MockWith {
                    param($ComputerName, $ItemCount, $AuditOnly, $Confirm, $context)
                    if ($confirm)
                    {
                        return ShouldContinueWrapper -Context $context -QueryMessage "Are you sure?" -CaptionMessage "Confirm Deletion"
                    }
                    else
                    {
                        return $true
                    }
                }

                # Run the function with Confirm enabled
                Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -Force:$true -Confirm:$false

                # Assert that PromptForConfirmation was called
                Assert-MockCalled -CommandName 'ShouldContinueWrapper' -Exactly -Times 0 -Scope It

                # Assert that Invoke-UserProfileRegRemoval is called after confirmation
                Assert-MockCalled -CommandName 'Invoke-UserProfileRegRemoval' -Exactly -Times 1

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

        It 'Should call Invoke-UserProfileRegRemoval in audit mode with UserProfiles' {

            InModuleScope -ScriptBlock {
                # Create mock UserProfile objects using New-UserProfileObject
                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\testuser1' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1002' -ProfilePath 'C:\Users\testuser2' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false

                # Run the function
                # Run the function
                $return = Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -AuditOnly

                $GroupedProfiles = $MockUserProfileObjects | Group-Object -Property ComputerName

                $Profile1 = ($GroupedProfiles.Group)[0]
                $Profile2 = ($GroupedProfiles.Group)[1]



                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 2 -Scope It -ParameterFilter {
                    $AuditOnly -eq $true
                }

                # Assert that Invoke-UserProfileRegRemoval is called with the UserProfiles
                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $SID -eq $Profile1.SID -and $computerName -eq $Profile1.computerName -and $AuditOnly -eq $true
                }

                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $SID -eq $Profile2.SID -and $computerName -eq $Profile2.computerName
                }

            }
        }

        It 'Should group UserProfiles by ComputerName and call processing per group' {
            InModuleScope -ScriptBlock {
                # Create mock UserProfile objects using New-UserProfileObject
                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\testuser1' -IsOrphaned $false -ComputerName 'TestComputer2' -IsSpecial:$false
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1002' -ProfilePath 'C:\Users\testuser2' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false


                # Run the function
                $return = Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -Force

                # Assert that Invoke-UserProfileRegRemoval is called for each computer
                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 2 -Scope It

                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $ComputerName -eq 'TestComputer1'
                }

                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $ComputerName -eq 'TestComputer2'
                }


            }
        }

        It 'Should process profiles grouped by ComputerName' {
            InModuleScope -ScriptBlock {
                # Create mock UserProfile objects for different computers
                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\testuser1' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1002' -ProfilePath 'C:\Users\testuser2' -IsOrphaned $false -ComputerName 'TestComputer2' -IsSpecial:$false

                # Run the function
                $return = Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -Force

                # Assert that Invoke-UserProfileRegRemoval is called for each computer
                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 2 -Scope It

                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $ComputerName -eq 'TestComputer1'
                }

                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $ComputerName -eq 'TestComputer2'
                }
            }
        }

        It 'Should prompt and process profiles for each unique computer' {
            InModuleScope -ScriptBlock {

                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\testuser1' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1002' -ProfilePath 'C:\Users\testuser2' -IsOrphaned $false -ComputerName 'TestComputer2' -IsSpecial:$false

                # Mock ShouldContinueWrapper to simulate the prompt and user saying "yes"
                Mock -CommandName 'ShouldContinueWrapper' -MockWith { return $true }

                # Mock the confirmation prompt for both computers
                Mock -CommandName 'PromptForConfirmation' -MockWith {
                    return ShouldContinueWrapper -Context $PSCmdlet -QueryMessage "Are you sure?" -CaptionMessage "Confirm Deletion"
                }

                # Run the function
                $return = Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -Confirm:$true

                # Assert that confirmation prompt was shown for both computers
                Assert-MockCalled -CommandName 'PromptForConfirmation' -Exactly -Times 2 -Scope It

                # Assert that profiles were processed for both computers
                Assert-MockCalled -CommandName 'Invoke-UserProfileRegRemoval' -Exactly -Times 2 -ParameterFilter {
                    $Computername -eq 'TestComputer1' -or $Computername -eq 'TestComputer2'
                }
            }
        }

        It 'Should process single profile for a computer correctly' {
            InModuleScope -ScriptBlock {
                # Create mock UserProfile object for one computer
                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\testuser1' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false

                # Run the function
                $return = Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -Force

                # Assert that Invoke-UserProfileRegRemoval is called once for the computer
                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $ComputerName -eq 'TestComputer1'
                }
            }
        }
    }


    ### Mode Tests ###
    Context 'Audit Mode' {
        It 'Should return profiles for audit and not remove them' {
            InModuleScope -ScriptBlock {
                # Create mock UserProfile objects for auditing
                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\testuser1' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1002' -ProfilePath 'C:\Users\testuser2' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false



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
                    $AuditOnly -eq $true -and $SID -eq 'S-1-5-21-1234567890-1001'
                }

                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $AuditOnly -eq $true -and $SID -eq 'S-1-5-21-1234567890-1002'
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

        It 'Should bypass deletion and only audit when AuditOnly is set' {
            InModuleScope -ScriptBlock {

                # Create mock user profile objects
                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\testuser1' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false

                # Mock Invoke-UserProfileRegRemoval to simulate audit mode
                Mock -CommandName 'Invoke-UserProfileRegRemoval' -MockWith {
                    param($SID, $ComputerName, $AuditOnly, $Force)
                    New-ProfileDeletionResult -SID $SID -ProfilePath "FakePath" -DeletionSuccess $false -DeletionMessage "Audit mode" -ComputerName $ComputerName
                }

                # Run the function in audit mode
                $Return = Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -AuditOnly

                # Assert that no deletion was attempted
                Assert-MockCalled -CommandName 'Invoke-UserProfileRegRemoval' -Exactly -Times 1 -ParameterFilter {
                    $AuditOnly -eq $true
                }

                # Ensure the returned result contains audit information
                $Return[0].DeletionMessage | Should -Be 'Audit mode'
            }
        }
    }

    ### Error Handling ###
    Context "Error Tests" {

        It 'Should throw error if no SIDs, Usernames, or UserProfiles are provided' {
            $computerName = "TestComputer"
            { Remove-UserProfilesFromRegistry -ComputerName $computerName -Force } | Should -Throw
        }

        It 'Should throw empty SIDs array' {

            $computerName = "TestComputer"
            $SIDs = @()
            { Remove-UserProfilesFromRegistry -SIDs $SIDs -ComputerName $computerName -Force } | Should  -Throw
        }

        It 'Should throw empty Usernames array' {
            $computerName = "TestComputer"
            $Usernames = @()
            { Remove-UserProfilesFromRegistry -Usernames $Usernames -ComputerName $computerName -Force } | Should  -Throw
        }

        It 'Should throw empty UserProfiles array' {
            $computerName = "TestComputer"
            $UserProfiles = @()
            { Remove-UserProfilesFromRegistry -UserProfiles $UserProfiles -ComputerName $computerName -Force } | Should  -Throw
        }

        It 'Should handle exceptions thrown during profile removal' {
            InModuleScope -ScriptBlock {
                # Mock UserProfile objects
                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\testuser' -IsOrphaned $false -ComputerName 'TestComputer' -IsSpecial:$false

                mock Write-Error

                # Mock Invoke-UserProfileRegRemoval to throw an error
                Mock -CommandName Invoke-UserProfileRegRemoval -MockWith { throw "Test exception" }

                # Run the function and catch the error
                { Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -Force } | Should -not -Throw


                # Assert that Write-Error was called
                Assert-MockCalled -CommandName Write-Error -Exactly -Times 1 -Scope It


                # Optionally, check if the function handled the error gracefully
                # Assert that an appropriate error message is logged or returned
            }
        }

        It 'Should throw an error if no UserProfiles, SIDs, or Usernames are provided' {
            $computerName = "TestComputer"
            { Remove-UserProfilesFromRegistry -ComputerName $computerName -Force } | Should -Throw
        }


    }

    ### Large Input Sets ###
    Context 'Large Input Sets - Maximum Profiles' {
        It 'Should process a large number of profiles without errors' {
            InModuleScope -ScriptBlock {
                # Mock a large number of UserProfile objects
                $MockUserProfileObjects = 1..100 | ForEach-Object {
                    New-UserProfileObject -SID "S-1-5-21-1234567890-$_" -ProfilePath "C:\Users\testuser$_" -IsOrphaned $false -ComputerName 'TestComputer' -IsSpecial:$false
                }

                # Run the function
                $return = Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -Force

                # Assert that all profiles were processed without errors
                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 100
            }
        }
    }

}
#>

Describe 'Remove-UserProfilesFromRegistry Tests' -Tag 'Public', 'Unit', 'UserProfileAudit' {

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




<#
        It 'Should call Invoke-UserProfileRegRemoval in audit mode with UserProfiles' {

            InModuleScope -ScriptBlock {
                # Create mock UserProfile objects using New-UserProfileObject
                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\testuser1' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1002' -ProfilePath 'C:\Users\testuser2' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false

                # Run the function
                $return = Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -Force -AuditOnly

                $GroupedProfiles = $MockUserProfileObjects | Group-Object -Property ComputerName

                $ProfilesGroup = ($GroupedProfiles.Group)[0]


                # Assert that Invoke-UserProfileRegRemoval is called with the UserProfiles
                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $Profiles -contains $MockUserProfileObjects[0] `
                        -and $Profiles -contains $MockUserProfileObjects[1] `
                        -and $computerName -eq "TestComputer1" -and $AuditOnly -eq $true
                }

            }
        }

        It 'Should group UserProfiles by ComputerName and call processing per group' {
            InModuleScope -ScriptBlock {
                # Create mock UserProfile objects using New-UserProfileObject
                $MockUserProfileObjects = @()
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1001' -ProfilePath 'C:\Users\testuser1' -IsOrphaned $false -ComputerName 'TestComputer2' -IsSpecial:$false
                $MockUserProfileObjects += New-UserProfileObject -SID 'S-1-5-21-1234567890-1002' -ProfilePath 'C:\Users\testuser2' -IsOrphaned $false -ComputerName 'TestComputer1' -IsSpecial:$false


                # Run the function
                $return = Remove-UserProfilesFromRegistry -UserProfiles $MockUserProfileObjects -Force

                # Assert that Invoke-UserProfileRegRemoval is called for each computer
                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 2 -Scope It

                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $ComputerName -eq 'TestComputer1'
                }

                Assert-MockCalled -CommandName Invoke-UserProfileRegRemoval -Exactly -Times 1 -Scope It -ParameterFilter {
                    $ComputerName -eq 'TestComputer2'
                }


            }
        }


    }

    Context "Error Tests" {

        It 'Should throw error if no SIDs, Usernames, or UserProfiles are provided' {
            { Remove-UserProfilesFromRegistry -ComputerName 'TestComputer' -Force } | Should -Throw
        }


    }

    Context "Empty Input Tests" {

        It 'Should throw empty SIDs array' {
            $SIDs = @()
            { Remove-UserProfilesFromRegistry -SIDs $SIDs -ComputerName 'TestComputer' -Force } | Should  -Throw
        }

        It 'Should throw empty Usernames array gracefully' {
            $Usernames = @()
            { Remove-UserProfilesFromRegistry -Usernames $Usernames -ComputerName 'TestComputer' -Force } | Should  -Throw
        }

        It 'Should throw empty UserProfiles array gracefully' {
            $UserProfiles = @()
            { Remove-UserProfilesFromRegistry -UserProfiles $UserProfiles -ComputerName 'TestComputer' -Force } | Should  -Throw
        }


    }

}




    BeforeEach {

        InModuleScope -scriptblock {

            # Mock necessary functions
            Mock Get-DirectoryPath { "C:\LHStuff\RegBackUp" }
            Mock Test-DirectoryExistence { $true }
            Mock Open-RegistryKey { New-MockObject -Type Microsoft.Win32.RegistryKey -Methods @{ Dispose = {} } }
            Mock Invoke-UserProfileAudit {
                param($IgnoreSpecial, $computerName)

                $objects = @()
                $objects += New-UserProfileObject -SID "S-1-5-21-1234567890-1003" -ProfilePath "$env:SystemDrive\Users\TestUserSpecial" -IsOrphaned $false -ComputerName $computerName -IsSpecial $true
                $objects += New-UserProfileObject -SID "S-1-5-21-1234567890-1001" -ProfilePath "$env:SystemDrive\Users\TestUser1" -IsOrphaned $false -ComputerName $computerName -IsSpecial $false
                $objects += New-UserProfileObject -SID "S-1-5-21-1234567890-1002" -ProfilePath "$env:SystemDrive\Users\TestUser2" -IsOrphaned $false -ComputerName $computerName -IsSpecial $false
                if ($IgnoreSpecial)
                {
                    return $objects | Where-Object { $_.IsSpecial -eq $false }
                }
                else
                {
                    return $objects
                }
            }

            Mock Invoke-UserProfileRegRemoval {
                param($ComputerName, $SIDs, $Profiles, $RegistryPath, $ProfileFolderPath, $RegistryHive, $Force, $AuditOnly, $Confirm)

                # Initialize $deletionResults as an empty array
                $deletionResults = @()

                if ($SIDs)
                {
                    foreach ($SID in $SIDs)
                    {
                        Invoke-SingleProfileAction -SID $SID -AuditResults $null -ComputerName $ComputerName -BaseKey $null -Force:$Force -AuditOnly:$AuditOnly -DeletionResults ([ref]$deletionResults) -Confirm:$Confirm
                    }
                }
                if ($Profiles)
                {
                    foreach ($Profile in $Profiles)
                    {
                        Invoke-SingleProfileAction -SID $Profile.SID -AuditResults $null -SelectedProfile $Profile -ComputerName $ComputerName -BaseKey $null -Force:$Force -AuditOnly:$AuditOnly -DeletionResults ([ref]$deletionResults) -Confirm:$Confirm
                    }
                }

                return $deletionResults  # Return the accumulated deletion results
            }

            Mock Invoke-SingleProfileAction {
                param($SID, $AuditResults, $SelectedProfile, $BaseKey, [ref]$DeletionResults, $Force, $AuditOnly, $Confirm)

                # Call Invoke-ProcessProfileRemoval to simulate the removal or auditing of the profile
                $results = Invoke-ProcessProfileRemoval -SID $SID -SelectedProfile $SelectedProfile -BaseKey $BaseKey -AuditOnly:$AuditOnly -ComputerName $ComputerName -Confirm:$Confirm

                # Append the result to the DeletionResults array
                $DeletionResults.Value += $results
            }

            Mock  Invoke-ProcessProfileRemoval {
                param($SID, $SelectedProfile, $BaseKey, $AuditOnly, $ComputerName, $Confirm)

                # Simulate the result based on whether AuditOnly is true or not
                if ($AuditOnly)
                {
                    return New-ProfileDeletionResult -SID $SID -ProfilePath $SelectedProfile.ProfilePath -DeletionSuccess $true -DeletionMessage "Audit only, no deletion performed." -ComputerName $ComputerName
                }
                else
                {
                    return New-ProfileDeletionResult -SID $SID -ProfilePath $SelectedProfile.ProfilePath -DeletionSuccess $true -DeletionMessage "Profile removed successfully." -ComputerName $ComputerName
                }
            }

        } -ModuleName $Script:dscModuleName
    }

    Context 'When profiles are successfully removed' {
        It 'Should remove the user profile successfully' {

            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001") -ComputerName $env:COMPUTERNAME -Confirm:$false -force
            $result | Should -HaveCount 1
            $result[0].DeletionSuccess | Should -Be $true
            $result[0].DeletionMessage | Should -Be "Profile removed successfully."
        }

        It 'Should remove multiple user profiles successfully' {
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001", "S-1-5-21-1234567890-1002") -ComputerName $env:COMPUTERNAME -Confirm:$false -force
            $result | Should -HaveCount 2
            $result[0].DeletionSuccess | Should -Be $true
            $result[0].DeletionMessage | Should -Be "Profile removed successfully."
            $result[1].DeletionSuccess | Should -Be $true
            $result[1].DeletionMessage | Should -Be "Profile removed successfully."
        }

        It 'Should only audit the profile without removing it when AuditOnly is set' {
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001") -AuditOnly -ComputerName $env:COMPUTERNAME -Confirm:$false -force
            $result | Should -HaveCount 1
            $result[0].DeletionSuccess | Should -Be $true
            $result[0].DeletionMessage | Should -Be "Audit only, no deletion performed."
        }
    }

    Context 'When confirmation is required' {
        It 'Should remove profile when confirmation is bypassed' {

            # Using -Confirm:$false to bypass confirmation
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001") -Confirm:$false -Force
            $result | Should -HaveCount 1
            $result[0].DeletionSuccess | Should -Be $true

            Should -Invoke Invoke-ProcessProfileRemoval -Exactly 1 -Scope It
        }
    }

    Context 'When profiles are successfully removed' {
        It 'Should remove the user profile successfully' {
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001") -ComputerName $env:COMPUTERNAME -Confirm:$false
            $result | Should -HaveCount 1
            $result[0].DeletionSuccess | Should -Be $true
            $result[0].DeletionMessage | Should -Be "Profile removed successfully."
        }

        It 'Should remove multiple user profiles successfully' {
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001", "S-1-5-21-1234567890-1002") -ComputerName $env:COMPUTERNAME -Confirm:$false
            $result | Should -HaveCount 2
            $result[0].DeletionSuccess | Should -Be $true
            $result[0].DeletionMessage | Should -Be "Profile removed successfully."
            $result[1].DeletionSuccess | Should -Be $true
            $result[1].DeletionMessage | Should -Be "Profile removed successfully."
        }

        It 'Should only audit the profile without removing it when AuditOnly is set' {
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001") -AuditOnly -ComputerName $env:COMPUTERNAME -Confirm:$false
            $result | Should -HaveCount 1
            $result[0].DeletionSuccess | Should -Be $true
            $result[0].DeletionMessage | Should -Be "Audit only, no deletion performed."
        }

        It 'Should skip special profiles' {
            # Mock a special profile

            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1003") -ComputerName $env:COMPUTERNAME -Confirm:$false
            $result | Should -HaveCount 1
            $result[0].DeletionSuccess | Should -Be $false
            $result[0].DeletionMessage | Should -Be "Profile not found."
        }

        It 'Should handle profiles that are already removed or not found' {
            # Mock no profile found
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1005") -ComputerName $env:COMPUTERNAME -Confirm:$false
            $result | Should -HaveCount 1
            $result[0].DeletionSuccess | Should -Be $false
            $result[0].DeletionMessage | Should -Be "Profile not found."
        }



    }

    Context 'When registry or file operations fail' {
        It 'Should throw an error when registry key cannot be opened' {
            # Mock registry key failure
            Mock Open-RegistryKey { $null } -ModuleName $script:dscModuleName

            $message = 'Error in Begin block: Failed to open registry key at path: SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

            { Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001") -ComputerName $env:COMPUTERNAME -Confirm:$false } | Should -Throw $message
        }

        It 'Should throw an error when backup directory does not exist' {
            # Mock directory existence check to fail
            Mock Test-DirectoryExistence { throw } -ModuleName $Script:dscModuleName

            $message = 'Error in Begin block: ScriptHalted'
            { Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001") -ComputerName $env:COMPUTERNAME -Confirm:$false } | Should -Throw $message
        }
    }

    Context 'When confirmation is required' {
        It 'Should prompt for confirmation before removing profile' {
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001") -whatif
            $result | Should -BeNullOrEmpty
            Should -Invoke Invoke-ProcessProfileRemoval -Exactly 0 -Scope It
        }

        It 'Should remove profile when confirmation is bypassed' {
            # Using -Confirm:$false to bypass confirmation
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001") -Confirm:$false
            $result | Should -HaveCount 1
            $result[0].DeletionSuccess | Should -Be $true

            Should -Invoke Invoke-ProcessProfileRemoval -Exactly 1 -Scope It
        }
    }

    Context 'Handling multiple SIDs with mixed outcomes' {
        It 'Should handle a mix of profiles where some are successfully removed and some are not found' {
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001", "S-1-5-21-1234567890-1005") -ComputerName $env:COMPUTERNAME -Confirm:$false
            $result | Should -HaveCount 2

            $result[0].DeletionSuccess | Should -Be $true
            $result[0].DeletionMessage | Should -Be "Profile removed successfully."

            $result[1].DeletionSuccess | Should -Be $false
            $result[1].DeletionMessage | Should -Be "Profile not found."
        }
    }

    Context 'When removing profiles from a remote computer' {
        It 'Should remove profile from remote computer successfully' {
            $remoteComputerName = "RemotePC"
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001") -ComputerName $remoteComputerName -Confirm:$false
            $result | Should -HaveCount 1
            $result[0].ComputerName | Should -Be $remoteComputerName
            $result[0].DeletionSuccess | Should -Be $true
        }

        It 'Should handle failure when connecting to remote computer' {
            Mock Open-RegistryKey { throw }

            $remoteComputerName = "RemotePC"
            $message = 'Error in Begin block: ScriptHalted'
            { Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001") -ComputerName $remoteComputerName -Confirm:$false } | Should -Throw $message
        }
    }
    Context 'Handling invalid input and SIDs' {
        It 'Should throw an error when no SIDs are provided' {
            $message = "Cannot bind argument to parameter 'SIDs' because it is an empty array."
            { Remove-UserProfilesFromRegistry -SIDs @() -ComputerName $env:COMPUTERNAME -Confirm:$false } | Should -Throw $message
        }

        It 'Should return a message for an invalid SID format' {
            # Simulate an invalid SID format
            $result = Remove-UserProfilesFromRegistry -SIDs @("Invalid-SID") -ComputerName $env:COMPUTERNAME -Confirm:$false
            $result | Should -HaveCount 1
            $result[0].DeletionSuccess | Should -Be $false
            $result[0].DeletionMessage | Should -Be "Invalid SID format encountered: 'Invalid-SID'."
        }

        It 'Should return a profile not found message for a valid but non-existent SID' {
            # Mock no profile found for the given valid SID
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1005") -ComputerName $env:COMPUTERNAME -Confirm:$false
            $result | Should -HaveCount 1
            $result[0].DeletionSuccess | Should -Be $false
            $result[0].DeletionMessage | Should -Be "Profile not found."
        }

        It 'Should handle multiple SIDs with one invalid and one valid SID' {
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-10015", "Invalid-SID") -ComputerName $env:COMPUTERNAME -Confirm:$false
            $result | Should -HaveCount 2

            # The first SID should be valid but not found
            $result[0].SID | Should -Be "S-1-5-21-1234567890-10015"
            $result[0].DeletionSuccess | Should -Be $false
            $result[0].DeletionMessage | Should -Be "Profile not found."

            # The second SID should be invalid
            $result[1].SID | Should -Be "Invalid-SID"
            $result[1].DeletionSuccess | Should -Be $false
            $result[1].DeletionMessage | Should -Be "Invalid SID format encountered: 'Invalid-SID'."
        }
    }
}
#>
