function New-WINCmdlet {

<#
    .SYNOPSIS
    A brief description of the function or script. This keyword can be used
    only once in each topic.

	.DESCRIPTION
    A detailed description of the function or script. This keyword can be used
	only once in each topic.
	
	.NOTES
    Additional information about the function or script.

	.EXAMPLE
    A sample command that uses the function or script, optionally followed by
	sample output and a description. Repeat this keyword for each example.

	.EXAMPLE
    Give another example of how to use it

	.PARAMETER computername
    The computer name to query. Just one.

	.PARAMETER logname
    The name of a file to write failed computer names to. Defaults to errors.txt.

	.PARAMETER  <Parameter-Name>
	The description of a parameter. Add a .PARAMETER keyword for each parameter
	in the function or script syntax.
	
	.LINK
    The name of a related topic. The value appears on the line below the .LINK
	keyword. Repeat the .LINK keyword for each related topic.
	
	.LINK
	https://github.com/Windos/powershell-depot
#>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   HelpMessage='What computer name would you like to target?')]
        [ValidateLength(3,30)]
        [string]$verb='Get',

        [Parameter(Mandatory=$false,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   HelpMessage='What computer name would you like to target?')]
        [ValidateLength(3,30)]
        [string]$noun='Something',

        [Parameter(Mandatory=$False)]
        [switch]$VMware,

        [string]$logname = 'errors.txt'
    )

    begin
	{
        write-verbose "Deleting $logname"
        del $logname -ErrorAction SilentlyContinue
    }

    process
	{
        $cmdletTemplate = Get-Content -Path 'c:\github\powershell-depot\general\cmdletTemplate.ps1' -Raw
		
		if ($VMware)
		{
		    $vmwareTemplate = Get-Content -Path 'c:\github\powershell-depot\general\vmwareTemplate.ps1' -Raw
            $cmdletTemplate = $cmdletTemplate -replace '__VMWARE_BEGIN__', $vmwareTemplate
		}
        else
        {
            $cmdletTemplate = $cmdletTemplate -replace '__VMWARE_BEGIN__', ''
        }
		
		$cmdletTemplate
    }
}
