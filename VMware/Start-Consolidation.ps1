# Adding this PsSnapin here, instead of in the begin block, as I am using the VirtualMachine type for a parameter
if ( (Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null ) {
  Add-PsSnapin -Name VMware.VimAutomation.Core
}

function Start-Consolidation {
  <#
  .SYNOPSIS
  Consolidates VM disks
  .DESCRIPTION
  Calls a VM object's "ConsolidateVMDisks" method. Takes VirtualMachine objects as input (Get-VM or similar command), best used in conjunction with Get-ConsolidationNeeded which will only return objects that require disk consolidation.

  Will connect to 'vcenter.hawk-i.govt.nz' if you have not connected to a vCenter server with the Connect-VIServer cmdlet.
  .EXAMPLE
  Get-VM | Start-Consolidation

  Attempts to consolidate every VM registered to the currently connected vCenter server regardless of whether they need consolidation or not.
  .EXAMPLE
  Get-ConsolidationNeeded | Start-Consolidation

  Determines which VMs, out of all VMs registered to the currently connected vCenter server, needs consolidation and consolidates them.
  .PARAMETER VM
  Specifies the Virtual Machine you would like to conolsidate.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  .LINK
  https://github.com/Windos/powershell-depot
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Position=0,
      Mandatory=$True,
      ValueFromPipeline=$True,
      ValueFromPipelineByPropertyName=$True,
      HelpMessage='Which virtual machine(s) would you like to target?')]
    [VirtualMachine[]]$VM,
		
    [string]$logname = 'errors.txt'
  )

  begin {
    Write-Verbose -Message "Deleting $logname"
    Remove-Item -Path $logname -ErrorAction SilentlyContinue
	
    Write-Verbose -Message "Checking for vCenter connection"
    if ( $global:DefaultVIServers.Count -gt 0 ) {
      Write-Verbose -Message "Already connected to vCenter"
    } else {
      Write-Verbose -Message "Not connected to vCenter, connecting"
      Connect-VIServer -Server ___VCENTER_SERVER___ -WarningAction SilentlyContinue > $null
    }
  }

  process {
    Write-Verbose -Message "Beginning process loop"
    $VM | ForEach-Object {
      Write-Verbose -Message "Starting disk consolidation on $_.Name"
      try {
        $_.ExtensionData.ConsolidateVMDisks()
        Write-Verbose -Message "Finished disk consolidation on $_.Name"
      }
      catch
      {
        Write-Warning -Message "Disk consolidation failed on $_.Name, it is possible that this Virtual Machine did not require consolidation."
      }
    }
  }
}