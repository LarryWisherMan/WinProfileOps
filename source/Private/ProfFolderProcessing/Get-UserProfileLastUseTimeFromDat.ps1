function Get-UserProfileLastUseTimeFromDat
{
    [CmdletBinding()]
    param (
        [string]$ComputerName = $env:COMPUTERNAME,

        [ValidateNotNullOrEmpty()]
        [string]$SystemDrive = $env:SystemDrive
    )

    begin
    {
        Write-Verbose "Starting function Get-UserProfileLastUseTimeFromDat for computer: $ComputerName"

        # Check if we are querying a local or remote computer
        $isLocal = ($ComputerName -eq $env:COMPUTERNAME)

        # Base path to search for UsrClass.dat files in user profiles
        $BasePath = "$SystemDrive\Users\*\AppData\Local\Microsoft\Windows\UsrClass.dat"
        Write-Verbose "Base path for UsrClass.dat: $BasePath"

        $Path = Get-DirectoryPath -BasePath $BasePath -ComputerName $ComputerName -IsLocal $isLocal
        Write-Verbose "Resolved path: $Path"
    }

    process
    {
        try
        {
            # Retrieve the UsrClass.dat file's last write time for each user profile
            Write-Verbose "Retrieving UsrClass.dat files from $Path"
            $profileItems = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue | Sort-Object LastWriteTime

            # Check if any UsrClass.dat files were found
            if (-not $profileItems)
            {
                Write-Warning "No UsrClass.dat files found in path: $Path"
                return [pscustomobject]@{
                    Success      = $false
                    ComputerName = $ComputerName
                    Message      = "No UsrClass.dat files found."
                }
            }

            # Create custom objects for each profile
            $profileItems | ForEach-Object {
                $datFilePath = $_.FullName

                # Extract the user folder path (everything before 'AppData\Local\Microsoft\Windows')
                $userPath = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetDirectoryName([System.IO.Path]::GetDirectoryName([System.IO.Path]::GetDirectoryName([System.IO.Path]::GetDirectoryName($datFilePath)))))

                # Extract the user name based on the user folder path
                $userName = if ($isLocal)
                {
                    ($userPath).split("\")[2]
                }
                else
                {
                    ($userPath).split("\")[5]
                }

                $lastLogon = $_.LastWriteTime

                [pscustomobject]@{
                    Success      = $true
                    ComputerName = $ComputerName
                    Username     = $userName
                    LastLogon    = $lastLogon
                    UserPath     = $userPath
                }
            }
        }
        catch
        {
            Write-Warning "An error occurred while processing UsrClass.dat files: $_"
            return [pscustomobject]@{
                Success      = $false
                ComputerName = $ComputerName
                Error        = $_.Exception.Message
                LastLogon    = $null
            }
        }
    }

    end
    {
        Write-Verbose "Completed function Get-UserProfileLastUseTimeFromDat for computer: $ComputerName"
    }
}
