# OpenVPN-GUI を使用して接続する関数
function Connect-OpenVPN
{
    <#
        .SYNOPSIS
            OpenVPN-GUIを使用してOpenVPNサーバーへ接続します。

        .DESCRIPTION
            関数 Connect-OpenVPN は、OpenVPN-GUI.exe を使用して、OpenVPN サーバーへ接続します。

            使用するためには、OpenVPN-GUI がパスのとおったフォルダーにあること、設定ファイルが
            OpenVPN インストールフォルダーの config サブフォルダーにあること、OpenVPN の
            ネットワークドライバーがインストールされていること、が必要です。

        .PARAMETER ConfigFile
            設定ファイルのファイル名

        .INPUTS
            None

        .OUTPUTS
            None
    #>
    [CmdletBinding()]
    Param
    (
        [string]$ConfigFile
    )

    Begin
    {
        #region フィルター

        # ネットワークデバイスがアクティブではない、かつ、制限時間内ならば真、そうでなければ偽を返すフィルター
        filter Test-NetNotUpAndInTime([ciminstance]$NetAdapter, [datetime]$Start, [int]$Expire)
        {
            <#
                .SYNOPSIS
                    ネットワークデバイスがアクティブではない、かつ、制限時間内ならば真、そうでなければ偽を返す。

                .DESCRIPTION
                    フィルター Test-NetNotUpAndInTime は、ネットワークデバイスの状態(Status)を取得して、
                    アクティブ("Up")ではなく、かつ、制限時間内なら真(true)、そうでなければ偽(false)を返します。

                    ネットワークデバイスのインデックス番号(ifIndex)のプロパティが存在しなかったり、インデックス
                    番号のネットワークデバイスが存在しなかったりした場合は、偽(false)を返します。

                .PARAMETER NetAdapter
                    ネットワークデバイス

                .PARAMETER Start
                    開始時刻

                .PARAMETER Expire
                    制限時間（分）

                .INPUTS
                    None

                .OUTPUTS
                    System.Boolean
            #>
            if($NetAdapter.IfIndex -ne $null)
            {
                $DefaultErrorActionPreference = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
                try
                {
                    $Status = (Get-NetAdapter -InterfaceIndex $NetAdapter.ifIndex).Status
                }
                catch
                {
                    $False
                }
                finally
                {
                    $ErrorActionPreference = $DefaultErrorActionPreference
                }
                $Status -ne 'Up' -and (Get-Date) -lt $StartTime.AddMinutes($Expire)
            }
            else
            {
                $False
            }
        }

        #endregion

        #region メッセージ

        $Message = DATA {
            ConvertFrom-StringData -StringData @'
                MultipleAdapters = There are multiple network adapters.
                MultipleConfFiles = There are multiple configure files.
'@
        }

        #endregion

        #region 定数

        $ConectCommand = '{0} --connect {1}' # VPN接続コマンド {0}:アプリケーション名 {1}:設定ファイル名
        $Expire        = 5 # 制限時間（分）
        $Extension     = 'exe' # アプリケーションの拡張子
        $Interval      = 1 # 接続確認実行の間隔（秒）
        $OpenVPN       = 'OpenVPN' # OpenVPN の名前
        $OpenVPNGUI    = 'OpenVPN-GUI' # OpenVPNGUI のアプリケーション名（拡張子なし）
        $Stopped       = $false # 停止中フラグ

        $CommandName    = '{0}.{1}' -f $OpenVPNGUI, $Extension # アプリケーション名
        $LegalCopyright = '*{0}*' -f $OpenVPN # ドライバーファイルの「著作権」に一致させるワイルドカード使用文字列
        $Process        = New-Object -TypeName 'System.Diagnostics.Process' # プロセスオブジェクト

        #endregion

        #region 前処理

        $DefaultErrorActionPreference = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
        try
        {
            # 開始時刻を取得
            $StartTime = Get-Date
            # OpenVPN設定ファイルのファイルオブジェクトを取得
            $Config = Get-OpenVPNConfig -File $ConfigFile
            # ドライバーファイルの「著作権」に "OpenVPN" を含むネットワークアダプターオブジェクトを取得
            $NetAdapter = Get-NetAdapterLegalCopyright -LegalCopyright $LegalCopyright
        }
        catch
        {
            throw
        }
        finally
        {
            $ErrorActionPreference = $DefaultErrorActionPreference
        }

        # 設定ファイルが複数あったら終了
        if($Config -is [System.Object[]])
        {
            throw $Message.MultipleConfFiles
        }

        # 対象のネットワークアダプターが複数あったら終了
        if($NetAdapter -is [System.Object[]])
        {
            throw $Message.MultipleAdapters
        }

        #endregion
    }

    Process
    {
        # VPN接続されておらず、かつ、制限時間内なら接続を実行
        while(Test-NetNotUpAndInTime -NetAdapter $NetAdapter -Start $StartTime -Expire $Expire)
        {
            # OpenVPNのプロセスを取得
            $DefaultErrorActionPreference = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
            try
            {
                $Process = Get-Process -Name $OpenVPNGUI
            }
            # プロセスが存在しなければ、OpenVPNの接続を実行して、接続完了（または時間切れ）まで待機
            catch [Microsoft.PowerShell.Commands.ProcessCommandException]
            {
                Invoke-Expression -Command ($ConectCommand -f $CommandName, $Config.Name)
                while(Test-NetNotUpAndInTime -NetAdapter $NetAdapter -Start $StartTime -Expire $Expire)
                {
                    Start-Sleep -Seconds $Interval
                }
            }
            # プロセス取得時にエラーが発生したら終了
            catch
            {
                throw
            }
            finally
            {
                $ErrorActionPreference = $DefaultErrorActionPreference
            }

            # VPN接続していないのにOpenVPNプロセスが存在したらプロセスを停止、停止中フラグを立てる
            $DefaultErrorActionPreference = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
            try
            {
                if($Process.Name -and -not $Stopped)
                {
                    Stop-Process -InputObject $Process
                    $Stopped = $true
                }
            }
            # プロセス停止時にエラーが発生したら終了
            catch
            {
                throw
            }
            finally
            {
                $ErrorActionPreference = $DefaultErrorActionPreference
            }
        }
    }
}
