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

Describe 'Join-UserProfiles Tests' -Tags "Private", "Unit", "UserProfileAudit" {

    BeforeAll {
        InModuleScope -Scriptblock {
            # Since Get-MergeKey is called inside the function, you might need to mock it if it is an external function.
            Mock Get-MergeKey -MockWith {
                param ($SID, $ProfilePath)
                return "$SID|$ProfilePath"  # Return a mock merge key based on SID and ProfilePath
            }
        }
    }

    Context 'Positive Tests' {
        It 'Should merge folder and registry profiles by SID and ProfilePath' {
            InModuleScope -Scriptblock {
                # Arrange: Create sample folder and registry profiles
                $folderProfiles = @(
                    [pscustomobject]@{
                        SID           = "S-1-5-21-1234567890"
                        UserName      = "User1"
                        ProfilePath   = "C:\Users\User1"
                        LastLogonDate = [datetime]"2023-01-01"
                        HasUserFolder = $true
                        ComputerName  = "Computer1"
                        IsSpecial     = $false
                        Domain        = "Domain1"
                        ErrorAccess   = $false
                    }
                )

                $registryProfiles = @(
                    [pscustomobject]@{
                        SID              = "S-1-5-21-1234567890"
                        UserName         = "User1"
                        ProfilePath      = "C:\Users\User1"
                        LastLogonDate    = [datetime]"2023-02-01"
                        HasUserFolder    = $true
                        ComputerName     = "Computer1"
                        IsSpecial        = $false
                        Domain           = "Domain1"
                        HasRegistryEntry = $true
                        ProfileState     = 1
                        IsLoaded         = $false
                        LastLogOffDate   = [datetime]"2023-01-31"
                        ErrorAccess      = $false
                    }
                )

                # Act: Run Join-UserProfiles with the mock data
                $result = Join-UserProfiles -FolderProfiles $folderProfiles -RegistryProfiles $registryProfiles

                # DEBUG: Output the result to see what's happening
                $result | Should -Not -BeNullOrEmpty

                $DateTime = [datetime]::new(2023, 2, 1, 0, 0, 0)

                # Assert: Verify the output is correctly merged
                ($result | Measure-Object).Count | Should -Be 1
                $result[0].SID | Should -Be "S-1-5-21-1234567890"
                $result[0].ProfilePath | Should -Be "C:\Users\User1"
                $result[0].HasRegistryEntry | Should -Be $true
                $result[0].ProfileState | Should -Be 1
                $result[0].LastLogonDate | Should -Be $DateTime # Registry profile takes precedence
            }
        }
    }

    Context 'Negative Tests' {
        It 'Should throw an error if both FolderProfiles and RegistryProfiles are empty' {
            InModuleScope -Scriptblock {
                # Arrange: Empty profiles arrays
                $folderProfiles = @()
                $registryProfiles = @()

                # Act/Assert: Expect the function to throw an error
                { Join-UserProfiles -FolderProfiles $folderProfiles -RegistryProfiles $registryProfiles } | Should -Throw
            }
        }
    }

    Context 'Edge Case Tests' {
        It 'Should return profiles if FolderProfiles is empty and RegistryProfiles is not' {
            InModuleScope -Scriptblock {
                # Arrange: Empty folder profiles and non-empty registry profiles
                $folderProfiles = @()
                $registryProfiles = @(
                    [pscustomobject]@{
                        SID              = 'S-1-5-21-1234567890-1234567890-1234567890-1002'
                        UserName         = 'User2'
                        ProfilePath      = 'C:\Users\User2'
                        LastLogonDate    = (Get-Date).AddHours(-5)
                        LastLogOffDate   = (Get-Date).AddHours(-3)
                        HasRegistryEntry = $true
                        ProfileState     = 0
                        IsLoaded         = $false
                        ComputerName     = 'Computer1'
                        IsSpecial        = $false
                        Domain           = 'Domain'
                        ErrorAccess      = $false
                    }
                )

                # Act: Call Join-UserProfiles
                $result = Join-UserProfiles -FolderProfiles $folderProfiles -RegistryProfiles $registryProfiles

                # Assert: Expect profiles to be returned
                ($result |Measure-Object).Count | Should -Be 1
                $result[0].SID | Should -Be 'S-1-5-21-1234567890-1234567890-1234567890-1002'
            }
        }

        It 'Should return profiles if RegistryProfiles is empty and FolderProfiles is not' {
            InModuleScope -Scriptblock {
                # Arrange: Empty registry profiles and non-empty folder profiles
                $folderProfiles = @(
                    [pscustomobject]@{
                        SID           = 'S-1-5-21-1234567890-1234567890-1234567890-1003'
                        UserName      = 'User3'
                        ProfilePath   = 'C:\Users\User3'
                        LastLogonDate = (Get-Date)
                        HasUserFolder = $true
                        ComputerName  = 'Computer1'
                        IsSpecial     = $false
                        Domain        = 'Domain'
                        ErrorAccess   = $false
                    }
                )
                $registryProfiles = @()

                # Act: Call Join-UserProfiles
                $result = Join-UserProfiles -FolderProfiles $folderProfiles -RegistryProfiles $registryProfiles

                # Assert: Expect profiles to be returned
                ($result |Measure-Object).Count | Should -Be 1
                $result[0].SID | Should -Be 'S-1-5-21-1234567890-1234567890-1234567890-1003'
            }
        }

        It 'Should handle cases where registry profiles do not match any folder profiles' {
            InModuleScope -Scriptblock {
                # Arrange: Create sample registry profile with no matching folder profile
                $registryProfiles = @(
                    [pscustomobject]@{
                        SID              = "S-1-5-21-9876543210"
                        UserName         = "User2"
                        ProfilePath      = "C:\Users\User2"
                        LastLogonDate    = [datetime]"2023-02-01"
                        HasUserFolder    = $true
                        ComputerName     = "Computer1"
                        IsSpecial        = $false
                        Domain           = "Domain2"
                        HasRegistryEntry = $true
                        ProfileState     = 2
                        IsLoaded         = $false
                        LastLogOffDate   = [datetime]"2023-02-01"
                        ErrorAccess      = $false
                    }
                )

                $folderProfiles = @(
                    [pscustomobject]@{
                        SID           = "S-1-5-21-1234567890"
                        UserName      = "User1"
                        ProfilePath   = "C:\Users\User1"
                        LastLogonDate = [datetime]"2023-01-01"
                        HasUserFolder = $true
                        ComputerName  = "Computer1"
                        IsSpecial     = $false
                        Domain        = "Domain1"
                        ErrorAccess   = $false
                    }
                )

                # Act: Run Join-UserProfiles with no matching SIDs between folder and registry profiles
                $result = Join-UserProfiles -FolderProfiles $folderProfiles -RegistryProfiles $registryProfiles

                # Assert: Ensure both profiles are returned in the merged output
                $result.Count | Should -Be 2
            }
        }
    }

    Context 'Verbose Logging Tests' {

    }

    Context 'Performance Tests' {
        It 'Should execute within acceptable time frame' {
            InModuleScope -Scriptblock {
                $folderProfiles = @(
                    [pscustomobject]@{
                        SID           = "S-1-5-21-1234567890"
                        UserName      = "User1"
                        ProfilePath   = "C:\Users\User1"
                        LastLogonDate = [datetime]"2023-01-01"
                        HasUserFolder = $true
                        ComputerName  = "Computer1"
                        IsSpecial     = $false
                        Domain        = "Domain1"
                        ErrorAccess   = $false
                    }
                )

                $registryProfiles = @(
                    [pscustomobject]@{
                        SID              = "S-1-5-21-1234567890"
                        UserName         = "User1"
                        ProfilePath      = "C:\Users\User1"
                        LastLogonDate    = [datetime]"2023-02-01"
                        HasUserFolder    = $true
                        ComputerName     = "Computer1"
                        IsSpecial        = $false
                        Domain           = "Domain1"
                        HasRegistryEntry = $true
                        ProfileState     = 1
                        IsLoaded         = $false
                        LastLogOffDate   = [datetime]"2023-01-31"
                        ErrorAccess      = $false
                    }
                )

                $elapsedTime = Measure-Command { Join-UserProfiles -FolderProfiles $folderProfiles -RegistryProfiles $registryProfiles }
                $elapsedTime.TotalMilliseconds | Should -BeLessThan 1000
            }
        }
    }
}
