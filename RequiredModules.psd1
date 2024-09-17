@{
    <#
        This is only required if you need to use the method PowerShellGet & PSDepend
        It is not required for PSResourceGet or ModuleFast (and will be ignored).
        See Resolve-Dependency.psd1 on how to enable methods.
    #>
    #PSDependOptions             = @{
    #    AddToPath  = $true
    #    Target     = 'output\RequiredModules'
    #    Parameters = @{
    #        Repository = 'PSGallery'
    #    }
    #}

    InvokeBuild           = 'latest'
    PSScriptAnalyzer      = 'latest'
    Pester                = 'latest'
    ModuleBuilder         = 'latest'
    ChangelogManagement   = 'latest'
    Sampler               = 'latest'
    'Sampler.GitHubTasks' = 'latest'
    'WisherTools.Helpers' = 'latest'
    #'WinRegOps'           = '0.3.0'

    'WinRegOps'           = @{
        Version    = '0.4.0-preview0002'
        Parameters = @{
            AllowPrerelease = $true
            Repository      = "PSGallery"
        }
    }
}
