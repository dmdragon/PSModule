# A function retrieves a network device using a driver signed by the specified digital signer.
function Get-NetAdapterSigner
{
    [CmdletBinding()]
    Param
    (
        [string]$Signer
    )

    Process
    {
        Get-NetAdapter |
        Where-Object -FilterScript {
            (($_ |
            Get-NetDriverPath |
            Get-AuthenticodeSignature).SignerCertificate.Subject |
            ConvertFrom-CertificateSubject).CN -like $Signer
        }
    }
}
