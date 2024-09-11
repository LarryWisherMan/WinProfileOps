# Changelog for WinProfileOps

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
