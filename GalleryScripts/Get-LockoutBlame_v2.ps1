<#
.SYNOPSIS
	Gets a Windows Event about Locked Accounts.
.DESCRIPTION
	Script to get a Windows Event about Locked Accounts, including the host which caused the lockout.
	By default only events triggered in the last hour are returned, but a different time frame can be provided with the
	PastHours parameter or overridden with the All switch.
.EXAMPLE
	PS C:\> .\Get-LockoutBlame.ps1
	Returns all account lockout events that were triggered in the past hour.
.EXAMPLE
	PS C:\> .\Get-LockoutBlame.ps1 -PastHours 24
	Returns all account lockout events that were triggered in the last 24 hours.
.EXAMPLE
	PS C:\> .\Get-LockoutBlame.ps1 -All -Verbose
	Returns all account lockout events present in the event log.
	Show error messages if were occurred.
.EXAMPLE
	PS C:\> .\Get-LockoutBlame.ps1 -UserName johnd -ComputerName localhost
	Returns all account lockout events for the user johnd in the past hour.
.EXAMPLE
	PS C:\> .\Get-LockoutBlame.ps1 -UserName johnd -All
	Returns all account lockout events for the user johnd present in the event log.
.NOTES
	Idea      :: Joshua (Windos) King (@WindosNZ).
	Edited by :: Roman Gelman (@rgelman75).
	Changes   ::
	[1] Multiple DC are supported in the -ComputerName parameter.
	[2] The returned object changed: added 'DC' property, other properties were renamed.
	[3] Error messages displayed only while -Verbose parameter is used.
	The default value for the -ComputerName parameter uses a cmdlet from the ActiveDirectory module, if you don't have 
	this installed (why?) you can either provide a domain controller at runtime or hardcode it as the default.
	The 'localhost' suitable too if you are on a Domain Controller.
#>

[CmdletBinding(DefaultParameterSetName='Filtered')]
[OutputType('System.Diagnostics.Eventing.Reader.EventLogRecord')]

Param (
    
	[Parameter(Position=0)]
    	[ValidateNotNullOrEmpty()]
    [string]$UserName
	,
    [Parameter(ParameterSetName='Filtered')]
    	[ValidateNotNullOrEmpty()]
    [int]$PastHours = 1
	,
    [Parameter(ParameterSetName='Unfiltered')]
    [switch]$All
	,
    [Parameter()]
    	[ValidateNotNullOrEmpty()]
		[Alias("DC","DomainController")]
    [string[]]$ComputerName = @((Get-ADDomainController -Filter *).Hostname)
)

Process {

	Foreach ($CN in $ComputerName) {

	    Try
	    {
	        $filter = '*[System[EventID=4740'

	        If (!$All) {
	            $PastMilliseconds = $PastHours * 3600000
	            $filter += " and TimeCreated[timediff(@SystemTime) <= $PastMilliseconds]]"
	        } Else {
	            $filter += ']'
	        }

	        If ($UserName) {
	            $filter += " and EventData[Data[@Name='TargetUserName']='$UserName']]"
	        } Else {
	            $filter += ']'
	        }

	        $Events = Get-WinEvent -ComputerName $CN -Logname Security -FilterXPath $filter -ErrorAction Stop
	        $Events |select @{N='LockedOut';E={([datetime]$_.TimeCreated).ToString('dd/MM/yyyy HH:mm:ss')}},
	        @{N='DC';E={$_.MachineName}},
			@{N='UserName';E={$_.Properties[0].Value}},
	        @{N='SourceHost';E={$_.Properties[1].Value}}
	    }
	    Catch
	    {
	        If ($PSBoundParameters.ContainsKey('Verbose')) {
				$ErrMsg = ("{0}" -f $Error.Exception.Message).ToString()
				Write-Host "$CN :: $ErrMsg" -ForegroundColor Yellow
			}
	    }
	}

} #EndProcess
