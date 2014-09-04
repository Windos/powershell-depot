function Get-WINFileExists {

<#
    .SYNOPSIS
    Determines if a file or directory path exists on a specified group of computers.

	.DESCRIPTION
    The Get-WINFileExists cmdlet determines whether a file or directory path exists on a group of computers. As it can test multiple computers and paths it returns the computer name, path and $true or $false depending on whether or not the path exists. If a specified path include 'Program Files', the cmdlet will automatically check 'Program Files (x86)' if not manually specified.

	.NOTES
    The original idea and intial script implementation for this cmdlet is attributed to Kevin Dresser.

	.EXAMPLE
    Get-WINFileExists -path 'c$\Program Files\PC Monitor\PCMonitorManager.exe' -OperatingSystem ad1,ad2,ex1,file1

    Checks for the executable 'PCMonitorManager.exe' within the specified directory (and it's (x86) varient) on all four listed computers.

	.EXAMPLE
    Get-WINFileExists -path 'c$\Program Files (x86)\Mozilla Firefox\firefox.exe' -OperatingSystem *server*

    Checks to see if the firefox executable exists on any computer in Active Directory with 'server' contained in it's operationg system (for example 'Windows Server 2008 R2 Standard')

    Note: as the (x86) directory was specified by itself when calling the cmdlet, the non-x86 directory will not be checked.

	.EXAMPLE
    Get-WINFileExists -path 'c$\doom.exe' -SearchBase 'OU=Workstations,OU=Computers,DC=example,DC=local'

    Checks to see if DOOM has been installed to the root of the c drive on any computer in the exmaple.local domain's Worstation OU.

    Note: I here installing DOOM on your c drive is a thing users do... or something?

    .PARAMETER Path
    Part of the UNC path to the file starting from the drive letter.

    For example, if the full path on one system is '\\file1\c$\directory\program.exe' then specify the path 'c$\directory\program.exe'

	.PARAMETER ComputerName
    The name of a computer to test for the existence of paths. Can be one or an list.

    Cannot be used in conjunction with SearchBase or OperatingSystem

	.PARAMETER  SearchBase
	The full Active Directory Ogranizational Unit to gather computer names from, specify in the form of: 'OU=Workstations,OU=Computers,DC=example,DC=local'

    Cannot be used in conjunction with ComputerName or OperatingSystem

    .PARAMETER  OperatingSystem
	Specifies the Operating System search string for filtering Active Directory computer objects. Use wildcard as it is being used in a '-like' operations, for example: '*server*'

    Cannot be used in conjunction with ComputerName or SearchBase

	.LINK
	https://github.com/Windos/powershell-depot
#>

    [CmdletBinding(DefaultParametersetName="ComputerName")]
	[OutputType([PSCustomObject[]])]
    param
    (
        [Parameter(Mandatory=$True,
                   Position=0,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [string[]]$Path,

        [Parameter(ParameterSetName="ComputerName",
                   Mandatory=$True,
                   Position=1,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [Alias('Host')]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName="SearchBase",
                   Mandatory=$True,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [Alias('OU')]
        [string]$SearchBase,

        [Parameter(ParameterSetName="OperatingSystem",
                   Mandatory=$True,
                   ValueFromPipeline=$False,
                   ValueFromPipelineByPropertyName=$True)]
        [Alias('OS')]
        [string]$OperatingSystem
    )

    begin
	{
        Import-Module ActiveDirectory
    }

    process
	{
        switch ($PSCmdlet.ParameterSetName)
        {
            'ComputerName'
            {
                $computers = $ComputerName | Sort-Object
                break
            }
            'SearchBase'
            {
                $computers = Get-ADComputer -SearchBase $SearchBase -Filter '*' | ForEach-Object {$_.Name} | Sort-Object
                break
            }
            'OperatingSystem'
            {
                $computers = Get-ADComputer -filter {OperatingSystem -like $OperatingSystem} | ForEach-Object {$_.Name} | Sort-Object
                break
            }
        }

        foreach ($testpath in $path)
        {
            if ($testpath -like "*Program Files*")
            {
                $x86path = $testpath.Replace('Program Files','Program Files (x86)')
                if ($path -notcontains $x86path)
                {
                    $path += $x86path
                }
            }
        }

        foreach ($computer in $computers)
		{
            if (Test-Connection -ComputerName $computer -BufferSize 16 -Count 1 -Quiet)
            {
                foreach ($partialpath in $path)
                {
                    $fullpath = "\\$computer\$partialpath"
                    $fileexists = Test-Path -Path $fullpath

                    $info = [ordered]@{'ComputerName'=$computer;
                              'Path'=$fullpath;
                              'FileExists'=$fileexists;
                    }
                    Write-Output (New-Object –Typename PSCustomObject –Prop $info)
                }
            }
        }
    }
}
