# A function verifies the connection of a network device.
function Test-NetAdapterConnection
{
    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline=$true)]
        [Microsoft.Management.Infrastructure.CimInstance]
        $NetAdapter
    )

    Begin
    {
        $Up = 'Up'
    }

    Process
    {
        if($NetAdapter.Status -eq $Up)
        {
            $true
        }
        else
        {
            $false
        }
    }
}
