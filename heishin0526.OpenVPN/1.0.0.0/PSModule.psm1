
#########################################################################################
#
# Copyright (c) Pull Promotion 3rd Previous Paddy. All rights reserved.
#
# heishin0526.OpenVPN Module
#
#########################################################################################

Microsoft.PowerShell.Core\Set-StrictMode -Version Latest

#region script variables

# Check if this is nano server. [System.Runtime.Loader.AssemblyLoadContext] is only available on NanoServer
$script:isNanoServer = $null -ne ('System.Runtime.Loader.AssemblyLoadContext' -as [Type])

$script:Extension = 'ps1'
$script:NotMatch = '\.Tests\.'
$script:Path = $PSScriptRoot

$script:Include = '*.{0}' -f $Extension

#endregion

#region functions

foreach($Item in (Microsoft.PowerShell.Management\Get-ChildItem -Path $Path -Include $Include -Recurse -File))
{
    if($Item.Name -notmatch $NotMatch)
    {
        . $Item.PSPath
    }
}

#endregion
