<#
.SYNOPSIS
Validates the presence of a specific environment variable.

.DESCRIPTION
The Test-EnvironmentVariable function checks if the specified environment variable exists.
If the variable is found, it returns its value. If not, an error is thrown.

.PARAMETER Name
The name of the environment variable to check.

.EXAMPLE
Test-EnvironmentVariable -Name 'Path'

This command checks if the 'Path' environment variable is present and returns its value if found.

.OUTPUTS
String (Value of the environment variable)

.NOTES
This function will throw an error if the environment variable is missing.
#>
function Test-EnvironmentVariable
{
    param ([string]$Name)

    # Dynamically retrieve the environment variable
    $value = Get-Item -Path "Env:$Name" -ErrorAction SilentlyContinue

    if (-not $value)
    {
        throw "Missing required environment variable: $Name"
    }

    return $value.Value
}
