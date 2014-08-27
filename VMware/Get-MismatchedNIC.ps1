function Get-MismatchedNIC {
  <#
  .SYNOPSIS
  Determines if there is a mismatch between "Connected" and "Connect at power 
  on" properties on VM NICs.
  .DESCRIPTION
  This cmdlet loops through a supplied list of VMs, all VMs in provided 
  clusters, or all VMs in the vCenter. For each VM, every network interface is 
  checked to determine if it is currently connected and if it is set to connect 
  when the VM starts. This is important as a NIC that is currently connected 
  could unexpectidly become disconnected after a reboot of the VM.

  true  = a mismatch has been detected
  false = the configuration of both connection states is identical

  If there is a mismatch detected but the VM is currently powered off (and the 
  NIC is set to connect at power on), this is counted as a flase positive and 
  false is returned.
  .EXAMPLE
  Get-MismatchedNIC -Cluster Production

  Tests all of the NICs for all of the VMs within the "Production" cluster.
  .EXAMPLE
  Get-MismatchedNIC -Guest ad1,ad2,ex1

  Tests the NICs on the specified VMs.
  .EXAMPLE
  Get-MismatchedNIC -All

  Tests for NIC status mismatches for all VMs registered to the currently 
  connected vCenter Server.
  .EXAMPLE
  Get-MismatchedNIC Production | Group "Mismatch"

  Groups the results of all tested VMs by their Mismatch status (true or 
  false), returning arrays of VMs.
  .EXAMPLE
  Get-MismatchedNIC -Guest ad1 | Select *

  See more details than what is returned by default, for example the actual 
  values for the component status that determine a mismatch and the VM's 
  cluster.
  .PARAMETER cluster
  The cluster to gather VMs from. You can specify one, or an array of clusters. 
  If no parameters are set it is assumed you are supplying the name, or names, 
  of a cluster.

  By default output will be ordered by cluster then by VM name.
  .PARAMETER guest
  The name of the VM to query. You can specify one, or an array of VMs.

  By default output will be ordered by VM name.
  .PARAMETER all
  This switch will gather all VMs registered to the currently connected vCenter 
  Server, regardless of name or the cluster it resides within.
  .PARAMETER logname
  The name of a file to write failure events to. Defaults to errors.txt.
  #>
  [CmdletBinding(DefaultParameterSetName = 'ClusterTarget')]
  param
  (
    [Parameter(Mandatory=$True,
      ValueFromPipeline=$True,
      ValueFromPipelineByPropertyName=$True,
      ParameterSetName='ClusterTarget',
      Position=0,
      HelpMessage='What cluster would you like to target?')]
    [string[]]$cluster,

    [Parameter(Mandatory=$True,
      ValueFromPipelineByPropertyName=$True,
      ParameterSetName='GuestTarget',
      HelpMessage='Which guest would you like to target?')]
    [Alias('vm')]
    [string[]]$guest,

    [Parameter(Mandatory=$True,
      ParameterSetName='TargetAll')]
    [switch]$all,

    [string]$logname = 'errors.txt'
  )

  begin {
    $defaultDisplaySet = 'VM Name','Network Adapter','Mismatch'
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

    write-verbose "Deleting $logname"
    Remove-Item $logname -ErrorAction SilentlyContinue

    write-verbose "Checking for VMware PsSnapin"
    if ( (Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null ) {
      write-verbose "VMware PsSnapin not present, adding it to session"
      Add-PsSnapin VMware.VimAutomation.Core
    } else {
      write-verbose "VMware PsSnapin present"
    }

    write-verbose "Checking for vCenter connection"
    if ( $global:DefaultVIServers.Count -gt 0 ) {
      write-verbose "Already connected to vCenter"
    } else {
      write-verbose "Not connected to vCenter, connecting"
      Connect-VIServer ___VCENTER_SERVER___ -WarningAction SilentlyContinue > $null
    }
  }

  process {
    Write-Verbose 'Generating list of targets'
    $targets = @()
    if ($PSCmdlet.ParameterSetName -eq 'ClusterTarget') {
      $clusters = Get-Cluster -Name $cluster | Sort-Object -Property Name
      foreach($c in $clusters)
      {
        $targets += $c | Get-VM | Sort-Object -Property Name
      }
    } elseif ($PSCmdlet.ParameterSetName -eq 'GuestTarget') {
      $targets = Get-VM $guest | Sort-Object -Property Name
    } else {
      $targets = Get-VM | Sort-Object -Property Name
    }
    
    Write-Verbose 'Begining process loop on targets'
    foreach($target in $targets) {
      Write-Verbose "Testing $target"
      $NetworkAdapters = $target | Get-NetworkAdapter
      foreach($n in $NetworkAdapters)
      {
        $mismatched = $false
        if ($n.ConnectionState.Connected -ne $n.ConnectionState.StartConnected) {
          if ($target.PowerState -ne "PoweredOff") {
            $mismatched = $true
          } elseif ($target.PowerState -eq "PoweredOff" -and $n.ConnectionState.StartConnected -eq $false) {
            $mismatched = $true
          }
        }

        $result = New-Object -TypeName PSCustomObject -property @{"VM Name"=$target.Name;
          "Cluster"=Get-Cluster -VM $target;
          "Power State"=$target.PowerState;
          "Network Adapter"=$n.Name;
          "Mismatch"=$mismatched;
          "Currently Connected"=$n.ConnectionState.Connected;
          "Connect on Start"=$n.ConnectionState.StartConnected} 
                            
        $result | Add-Member MemberSet PSStandardMembers $PSStandardMembers
        $result
      }
    }
  }
}