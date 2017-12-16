# Retrieve the FileInfo object of the OpenVPN configuration file.
function Get-OpenVPNConfig
{
    <#
        .SYMOPSIS
            Gets the FileInfo object for the OpenVPN configuration file.

        .DESCRIPTION
            The Get-OpenVPNCnfig function retrieves the file object of the OpenVPN configuration file.

            The OpenVPN configuration file is either%userprofile%\openvpn\config or stored in the path specified in the registry. Also, the extension of the configuration file is specified in the registry. Get the file object from them.

            If you specify a configuration file name in the parameter $File, retrieve the file object for that file name.

        .PARAMETER FileName
            The name of a configuration file

        .INPUTS
            None

        .OUTPUTS
            System.IO.FileInfo
    #>
    [CmdletBinding()]
    Param
    (
        [string]
        $FileName
    )

    Begin
    {
        #region Message

        $Message = DATA {
            ConvertFrom-StringData -StringData @'
                NotOpenVPNConfigPath = The folder that contains the OpenVPN configuration file does not exist.
                NotOpenVPNConfigExt  = OpenVPN configuration file extension is not set.
'@
        }

        #endregion

        #region Variables

        $Config         = 'config'
        $ConfigDir      = 'config_dir'
        $ConfigExt      = 'config_ext'
        $Format         = '*.{0}'
        $FullName       = 'FullName'
        $HkcuOpenVpnGui = 'HKCU:\Software\OpenVPN-GUI'
        $HklmOpenVpn    = 'HKLM:\SOFTWARE\OpenVPN'
        $OpenVpn        = 'OpenVPN'

        $ConfigDirectoryInfo = @()

        #endregion

        #region Pre process

        # Candidate of the config path:
        # 1. %USERPROFILE%\OpenVPN\config, 2. HKCM:\Software\OpenVPN-GUI, 3. HKLM:\SOFTWARE\OpenVPN
        $ConfigPath = @(
            (Join-Path -Path $env:USERPROFILE -ChildPath (Join-Path -Path $OpenVpn -ChildPath $Config)),
            (Get-Item -Path $HkcuOpenVpnGui).GetValue($ConfigDir),
            (Get-Item -Path $HklmOpenVpn).GetValue($ConfigDir)
        )

        # Candidate of the extension:
        # 1. HKCM:\Software\OpenVPN-GUI, 2. HKLM:\SOFTWARE\OpenVPN
        $ConfigExtValue = @(
            (Get-Item -Path $HkcuOpenVpnGui).GetValue($ConfigExt),
            (Get-Item -Path $HklmOpenVpn).GetValue($ConfigExt)
        )

        # Get objects of the configuration path from candidates
        foreach($Item in $ConfigPath)
        {
            if($Item -and (Test-Path -Path $Item))
            {
                [object[]]$ConfigDirectoryInfo += Get-Item -Path $Item
            }
        }

        # If the full path is the same, put it together.
        if($ConfigDirectoryInfo)
        {
            $ConfigDirectoryInfo = Sort-Object -InputObject $ConfigDirectoryInfo -Property $FullName -Unique
        }
        # If not, the error ends.
        else
        {
            throw $Message.NotOpenVPNConfigPath
        }

        # If a file parameter specifies, set to filter.
        if($FileName)
        {
            $Filter = $FileName
        }
        else
        {
            # Get the extension of the configuration file from candidates
            foreach($Item in $ConfigExtValue)
            {
                if($Item -ne $null)
                {
                    $Extension = $Item
                    break
                }
            }

            # Set a filter to "*.$extension"
            if($Extension)
            {
                $Filter = $Format -f $Extension
            }
            # If not, the error ends.
            else
            {
                throw $Message.NotOpenVPNConfigExt
            }
        }

        #endregion
    }

    Process
    {
        # Return objects of the configuration file.
        Get-ChildItem -Path $ConfigDirectoryInfo -Filter $Filter -File -Recurse
    }
}
