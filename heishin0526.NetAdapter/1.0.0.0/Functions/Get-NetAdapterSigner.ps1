# 指定されたデジタル署名者によって署名されたドライバーを使用しているネットワークデバイスを取得する関数
function Get-NetAdapterSigner
{
    [CmdletBinding()]
    Param
    (
        [string]$Signer
    )

    Process
    {
        # 署名されていない場合、SignerCertificate が存在しないため、
        # Subject を取得できない。
        Get-NetAdapter |
        Where-Object -FilterScript {
            (($_ |
            Get-NetDriverPath |
            Get-AuthenticodeSignature).SignerCertificate.Subject |
            ConvertFrom-CertificateSubject).CN -like $Signer
        }
    }
}
