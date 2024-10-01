class LoggingService
{
    [System.Collections.Concurrent.ConcurrentQueue[string]]$Queue
    [string]$LocalLogFilePath
    [string]$RemoteLogFilePath
    [bool]$LogToLocal
    [bool]$LogToRemote
    [int]$RetryCount
    [int]$RetryDelay
    [powershell]$BackgroundRunspace
    [System.IAsyncResult]$AsyncResult

    LoggingService([string]$localLogFilePath, [string]$remoteLogFilePath = $null, [bool]$logToLocal = $true, [bool]$logToRemote = $false, [int]$retryCount = 5, [int]$retryDelay = 500)
    {
        $this.Queue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
        $this.LocalLogFilePath = $localLogFilePath
        $this.RemoteLogFilePath = $remoteLogFilePath
        $this.LogToLocal = $logToLocal
        $this.LogToRemote = $logToRemote
        $this.RetryCount = $retryCount
        $this.RetryDelay = $retryDelay
    }

    [void] EnsureLogFile([string]$filePath)
    {
        $logDir = [System.IO.Path]::GetDirectoryName($filePath)
        if (-not (Test-Path $logDir))
        {
            New-Item -Path $logDir -ItemType Directory -Force
        }
    }

    [void] EnqueueMessage([string]$message)
    {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "[$timestamp] $message"
        $this.Queue.Enqueue($logMessage)
        Write-Verbose "Message added to the queue: $logMessage"
    }

    [void] ProcessQueue()
    {
        while (-not $this.Queue.IsEmpty)
        {
            [string]$logMessage = $null

            if ($this.Queue.TryDequeue([ref]$logMessage))
            {
                if ($logMessage)
                {
                    if ($this.LogToLocal -and $this.LocalLogFilePath)
                    {
                        $this.WriteLogWithRetry($this.LocalLogFilePath, $logMessage)
                    }

                    if ($this.LogToRemote -and $this.RemoteLogFilePath)
                    {
                        $this.WriteLogWithRetry($this.RemoteLogFilePath, $logMessage)
                    }
                }
            }
        }
    }

    [void] WriteLogWithRetry([string]$filePath, [string]$logMessage)
    {
        $this.EnsureLogFile($filePath)

        $_retryCount = 0
        while ($_retryCount -lt $this.RetryCount)
        {
            try
            {
                $fileStream = [System.IO.File]::Open($filePath, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
                $streamWriter = New-Object System.IO.StreamWriter($fileStream)

                try
                {
                    $streamWriter.WriteLine($logMessage)
                    $streamWriter.Flush()
                    Write-Verbose "Logged message to $filePath"
                    break
                }
                finally
                {
                    $streamWriter.Close()
                    $fileStream.Close()
                }
            }
            catch
            {
                Write-Warning "Failed to write log to $filePath. Retry $($_retryCount + 1) of $($this.RetryCount)."
                $_retryCount++
                Start-Sleep -Milliseconds $this.RetryDelay
            }
        }

        if ($_retryCount -ge $this.RetryCount)
        {
            Write-Error "Unable to write log to $filePath after $($this.RetryCount) attempts."
        }
    }

    [void] StartBackgroundProcessing()
    {
        if ($this.BackgroundRunspace -and $this.AsyncResult -and $this.BackgroundRunspace.InvocationStateInfo.State -eq 'Running')
        {
            Write-Verbose "Background logging is already running."
            return
        }

        $scriptBlock = {
            param($logService)
            while ($true)
            {
                $logService.ProcessQueue()
                Start-Sleep -Seconds 5
            }
        }

        $this.BackgroundRunspace = [powershell]::Create().AddScript($scriptBlock).AddArgument($this)
        $this.AsyncResult = $this.BackgroundRunspace.BeginInvoke()
        Write-Verbose "Started background log processing."
    }

    [void] StopBackgroundProcessing()
    {
        if ($this.BackgroundRunspace -and $this.AsyncResult)
        {
            $this.BackgroundRunspace.Stop()
            $this.BackgroundRunspace.Dispose()
            $this.BackgroundRunspace = $null
            $this.AsyncResult = $null
            Write-Verbose "Stopped background log processing."
        }
    }
}

# Module Functions

function New-LoggingService
{
    param (
        [string]$localLogFilePath,
        [string]$remoteLogFilePath = $null,
        [bool]$logToLocal = $true,
        [bool]$logToRemote = $false,
        [int]$retryCount = 5,
        [int]$retryDelay = 500


    )
    return [LoggingService]::new($localLogFilePath, $remoteLogFilePath, $logToLocal, $logToRemote, $retryCount, $retryDelay)
}

function Add-LogMessage
{
    param (
        [LoggingService]$logService,
        [string]$message
    )
    $logService.EnqueueMessage($message)
}

function Start-LoggingService
{
    param (
        [LoggingService]$logService
    )
    $logService.StartBackgroundProcessing()
}

function Stop-LoggingService
{
    param (
        [LoggingService]$logService
    )
    $logService.StopBackgroundProcessing()
}


# Create a new logging service
$logService = New-LoggingService "C:\Temp\localLog.log" -remoteLogFilePath "\\wvrcarpen\c$\Temp\localLog.log" -logToRemote $true

# Start the background logging service
Start-LoggingService -logService $logService

# Add log messages (this will not block the main thread)
1..10 | ForEach-Object {
    Add-LogMessage -logService $logService -message "This is log entry $_"

}

# Simulate other processing while logs are being processed in the background
#Write-Host "Continuing with other tasks..."

# Stop the background logging service after a delay
#Start-Sleep -Seconds 15
#Stop-LoggingService -logService $logService
