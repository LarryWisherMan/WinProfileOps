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
  - `Get-SIDProfileInfo`

- Comment-based help documentation added for the following public functions:
- `New-UserProfileObject`
- `Remove-RegistryKeyForSID`
- `Remove-ProfilesForSIDs`
- `Get-RegistryKeyForSID`
- `Get-ProfilePathFromSID`
- `Test-FolderExists`
- `Test-OrphanedProfile`
- `Test-SpecialAccount`
