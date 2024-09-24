<#
.SYNOPSIS
Prompts the user for confirmation before proceeding with a deletion operation.

.DESCRIPTION
The `PromptForConfirmation` function asks the user to confirm before performing a deletion operation on a specified computer's registry. If the `AuditOnly` flag is specified, the prompt is skipped. If `Confirm` is set to `$true`, the function displays a confirmation message with details about the number of items to delete and the target computer. The user response is handled by the `ShouldContinueWrapper` function, which manages the confirmation prompt.

.PARAMETER ComputerName
Specifies the name of the computer where the deletion operation will take place.

.PARAMETER ItemCount
Specifies the number of profiles to delete from the computer's registry. This is displayed in the confirmation message.

.PARAMETER AuditOnly
If this switch is specified, the function will skip the confirmation prompt and proceed without making any changes. This is typically used for audit or dry-run scenarios.

.PARAMETER Confirm
If this switch is specified, the function will always prompt the user for confirmation before proceeding.

.PARAMETER context
Specifies the execution context, typically used to access methods like `ShouldContinue` for the confirmation prompt.

.EXAMPLE
PromptForConfirmation -ComputerName 'Server01' -ItemCount 5 -Confirm

Description:
Prompts the user to confirm the deletion of 5 profiles from the registry of 'Server01'. If the user confirms, the function returns `$true`; otherwise, it returns `$false`.

.EXAMPLE
PromptForConfirmation -ComputerName 'Server02' -ItemCount 10 -AuditOnly

Description:
Skips the confirmation prompt since the `AuditOnly` switch is used, and returns `$true` to proceed with the audit operation.

.NOTES
The function assumes that `ShouldContinueWrapper` is available to handle the actual confirmation prompt.
#>

function PromptForConfirmation
{
    param (
        [string]$ComputerName,
        [int]$ItemCount,
        [switch]$AuditOnly,
        [switch]$Confirm,
        $context
    )

    # Skip prompt if in AuditOnly mode
    if ($AuditOnly)
    {
        return $true
    }


    # Always prompt unless Force is specified or Confirm is explicitly set to false
    if ($Confirm -eq $true)
    {
        $QueryMessage = "Are you sure you want to delete $ItemCount profiles from $ComputerName's registry?"
        $CaptionMessage = "Confirm Deletion"

        # Use the ShouldContinueWrapper to handle the prompt
        return (ShouldContinueWrapper -Context $context -QueryMessage $QueryMessage -CaptionMessage $CaptionMessage)
    }

    return $true # Proceed if Force is used or if AuditOnly is true
}
