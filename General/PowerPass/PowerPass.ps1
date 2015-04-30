$CredLocker = @()

class PPCredential {
    [string] $Name;
    [uint32] $Id;
    [pscredential] $Credential;
    [string] $Folder;
    [string] $Notes;
    [securestring] $SecureNotes;
    [bool] $Favorite;
    [datetime] $Retrieved;
    [bool] $LatestUsed;

    PPCredential([string] $Name, [pscredential] $Credential, [string] $Folder, [string] $Notes, [securestring] $SecureNotes, [bool] $Favorite) {
        $this.Credential = $Credential
        $this.Name = $Name
        $this.Folder = $Folder
        $this.Notes = $Notes
        $this.SecureNotes = $SecureNotes
        $this.Favorite = $Favorite
        $this.Retrieved = Get-Date
    }
    
    PPCredential([string] $Name, [pscredential] $Credential) {
        $this.Credential = $Credential
        $this.Name = $Name
        $this.Retrieved = Get-Date
    }
}

function New-PPCredential {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
#>
    [CmdletBinding(DefaultParameterSetName='String')]
    [OutputType([PPCredential])]
    Param (
        [string] $Name,
        [pscredential] $Credential,
        [string] $Folder = 'Default',
        [string] $Note = '',
        
        [Parameter(ParameterSetName='SecureString')]
        [securestring] $SecureNote,
        
        [Parameter(ParameterSetName='String')]
        [string] $SecureNoteAsString = 'This is a secure string',
        
        [switch] $Favorite,
        [switch] $Add,
        [switch] $Save
    )

    if ($Credential -eq $null) {
        $Credential = Get-Credential
    }

    if ($Name -eq $null -or $Name -eq '') {
        $Name = $Credential.UserName
    }

    if ($SecureNoteAsString -ne $null -or $SecureNoteAsString -eq '') {
        $SecureNote = $SecureNoteAsString | ConvertTo-SecureString -AsPlainText -Force
    }

    $PPCred = [PPCredential]::new($Name, $Credential, $Folder, $Note, $SecureNote, $Favorite)

    if ($Add -and $Save) {
        Add-PPCredential -Credential $PPCred -Save
    } elseif ($Add) {
        Add-PPCredential -Credential $PPCred
    }

    $PPCred
}

function Add-PPCredential {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
#>
    [CmdletBinding()]
    Param (
        [PPCredential] $Credential,
        [switch]$Save
    )

    if ($Credential -eq $null) {
        $Credential = New-PPCredential
    }

    $script:CredLocker += ($Credential)

    if ($Save) { Save-PPCredential }
}

function Save-PPCredential {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
#>
    [CmdletBinding()]
    Param ()

    $SavePath = Join-Path (Split-Path $profile) 'PPCredential.clixml'
    Export-Clixml -InputObject $Script:CredLocker -Path $SavePath
}

function Open-PPCredential {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
#>

    [CmdletBinding()]
    Param ()

    $OpenPath = Join-Path (Split-Path $profile) 'PPCredential.clixml'
    $global:CredLocker = Import-Clixml -Path $OpenPath
}

function Show-PPCredential {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
#>

    [CmdletBinding()]
    Param ()

    $Script:CredLocker
}

function Search-PPCredential {
<#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
#>

    [CmdletBinding(DefaultParameterSetName='Default')]
    Param (
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   Position=0)]
        [alias('User')]
        [ValidateNotNullorEmpty()]
        [string[]]$UserName,

        [Parameter(ParameterSetName='Default')]
        [switch]$SearchInCredential,
        
        [Parameter(ParameterSetName='Default')]
        [alias('Case')]
        [switch]$CaseSensitive,

        [Parameter(ParameterSetName='Default')]
        [alias('Exact')]
        [switch]$WholeWord,

        [Parameter(ParameterSetName='Regex')]
        [switch]$Regex
    )

    begin {}
    process {
        foreach ($searchCase in $UserName) {
            foreach ($cred in $Script:CredLocker) {
                $search = $cred.Name
                if ($SearchInCredential) { $search = $cred.Credential.UserName }

                if ($Regex) {
                    if ($search -match $searchCase) {
                        $cred
                    }
                } else {
                    if ($WholeWord) {    
                        if ($CaseSensitive) {
                            if ($search -ceq $searchCase) {
                                $cred
                            }
                        } else {
                            if ($search -eq $searchCase) {
                                $cred
                            }
                        }
                    } else {
                        if ($CaseSensitive) {
                            if ($search -clike "*$searchCase*") {
                                $cred
                            }
                        } else {
                            if ($search -like "*$searchCase*") {
                                $cred
                            }
                        }
                    }
                }
            }
        }
    }
    end {} 
}