function __VERB__-__NOUN__ {

<#
    .SYNOPSIS
    __SYNOPSIS__

	.DESCRIPTION
    __DESCRIPTION__
	
	.NOTES
    __NOTES__

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
	[OutputType([PSCustomObject[]])]
    param
    (
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   HelpMessage='What computer name would you like to target?')]
        [Alias('host')]
        [ValidateLength(3,30)]
        [string[]]$computername,

        [string]$logname = 'errors.txt'
    )

    begin
	{
	    write-verbose "Deleting $logname"
        del $logname -ErrorAction SilentlyContinue
__VMWARE_BEGIN__    }

    process
	{
        write-verbose "Beginning process loop"

        foreach ($computer in $computername)
		{
            Write-Verbose "Processing $computer"
            # use $computer to target a single computer

            # create a hashtable with your output info
            $info = @{'info1'=$value1;
                      'info2'=$value2;
                      'info3'=$value3;
                      'info4'=$value4
            }
            Write-Output (New-Object –TypenamePSObject –Prop $info)
        }
    }
}
