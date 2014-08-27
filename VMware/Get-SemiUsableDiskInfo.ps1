function Get-SemiUsableDiskInfo {
  <#
  .SYNOPSIS
  Gathers information about disks on Virtual Machines
  .DESCRIPTION
  Merges disk information from both vCenter and Windows to help determine 
  exactly which disks in either system correlate to disks in the other.

  Helps to ensure that maintenance or deletion are happening to the correct 
  disk.
  .EXAMPLE
  Get-SemiUsableDiskInfo file1

  Displays the combined information about all SCSI disks on the server "file1."
  .EXAMPLE
  Get-SemiUsableDiskInfo -computername file1,file2,file3 | Format-Table

  Displays the combined information about all SCSI disks on the servers "file1", 
  "file2", "file3" and formats the output in a table.
  .NOTES
  Requires that VMware PowerCLI is installed on the system that runs this 
  cmdlet

  This cmdlet must be run by an account with administrator access on the target 
  systems.

  The Windows Remote Management service must be configered on the target 
  systems (winrm qc)

  The name of this cmdlet was chosen in a previous revision, when the 
  information returned was much less complete and not as useful, requiring more 
  manual work. The name stuck.
  .PARAMETER computer
  The computer name to query. Can be one or more.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  .LINK
  https://github.com/Windos/powershell-depot
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$True,
      ValueFromPipeline=$True,
      ValueFromPipelineByPropertyName=$True,
      Position=0,
      HelpMessage='What computer name would you like to target?')]
    [Alias('host')]
    [string[]]$computername,
		
    [string]$logname = 'errors.txt'
  )

  begin {
    $defaultDisplaySet = 'VMwareDiskName','WindowsDiskNumber','TotalSize','SCSIController','Filename'
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet(‘DefaultDisplayPropertySet’,[string[]]$defaultDisplaySet)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)

    Write-Verbose -Message "Deleting $logname"
    Remove-Item -Path $logname -ErrorAction SilentlyContinue

    Write-Verbose -Message "Checking for VMware PsSnapin"
    if ( (Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null ) {
      Write-Verbose -Message "VMware PsSnapin not present, adding it to session"
      Add-PsSnapin -Name VMware.VimAutomation.Core
    } else {
      Write-Verbose -Message "VMware PsSnapin present"
    }

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

    foreach ( $computer in $computername ) {
      
      # Gathering initial information from vCenter
      $vm = get-vm $computer
      $scsiList = $VM.Extensiondata.Config.Extraconfig | Where-Object {$_.key –like "scsi*.pcislotnumber"} | Select-Object -Property key,value
      $vmDisks = Get-HardDisk -VM $vm

      # Garther Disk information from remote computer, if an error occurs it may be firewall or WinRM related
      $cimDisks = get-disk -CimSession $computer -ErrorAction Continue | Select-Object -Property path,number,size | Sort-Object -Property number
      
      $gatheredInformation = @()
    
      # Performing a little preperation on the information gathered so far
      foreach ( $cimDisk in $cimDisks ) {
        $splitPath = $cimDisk.path.ToString().Split('#')
        $diskInfoArray = ,($splitPath[1],$splitPath[2],$cimDisk.number,$cimDisk.size)
        $gatheredInformation += $diskInfoArray
      }

      foreach ( $info in $gatheredInformation ) {
        $parent = $info[0]
        
        # Only continue if disk is of the type we're looking for, determined by the $parent variable
        if ( $parent -eq 'Disk&Ven_VMware&Prod_Virtual_disk' ) {
          $sub = $info[1]
          
          # Open remote registery and retrieve desired information
          # Requires admin privilages on remote computer
          $fullPath = "SYSTEM\CurrentControlSet\Enum\SCSI\$parent\$sub\"
          $remoteReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
          $remoteRegKey= $remoteReg.OpenSubKey($fullPath)
          $infoUINumber = $remoteRegKey.GetValue("UINumber")
          $infoLocInfo = ((($remoteRegKey.GetValue("LocationInformation")).Split(' '))[5]).Replace(',','')
          
          # I ran into a miss match between the UINumber reported by VMware and Windows
          # Corrects the Windows value (161) to the VMware value (1184)
          if ( $infoUINumber -eq 161 ) {
            $infoUINumber = 1184
          }
          
          # Loop through all SCSI controllers, as disovered using the current target's VM Extensiondata
          # Tidy up string if the controller's pcislotnumber equals the current disk's UINumber
          $scsiController = foreach ($scsi in $scsiList) { if ($scsi.value -eq $infoUINumber) {$scsi.Key} }
          if ( $scsiController -ne $null ) {
            $scsiController = (($scsiController.Split('.'))[0]).TrimStart("scsi")
          } else {
            $scsiController = '<NOT FOUND>'
          }    

          # Create Output object using existing data
          $result = New-Object -TypeName PSCustomObject -property @{"WindowsDiskNumber"=$info[2];
            "TotalSize"=$info[3]/1GB;
            "SCSIController"=$scsiController + ':' + $infoLocInfo;
            "UINumber"=$infoUINumber
          }

          # Finally, get some more information from vCenter for names and locations to make actioning
          # tasks easier
          foreach ( $vmDisk in $vmDisks ) {
            $controller = Get-ScsiController -HardDisk $vmDisk
            if ( ($controller.Name).TrimStart("SCSI controller") -eq $scsiController ) {
              if ( $vmDisk.ExtensionData.UnitNumber -eq $infoLocInfo ) {
                $result | Add-Member -MemberType NoteProperty -Name 'VMwareDiskName' -Value $vmDisk.Name
                $result | Add-Member -MemberType NoteProperty -Name 'FileName' -Value $vmDisk.Filename
              }
            }
          }

          $result | Add-Member MemberSet PSStandardMembers $PSStandardMembers
          $result
        }
      }
    }
  }
}