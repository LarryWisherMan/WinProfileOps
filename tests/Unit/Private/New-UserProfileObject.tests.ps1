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

Describe "New-UserProfileObject" -Tag 'Private' {

    Context "When creating a new UserProfile object" {

        It "Should return a valid UserProfile object with all properties set" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"
                $isOrphaned = $true
                $orphanReason = "MissingRegistryEntry"
                $computerName = "Server01"
                $isSpecial = $false
                $isLoaded = $true
                $profileState = "Active"
                $hasRegistryEntry = $true
                $hasUserFolder = $true
                $lastLogonDate = [datetime]"2023-01-01"
                $lastLogOffDate = [datetime]"2023-01-02"
                $userName = "John"
                $domain = "Domain"

                # Act
                $result = New-UserProfileObject -SID $sid -ProfilePath $profilePath -IsOrphaned $isOrphaned -OrphanReason $orphanReason `
                    -ComputerName $computerName -IsSpecial $isSpecial -IsLoaded $isLoaded -ProfileState $profileState `
                    -HasRegistryEntry $hasRegistryEntry -HasUserFolder $hasUserFolder -LastLogonDate $lastLogonDate `
                    -LastLogOffDate $lastLogOffDate -UserName $userName -Domain $domain

                # Assert
                $result.GetType().name | Should -Be 'UserProfile'
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -Be $profilePath
                $result.IsOrphaned | Should -Be $isOrphaned
                $result.OrphanReason | Should -Be $orphanReason
                $result.ComputerName | Should -Be $computerName
                $result.IsSpecial | Should -Be $isSpecial
                $result.IsLoaded | Should -Be $isLoaded
                $result.ProfileState | Should -Be $profileState
                $result.HasRegistryEntry | Should -Be $hasRegistryEntry
                $result.HasUserFolder | Should -Be $hasUserFolder
                $result.LastLogonDate | Should -Be $lastLogonDate
                $result.LastLogOffDate | Should -Be $lastLogOffDate
                $result.UserName | Should -Be $userName
                $result.Domain | Should -Be $domain
            }
        }

        It "Should return a UserProfile object with default values for dates if not provided" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1001"
                $profilePath = "C:\Users\John"
                $isOrphaned = $false
                $computerName = "Server01"
                $isSpecial = $false
                $isLoaded = $true
                $profileState = "Inactive"
                $hasRegistryEntry = $true
                $hasUserFolder = $false
                $userName = "John"
                $domain = "Domain"

                # Act
                $result = New-UserProfileObject -SID $sid -ProfilePath $profilePath -IsOrphaned $isOrphaned `
                    -ComputerName $computerName -IsSpecial $isSpecial -IsLoaded $isLoaded `
                    -ProfileState $profileState -HasRegistryEntry $hasRegistryEntry `
                    -HasUserFolder $hasUserFolder -UserName $userName -Domain $domain

                $minDate = [datetime]::MinValue
                # Assert
                $result.GetType().name  | Should -Be 'UserProfile'
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -Be $profilePath
                $result.IsOrphaned | Should -Be $isOrphaned
                $result.ComputerName | Should -Be $computerName
                $result.IsSpecial | Should -Be $isSpecial
                $result.IsLoaded | Should -Be $isLoaded
                $result.ProfileState | Should -Be $profileState
                $result.HasRegistryEntry | Should -Be $hasRegistryEntry
                $result.HasUserFolder | Should -Be $hasUserFolder
                $result.LastLogonDate | Should -Be $minDate
                $result.LastLogOffDate | Should -Be $minDate
                $result.UserName | Should -Be $userName
                $result.Domain | Should -Be $domain
            }
        }

        It "Should handle special accounts properly" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-18"  # Local system SID
                $profilePath = "C:\WINDOWS\system32\config\systemprofile"
                $isOrphaned = $false
                $computerName = "Server01"
                $isSpecial = $true
                $isLoaded = $false
                $profileState = "Inactive"
                $hasRegistryEntry = $true
                $hasUserFolder = $true
                $userName = "SYSTEM"
                $domain = "NT AUTHORITY"

                # Act
                $result = New-UserProfileObject -SID $sid -ProfilePath $profilePath -IsOrphaned $isOrphaned `
                    -ComputerName $computerName -IsSpecial $isSpecial -IsLoaded $isLoaded `
                    -ProfileState $profileState -HasRegistryEntry $hasRegistryEntry `
                    -HasUserFolder $hasUserFolder -UserName $userName -Domain $domain

                # Assert
                $result.GetType().name  | Should -Be 'UserProfile'
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -Be $profilePath
                $result.IsOrphaned | Should -Be $isOrphaned
                $result.ComputerName | Should -Be $computerName
                $result.IsSpecial | Should -Be $isSpecial
                $result.IsLoaded | Should -Be $isLoaded
                $result.ProfileState | Should -Be $profileState
                $result.HasRegistryEntry | Should -Be $hasRegistryEntry
                $result.HasUserFolder | Should -Be $hasUserFolder
                $result.UserName | Should -Be $userName
                $result.Domain | Should -Be $domain
            }
        }

        It "Should correctly handle OrphanReason 'AccessDenied'" {
            InModuleScope -ScriptBlock {
                # Arrange
                $sid = "S-1-5-21-123456789-1004"
                $profilePath = "C:\Users\Jane"
                $isOrphaned = $true
                $orphanReason = "AccessDenied"
                $computerName = "Server01"
                $isSpecial = $false
                $isLoaded = $false
                $profileState = "Inactive"
                $hasRegistryEntry = $false
                $hasUserFolder = $true
                $userName = "Jane"
                $domain = "Domain"

                # Act
                $result = New-UserProfileObject -SID $sid -ProfilePath $profilePath -IsOrphaned $isOrphaned -OrphanReason $orphanReason `
                    -ComputerName $computerName -IsSpecial $isSpecial -IsLoaded $isLoaded -ProfileState $profileState `
                    -HasRegistryEntry $hasRegistryEntry -HasUserFolder $hasUserFolder -UserName $userName -Domain $domain

                # Assert
                $result.GetType().Name | Should -Be 'UserProfile'
                $result.SID | Should -Be $sid
                $result.ProfilePath | Should -Be $profilePath
                $result.IsOrphaned | Should -Be $isOrphaned
                $result.OrphanReason | Should -Be $orphanReason
                $result.ComputerName | Should -Be $computerName
                $result.IsSpecial | Should -Be $isSpecial
                $result.IsLoaded | Should -Be $isLoaded
                $result.ProfileState | Should -Be $profileState
                $result.HasRegistryEntry | Should -Be $hasRegistryEntry
                $result.HasUserFolder | Should -Be $hasUserFolder
                $result.UserName | Should -Be $userName
                $result.Domain | Should -Be $domain
            }
        }
    }
}
