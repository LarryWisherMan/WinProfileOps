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

# Unit Tests for Update-JsonFile
Describe 'Update-JsonFile'  -tags "Private", "Helpers" {


    BeforeEach {

        InModuleScope -ScriptBlock {
            # Mock filesystem interaction for the tests
            Mock -CommandName Test-Path
            Mock -CommandName Get-Content
            Mock -CommandName Set-Content
            Mock -CommandName Out-File

        }

    }


    # Context: Ensure existing data is correctly handled
    Context 'When existing data is not an array' {
        It 'should convert the existing data to an array and append the new data' {
            InModuleScope -ScriptBlock {
                # Mock the behavior of Test-Path to simulate the file exists
                Mock Test-Path -MockWith { return $true }

                # Mock the behavior of Get-Content and ConvertFrom-Json to simulate a single non-array object
                Mock Get-Content -MockWith { return '{"Name":"HKEY_LOCAL_MACHINE\\Software\\SingleKey","Value":"SingleValue"}' }

                # New registry data to be appended
                $newRegistryData = @(
                    @{ Name = 'HKEY_LOCAL_MACHINE\Software\TestKey'; Value = 'TestValue' }
                )

                # Act: Call the function
                Update-JsonFile -OutputFile 'C:\Temp\RegistryData.json' -RegistryData $newRegistryData

                #Asert: Ensure that Set-Content was called to write the updated data back to the file
                Assert-MockCalled Set-Content -Exactly 1 -Scope It
            }
        }
    }

    # Test: Create a new file when it doesn't exist
    Context "When the JSON file does not exist" {
        It "Should create a new file with the provided data" {

            InModuleScope -ScriptBlock {

                Mock Test-Path { return $false }
                Mock Out-File

                $registryData = @(@{ Name = 'HKEY_LOCAL_MACHINE\Software\TestKey'; Value = 'TestValue' })
                $outputFile = 'C:\Temp\RegistryData.json'

                Update-JsonFile -OutputFile $outputFile -RegistryData $registryData

                Assert-MockCalled Out-File -Exactly 1 -Scope It

            }
        }
    }

    # Test: Append data when the file exists
    Context "When the JSON file exists" {

        It "Should append the new data to the existing JSON file" {
            InModuleScope -ScriptBlock {
                Mock Test-Path { return $true }
                Mock Get-Content { '[{"Name":"HKEY_LOCAL_MACHINE\\Software\\ExistingKey", "Value":"ExistingValue"}]' }
                Mock Set-Content
                $existingData = @(@{ Name = 'HKEY_LOCAL_MACHINE\Software\ExistingKey'; Value = 'ExistingValue' })
                $newData = @(@{ Name = 'HKEY_LOCAL_MACHINE\Software\NewKey'; Value = 'NewValue' })
                $outputFile = 'C:\Temp\RegistryData.json'

                Update-JsonFile -OutputFile $outputFile -RegistryData $newData

                Assert-MockCalled Set-Content -Exactly 1 -Scope It
            }
        }
    }

    # Test: Handle invalid or empty data
    Context "When invalid data is passed" {

        It "Should throw an error if the RegistryData is not passed" {
            InModuleScope -ScriptBlock {
                { Update-JsonFile -OutputFile 'C:\Temp\RegistryData.json' -RegistryData $null } | Should -Throw
            }
        }
    }

    # Test: Handle multiple entries in RegistryData
    Context "When multiple entries are passed in RegistryData" {
        It "Should append all entries to the existing JSON file" {
            InModuleScope -ScriptBlock {
                Mock Test-Path { return $true }
                Mock Get-Content { '[{"Name":"HKEY_LOCAL_MACHINE\\Software\\ExistingKey","Value":"ExistingValue"}]' }
                Mock Set-Content

                $registryData = @(
                    @{ Name = 'HKEY_LOCAL_MACHINE\Software\NewKey1'; Value = 'NewValue1' },
                    @{ Name = 'HKEY_LOCAL_MACHINE\Software\NewKey2'; Value = 'NewValue2' }
                )
                $outputFile = 'C:\Temp\RegistryData.json'

                Update-JsonFile -OutputFile $outputFile -RegistryData $registryData

                Assert-MockCalled Set-Content -Exactly 1 -Scope It
            }
        }
    }



    Context "Ensure correct JSON depth is used" {
        It "Should output JSON with a depth of 10" {
            InModuleScope -ScriptBlock {
                Mock Test-Path { return $false }
                Mock ConvertTo-Json {}
                Mock Out-File

                $registryData = @(@{ Name = 'HKEY_LOCAL_MACHINE\Software\TestKey'; Value = 'TestValue' })
                $outputFile = 'C:\Temp\RegistryData.json'

                Update-JsonFile -OutputFile $outputFile -RegistryData $registryData

                Assert-MockCalled ConvertTo-Json -Exactly 1 -Scope It -ParameterFilter {
                    $Depth -eq 10
                }
            }
        }
    }

    # Test: Handle missing OutputFile parameter
    Context "When OutputFile is not provided" {
        It "Should throw an error" {
            InModuleScope -ScriptBlock {
                { Update-JsonFile -RegistryData @(@{ Name = 'HKEY_LOCAL_MACHINE\Software\NewKey'; Value = 'NewValue' }) -OutputFile $Null } | Should -Throw
            }
        }
    }

    # Test: Handle empty JSON file
    Context "When the JSON file exists but is empty" {
        It "Should create a new array with the provided registry data" {
            InModuleScope -ScriptBlock {
                Mock Test-Path { return $true }
                Mock Get-Content { '' }  # Simulate empty file content
                Mock Set-Content

                $newRegistryData = @(@{ Name = 'HKEY_LOCAL_MACHINE\Software\NewKey'; Value = 'NewValue' })
                $outputFile = 'C:\Temp\RegistryData.json'

                Update-JsonFile -OutputFile $outputFile -RegistryData $newRegistryData

                Assert-MockCalled Set-Content -Exactly 1 -Scope It
            }
        }
    }


}
