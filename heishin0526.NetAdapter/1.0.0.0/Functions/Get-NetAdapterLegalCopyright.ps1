# A function retrieves a network adapter using a driver file
# with a legal copyright matches the specified wildcard string.
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
