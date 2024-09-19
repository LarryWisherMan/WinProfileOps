BeforeAll {
    $script:dscModuleName = "WinProfileOps"

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName

    # Set up environment variables used in the function
    $env:GetSIDProfileInfo_RegistryPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
    $env:GetSIDProfile_RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
    $env:WinProfileOps_RegBackUpDirectory = "C:\LHStuff\RegBackUp"
    $env:GetSIDProfileInfo_ProfileFolderPath = "$env:SystemDrive\Users"
}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Remove-UserProfilesFromRegistry'  -Tag 'Public' {

    BeforeEach {

        InModuleScope -scriptblock {

            # Mock necessary functions
            Mock Get-DirectoryPath { "C:\LHStuff\RegBackUp" }
            Mock Test-DirectoryExistence { $true }
            Mock Open-RegistryKey { New-MockObject -Type Microsoft.Win32.RegistryKey }
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

            Mock Invoke-ProcessProfileRemoval {
                param($SID, $computerName)
                New-ProfileDeletionResult -SID $SID -ProfilePath "$env:SystemDrive\Users\TestUser" -DeletionSuccess $true -DeletionMessage "Profile removed successfully." -ComputerName $computerName
            }

            Mock Invoke-UserProfileProcessing {
                param($ComputerName, $SIDs, $Profiles, $RegistryPath, $ProfileFolderPath, $RegistryHive, $Force, $AuditOnly, $Confirm)
                # Simulate successful removal of profiles
                foreach ($sid in $SIDs)
                {
                    if ($AuditOnly)
                    {

                        return New-ProfileDeletionResult -SID $sid -ProfilePath "$env:SystemDrive\Users\TestUser" -DeletionSuccess $true -DeletionMessage "Audit only, no deletion performed." -ComputerName $ComputerName

                    }

                    New-ProfileDeletionResult -SID $sid -ProfilePath "$env:SystemDrive\Users\TestUser" -DeletionSuccess $true -DeletionMessage "Profile removed successfully." -ComputerName $ComputerName
                }
            }
        } -ModuleName $Script:dscModuleName
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
    }

    Context 'When confirmation is required' {
        It 'Should prompt for confirmation before removing profile' {
            $result = Remove-UserProfilesFromRegistry -SIDs @("S-1-5-21-1234567890-1001") -WhatIf
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
}

<#
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
