# WinProfileOps

<p align="center">
  <img src="https://raw.githubusercontent.com/LarryWisherMan/ModuleIcons/main/WinProfileOps.png"
       alt="WinProfileOps Icon" width="400" />
</p>

The **WinProfileOps** module provides a robust toolkit for managing Windows user
profiles on both local and remote computers. This module simplifies and automates
complex profile management tasks, such as detecting orphaned profiles, validating
profile paths, and identifying stale or corrupted profiles. It handles both filesystem
and registry operations, utilizing the **WinRegOps** module for registry-related
functions.

**WinProfileOps** seamlessly integrates with **WinRegOps** to manage profiles by
querying, validating, and auditing user profile-related data from the Windows
registry. This module is ideal for system administrators who want to streamline
profile management operations, especially in environments with numerous users and
computers.

---

## Dependencies

- **WinRegOps**: The **WinProfileOps** module depends on
  [**WinRegOps**](https://github.com/LarryWisherMan/WinRegOps) for registry
  operations such as querying, opening, and modifying registry keys related to user
  profiles.

---

## Key Features

- **Retrieve user profile information** from both the registry and the file system
  (local and remote).
- **Detect orphaned profiles**, such as profiles missing from the file system or
  registry.
- **Filter and exclude special accounts** like system or service accounts (e.g.,
  `defaultuser0`, `S-1-5-18`).
- **Remote profile management** with support for handling user profiles across
  different systems.
- **Error handling** for permission issues, unreachable systems, and missing data.
- **Class-based profile objects** for easy integration with other automation tasks
  or scripts.

---

## Typical Use Cases

- **Cleaning up orphaned profiles** after system migrations, user deactivations, or
  profile corruption.
- **Managing user profiles in large-scale environments**, such as terminal servers,
  Citrix environments, or multi-user systems.
- **Excluding system accounts** from profile cleanup operations to prevent accidental
  deletion of important system profiles.
- **System maintenance routines** that include profile validation and management as
  part of a broader system health check.

---

## Installation

You have two options to install **WinProfileOps**:

1. **Install from PowerShell Gallery**  
   You can install the module directly from the 
   [PowerShell Gallery](https://www.powershellgallery.com/packages/WinProfileOps)
   using the `Install-Module` command:

   ```powershell
   Install-Module -Name WinProfileOps
   ```

2. **Install from GitHub Releases**  
   You can also download the latest release from the 
   [GitHub Releases page](https://github.com/LarryWisherMan/WinProfileOps/releases).  
   Download the `.zip` file, extract it, and place it in one of your `$PSModulePath`
   directories.

---

## Usage

#### Example 1: Detecting Orphaned Profiles

Use the `Get-OrphanedProfiles` function to detect orphaned profiles on a local or
remote machine:

```powershell
$orphanedProfiles = Get-OrphanedProfiles -ComputerName "RemotePC" -IgnoreSpecial
```

This retrieves all orphaned profiles on `RemotePC`, excluding special accounts.

#### Example 2: Retrieving User Profiles from the File System

Use the `Get-UserProfilesFromFolders` function to retrieve user profile folders from
the file system on a local or remote machine:

```powershell
$userFolders = Get-UserProfilesFromFolders -ComputerName "Server01"
```

This retrieves user profile folders from the default `C:\Users` directory on `Server01`.

#### Example 3: Retrieving User Profiles from the Registry

Use the `Get-UserProfilesFromRegistry` function to query user profiles from the
Windows registry:

```powershell
$registryProfiles = Get-UserProfilesFromRegistry -ComputerName "LocalHost"
```

This retrieves user profiles from the registry on `LocalHost`.

#### Example 4: Auditing User Profiles

Use the `Invoke-UserProfileAudit` function to audit profiles across the file system and
registry:

```powershell
$allProfiles = Invoke-UserProfileAudit -ComputerName "Server01"
```

This audits user profiles on `Server01`, returning both file system and registry
profile information.

---

## Key Functions

- **`Get-OrphanedProfiles`**: Detects orphaned profiles by checking both the
  registry and file system.
- **`Invoke-UserProfileAudit`**: Audits and compares profiles from both the registry
  and file system, identifying discrepancies such as orphaned profiles.
- **`Get-UserProfilesFromRegistry`**: Retrieves user profiles from the Windows
  registry.
- **`Get-UserProfilesFromFolders`**: Retrieves user profile folders from the file
  system.

---

## Upcoming Features

### `Remove-UserProfile` (Coming Soon!)

The `Remove-UserProfile` function will provide the ability to remove user
profiles safely from both the registry and the file system. Here are some of the
 key features being tested for this functionality:

- **Safely remove user profiles** either from the file system (i.e., user profile
 folders) or from the Windows registry.

- **Flexible inputs**: Accepts a UserProfile object, a username, or a SID for
 profile removal.

- **Powerful safeguards**: Uses `ShouldProcess`, `-WhatIf`, and `-Confirm` to
 ensure that deletion is intentional and carefully reviewed.

- **Handles special accounts**: Prevents accidental removal of critical system
 or service accounts (e.g., `S-1-5-18`).

- **Remote profile removal**: Enables profile deletion from both local and remote
 computers.

- **Verbose and error handling**: Logs every action taken and handles errors to
 provide full transparency and avoid unexpected issues.

The feature is being heavily tested to ensure safety, reliability, and accuracy.

---

## Contributing

Contributions are welcome! Feel free to fork the repository, submit pull requests,
or report issues. You can contribute by adding new features, improving the existing
code, or enhancing the documentation.
