BeforeAll {
    $script:dscModuleName = "WinProfileOps"

    # Import the module being tested
    Import-Module -Name $script:dscModuleName

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:dscModuleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:dscModuleName



}

AfterAll {
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    # Unload the module being tested
    Get-Module -Name $script:dscModuleName -All | Remove-Module -Force

    # Clean up environment variables
    Remove-Item -Path Env:Registry_Path -ErrorAction SilentlyContinue
    Remove-Item -Path Env:Export_Path -ErrorAction SilentlyContinue

}

Describe "PublicFuntions Tests" -Tag "Intergration" {

    Context "Get-UserProfilesFromFolders" {

        BeforeEach {
            $MockOutProfilePath = mkdir "$TestDrive\Users"
            $MockeFolderNames = @("User1", "User2", "User3")

            $MockedItems = $MockeFolderNames | ForEach-Object {
                $FolderName = $_
                mkdir "$TestDrive\Users\$folderName"
            }

            Mock Get-SIDFromUsername {
                param($Username)
                switch ($Username)
                {
                    'user1'
                    {
                        return "S-1-5-21-1234567890-1"
                    }
                    'user2'
                    {
                        return "S-1-5-21-1234567890-2"
                    }
                    'user3'
                    {
                        return "S-1-5-21-1234567890-3"
                    }
                }
            } -ModuleName $script:dscModuleName

            Mock Get-UserAccountFromSID {
                param($SID)
                switch ($SID)
                {
                    'S-1-5-21-1234567890-1'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-1"
                            Domain   = "Domain"
                            Username = "User1"
                        }
                    }
                    'S-1-5-21-1234567890-2'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-2"
                            Domain   = "Domain"
                            Username = "User2"
                        }
                    }
                    'S-1-5-21-1234567890-3'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-3"
                            Domain   = "Domain"
                            Username = "User3"
                        }
                    }
                }
            } -ModuleName $script:dscModuleName

            Mock Get-UserProfileLastUseTimeFromDat {
                param($ComputerName, $SystemDrive)

                $ProfileList = @(

                    [PSCustomObject]@{
                        Success      = $true
                        ComputerName = $ComputerName
                        Username     = "User1"
                        LastLogon    = (Get-Date).AddDays(-1)
                        UserPath     = "$TestDrive\Users\User1"
                    },
                    [PSCustomObject]@{
                        Success      = $true
                        ComputerName = $ComputerName
                        Username     = "User2"
                        LastLogon    = (Get-Date).AddDays(-2)
                        UserPath     = "$TestDrive\Users\User2"
                    },
                    [PSCustomObject]@{
                        Success      = $true
                        ComputerName = $ComputerName
                        Username     = "User3"
                        LastLogon    = (Get-Date).AddDays(-3)
                        UserPath     = "$TestDrive\Users\User3"
                    }
                )

                return $ProfileList
            } -ModuleName $script:dscModuleName

        }

        AfterEach {
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force
            }
        }

        It "Should return an array of user profile folders" {

            #$MockRegPath = "TestRegistry:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
            #$MockOutRegPath = New-Item -Path $MockRegPath

            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $result = Get-UserProfilesFromFolders -ComputerName $ComputerName -ProfileFolderPath $profilePath

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3

            $Check = $result[0]

            $Check.Username | Should -Be "User1"
            $Check.ComputerName | Should -Be $ComputerName
            $Check.IsSpecial | Should -Be $false
            $Check.LastLogon | Should -BeLessThan (Get-Date)
            $Check.SID | Should -Be "S-1-5-21-1234567890-1"
            $Check.ProfilePath | Should -Be "$ProfilePath\User1"
            $Check.ExistsInRegistry | Should -Be $false
            $check.HasUserFolder | Should -Be $true
            $Check.Domain | Should -Be "Domain"
        }
    }


    Context "Get-UserProfilesFromRegistry" {

        BeforeEach {
            # Ensure clean-up of TestDrive before creating folders
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force -ErrorAction SilentlyContinue
            }

            # Create mock profile folders in TestDrive
            $MockProfilePath = mkdir "$TestDrive\Users"
            $MockUsers = @(
                @{
                    Foldername = "User1"
                    SID        = "S-1-5-21-1234567890-1"
                },
                @{
                    Foldername = "User2"
                    SID        = "S-1-5-21-1234567890-2"
                },
                @{
                    Foldername = "User3"
                    SID        = "S-1-5-21-1234567890-3"
                }
            )

            $MockUsers | ForEach-Object {
                mkdir "$TestDrive\Users\$($_.Foldername)"
            }

            # Mock registry entries in TestRegistry
            $MockRegistryPath = "HKCU:\Software\Pester\ProfileList"

            # Create registry path if it doesn't exist
            if (-not (Test-Path $MockRegistryPath))
            {
                New-Item -Path $MockRegistryPath -ItemType Directory
            }

            # Set up the environment variable for the registry path
            $env:WinProfileOps_RegistryPath = "Software\Pester\ProfileList"
            $env:WinProfileOps_RegistryHive = [Microsoft.Win32.RegistryHive]::CurrentUser

            # Create registry items for each mock user
            $MockUsers | ForEach-Object {
                $SID = $_.SID
                $FolderName = $_.Foldername
                $RegistryItemPath = "$MockRegistryPath\$SID"

                # Create registry key and set profile path
                if (-not (Test-Path $RegistryItemPath))
                {
                    New-Item -Path $RegistryItemPath
                }

                Set-ItemProperty -Path $RegistryItemPath -Name ProfileImagePath -Value "$TestDrive\Users\$FolderName"
                Set-ItemProperty -Path $RegistryItemPath -Name State -Value 0 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileLoadTimeLow -Value 2837573704 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileLoadTimeHigh -Value 31112838 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileUnloadTimeLow -Value 3518621425 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileUnloadTimeHigh -Value 31114160 -Type DWord

            }

            Mock Get-SIDFromUsername {
                param($Username)
                switch ($Username)
                {
                    'user1'
                    {
                        return "S-1-5-21-1234567890-1"
                    }
                    'user2'
                    {
                        return "S-1-5-21-1234567890-2"
                    }
                    'user3'
                    {
                        return "S-1-5-21-1234567890-3"
                    }
                }
            } -ModuleName $script:dscModuleName


            Mock Get-UserAccountFromSID {
                param($SID)
                switch ($SID)
                {
                    'S-1-5-21-1234567890-1'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-1"
                            Domain   = "Domain"
                            Username = "User1"
                        }
                    }
                    'S-1-5-21-1234567890-2'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-2"
                            Domain   = "Domain"
                            Username = "User2"
                        }
                    }
                    'S-1-5-21-1234567890-3'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-3"
                            Domain   = "Domain"
                            Username = "User3"
                        }
                    }
                }
            } -ModuleName $script:dscModuleName

        }


        AfterEach {
            # Clean up mock folders and registry items
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force
            }

            if (Test-Path "HKCU:\Software\Pester\ProfileList")
            {
                Remove-Item -Path "HKCU:\Software\Pester\ProfileList" -Recurse
            }

            #resetEnvVariables
            Remove-Item -Path Env:WinProfileOps_RegistryPath -ErrorAction SilentlyContinue
            Remove-Item -Path Env:WinProfileOps_RegistryHive -ErrorAction SilentlyContinue
        }

        It "Should return an array of user profiles from the registry" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Get-UserProfilesFromRegistry -ComputerName $ComputerName
            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ProfilePath | Should -Be "$ProfilePath\User1"

            $check = $result[0]

            $expectedLogonDate = (Get-Date "6/14/2024 11:14:13 AM").ToUniversalTime().ToString("o").Split(".")[0]
            $expectedLogoffDate = (Get-Date "6/21/2024 12:58:36 AM").ToUniversalTime().ToString("o").Split(".")[0]

            # Fetch the actual date and remove milliseconds and time zone info
            $actualLogOnDate = $Check.LastLogOnDate.ToUniversalTime().ToString("o").Split(".")[0]
            $actualLogOffDate = $Check.LastLogOffDate.ToUniversalTime().ToString("o").Split(".")[0]

            $check.Sid | Should -Be "S-1-5-21-1234567890-1"
            $check.ProfilePath | Should -Be "$ProfilePath\User1"
            $check.ProfileState | Should -Be "StandardLocal"
            $check.ComputerName | Should -Be $ComputerName
            $check.HasRegistryEntry | Should -Be $true
            $Check.Isloaded | Should -Be $false
            $check.HasUserFolder | Should -Be $true
            $Check.UserName | Should -Be "User1"
            $Check.Domain | Should -Be "Domain"
            $check.IsSpecial | Should -Be $false
            $actualLogOnDate | Should -Be $expectedLogonDate
            $actualLogOffDate | Should -Be $expectedLogoffDate
            $check.ErrorAccess | Should -Be $false
            $check.ErrorAccessMessage | Should -BeNullOrEmpty
        }


        It "It should return object even if  missing ProfileImagePath in Registry" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Set-ItemProperty -Path "HKCU:\Software\Pester\ProfileList\S-1-5-21-1234567890-1" -Name ProfileImagePath -Value ""

            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Get-UserProfilesFromRegistry $ComputerName

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3

            $check = $result[0]

            $result[0].profilePath | Should -BeNullOrEmpty
            $result[0].HasRegistryEntry | Should -Be $true
        }

    }

    Context "Invoke-UserProfileAudit" {

        BeforeEach {
            # Ensure clean-up of TestDrive before creating folders
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force -ErrorAction SilentlyContinue
            }

            # Create mock profile folders in TestDrive
            $MockProfilePath = mkdir "$TestDrive\Users"
            $MockUsers = @(
                @{
                    Foldername = "User1"
                    SID        = "S-1-5-21-1234567890-1"
                },
                @{
                    Foldername = "User2"
                    SID        = "S-1-5-21-1234567890-2"
                },
                @{
                    Foldername = "User3"
                    SID        = "S-1-5-21-1234567890-3"
                }
            )

            $MockUsers | ForEach-Object {
                mkdir "$TestDrive\Users\$($_.Foldername)"
            }

            # Mock registry entries in TestRegistry
            $MockRegistryPath = "HKCU:\Software\Pester\ProfileList"

            # Create registry path if it doesn't exist
            if (-not (Test-Path $MockRegistryPath))
            {
                New-Item -Path $MockRegistryPath -ItemType Directory
            }

            # Set up the environment variable for the registry path
            $env:WinProfileOps_RegistryPath = "Software\Pester\ProfileList"
            $env:WinProfileOps_RegistryHive = [Microsoft.Win32.RegistryHive]::CurrentUser

            # Create registry items for each mock user
            $MockUsers | ForEach-Object {
                $SID = $_.SID
                $FolderName = $_.Foldername
                $RegistryItemPath = "$MockRegistryPath\$SID"

                # Create registry key and set profile path
                if (-not (Test-Path $RegistryItemPath))
                {
                    New-Item -Path $RegistryItemPath
                }

                Set-ItemProperty -Path $RegistryItemPath -Name ProfileImagePath -Value "$TestDrive\Users\$FolderName"
                Set-ItemProperty -Path $RegistryItemPath -Name State -Value 0 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileLoadTimeLow -Value 2837573704 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileLoadTimeHigh -Value 31112838 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileUnloadTimeLow -Value 3518621425 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileUnloadTimeHigh -Value 31114160 -Type DWord
            }

            Mock Get-SIDFromUsername {
                param($Username)
                switch ($Username)
                {
                    'user1'
                    {
                        return "S-1-5-21-1234567890-1"
                    }
                    'user2'
                    {
                        return "S-1-5-21-1234567890-2"
                    }
                    'user3'
                    {
                        return "S-1-5-21-1234567890-3"
                    }
                }
            } -ModuleName $script:dscModuleName

            Mock Get-UserAccountFromSID {
                param($SID)
                switch ($SID)
                {
                    'S-1-5-21-1234567890-1'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-1"
                            Domain   = "Domain"
                            Username = "User1"
                        }
                    }
                    'S-1-5-21-1234567890-2'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-2"
                            Domain   = "Domain"
                            Username = "User2"
                        }
                    }
                    'S-1-5-21-1234567890-3'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-3"
                            Domain   = "Domain"
                            Username = "User3"
                        }
                    }
                }
            } -ModuleName $script:dscModuleName

            Mock Get-UserProfileLastUseTimeFromDat {
                param($ComputerName, $SystemDrive)

                $ProfileList = @(

                    [PSCustomObject]@{
                        Success      = $true
                        ComputerName = $ComputerName
                        Username     = "User1"
                        LastLogon    = (Get-Date).AddDays(-1)
                        UserPath     = "$TestDrive\Users\User1"
                    },
                    [PSCustomObject]@{
                        Success      = $true
                        ComputerName = $ComputerName
                        Username     = "User2"
                        LastLogon    = (Get-Date).AddDays(-2)
                        UserPath     = "$TestDrive\Users\User2"
                    },
                    [PSCustomObject]@{
                        Success      = $true
                        ComputerName = $ComputerName
                        Username     = "User3"
                        LastLogon    = (Get-Date).AddDays(-3)
                        UserPath     = "$TestDrive\Users\User3"
                    }
                )

                return $ProfileList
            } -ModuleName $script:dscModuleName
        }


        AfterEach {
            # Clean up mock folders and registry items
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force
            }

            if (Test-Path "HKCU:\Software\Pester\ProfileList")
            {
                Remove-Item -Path "HKCU:\Software\Pester\ProfileList" -Recurse
            }

            #resetEnvVariables
            Remove-Item -Path Env:WinProfileOps_RegistryPath -ErrorAction SilentlyContinue
            Remove-Item -Path Env:WinProfileOps_RegistryHive -ErrorAction SilentlyContinue
        }

        It "It should return non orphaned Audit Objects" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $profilePath

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].ProfilePath | Should -Be "$ProfilePath\User1"
        }

        It "It should return 1 orphaned due to missing folder" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Remove-Item "$profilePath\User1" -Recurse -Force
            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $profilePath

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0].OrphanReason | Should -Be "MissingFolder"
            $result[0].IsOrphaned | Should -Be $true
            $result[0].FolderPath | Should -BeNullOrEmpty
            $result[0].ProfilePath | should -Not -BeNullOrEmpty
        }

        It "It should return 1 orphaned due to missing registry entry" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Remove-Item "HKCU:\Software\Pester\ProfileList\S-1-5-21-1234567890-1" -Recurse -Force
            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $profilePath

            $selected = $result | Where-Object { $_.UserName -match "User1" }

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $selected.OrphanReason | Should -Be "MissingRegistryEntry"
            $selected.IsOrphaned | Should -Be $true
        }

        It "It should return 1 orphaned due to missing ProfileImagePath in Registry" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Set-ItemProperty -Path "HKCU:\Software\Pester\ProfileList\S-1-5-21-1234567890-1" -Name ProfileImagePath -Value ""

            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $profilePath


            $Orphaned = $result | Where-Object { $_.IsOrphaned -eq $true }

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $Orphaned.Count | Should -Be 1
            $Orphaned[0].OrphanReason | Should -Be "MissingProfileImagePath"

        }

        It "It should return 1 orphaned due to missing MissingProfileImagePathAndFolder in Registry" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Set-ItemProperty -Path "HKCU:\Software\Pester\ProfileList\S-1-5-21-1234567890-1" -Name ProfileImagePath -Value ""
            $null = Remove-Item "$profilePath\User1" -Recurse -Force

            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Invoke-UserProfileAudit -ComputerName $ComputerName -ProfileFolderPath $profilePath


            $Orphaned = $result | Where-Object { $_.IsOrphaned -eq $true }

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $Orphaned.Count | Should -Be 1
            $Orphaned[0].OrphanReason | Should -Be "MissingProfileImagePathAndFolder"

        }



    }

    Context "Get-OrphanedProfiles" {

        BeforeEach {
            # Ensure clean-up of TestDrive before creating folders
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force -ErrorAction SilentlyContinue
            }

            # Create mock profile folders in TestDrive
            $MockProfilePath = mkdir "$TestDrive\Users"
            $MockUsers = @(
                @{
                    Foldername = "User1"
                    SID        = "S-1-5-21-1234567890-1"
                },
                @{
                    Foldername = "User2"
                    SID        = "S-1-5-21-1234567890-2"
                },
                @{
                    Foldername = "User3"
                    SID        = "S-1-5-21-1234567890-3"
                }
            )

            $MockUsers | ForEach-Object {
                mkdir "$TestDrive\Users\$($_.Foldername)"
            }

            # Mock registry entries in TestRegistry
            $MockRegistryPath = "HKCU:\Software\Pester\ProfileList"

            # Create registry path if it doesn't exist
            if (-not (Test-Path $MockRegistryPath))
            {
                New-Item -Path $MockRegistryPath -ItemType Directory
            }

            # Set up the environment variable for the registry path
            $env:WinProfileOps_RegistryPath = "Software\Pester\ProfileList"
            $env:WinProfileOps_RegistryHive = [Microsoft.Win32.RegistryHive]::CurrentUser

            # Create registry items for each mock user
            $MockUsers | ForEach-Object {
                $SID = $_.SID
                $FolderName = $_.Foldername
                $RegistryItemPath = "$MockRegistryPath\$SID"

                # Create registry key and set profile path
                if (-not (Test-Path $RegistryItemPath))
                {
                    New-Item -Path $RegistryItemPath
                }

                Set-ItemProperty -Path $RegistryItemPath -Name ProfileImagePath -Value "$TestDrive\Users\$FolderName"
                Set-ItemProperty -Path $RegistryItemPath -Name State -Value 0 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileLoadTimeLow -Value 2837573704 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileLoadTimeHigh -Value 31112838 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileUnloadTimeLow -Value 3518621425 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileUnloadTimeHigh -Value 31114160 -Type DWord
            }

            Mock Get-SIDFromUsername {
                param($Username)
                switch ($Username)
                {
                    'user1'
                    {
                        return "S-1-5-21-1234567890-1"
                    }
                    'user2'
                    {
                        return "S-1-5-21-1234567890-2"
                    }
                    'user3'
                    {
                        return "S-1-5-21-1234567890-3"
                    }
                }
            } -ModuleName $script:dscModuleName

            Mock Get-UserAccountFromSID {
                param($SID)
                switch ($SID)
                {
                    'S-1-5-21-1234567890-1'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-1"
                            Domain   = "Domain"
                            Username = "User1"
                        }
                    }
                    'S-1-5-21-1234567890-2'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-2"
                            Domain   = "Domain"
                            Username = "User2"
                        }
                    }
                    'S-1-5-21-1234567890-3'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-3"
                            Domain   = "Domain"
                            Username = "User3"
                        }
                    }
                }
            } -ModuleName $script:dscModuleName

            Mock Get-UserProfileLastUseTimeFromDat {
                param($ComputerName, $SystemDrive)

                $ProfileList = @(

                    [PSCustomObject]@{
                        Success      = $true
                        ComputerName = $ComputerName
                        Username     = "User1"
                        LastLogon    = (Get-Date).AddDays(-1)
                        UserPath     = "$TestDrive\Users\User1"
                    },
                    [PSCustomObject]@{
                        Success      = $true
                        ComputerName = $ComputerName
                        Username     = "User2"
                        LastLogon    = (Get-Date).AddDays(-2)
                        UserPath     = "$TestDrive\Users\User2"
                    },
                    [PSCustomObject]@{
                        Success      = $true
                        ComputerName = $ComputerName
                        Username     = "User3"
                        LastLogon    = (Get-Date).AddDays(-3)
                        UserPath     = "$TestDrive\Users\User3"
                    }
                )

                return $ProfileList
            } -ModuleName $script:dscModuleName
        }

        AfterEach {
            # Clean up mock folders and registry items
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force
            }

            if (Test-Path "HKCU:\Software\Pester\ProfileList")
            {
                Remove-Item -Path "HKCU:\Software\Pester\ProfileList" -Recurse
            }

            #resetEnvVariables
            Remove-Item -Path Env:WinProfileOps_RegistryPath -ErrorAction SilentlyContinue
            Remove-Item -Path Env:WinProfileOps_RegistryHive -ErrorAction SilentlyContinue
        }

        It "Should return null if no orphaned profiles are found" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Get-OrphanedProfiles -ComputerName $ComputerName -ProfileFolderPath $profilePath

            # Validate the result
            $result | Should -BeNullOrEmpty
            $result.Count | Should -Be 0
        }

        It "Should return 1 orphaned profile due to missing folder" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Remove-Item "$profilePath\User1" -Recurse -Force
            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Get-OrphanedProfiles -ComputerName $ComputerName -ProfileFolderPath $profilePath

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result.OrphanReason | Should -Be "MissingFolder"
            $result.IsOrphaned | Should -Be $true
        }

        It "Should return 1 orphaned profile due to missing registry entry" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Remove-Item "HKCU:\Software\Pester\ProfileList\S-1-5-21-1234567890-1" -Recurse -Force
            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Get-OrphanedProfiles -ComputerName $ComputerName -ProfileFolderPath $profilePath

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result.OrphanReason | Should -Be "MissingRegistryEntry"
            $result.IsOrphaned | Should -Be $true
        }

        It "Should return 2 orphaned profile due to missing registry entry and folder" {
            $ComputerName = $Env:COMPUTERNAME
            $profilePath = "$TestDrive\Users"

            $null = Remove-Item "HKCU:\Software\Pester\ProfileList\S-1-5-21-1234567890-1" -Recurse -Force
            $null = Remove-Item "$profilePath\User2" -Recurse -Force
            # Call the function to test (this is the function that fetches profiles from the registry)
            $result = Get-OrphanedProfiles -ComputerName $ComputerName -ProfileFolderPath $profilePath

            # Validate the result
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2

            $result[0].OrphanReason | Should -Be "MissingRegistryEntry"
            $result[0].IsOrphaned | Should -Be $true

            $result[1].OrphanReason | Should -Be "MissingFolder"
            $result[1].IsOrphaned | Should -Be $true

        }

    }


    Context "Remove-UserProfilesFromRegistry" {

        BeforeEach {
            # Ensure clean-up of TestDrive before creating folders
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force -ErrorAction SilentlyContinue
            }

            # Create mock profile folders in TestDrive
            $MockProfilePath = mkdir "$TestDrive\Users"
            $MockUsers = @(
                @{
                    Foldername = "User1"
                    SID        = "S-1-5-21-1234567890-1"
                },
                @{
                    Foldername = "User2"
                    SID        = "S-1-5-21-1234567890-2"
                },
                @{
                    Foldername = "User3"
                    SID        = "S-1-5-21-1234567890-3"
                }
            )

            $MockUsers | ForEach-Object {
                mkdir "$TestDrive\Users\$($_.Foldername)"
            }

            # Mock registry entries in TestRegistry
            $MockRegistryPath = "HKCU:\Software\Pester\ProfileList"

            # Create registry path if it doesn't exist
            if (-not (Test-Path $MockRegistryPath))
            {
                New-Item -Path $MockRegistryPath -ItemType Directory
            }

            # Set up the environment variable for the registry path
            $env:WinProfileOps_RegistryPath = "Software\Pester\ProfileList"
            $env:WinProfileOps_RegistryHive = [Microsoft.Win32.RegistryHive]::CurrentUser
            $env:WinProfileOps_ProfileFolderPath = "$TestDrive\Users"
            $env:WinProfileOps_RegBackUpDirectory = "$TestDrive\RegBackUp"

            $MockUsers | ForEach-Object {
                $SID = $_.SID
                $FolderName = $_.Foldername
                $RegistryItemPath = "$MockRegistryPath\$SID"

                # Create registry key and set profile path
                if (-not (Test-Path $RegistryItemPath))
                {
                    New-Item -Path $RegistryItemPath
                }

                Set-ItemProperty -Path $RegistryItemPath -Name ProfileImagePath -Value "$TestDrive\Users\$FolderName"
                Set-ItemProperty -Path $RegistryItemPath -Name State -Value 0 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileLoadTimeLow -Value 2837573704 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileLoadTimeHigh -Value 31112838 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileUnloadTimeLow -Value 3518621425 -Type DWord
                Set-ItemProperty -Path $RegistryItemPath -Name LocalProfileUnloadTimeHigh -Value 31114160 -Type DWord
            }

            Mock Get-SIDFromUsername {
                param($Username)
                switch ($Username)
                {
                    'user1'
                    {
                        return "S-1-5-21-1234567890-1"
                    }
                    'user2'
                    {
                        return "S-1-5-21-1234567890-2"
                    }
                    'user3'
                    {
                        return "S-1-5-21-1234567890-3"
                    }
                }
            } -ModuleName $script:dscModuleName

            Mock Get-UserAccountFromSID {
                param($SID)
                switch ($SID)
                {
                    'S-1-5-21-1234567890-1'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-1"
                            Domain   = "Domain"
                            Username = "User1"
                        }
                    }
                    'S-1-5-21-1234567890-2'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-2"
                            Domain   = "Domain"
                            Username = "User2"
                        }
                    }
                    'S-1-5-21-1234567890-3'
                    {
                        return [PSCustomObject]@{
                            SID      = "S-1-5-21-1234567890-3"
                            Domain   = "Domain"
                            Username = "User3"
                        }
                    }
                }
            } -ModuleName $script:dscModuleName

            Mock Get-UserProfileLastUseTimeFromDat {
                param($ComputerName, $SystemDrive)

                $ProfileList = @(

                    [PSCustomObject]@{
                        Success      = $true
                        ComputerName = $ComputerName
                        Username     = "User1"
                        LastLogon    = (Get-Date).AddDays(-1)
                        UserPath     = "$TestDrive\Users\User1"
                    },
                    [PSCustomObject]@{
                        Success      = $true
                        ComputerName = $ComputerName
                        Username     = "User2"
                        LastLogon    = (Get-Date).AddDays(-2)
                        UserPath     = "$TestDrive\Users\User2"
                    },
                    [PSCustomObject]@{
                        Success      = $true
                        ComputerName = $ComputerName
                        Username     = "User3"
                        LastLogon    = (Get-Date).AddDays(-3)
                        UserPath     = "$TestDrive\Users\User3"
                    }
                )

                return $ProfileList
            } -ModuleName $script:dscModuleName
        }

        AfterEach {
            # Clean up mock folders and registry items
            if (Test-Path "$TestDrive\Users")
            {
                Remove-Item -Path "$TestDrive\Users" -Recurse -Force
            }

            if (Test-Path "HKCU:\Software\Pester\ProfileList")
            {
                Remove-Item -Path "HKCU:\Software\Pester\ProfileList" -Recurse
            }

            # Reset environment variables
            Remove-Item -Path Env:WinProfileOps_RegistryPath -ErrorAction SilentlyContinue
            Remove-Item -Path Env:WinProfileOps_RegistryHive -ErrorAction SilentlyContinue
            Remove-Item -Path Env:WinProfileOps_ProfileFolderPath -ErrorAction SilentlyContinue
            Remove-Item -Path Env:WinProfileOps_RegBackUpDirectory -ErrorAction SilentlyContinue
        }

        It "Should remove the specified profiles from the registry" {
            $testSID = "S-1-5-21-1234567890-1"
            $profilePath = "$TestDrive\Users"
            $ComputerName = $Env:COMPUTERNAME

            # Validate the registry entry exists before removal
            (Test-Path "HKCU:\Software\Pester\ProfileList\$testSID") | Should -Be $true

            # Call Remove-UserProfilesFromRegistry to remove the profile
            $result = Remove-UserProfilesFromRegistry -SIDs $testSID -Force -Confirm:$false

            # Validate that the profile was removed from the registry
            (Test-Path "HKCU:\Software\Pester\ProfileList\$testSID") | Should -Be $false
            $result.DeletionSuccess | Should -Be $true

            # Validate the backup file was created
            $backupFile = Get-ChildItem $env:WinProfileOps_RegBackUpDirectory

            $backupFile | Should -Not -BeNullOrEmpty
            $backupContent = Get-Content -path $backupFile.FullName -raw | ConvertFrom-Json | Where-Object { $_.RegistryPath -match $testSID } | sort BackupDate -Descending | Select -First 1
            $backupContent.RegistryPath | Should -Be "HKEY_CURRENT_USER\Software\Pester\ProfileList\$testSID"
        }

        It "Should not remove profiles in AuditOnly mode" {
            $testSID = "S-1-5-21-1234567890-1"
            $profilePath = "$TestDrive\Users"
            $ComputerName = $Env:COMPUTERNAME

            # Validate the registry entry exists before attempting audit
            (Test-Path "HKCU:\Software\Pester\ProfileList\$testSID") | Should -Be $true

            # Call Remove-UserProfilesFromRegistry with -AuditOnly
            $result = Remove-UserProfilesFromRegistry -SIDs $testSID -AuditOnly

            # Validate that the profile was not removed
            (Test-Path "HKCU:\Software\Pester\ProfileList\$testSID") | Should -Be $true
            $result | Should -Not -BeNullOrEmpty
            $result.DeletionMessage | Should -Be "Audit only, no deletion performed."
        }

        It "Should handle missing registry entries gracefully" {
            $missingSID = "S-1-5-21-1234567890-999"  # Non-existing SID
            $profilePath = "$TestDrive\Users"
            $ComputerName = $Env:COMPUTERNAME

            Mock Write-Warning

            # Call Remove-UserProfilesFromRegistry on a missing profile
            $result = Remove-UserProfilesFromRegistry -SIDs $missingSID -Force -Confirm:$false

            # Validate the result should indicate failure due to missing registry entry
            $result.DeletionSuccess | Should -Be $false
            $result.DeletionMessage | Should -Be "Profile not found"

            Assert-MockCalled -CommandName Write-Warning -Times 1 -ParameterFilter {
                $message -eq "Profile not found for SID: $missingSID on $ComputerName."
            }
        }

        It "Should remove multiple profiles from the registry" {
            $testSIDs = @("S-1-5-21-1234567890-1", "S-1-5-21-1234567890-2")
            $profilePath = "$TestDrive\Users"
            $ComputerName = $Env:COMPUTERNAME

            # Validate the registry entries exist before removal
            $testSIDs | ForEach-Object {
                (Test-Path "HKCU:\Software\Pester\ProfileList\$_") | Should -Be $true
            }

            # Call Remove-UserProfilesFromRegistry to remove the profiles
            $result = Remove-UserProfilesFromRegistry -SIDs $testSIDs -Force -Confirm:$false

            # Validate that the profiles were removed from the registry
            $testSIDs | ForEach-Object {
                (Test-Path "HKCU:\Software\Pester\ProfileList\$_") | Should -Be $false
            }

            $result.DeletionSuccess | ForEach-Object { $_ | Should -Be $true }
        }

        It "Should handle profiles with missing folders" {
            $testSID = "S-1-5-21-1234567890-1"
            $profilePath = "$TestDrive\Users"
            $ComputerName = $Env:COMPUTERNAME

            # Remove folder for the profile
            Remove-Item "$profilePath\User1" -Recurse -Force

            # Call Remove-UserProfilesFromRegistry
            $result = Remove-UserProfilesFromRegistry -SIDs $testSID -Force -Confirm:$false

            # Validate the registry entry was removed
            (Test-Path "HKCU:\Software\Pester\ProfileList\$testSID") | Should -Be $false
            $result.DeletionSuccess | Should -Be $true
        }

        It "Should prompt for confirmation before removing profiles" {
            $testSID = "S-1-5-21-1234567890-1"
            $profilePath = "$TestDrive\Users"
            $ComputerName = $Env:COMPUTERNAME

            InModuleScope -ScriptBlock {
                mock ShouldContinueWrapper {
                    $false
                }
            }

            # Call Remove-UserProfilesFromRegistry without confirming
            $result = Remove-UserProfilesFromRegistry -SIDs $testSID -Force -Confirm:$true

            # assert ShouldContinueWrapper was called
            Assert-MockCalled ShouldContinueWrapper -Exactly 1 -Scope It

            # Validate that the profile was not removed
            (Test-Path "HKCU:\Software\Pester\ProfileList\$testSID") | Should -Be $true
        }

        It "Should handel UserProfile Types from the Pipeline" {
            $computerName = $Env:COMPUTERNAME
            $userProfileAudit = Invoke-UserProfileAudit -IgnoreSpecial

            if ($userProfileAudit.count -eq 3)
            {
                $result = Remove-UserProfilesFromRegistry -UserProfiles $userProfileAudit -AuditOnly
            }

            $result | Should -Not -BeNullOrEmpty
            $result.count | Should -Be 3
            $result | ForEach-Object {
                $_.DeletionSuccess | Should -Be $true
            }

        }

        It "Should not Delete Loaded Profiles" {

            InModuleScope -ScriptBlock {
                Mock Get-ProfileRegistryItems {
                    param($ComputerName)
                    return [pscustomobject]@{
                        SID              = "S-1-5-21-1234567890-1"
                        ProfilePath      = "$TestDrive\Users\User1"
                        ProfileState     = "StandardLocal"
                        ComputerName     = $ComputerName
                        HasRegistryEntry = $true
                        IsLoaded         = $true
                        HasUserFolder    = $true
                        UserName         = "User1"
                        Domain           = "Domain"
                        IsSpecial        = $false
                        LastLogOnDate    = (Get-Date).AddDays(-1)
                        LastLogOffDate   = (Get-Date).AddDays(-1)
                        ErrorAccess      = $false
                        ErrorCapture     = $null
                    }
                } -ModuleName $script:dscModuleName
            }

            mock Write-Warning

            $testSID = "S-1-5-21-1234567890-1"
            $result = Remove-UserProfilesFromRegistry -SIDs $testSID -Force -Confirm:$false

            $result.DeletionSuccess | Should -Be $false
            $result.DeletionMessage | Should -Be "Profile is currently loaded and cannot be deleted"

            Assert-MockCalled -CommandName Write-Warning -Times 1 -ParameterFilter {
                $message -eq "Profile is currently loaded and cannot be deleted: $testSID on $Env:ComputerName."


            }

        }


        It "Should not Delete Special Profiles" {

            InModuleScope -ScriptBlock {
                Mock Get-ProfileRegistryItems {
                    param($ComputerName)
                    return [pscustomobject]@{
                        SID              = "S-1-5-21-1234567890-1"
                        ProfilePath      = "$TestDrive\Users\User1"
                        ProfileState     = "StandardLocal"
                        ComputerName     = $ComputerName
                        HasRegistryEntry = $true
                        IsLoaded         = $false
                        HasUserFolder    = $true
                        UserName         = "User1"
                        Domain           = "Domain"
                        IsSpecial        = $True
                        LastLogOnDate    = (Get-Date).AddDays(-1)
                        LastLogOffDate   = (Get-Date).AddDays(-1)
                        ErrorAccess      = $false
                        ErrorCapture     = $null
                    }
                } -ModuleName $script:dscModuleName
            }

            mock Write-Warning

            $testSID = "S-1-5-21-1234567890-1"
            $result = Remove-UserProfilesFromRegistry -SIDs $testSID -Force -Confirm:$false

            $result.DeletionSuccess | Should -Be $false
            $result.DeletionMessage | Should -Be "Profile not found"


            Assert-MockCalled -CommandName Write-Warning -Times 1 -ParameterFilter {
                $message -eq "Profile not found for SID: $testSID on $Env:ComputerName."


            }

        }


    }

}
