<#PSScriptInfo
.VERSION
    0.0.1
.GUID
    e064449d-da80-4499-b7e6-94cdd066c701
.AUTHOR
    Joshua (Windos) King
.COMPANYNAME
    king.geek.nz
.COPYRIGHT
    (c) 2016 Joshua (Windos) King. All rights reserved.
.TAGS
    ActiveDirectory
.PROJECTURI
    https://github.com/Windos/powershell-depot/tree/master/GalleryScripts
.RELEASENOTES
#>

<#
.SYNOPSIS
Gets a Windows Event about Locked Accounts.

.DESCRIPTION
Script to get a Windows Event about Locked Accounts, including the host which caused the lockout.

By default only events triggered in the last hour are returned, but a different time frame can be provided with the PastHours parameter or overridden with the All switch.

.EXAMPLE
Get-LockoutBlame

Returns all account lockout events that were triggered in the past hour.

.EXAMPLE
Get-LockoutBlame -PastHours 24

Returns all account lockout events that were triggered in the last 24 hours.

.EXAMPLE
Get-LockoutBlame -All

Returns all account lockout events present in the event log.

.EXAMPLE
Get-LockoutBlame -UserName johnd

Returns all account lockout events for the user johnd in the past hour

.EXAMPLE
Get-LockoutBlame -UserName johnd -All

Returns all account lockout events for the user johnd present in the event log.

.NOTES
The default value for the ComputerName parameter uses a cmdlet from the ActiveDirectory module, if you don't have this installed (why?) you can either provide a domain controller at runtime or hardcode it as the default.
#>

[CmdletBinding(DefaultParameterSetName='Filtered')]
[OutputType('System.Diagnostics.Eventing.Reader.EventLogRecord')]
param
(
    [Parameter(Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string] $UserName,

    [Parameter(ParameterSetName='Filtered')]
    [ValidateNotNullOrEmpty()]
    [int] $PastHours = 1,

    [Parameter(ParameterSetName='Unfiltered')]
    [switch] $All,
    
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $ComputerName = ((Get-ADDomainController -Discover -Service PrimaryDC).HostName)
)

process
{
    try
    {
        $filter = '*[System[EventID=4740'

        if (!$all) {
            $PastMilliseconds = $PastHours * 3600000
            $filter += " and TimeCreated[timediff(@SystemTime) <= $PastMilliseconds]]"
        } else {
            $filter += ']'
        }

        if ($username) {
            $filter += " and EventData[Data[@Name='TargetUserName']='$UserName']]"
        } else {
            $filter += ']'
        }

        $Events = Get-WinEvent -ComputerName $ComputerName -Logname Security -FilterXPath $filter
        $Events | Select-Object TimeCreated,
                                @{Name='User Name';Expression={$_.Properties[0].Value}},
                                @{Name='Source Host';Expression={$_.Properties[1].Value}}
    }
    catch
    {
        Throw $_.Exception
    }
}
