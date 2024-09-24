# Changelog for WinProfileOps

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- removed bug from `Process-RegistryProfiles` regarding populating the
FolderName variable

### Added

#### Functions

- New helper function `Validate-SIDFormat` to verify SID value upon retrieval
in `Get-ProfilePathFromSID`

- **Admin Detection and Environment Variable**: Added logic to detect whether the
 current user is an administrator and set an environment variable
  `WinProfileOps_IsAdmin` accordingly.

  - If the user is an administrator, `$ENV:WinProfileOps_IsAdmin` is set to
   `$true`. If not, it's set to `$false`.

  - The environment variable is automatically removed when the module is
   unloaded or when PowerShell exits.

  - Registered an `OnRemove` script block and a `PowerShell.Exiting` event to
   ensure cleanup of the environment variable on module removal or session exit.

- **Remove-UserProfilesFromRegistry**: Added a new function to remove user profiles
 from the Windows registry based on SIDs, Usernames, or UserProfile objects.

  - Supports three parameter sets: `UserProfileSet`, `SIDSet`, and `UserNameSet`.

  - Can be run in `AuditOnly` mode, where no actual deletion is performed, or
   in deletion mode where profiles are removed.

  - Includes a `Force` switch to bypass confirmation prompts and a `ComputerName`
   parameter for targeting remote computers.

  - Graceful error handling and logging for cases where the registry key cannot
   be opened or profiles cannot be processed for specific computers.

#### Environment Variables  

- **`$env:WinProfileOps_IsAdmin`**: A boolean value that determines if the
current user has administrative privileges. This is set by checking the user’s
security role against the built-in Administrator group using Windows security principals.
  
- **`$env:WinProfileOps_RegistryPath`**: Specifies the registry path used to
 manage user profiles. Default value: `"SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"`.

- **`$env:WinProfileOps_RegistryHive`**: Defines the registry hive to use,
 which is set to `LocalMachine` by default.

- **`$env:WinProfileOps_RegBackUpDirectory`**: Specifies the directory where
registry backups are stored. Default value: `"C:\LHStuff\RegBackUp"`.

- **`$env:WinProfileOps_ProfileFolderPath`**: The profile folder path,
defaulting to the system drive's `Users` folder. Example: `"C:\Users"`.

### Changed

- **Get-UserProfilesFromRegistry**: Updated the function to handle scenarios
 where the current user does not have administrative privileges.

  - The function now checks if the user is an administrator by evaluating the
   `WinProfileOps_IsAdmin` environment variable.

  - If the user has administrator privileges, the function retrieves user
   profiles from the registry using `Get-SIDProfileInfo`.

  - If the user lacks administrative privileges, the function falls back to the
   `Get-SIDProfileInfoFallback` method, which retrieves user profiles using
    CIM/WMI without requiring registry access.

  - A warning is logged when the fallback method is used, indicating that
   special system accounts are excluded.

- Refactored `Process-RegistryProfiles` to better account for access denied errors
when testing profile paths with `Test-FolderExists`

- Updated `UserProfile` object creation in `Test-OrphanedProfile` for
 `$AccessError` Scenarios

- Module is now using `WinRegOps` Version `0.4.0` for more refined registry value
retrieval

## [0.2.0] - 2024-09-12

### Added

- Added core functions
- configured `WinRegOps` as a dependant module
- Updated build file for release

- Comment-based help documentation added for the following public functions:
  - `Get-AllUserProfiles`
  - `Get-OrphanedProfiles`
  - `Remove-OrphanedProfiles`
  - `Remove-SIDProfile`
  - `Get-UserProfileFolders`
  - `Get-RegistryUserProfiles`
  - `Get-UserFolders`

- Comment-based help documentation added for the following public functions:
  - `New-UserProfileObject`
  - `Remove-RegistryKeyForSID`
  - `Remove-ProfilesForSIDs`
  - `Get-RegistryKeyForSID`
  - `Get-SIDProfileInfo`
  - `Get-ProfilePathFromSID`
  - `Test-FolderExists`
  - `Test-OrphanedProfile`
  - `Test-SpecialAccount`

- Implemented and completed Unit Tests for private functions

- **`Get-UserFolders`**
  - Added error handling using a `try`/`catch` block to ensure that if `Get-ChildItem`
   fails (e.g., due to permission issues), the function logs an error message and
   returns an empty array instead of throwing an unhandled exception.

  - Implemented an `OutputType` attribute for better PowerShell function introspection
   and to clearly indicate that the function returns an array of `[PSCustomObject]`.

- **`Invoke-UserProfileAudit` Supporting Functions:**

  - These supporting functions are now utilized within `Invoke-UserProfileAudit`
   to audit user profiles from both the file system and registry sources.

    - **`Process-RegistryProfiles`**: 
      - Processes profiles retrieved from the registry,
    compares them with folder profiles, and identifies orphaned profiles.

    - **`Process-FolderProfiles`**:
      - Processes user profiles from the folder system,
     identifies those without corresponding registry entries, and marks them as orphaned.

    - **`Test-ComputerReachability`**:
      - Encapsulates the common behavior of `Test-ComputerPing` to check if a computer
      is reachable before proceeding with operations like profile audits. This ensures
       consistent handling of unreachable computers across different functions.
  
### Changed

- Moved `Get-SIDProfileInfo` to the private functions folder. It will serve as
an internal function for `Get-RegistryUserProfiles`

- **`Get-SIDProfileInfo`**
  - Returns an empty array `@()` when no registry
  key or SIDs are found, improving handling for cases where there are no profiles.

  - Improved error handling to ensure proper error messages when the registry key
  or subkeys cannot be opened.

  - Enhanced handling of SIDs that are invalid or missing a `ProfileImagePath`,
  logging appropriate warnings or verbose messages.

  - Optimized function behavior to handle scenarios with no SIDs, invalid SID formats,
  and missing `ProfileImagePath` values gracefully.


- **`Get-UserFolders`**
  - The function now logs errors when folder retrieval fails, improving diagnostic
   feedback.

  - The default value for the `ComputerName` parameter is set to `$env:COMPUTERNAME`,
   ensuring local computer behavior by default without requiring the user to
   specify it manually.
  
  - Refined the `Get-DirectoryPath` call to ensure path conversion consistency
   across local and remote environments.

  - General code clean-up and improved resilience, returning an empty array when
   no folders are found or in case of failure, rather than proceeding
   without valid data.

- **`Get-UserProfilesFromRegistry`**
  - Added error handling using a `try-catch` block to capture and log errors
   during the retrieval of registry profiles.

  - Implemented a check using `Test-ComputerPing` to verify if the target computer
   is online or reachable before attempting to retrieve registry profiles.

  - Returns an empty array `@()` when the target computer is offline or unreachable,
   logging a warning in such cases.

  - Returns an empty array `@()` when an error occurs while accessing the registry
   profiles, logging an error message.

  - Integrated with the `-ErrorAction Stop` parameter when calling `Get-SIDProfileInfo`,
   ensuring that errors are caught and handled appropriately in the calling function.

- **`Get-UserProfilesFromFolders`**
  - Added error handling using a `try-catch` block to capture and log errors
   during the retrieval of user profile folders.

  - Implemented a check using `Test-ComputerPing` to verify if the target
   computer is online or reachable before attempting to retrieve user folders.

  - Returns an empty array `@()` when the target computer is offline or
   unreachable, logging a warning in such cases.

  - Returns an empty array `@()` when an error occurs while accessing the user
   folders, logging an error message.


- **`Invoke-UserProfileAudit`**
  - Renamed the previous `Get-AllUserProfiles` function to `Invoke-UserProfileAudit`.
  - Added `Get-AllUserProfiles` as an alias for `Invoke-UserProfileAudit`
  to maintain backward compatibility.

### Removed

- Removed the old `Get-AllUserProfiles` function and replaced it with the new
`Invoke-UserProfileAudit` function.

- Temporarily Removed functions (`Remove-OrphanedProfiles` and
 `Remove-ProfilesForSIDs`) related to Removing Users Folders and registry
keys for further testing before implementing
