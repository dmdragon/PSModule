# 指定されたワイルドカード文字列に一致する著作権(LegalCopyright)が設定された
# ドライバーファイルを使用しているネットワークアダプターを取得する関数
function Get-NetAdapterLegalCopyright
{
    [CmdletBinding()]
    Param
    (
        [string]
        $LegalCopyright
    )

    Process
    {
        foreach($NetAdapter in (Get-NetAdapter))
        {
            $NetDriverPath = Get-NetDriverPath -InputObject $NetAdapter
            $FileInfo = Get-Item -Path $NetDriverPath
            if($FileInfo -is [System.IO.FileInfo] -and
               $FileInfo.VersionInfo.LegalCopyright -like $LegalCopyright)
            {
                $NetAdapter
            }
        }
    }
}
