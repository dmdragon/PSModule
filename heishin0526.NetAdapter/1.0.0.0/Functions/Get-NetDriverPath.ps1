# ネットワークアダプターからドライバーのパスを取得する関数
function Get-NetDriverPath
{
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline = $true)]
        [ciminstance[]]
        $InputObject
    )

    Process
    {
        foreach($Item in $InputObject)
        {
            if($Item.DriverName -ne $null)
            {
                $EnvironmentName = ($DriverNameArray = $Item.DriverName -split '\\')[1]
                $DriverNamePath = $DriverNameArray[2..($DriverNameArray.Count - 1)] -join '\'
                foreach($Environment in (Get-ChildItem -Path env:))
                {
                    if($Environment.Name -eq $EnvironmentName)
                    {
                        $EnvironmentValue = $Environment.Value
                        break
                    }
                }
                Join-Path -Path $EnvironmentValue -ChildPath $DriverNamePath
            }
        }
    }
}
