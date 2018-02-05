function Get-MonitorInformation {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateScript({ Validate-Computername -ComputerName $_ })]
        [string] $ComputerName = $env:COMPUTERNAME
    )

    try {
        $Monitors = Get-CimInstance -ClassName WmiMonitorID -Namespace root\wmi -ComputerName $ComputerName -ErrorAction Stop
        Write-Verbose -Message "Retrieved 'WmiMonitorID' from $ComputerName."   
    } catch {
        throw "Error retrieving 'WmiMonitorID' from $ComputerName. You may need to configure WinRM on the target computer."
    }

    try {
        $Computer = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $ComputerName -ErrorAction Stop
        Write-Verbose -Message "Retrieved 'Win32_ComputerSystem' from $ComputerName."
        Write-Debug -Message $Computer
    } catch {
        throw "Error retrieving 'Win32_ComputerSystem' from $ComputerName. You may need to configure WinRM on the target computer."
    }

    try {
        foreach ($Monitor in $Monitors) {
            $MonitorInfo = [PSCustomObject] @{
                ComputerName  = $ComputerName
                ComputerType  = $Computer.Model
                MonitorSerial = ($Monitor.SerialNumberID -ne 0 | foreach {[char]$_}) -join ""
                MonitorType   = ''
            }

            if ($Monitor.UserFriendlyName -ne $null) {
                $MonitorInfo.MonitorType = ($Monitor.UserFriendlyName -ne 0 | foreach {[char]$_}) -join ""            
            }

            $MonitorInfo
            Write-Debug -Message $MonitorInfo
        }
    } catch {
        throw "Failed to get monitor information for computer $ComputerName"
    }
}
