#
# Module manifest for module 'WinProfileOps'
#
# Generated by: LarryWisherMan
#
# Generated on: 9/6/2024
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule           = 'WinProfileOps.psm1'

    # Version number of this module.
    ModuleVersion        = '0.0.1'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID                 = '1abff4b3-dadd-480c-a825-2671dfb7b3bd'

    # Author of this module
    Author               = 'LarryWisherMan'

    # Company or vendor of this module
    CompanyName          = 'LarryWisherMan'

    # Copyright statement for this module
    Copyright            = '(c) 2024 LarryWisherMan. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'The WinProfileOps module provides an essential toolkit for managing Windows user profiles across local and remote computers. This module automates complex profile management tasks such as detecting orphaned profiles, validating profile paths, and removing stale or corrupted profiles. It handles both filesystem and registry operations, leveraging its dependency on WinRegOps for registry-related functions.

WinProfileOps integrates with WinRegOps to seamlessly manage profiles by querying, validating, and deleting user profile-related data from the Windows registry. This module is ideal for system administrators seeking to streamline profile management operations, especially in environments with numerous users and computers.

Dependencies:
- WinRegOps: The WinProfileOps module depends on WinRegOps for registry operations such as querying, opening, and modifying registry keys related to user profiles.

Key features:
- Retrieve user profile information from both the registry and file system (local and remote).
- Detect orphaned profiles (e.g., missing profile folders or registry entries).
- Remove orphaned or unused profiles from the system.
- Filter and exclude special accounts like system or service accounts.
- Built-in support for remote profile management.
- Error handling for permission issues or unreachable systems.
- Class-based profile objects for easy integration with other automation tasks.

Typical use cases include:
- Cleaning up orphaned user profiles after system migrations or user deactivations.
- Automating the detection and removal of stale profiles on local and remote systems.
- Managing user profiles in large-scale, multi-user environments (e.g., terminal servers, Citrix environments).
- Excluding system accounts from profile cleanup operations, ensuring important profiles remain intact.
- Providing profile management capabilities as part of system maintenance routines.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion    = '5.1'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules      = @('WisherTools.Helpers')

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules        = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @()

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # Variables to export from this module
    VariablesToExport    = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @()

    # DSC resources to export from this module
    DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            Prerelease   = ''
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @(
                'WindowsProfiles',
                'ProfileManagement',
                'OrphanedProfiles',
                'RegistryOperations',
                'FilesystemOperations',
                'RemoteManagement',
                'UserProfiles',
                'ProfileCleanup',
                'WindowsRegistry',
                'SystemAdministration',
                'Automation',
                'ProfileValidation',
                'WindowsManagement',
                'ITAdministration',
                'UserProfileTools'
            )

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/LarryWisherMan/WinProfileOps/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/LarryWisherMan/WinProfileOps'

            # A URL to an icon representing this module.
            IconUri      = 'https://raw.githubusercontent.com/LarryWisherMan/ModuleIcons/main/WinProfileOps.png'

            # ReleaseNotes of this module
            ReleaseNotes = ''

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}
