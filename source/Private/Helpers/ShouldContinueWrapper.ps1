<#
.SYNOPSIS
Handles user confirmation prompts using the `ShouldContinue` method.

.DESCRIPTION
The `ShouldContinueWrapper` function prompts the user to confirm whether they want to proceed with an operation. It uses the `ShouldContinue` method from the execution context to display a message to the user. The function logs whether the user chose to continue or not and returns the result.

.PARAMETER Context
Specifies the execution context, typically used to invoke the `ShouldContinue` method.

.PARAMETER QueryMessage
Specifies the message to display to the user asking if they are sure they want to proceed.

.PARAMETER CaptionMessage
Specifies the caption of the confirmation prompt, providing additional context about the operation.

.EXAMPLE
$context = Get-ExecutionContext
ShouldContinueWrapper -Context $context -QueryMessage "Are you sure you want to delete these items?" -CaptionMessage "Confirm Deletion"

Description:
Prompts the user with the message "Are you sure you want to delete these items?" and the caption "Confirm Deletion". The function returns `$true` if the user chooses to continue, otherwise it returns `$false`.

.NOTES
This function assumes that it is called within an appropriate execution context where `ShouldContinue` can be invoked.
#>
function ShouldContinueWrapper
{
    param (
        [Parameter(Mandatory = $true)]
        $Context,

        [Parameter(Mandatory = $true)]
        [string]$QueryMessage,

        [Parameter(Mandatory = $true)]
        [string]$CaptionMessage
    )
    $result = $Context.ShouldContinue($QueryMessage, $CaptionMessage)

    Write-Verbose "User chose to continue: $result"

    return $result
}
