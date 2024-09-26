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

Describe 'New-ProfileRegistryItemObject' -Tags "Private", "Unit", "ProfileRegistryItems" {
    It 'Should return a PSCustomObject with the correct properties' {

        InModuleScope -Scriptblock {
            # Arrange
            $SID = 'S-1-5-21-1234567890-123456789-1234567890-1001'
            $ProfilePath = 'C:\Users\TestUser'
            $ProfileState = 'Active'
            $ComputerName = 'TestComputer'
            $HasRegistryEntry = $true
            $IsLoaded = $true
            $HasUserFolder = $true
            $UserName = 'TestUser'
            $Domain = 'TestDomain'
            $IsSpecial = $false
            $LastLogOnDate = [DateTime]'2024-09-25T12:00:00'
            $LastLogOffDate = [DateTime]'2024-09-25T13:00:00'
            $ErrorAccess = $false
            $errorCapture = $null

            # Act
            $result = New-ProfileRegistryItemObject -SID $SID -ProfilePath $ProfilePath -ProfileState $ProfileState -ComputerName $ComputerName -HasRegistryEntry $HasRegistryEntry -IsLoaded $IsLoaded -HasUserFolder $HasUserFolder -UserName $UserName -Domain $Domain -IsSpecial $IsSpecial -LastLogOnDate $LastLogOnDate -LastLogOffDate $LastLogOffDate -ErrorAccess $ErrorAccess -errorCapture $errorCapture

            # Assert
            $result | Should -BeOfType 'PSCustomObject'

            $result.SID | Should -BeExactly $SID
            $result.ProfilePath | Should -BeExactly $ProfilePath
            $result.ProfileState | Should -BeExactly $ProfileState
            $result.ComputerName | Should -BeExactly $ComputerName
            $result.HasRegistryEntry | Should -BeExactly $HasRegistryEntry
            $result.IsLoaded | Should -BeExactly $IsLoaded
            $result.HasUserFolder | Should -BeExactly $HasUserFolder
            $result.UserName | Should -BeExactly $UserName
            $result.Domain | Should -BeExactly $Domain
            $result.IsSpecial | Should -BeExactly $IsSpecial
            $result.LastLogOnDate | Should -BeExactly $LastLogOnDate
            $result.LastLogOffDate | Should -BeExactly $LastLogOffDate
            $result.ErrorAccess | Should -BeExactly $ErrorAccess
            $result.ErrorCapture | Should -BeExactly $errorCapture

        }
    }

    It 'Should default HasRegistryEntry to $true when not provided' {

        InModuleScope -Scriptblock {

            # Arrange
            $SID = 'S-1-5-21-1234567890-123456789-1234567890-1001'
            $ProfilePath = 'C:\Users\TestUser'
            $ProfileState = 'Inactive'
            $ComputerName = 'TestComputer'
            $IsLoaded = $false
            $HasUserFolder = $false
            $UserName = 'TestUser'
            $Domain = 'TestDomain'
            $IsSpecial = $false
            $LastLogOnDate = [DateTime]'2024-09-25T12:00:00'
            $LastLogOffDate = [DateTime]'2024-09-25T13:00:00'
            $ErrorAccess = $true
            $errorCapture = 'Error details here'

            # Act
            $result = New-ProfileRegistryItemObject -SID $SID -ProfilePath $ProfilePath -ProfileState $ProfileState -ComputerName $ComputerName -IsLoaded $IsLoaded -HasUserFolder $HasUserFolder -UserName $UserName -Domain $Domain -IsSpecial $IsSpecial -LastLogOnDate $LastLogOnDate -LastLogOffDate $LastLogOffDate -ErrorAccess $ErrorAccess -errorCapture $errorCapture

            # Assert
            $result | Should -BeOfType 'PSCustomObject'
            $result.HasRegistryEntry | Should -Be $true  # Check default value
        }
    }
}
