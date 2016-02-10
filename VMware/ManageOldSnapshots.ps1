#region Configuration

$WarningDays = 1
$DeletionDays = 3

$vCenterServer = 'vcenter.example.com'
$SmtpServer = 'mail.example.com'

# Specify the Distinguished Name for the person or group responsible for your virtual environment.
# Other forms of identity may work here, I opted for DN because it is uniform with the ManagedBy property in AD.
$OperationsDN = 'CN=Operations Team,OU=mailboxes,OU=users,DC=example,DC=com'

$OperationsEmail = 'operations@example.com'

# Specify any VMware clusters you do not wish to check, useful for VDI clusters where snapshots may be used for
# provisioning desktops.
$ExcludedCluster = @('vdi')

# Similar to $ExcludedCluster, list any descriptions you want to use to skip certain snapshots, such as those 
# created by backup appliances.
$BackupSnapshotDescription = @('Created by VDP workorder *')

$ExceptionDescription = 'DO NOT DELETE'

$Signature = 'The Operations Team'

#endregion

#region HTML

$BodyTemplateTop = @"
Hi __Manager__, there is currently a number of snapshots on virtual machines which are over $WarningDays day(s) old. This can cause storage and reliability issues.<br /><br />

VMware recommends that no single snapshot should be kept for more then 24-72 hours.<br /><br />

The following snapshots are on VMs which we have you listed as the manager:<br /><br />
"@

$BodyTemplateBottom = @"
These snapshots will be removed once they are over $DeletionDays days old unless we are advised otherwise.<br /><br />

Thank you,<br />
$Signature
"@

$Style = @"
<style>BODY{font-family: Arial; font-size: 10pt;}
TABLE{border: 1px solid black; border-collapse: collapse;}
TH{border: 1px solid black; background: #dddddd; padding: 5px; }
TD{border: 1px solid black; padding: 5px; }
</style>
"@

#endregion

#region Load Modules and Remote Conenction

Import-Module -Name VMware.VimAutomation.Core
Import-Module -Name ActiveDirectory

Connect-VIServer -Server $vCenterServer

#endregion

#region Data collection and categorization

$WarningDate = (Get-Date).AddDays(-$WarningDays)
$DeletionDate = (Get-Date).AddDays(-$DeletionDays)

$Snapshots = ((Get-VM).Where({ $_.VMHost.Parent.Name -notin $ExcludedClusters }) | Get-Snapshot).Where({ $_.Description -notin $BackupSnapshotDescription })

$Old = $Snapshots.Where({ $_.Created -le $WarningDate -and $_.Created -gt $DeletionDate })
$Older = $Snapshots.Where({ $_.Created -le $DeletionDate -and $_.Description -notlike "*$ExceptionDescription*" })

#endregion

#region Process

$Report = @{}

foreach ($Candidate in $Old) {
    $UseOperations = $false

    $AdObject = Get-AdComputer -Filter {ANR -eq $Candidate.VM.Name} -Properties ManagedBy

    if ($AdObject)
    {
        if ($AdObject.ManagedBy -ne $null -and $AdObject.ManagedBy -ne '')
        {
            foreach ($Manager in $AdObject.ManagedBy)
            {
                if (!$Report.ContainsKey($Manager))
                {
                    $Report.Add($Manager, @($Candidate))
                }
                else
                {
                    $Report.$Manager += ,$Candidate
                }
            }
        }
        else
        {
            Write-Warning -Message "No manager found for $($Candidate.VM.Name), using Operations."
            $UseOperations = $true
        }
    }
    else
    {
        Write-Warning -Message "No AD Object found for $($Candidate.VM.Name), using Operations."
        $UseOperations = $true
    }

    if ($UseOperations)
    {
        if (!$Report.ContainsKey($OperationsDN))
        {
            $Report.Add($OperationsDN, @($Candidate))
        }
        else
        {
            $Report.$OperationsDN += ,$Candidate
        }
    }
}

foreach ($Manager in $Report.Keys)
{
    if ($Manager -eq $OperationsDN)
    {
        $AdObject = Get-ADUser -Identity $Manager -Properties Description, EmailAddress

        $BodyTop = $BodyTemplateTop.Replace('__Manager__', $AdObject.Description.Split(' ')[0])
  
        $HTML = $Report.$Manager | Select VM, Created, Name, Description | Sort-Object -Property VM, Created | ConvertTo-Html -Head $Style

        $HTML = $HTML.Replace('<body>', "<body>$BodyTop")
        $HTML = $HTML.Replace('</table>', "</table><br />$BodyTemplateBottom")

        $Splat = @{
            'SmtpServer' = $SmtpServer
            'From' = $OperationsEmail
            'To' = $AdObject.EmailAddress
            'Subject' = 'Lingering VM snapshots'
            'Body' = $HTML | Out-String
            'BodyAsHtml' = $true
        }
        
        if ($Manager -ne $OperationsDN)
        {
            $Splat.Add('CC', $OperationsEmail)
        }
        
        Send-MailMessage @Splat
    }
}

Remove-Snapshot -Snapshot $Older

#endregion
