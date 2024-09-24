<#
.SYNOPSIS
Handles the user confirmation for actions using the `ShouldProcess` method.

.DESCRIPTION
The `ShouldProcessWrapper` function prompts the user to confirm whether they want to proceed with a specified action on a specified target. It uses the `ShouldProcess` method from the execution context, logging the action and the target for verbose output. The function returns the result of the user's decision, allowing the calling function to proceed or halt based on the confirmation.

.PARAMETER Context
Specifies the execution context, typically used to invoke the `ShouldProcess` method.

.PARAMETER Target
Specifies the target of the action, such as a computer, file, or registry path, that the user is being asked to confirm.

.PARAMETER ActionMessage
Specifies the action that will be performed on the target, such as "Deleting", "Modifying", or "Stopping a service."

.EXAMPLE
$context = Get-ExecutionContext
ShouldProcessWrapper -Context $context -Target "Server01" -ActionMessage "Delete profiles"

Description:
Prompts the user to confirm if they want to proceed with deleting profiles from "Server01". The function logs the action and the target, then returns `$true` if the user agrees, otherwise returns `$false`.

.EXAMPLE
ShouldProcessWrapper -Context $context -Target "C:\Temp\File.txt" -ActionMessage "Remove the file"

Description:
Prompts the user with the message "Remove the file" for the target file "C:\Temp\File.txt". It logs the action and returns the user's response.

.NOTES
This function is typically used in cmdlets or scripts that support the `ShouldProcess` functionality to allow confirmation before destructive or critical actions.
#>

function ShouldProcessWrapper
{
    param (
        [Parameter(Mandatory = $true)]
        $Context,

        [Parameter(Mandatory = $true)]
        [string]$Target,

        [Parameter(Mandatory = $true)]
        [string]$ActionMessage
    )

    # Log the action message for verbose output
    Write-Verbose "About to perform action: $ActionMessage on $Target"

    # Use the ShouldProcess method from the context
    $result = $Context.ShouldProcess($Target, $ActionMessage)

    Write-Verbose "User chose to process: $result"

    return $result
}
