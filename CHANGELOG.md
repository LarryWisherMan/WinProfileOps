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

### Changed

- Moved `Get-SIDProfileInfo` to the private functions folder. It will serve as
an internal function for `Get-RegistryUserProfiles`

- Updates to `Get-SIDProfileInfo`:
  
  - Returns an empty array `@()` when no registry
  key or SIDs are found, improving handling for cases where there are no profiles.

  - Improved error handling to ensure proper error messages when the registry key
  or subkeys cannot be opened.

  - Enhanced handling of SIDs that are invalid or missing a `ProfileImagePath`,
  logging appropriate warnings or verbose messages.

  - Optimized function behavior to handle scenarios with no SIDs, invalid SID formats,
  and missing `ProfileImagePath` values gracefully.
