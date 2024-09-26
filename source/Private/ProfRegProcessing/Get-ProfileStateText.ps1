<#
.SYNOPSIS
    Decodes and returns the profile state text from the given state value.

.DESCRIPTION
    The `Get-ProfileStateText` function decodes the integer `state` value associated with a user's profile and returns a comma-separated string of flags that describe the profile's state.
    The profile state is stored in the registry as a DWORD value under the `HKLM\Software\Microsoft\Windows NT\CurrentVersion\ProfileList\SID` key. Each bit in the state value represents a specific condition or property of the profile.

.PARAMETER state
    The integer state value of the profile to decode. This value can be retrieved from the "State" registry value of a user profile.
    If the state is 0 or less, the function returns "StandardLocal". Otherwise, the function decodes the state using bitwise checks to identify individual flags.

.OUTPUTS
    [string] - A comma-separated string of profile state flags.

.NOTES
    The profile state is stored in the following registry location:
    Key: HKLM\Software\Microsoft\Windows NT\CurrentVersion\ProfileList\SID
    Value: State
    DataType: REG_DWORD

    The state is a sum of the following bitwise flags, represented in hexadecimal (regedit displays them in hex with 0x at the start) and decimal:

    0x0001 (1)    = PROFILE_MANDATORY: Profile is mandatory.
    0x0002 (2)    = PROFILE_USE_CACHE: Update the locally cached profile.
    0x0004 (4)    = PROFILE_NEW_LOCAL: Using a new local profile.
    0x0008 (8)    = PROFILE_NEW_CENTRAL: Using a new central profile.
    0x0010 (16)   = PROFILE_UPDATE_CENTRAL: Need to update the central profile.
    0x0020 (32)   = PROFILE_DELETE_CACHE: Need to delete the cached profile.
    0x0040 (64)   = PROFILE_UPGRADE: Need to upgrade the profile.
    0x0080 (128)  = PROFILE_GUEST_USER: Using a guest user profile.
    0x0100 (256)  = PROFILE_ADMIN_USER: Using an administrator profile.
    0x0200 (512)  = DEFAULT_NET_READY: Default net profile is available & ready.
    0x0400 (1024) = PROFILE_SLOW_LINK: Identified a slow network link.
    0x0800 (2048) = PROFILE_TEMP_ASSIGNED: Temporary profile loaded.

    Common state values:
    - 0 = Standard local profile.
    - 5 = Newly-loaded mandatory profile.
    - 256 (0x0100) = Standard administrator local profile.

    reference:
    - https://www.pcreview.co.uk/threads/purpose-of-the-state-key-located-in-users-profiles.2939114/#:~:text=There%20is%20a%20state%20key%20associated
    - https://www.precedence.co.uk/wiki/Support-KB-Windows/ProfileStates

.EXAMPLE
    $profileState = 287
    Get-ProfileStateText -state $profileState

    Output:
    Mandatory,UseCache,NewLocal,NewCentral,UpdateCentral,AdminUser

    Description:
    This example decodes the profile state value `287`, which combines several flags, such as "Mandatory", "UseCache", "NewLocal", "NewCentral", "UpdateCentral", and "AdminUser".

.EXAMPLE
    Get-ProfileStateText -state 0

    Output:
    StandardLocal

    Description:
    This example returns "StandardLocal" for the profile state value `0`.

#>
function Get-ProfileStateText
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [int]$state = 0
    )

    $stateText = @()

    Write-Verbose "Profile state: $state"

    # Special case for state = 0 (Standard local profile)
    if ($state -le 0)
    {
        return "StandardLocal"
    }

    # Bitwise checks for each state flag
    if ($state -band 1)
    {
        $stateText += "Mandatory"
    }
    if ($state -band 2)
    {
        $stateText += "UseCache"
    }
    if ($state -band 4)
    {
        $stateText += "NewLocal"
    }
    if ($state -band 8)
    {
        $stateText += "NewCentral"
    }
    if ($state -band 16)
    {
        $stateText += "UpdateCentral"
    }
    if ($state -band 32)
    {
        $stateText += "DeleteCache"
    }
    if ($state -band 64)
    {
        $stateText += "Upgrade"
    }
    if ($state -band 128)
    {
        $stateText += "GuestUser"
    }
    if ($state -band 256)
    {
        $stateText += "AdminUser"
    }
    if ($state -band 512)
    {
        $stateText += "DefaultNetReady"
    }
    if ($state -band 1024)
    {
        $stateText += "SlowLink"
    }
    if ($state -band 2048)
    {
        $stateText += "TempAssigned"
    }

    # If no flags matched, return "Unknown"
    if (-not $stateText)
    {
        return "Unknown"
    }

    # Return the state descriptions joined by commas
    return $stateText -join ','
}
