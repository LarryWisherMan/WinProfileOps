BeforeAll {
    $script:dscModuleName = "WinProfileOps"

    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName

    # Mock Test-ComputerPing to return true (computer is online)
    Mock Test-ComputerPing {
        return $true
    }

}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested so that it doesn't impact any other tests.
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force
}

Describe 'Get-UserProfilesFromFolders Tests' -Tags 'Public', "Unit", "UserProfileAudit", "GetUserProfile" {

    BeforeAll {
        InModuleScope -ScriptBlock {
            # Mock dependencies
            Mock Test-ComputerPing -MockWith {
                return $true
            }
            Mock Get-UserFolders -MockWith {
                return @('User1', 'User2', 'User3')
            }
            Mock Get-ProcessedUserProfilesFromFolders -MockWith {
                param($UserFolders, $ComputerName)
                return @(
                    [PSCustomObject]@{FolderName = 'User1'; ProfilePath = 'C:\Users\User1'; ComputerName = $ComputerName },
                    [PSCustomObject]@{FolderName = 'User2'; ProfilePath = 'C:\Users\User2'; ComputerName = $ComputerName }
                )
            }
        }
    }

    Context 'Positive Tests' {

        It 'Should return user profile folders for a valid computer and profile path' {

            $result = Get-UserProfilesFromFolders -ComputerName 'Server01' -ProfileFolderPath 'D:\UserProfiles'

            # Assert that result is not null or empty
            $result | Should -Not -BeNullOrEmpty

            # Assert expected properties exist in returned objects
            $result[0].FolderName | Should -Be 'User1'
            $result[0].ProfilePath | Should -Be 'C:\Users\User1'
            $result[0].ComputerName | Should -Be 'Server01'

        }

        It 'Should return user profile folders for the local computer by default' {

            $result = Get-UserProfilesFromFolders

            # Assert that result is not null or empty
            $result | Should -Not -BeNullOrEmpty

            # Assert that ComputerName is local machine's name
            $result[0].ComputerName | Should -Be $env:COMPUTERNAME

        }
    }

    Context 'Negative Tests' {

        It 'Should return empty array and write-warning if computer is offline' {
            # Mock the ping check to return false (offline)
            Mock Test-ComputerPing -MockWith { return $false } -ModuleName $Script:dscModuleName

            mock Write-Warning


            $result = Get-UserProfilesFromFolders -ComputerName 'OfflineServer'

            # Assert that result is empty
            $result | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Warning -Scope It -ParameterFilter {
                $message -eq "Computer 'OfflineServer' is offline or unreachable."
            }
        }

        It 'Should write error if ProfileFolderPath is invalid' {

            # Mock Get-UserFolders to throw an exception
            Mock Get-UserFolders -MockWith { throw "Cannot find path" } -ModuleName $Script:dscModuleName
            #mock Write-Warning

            mock write-error

            Get-UserProfilesFromFolders -ProfileFolderPath 'InvalidFolderPath' | Out-Null


            Assert-MockCalled -CommandName Write-Error -Scope It -ParameterFilter {
                $message -like "*Cannot find path*"
            }

        }
    }

    Context 'Edge Case Tests' {

        It 'Should handle empty folder results gracefully' {
            # Mock Get-UserFolders to return an empty array
            Mock Get-UserFolders -MockWith { return @() } -ModuleName $Script:dscModuleName


            mock write-warning
            $result = Get-UserProfilesFromFolders -ProfileFolderPath 'EmptyFolderPath'


            # Assert that result is empty
            $result | Should -BeNullOrEmpty

            Assert-MockCalled -CommandName Write-Warning -Scope It -ParameterFilter {
                $message -eq "No user profile folders found in 'EmptyFolderPath' on computer '$env:COMPUTERNAME'."
            }

        }

        It 'Should handle null input for ComputerName by using the local machine name' {
            InModuleScope -ScriptBlock {
                $result = Get-UserProfilesFromFolders -ComputerName $null

                # Assert that the ComputerName defaults to the local machine
                $result[0].ComputerName | Should -Be $env:COMPUTERNAME
            }
        }
    }

    Context 'Exception Handling' {

        It 'Should return empty array if there is an error in retrieving user folders' {
            # Mock Get-UserFolders to throw an exception
            Mock Get-UserFolders -MockWith { throw "Error retrieving folders" } -ModuleName $Script:dscModuleName


            mock write-error

            $result = Get-UserProfilesFromFolders -ComputerName 'ErrorServer'

            # Assert that result is empty
            $result | Should -BeNullOrEmpty

        }

        It 'Should log an error message if retrieval fails' {
            Mock Get-UserFolders -MockWith { throw "Error retrieving folders" } -ModuleName $Script:dscModuleName

            mock write-error

            Get-UserProfilesFromFolders -ComputerName 'ErrorServer' | Out-Null

            Assert-MockCalled -Exactly 1 -CommandName 'Write-Error' -Scope It -ParameterFilter {
                $message -like "*Error retrieving folders*"
            }

        }
    }

    Context 'Verbose and Debug Logging' {



    }

    Context 'Performance Tests' {

        It 'Should execute within acceptable time for normal inputs' {

            $executionTime = Measure-Command {
                Get-UserProfilesFromFolders -ComputerName 'Server01'
            }

            # Assert that the execution time is less than 1 second
            $executionTime.TotalMilliseconds | Should -BeLessThan 1000

        }
    }

    Context 'Cleanup Tests' {

    }
}
