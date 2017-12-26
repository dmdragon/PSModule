# Connect using OpenVPN-GUI
function Connect-OpenVPN
{
    <#
        .SYNOPSIS
            Connect using OpenVPN-GUI to OpenVPN server.

        .DESCRIPTION
            The Connect-OpenVPN function uses OpenVPN-GUI.exe to connect to the OpenVPN server.

            To use, the folder included OpenVPN-GUI.exe should be in the PATH environment variable,

        .PARAMETER ConfigFile
            The name of the configuration file.

        .INPUTS
            None

        .OUTPUTS
            None
    #>
    [CmdletBinding()]
    Param
    (
        [string]
        $ConfigFile
    )

    Begin
    {
        #region Filter

        # Returns true if the network device is not active and true within the time limit, otherwise false.
        filter Test-NetNotUpAndInTime([ciminstance]$NetAdapter, [datetime]$Start, [int]$Expire)
        {
            <#
                .SYNOPSIS
                    Returns true if the network device is not active and true within the time limit, otherwise false.

                .DESCRIPTION
                    The filter Test-NetNotUpAndInTime returns true if status of the network device is not "up" and within the time limit, otherwise false.

                    Returns false if the network device's index number property does not exist, or if there is no network device with the index number.

                .PARAMETER NetAdapter
                    Network device

                .PARAMETER Start
                    Start time

                .PARAMETER Expire
                    Time limit (min.)

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

        #region Message

        $Message = DATA {
            ConvertFrom-StringData -StringData @'
                MultipleAdapters = There are multiple network adapters.
                MultipleConfFiles = There are multiple configure files.
'@
        }

        #endregion

        #region Set the value of variables

        $ConnectCommand = '{0} --connect {1}' # Command of connect VPN: {0}:Application name {1}:Configuration file name
        $Expire         = 5 # Time limit (min.)
        $Extension      = 'exe' # Extension of the application.
        $Interval       = 1 # Interval of checking to connect (sec.)
        $OpenVPN        = 'OpenVPN' # Name of OpenVPN
        $OpenVPNGUI     = 'OpenVPN-GUI' # Name of OpenVPN-GUI
        $Stopped        = $false # Stopped flag.

        $LegalCopyright        = '*{0}*' -f $OpenVPN # Wildcard use string that matches the "copyright" of the driver file
        $OpenVPNCommandName    = '{0}.{1}' -f $OpenVPN, $Extension # OpenVPN application name
        $OpenVPNGUICommandName = '{0}.{1}' -f $OpenVPNGUI, $Extension # OpenVPN-GUI application name
        $OpenVPNGUIProcess     = New-Object -TypeName 'System.Diagnostics.Process' # OpenVPN-GUI process object

        #endregion

        #region Pre process

        # Exit if OpenVPN.exe and OpenVPN-GUI.exe are not found.
        $DefaultErrorActionPreference = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
        try
        {
            Get-Command -Name $OpenVPNCommandName | Out-Null
            Get-Command -Name $OpenVPNGUICommandName | Out-Null
        }
        catch
        {
            throw
        }
        finally
        {
            $ErrorActionPreference = $DefaultErrorActionPreference
        }

        $DefaultErrorActionPreference = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
        try
        {
            # Get start time.
            $StartTime = Get-Date
            # Get file object of OpenVPN configuration file.
            $Config = Get-OpenVPNConfig -File $ConfigFile
            # Get the network adapter object that contains "OpenVPN" in the "copyright" of the driver file.
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

        # Exit if you have more than one configuration file.
        if($Config -is [System.Object[]])
        {
            throw $Message.MultipleConfFiles
        }

        # Exit if there are multiple network adapters.
        if($NetAdapter -is [System.Object[]])
        {
            throw $Message.MultipleAdapters
        }

        #endregion
    }

    Process
    {
        # If not connected to a VPN and in a limited time, run connecting.
        while(Test-NetNotUpAndInTime -NetAdapter $NetAdapter -Start $StartTime -Expire $Expire)
        {
            # If the OpenVPN process is exist, stop the process.
            # Since it is not normal for the process to exist while not connected.
            $DefaultErrorActionPreference = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
            try
            {
                if($OpenVPNProcess = Get-Process -Name $OpenVPN)
                {
                    Stop-Process -InputObject $OpenVPNProcess -Force
                }
            }
            catch [Microsoft.PowerShell.Commands.ProcessCommandException]
            {
                # Nothing if the OpenVPN process is not exist.
            }
            # Exit if an error occurs when get the OpenVPN process.
            catch
            {
                throw
            }
            finally
            {
                $ErrorActionPreference = $DefaultErrorActionPreference
            }

            # Get the OpenVPN-GUI process
            $DefaultErrorActionPreference = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
            try
            {
                $OpenVPNGUIProcess = Get-Process -Name $OpenVPNGUI
            }
            # If the OpenVPN-GUI process does not exist, perform a OpenVPN-GUI connection
            # and wait for the connection to complete (or run out of time).
            catch [Microsoft.PowerShell.Commands.ProcessCommandException]
            {
                Invoke-Expression -Command ($ConnectCommand -f $OpenVPNGUICommandName, $Config.Name)
                while(Test-NetNotUpAndInTime -NetAdapter $NetAdapter -Start $StartTime -Expire $Expire)
                {
                    Start-Sleep -Seconds $Interval
                }
            }
            # Exit if an error occurs when get the OpenVPN-GUI process.
            catch
            {
                throw
            }
            finally
            {
                $ErrorActionPreference = $DefaultErrorActionPreference
            }

            # If the OpenVPN-GUI process is not connected to a VPN, stop the process and flag it for a while.
            $DefaultErrorActionPreference = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
            try
            {
                if($OpenVPNGUIProcess.Name -and -not $Stopped)
                {
                    Stop-Process -InputObject $OpenVPNGUIProcess -Force
                    $Stopped = $true
                }
            }
            # Exit if an error occurs when stop the OpenVPN-GUI process.
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
