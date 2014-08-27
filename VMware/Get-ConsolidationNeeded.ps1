# Adding this PsSnapin here, instead of in the begin block, as I am using the
# VirtualMachine type strongly type return object
if ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null)
{
    Add-PsSnapin -Name VMware.VimAutomation.Core
}

function Get-ConsolidationNeeded
{

<#
    .SYNOPSIS
    Find vSphere VMs that need disk consolidation.

    .DESCRIPTION
    Checks vCenter for Virtual Machines that require disk consolidation. You
	can specify a sepcific VM, a list of VMs and/or a location in vSphere (like
	a folder) or not specify any arguments to get every VM registered to the
    currently connected vCenter Server.

    Will connect to 'vcenter.hawk-i.govt.nz' if you have not connected to a
    vCenter server with the Connect-VIServer cmdlet.

    .EXAMPLE
    Get-ConsolidationNeeded -Name AD1,AD2

    Checks the two specified VMs (AD1 and AD2) to determine if they require
	disk consolidation.

    .EXAMPLE
    Get-ConsolidationNeeded -Location TestDev

    Check all VMs in vSphere location "TestDev" for needed disk consolidation.

    .EXAMPLE
    Get-ConsolidationNeeded -Name isolated-* -Location Development

    Checks all VMs in Vsphere location "Development" whose name begins with
    isolated- for needed disk consolidation.

    .EXAMPLE
    Get-ConsolidationNeeded | Start-Consolidation

    Check all VMs registered to the currently connected vCenter server for
	needed disk consolidation and begins the proccess of consolidating disks if
	needed.

    .PARAMETER Name
    Specifies the name(s) of the virtual machine(s) you want to retrieve.

    .PARAMETER Location
    Specifies the name(s) of the vSphere container object(s) you want to search
    for virtual machines. Supported container object types are: ResourcePool,
    VApp, VMHost, Folder, Cluster, Datacenter.

    .PARAMETER logname
    The name of a file to write failed computer names to. Defaults to errors.txt.

    .LINK
    Start-Consolidation

    .LINK
    https://github.com/Windos/powershell-depot
#>

    [CmdletBinding()]
	[OutputType(VMware.VimAutomation.ViCore.Impl.V1.Inventory.VirtualMachineImpl[])]
    param
    (
        [Parameter(Position=0,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$False,
                   HelpMessage='What Virtual Machine would you like to target?')]
        [string[]]$Name,

        [Parameter(Mandatory=$False,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$False,
                   ValueFromRemainingArguments=$False,
                   HelpMessage='Which vSphere container would you like to search for virtual machines?')]
        [Alias('VIContainer')]
        [String[]]$Location,

        [string]$logname = 'errors.txt'
    )

    begin
	{
        Write-Verbose -Message "Deleting $logname"
        Remove-Item -Path $logname -ErrorAction SilentlyContinue

        Write-Verbose -Message 'Checking for vCenter connection'
        if ($global:DefaultVIServers.Count -gt 0)
		{
            Write-Verbose -Message 'Already connected to vCenter'
        }
		else
		{
            Write-Verbose -Message 'Not connected to vCenter, connecting'
            Connect-VIServer -Server ___VCENTER_SERVER___ -WarningAction SilentlyContinue > $null
        }
    }

    process
	{
        Write-Verbose -Message 'Determining parameters for Get-VM cmdlet'

        $splat = @{'Name' = $Name;
                   'Location' = $Location}

        if (!$Name)
		{
		    $splat.Remove('Name')
	    }

		if (!$Location)
		{
		    $splat.Remove('Location')
	    }

        Write-Verbose -Message 'Beginning look trough VMs'
        foreach ($vm in (Get-VM @splat))
		{
            Write-Verbose -Message "Checking for disk consolidated needed on $vm"
            if ($vm.Extensiondata.Runtime.ConsolidationNeeded)
			{
                Write-Verbose -Message "$vm requires disk consolidation"
                $vm | Select-Object -Property 'Name','PowerState',@{Name = 'ConsolidationNeeded'; Expression = {$_.Extensiondata.Runtime.ConsolidationNeeded}}
            }
        }
    }
}
