@{
    IgnoredAccounts = @(
        "defaultuser0",
        "DefaultAppPool",
        "servcm12",
        "Public",
        "PBIEgwService",
        "Default",
        "All Users",
        "win2kpro"
    )

    IgnoredSIDs     = @(
        "S-1-5-18",
        "S-1-5-19",
        "S-1-5-20"
    )

    IgnoredPaths    = @(
        "C:\WINDOWS\system32\config\systemprofile",
        "C:\WINDOWS\ServiceProfiles\*"
    )
}
