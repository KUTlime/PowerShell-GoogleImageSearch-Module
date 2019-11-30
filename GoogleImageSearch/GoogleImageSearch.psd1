#
# Module manifest for module 'GoogleImageSearch'
#
# Generated by: Radek Zahradník
#
# Generated on: 29.11.2019
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'GoogleImageSearch'

# Version number of this module.
ModuleVersion = '1.0.2.0'

# Supported PSEditions
# CompatiblePSEditions = @()

# ID used to uniquely identify this module
GUID = '4fa57004-f13e-4a10-81a1-abefb5310cb2'

# Author of this module
Author = 'Radek Zahradník'

# Company or vendor of this module
CompanyName = 'Radek Zahradník'

# Copyright statement for this module
Copyright = '(c) 2019 Radek Zahradník. All rights reserved.'

# Description of the functionality provided by this module
Description = 'This module enables users to search Windows lock screen wallpaper images or any another image in Google Search Image.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0.0.0'

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
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @('Search-WindowsLockScreenWallpapers','Search-Image')

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @('Search-WindowsLockScreenWallpapers','Search-Image')

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @('Google', 'Image', 'Search', 'Windows', 'wallpaper', 'wallpapers')

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/KUTlime/PowerShell-GoogleImageSearch-Module/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/KUTlime/PowerShell-GoogleImageSearch-Module'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = 'Initial release'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

