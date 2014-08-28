        
		write-verbose 'Checking for VMware PsSnapin'
        if ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null)
		{
            write-verbose 'VMware PsSnapin not present, adding it to session'
            Add-PsSnapin VMware.VimAutomation.Core
        }
		else
		{
            write-verbose 'VMware PsSnapin present'
        }

        write-verbose 'Checking for vCenter connection'
        if ($global:DefaultVIServers.Count -gt 0)
		{
            write-verbose 'Already connected to vCenter'
        }
		else
		{
            write-verbose 'Not connected to vCenter, connecting'
            Connect-VIServer ___VCENTER_SERVER___ -WarningAction SilentlyContinue > $null
        }
