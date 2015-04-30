<#
 # Project:     PowerPass, a Password Manager for PowerShell
 # Author:      Joshua King
 # Description: Store and manage credentials using PowerShell
 # 
 # License:     The MIT License (MIT)
 #
 #	            Copyright (c) 2015 Joshua King
 #
 #	            Permission is hereby granted, free of charge, to any person 
 #	            obtaining a copy of this software and associated documentation 
 #	            files (the "Software"), to deal in the Software without 
 #	            restriction, including without limitation the rights to use, 
 #	            copy, modify, merge, publish, distribute, sublicense, and/or sell
 #	            copies of the Software, and to permit persons to whom the 
 #	            Software is furnished to do so, subject to the following 
 #	            conditions:
 #              
 #	            The above copyright notice and this permission notice shall be 
 #	            included in all copies or substantial portions of the Software.
 #              
 #	            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
 #	            EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
 #	            OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
 #	            NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
 #	            HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
 #	            WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
 #	            FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
 #	            OTHER DEALINGS IN THE SOFTWARE.
 #
 # Change Log:  29/04/2015 - 0.2 - Expanded search cmdlet and created custom
 #                                 class for PPCredentials.
 #              28/04/2015 - 0.1 - Created project.
 #>

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