<#PSScriptInfo
.VERSION
    0.0.1
.GUID
    8bbc7734-6854-4441-8022-dc394fa335ff
.AUTHOR
    Joshua (Windos) King
.COMPANYNAME
    king.geek.nz
.COPYRIGHT
    (c) 2016 Joshua (Windos) King. All rights reserved.
.TAGS
    DNS
.PROJECTURI
    https://github.com/Windos/powershell-depot/tree/master/GalleryScripts
.RELEASENOTES
* Initial release
#>

#Requires -Module PoshRSJob
#Requires -Module DnsServer

<#
.SYNOPSIS
Tests for potentially stale DNS records in a DNS Zone.

.DESCRIPTION
Script to test for potentially stale DNS records in a DNS Zone.

Leverages PoshRSJob to test multiple records in parallel. 

.EXAMPLE
Test-DnsZone -Zone campus.example.com

Tests all Host and Alias records in the 'Campus' DNS zone, and returns any that do not respond the an echo request.

.EXAMPLE
Test-DnsZone -Zone campus.example.com -all

Tests all Host and Alias records in the 'Campus' DNS zone, and returns all records regardless of echo response.
#>

[CmdletBinding(DefaultParameterSetName='Filtered')]
[OutputType('System.Management.Automation.PSCustomObject')]
Param
(
    [Parameter(Position = 0,
               Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string] $ZoneName,

    # Specifies that all records should be returned regardless of echo response
    [switch] $All,
    
    [ValidateNotNullOrEmpty()]
    [string] $ComputerName = ((Get-ADDomainController -Discover -Service PrimaryDC).HostName)
)

$ScriptBlock = {
    [PSCustomObject] @{
        Name = $_.HostName
        Address = $_.RecordData.IPv4Address.ToString()
        Echo = Test-Connection -Count 1 -ComputerName $_.HostName -Quiet
    }
}

Import-Module -Name PoshRSJob
Import-Module -Name DnsServer

$Records = Get-DnsServerResourceRecord -ComputerName $ComputerName -ZoneName $ZoneName | Where { $_.Type -in 1,5 }
$Batch = "DnsTest-$(New-Guid)"

if ($all)
{
    $Records | Start-RSJob $ScriptBlock -Name {$_.HostName} -Throttle 20 -Batch $Batch | Wait-RSJob -ShowProgress | Receive-RSJob
}
else
{
    $Records | Start-RSJob $ScriptBlock -Name {$_.HostName} -Throttle 20 -Batch $Batch | Wait-RSJob -ShowProgress | Receive-RSJob | Where Echo -eq $false
}

Get-RSJob -Batch $Batch | Remove-RSJob
