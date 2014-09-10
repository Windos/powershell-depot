function Get-WDGroupMemberContact {

<#
    .SYNOPSIS
    A brief description of the function or script.

	.DESCRIPTION
    A detailed description of the function or script.'
	
	.NOTES
    Additional information about the function or script.

	.EXAMPLE
    A sample command that uses the function or script, optionally followed by
	sample output and a description. Repeat this keyword for each example.

	.EXAMPLE
    Give another example of how to use it

	.PARAMETER Group
    The Active Directory group or groups to gather users from. Can include wild cards.

	.PARAMETER Except
    The Active Directory group to exclude from searches. Just one. Can include wild cards.

	.LINK
	https://github.com/Windos/powershell-depot
#>

    [CmdletBinding()]
	[OutputType([PSCustomObject[]])]
    param
    (
        [Parameter(Position=0,
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   HelpMessage='Which group name would you like to target?')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Group,

        [Parameter(Position=1,
                   Mandatory=$False,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True,
                   HelpMessage='Which group name would you like to exclude?')]
        [ValidateNotNullOrEmpty()]
        [string]$Except
    )

    begin
	{
	    Import-Module ActiveDirectory
    }

    process
	{
        $users = @()

        foreach ($testgroup in $group)
        {
            $filter = "Name -like '$testgroup'"
            if ($Except -ne $null -and $Except -ne '')
            {
                $filter += " -and Name -notlike '$Except'"
            }
            $ADGroup = Get-ADGroup -Filter $filter
            $users += $ADGroups | Get-ADGroupMember | Get-ADUser -Properties Mail
        }

        $users | Select-Object Name,Mail -Unique
    }
}

