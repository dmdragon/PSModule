# OpenVPNの設定ファイルのFileInfoオブジェクトを取得する関数
function Get-OpenVPNConfig
{
    <#
        .SYMOPSIS
            OpenVPNの設定ファイルのFileInfoオブジェクトを取得します。

        .DESCRIPTION
            関数 Get-OpenVPNConfig は、OpenVPNの設定ファイルのファイルオブジェクトを取得します。

            OpenVPNの設定ファイルは、%USERPROFILE%\OpenVPN\config か、レジストリで指定されたパスに格納されています。また、
            設定ファイルの拡張子も、レジストリで指定されています。それらからファイルのオブジェクトを取得します。

            パラメーター $File で設定ファイル名を指定した場合は、そのファイル名のファイルオブジェクトを取得します。

            設定ファイル名を指定しない場合は、拡張子 ovpn のファイルのオブジェクトを取得します。

        .PARAMETER FileName
            設定ファイルのファイル名

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
        $Message = DATA {
            ConvertFrom-StringData -StringData @'
                NotOpenVPNConfigPath = The folder that contains the OpenVPN configuration file does not exist.
                NotOpenVPNConfigExt = OpenVPN configuration file extension is not set.
'@
        }

        $Config    = 'config'
        $ConfigDir = 'config_dir'
        $ConfigExt = 'config_ext'
        $OpenVPN   = 'OpenVPN'

        $ConfigPath = Join-Path -Path $env:USERPROFILE -ChildPath (Join-Path -Path $OpenVPN -ChildPath $Config)
        if($ConfigPath -and (Test-Path -Path $ConfigPath))
        {
            [object[]]$ConfigDirectoryInfo += Get-Item -Path $ConfigPath
        }
        $RegKey = 'HKCU:\Software\OpenVPN-GUI'
        $ConfigPath = (Get-Item -Path $RegKey).GetValue($ConfigDir)
        if($ConfigPath -and (Test-Path -Path $ConfigPath))
        {
            [object[]]$ConfigDirectoryInfo += Get-Item -Path $ConfigPath
        }
        $RegKey = 'HKLM:\SOFTWARE\OpenVPN'
        $ConfigPath = (Get-Item -Path $RegKey).GetValue($ConfigDir)
        if($ConfigPath -and (Test-Path -Path $ConfigPath))
        {
            [object[]]$ConfigDirectoryInfo += Get-Item -Path $ConfigPath
        }
        if(-not $ConfigDirectoryInfo)
        {
            throw $Message.NotOpenVPNConfigPath
        }

        $RegKey = 'HKCU:\Software\OpenVPN-GUI'
        $Extension = (Get-Item -Path $RegKey).GetValue($ConfigExt)
        if($Extension -eq $null)
        {
            $RegKey = 'HKLM:\SOFTWARE\OpenVPN'
            $Extension = (Get-Item -Path $RegKey).GetValue($ConfigExt)
        }
        if($Extension -eq $null)
        {
            throw $Message.NotOpenVPNConfigExt
        }

        $Filter = '*.{0}' -f $Extension

        if($FileName)
        {
            $Filter = $FileName
        }
    }

    Process
    {
        Get-ChildItem -Path $ConfigDirectoryInfo -Filter $Filter -File -Recurse
    }
}
