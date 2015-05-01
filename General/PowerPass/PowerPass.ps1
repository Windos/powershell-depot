<#
 # Project:     PowerPass, a Password Manager for PowerShell
 # Version:     0.2
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
    #region class properties
    [string] $Name;
    [uint32] $Id;
    [pscredential] $Credential;
    [string] $Folder;
    [string] $Notes;
    [securestring] $SecureNotes;
    [bool] $Favorite;
    [datetime] $Retrieved;
    [bool] $LatestUsed;
    #endregion

    #region class constructors
    PPCredential([string] $Name, [uint32] $Id, [pscredential] $Credential, [string] $Folder, [string] $Notes, [securestring] $SecureNotes, [bool] $Favorite) {
        $this.Credential = $Credential
        $this.Name = $Name
        $this.Id = $Id
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
    #endregion

    #region class methods

    #endregion
}

#region Helper Functions
function New-HighestPPCredId {
    $SortedLocker = $Global:CredLocker | Sort-Object -Property 'Id' -Descending
    $NewId = $SortedLocker[0].Id + 1
    $NewId
}

function New-LowestAvailPPCredId {
    $SortedLocker = $Global:CredLocker | Sort-Object -Property 'Id'
    $NewId = 1
    foreach ($Id in $SortedLocker) {
       $taken = $false
       if ($Id.Id -eq $NewId) {
           $taken = $true
       }
       if (!$taken) {
           break
       } else {
           $NewId++
       }
    }
    
    $NewId
}

function Get-CredById {
    Param ([uint32] $Id)

    ## MOVE TO EFFICIENT SEARCH ALGORITHM

    $SortedLocker = $Global:CredLocker | Sort-Object -Property 'Id'
    foreach ($Cred in $SortedLocker) {
        if ($Cred.Id -eq $Id) {
            $Cred
            break
        }
    }
}
#endregion

function New-PPCredential {
<#
    .Synopsis
    Creates a new PowerPass credential.
    .DESCRIPTION
    The New-PPCredential cmdlet creates a new PowerPass credential object. This cmdlet can add the object to the in memory credential locker and also save the credential locker to disk.

    You can provide an already created PSCredential object to this cmdlet, or create a new one when this cmdlet is run.
    .EXAMPLE
    New-PPCredential

    This command prompts you to enter a username and password in a Windows Security prompts, then it creates a PowerPass credential using the supplied username as the object's name.
    .EXAMPLE
    $cred = New-Credential
    PS C:\>New-PPCredential -Credential $cred

    This example creates a new PowerPass credential from a PSCredential stored in a variable. It set's the PowerPass credential's name to the username.
    .EXAMPLE
    New-Credential -Name 'Admin credentials for WebServer' -Folder 'Web' -Favorite $true -Note 'Default port changed to 8080'

    This command prompts you to enter a username and password in a Windows Security prompts, then it creates a PowerPass credential using the supplied properties.
    .OUTPUTS
    PPCredential
    .LINK
    https://github.com/Windos/powershell-depot/tree/master/General/PowerPass
    .LINK
    Add-PPCredential
    .LINK
    Save-PPCredential
#>
    [CmdletBinding(DefaultParameterSetName='String')]
    [OutputType([PPCredential])]
    Param (
        # When present, the Add switch will pass the new PowerPass credential to the Add-PPCredential cmdlet.
        [switch] $Add,

        # Specifies the PSCredential object to store inside the PowerPass credential object. If not supplied, you will be prompted to create one.
        [pscredential] $Credential,
        
        # Specifies whether a PPCredential should be considered a favorite, useful for quickly retrieving commonly used credentials.
        [switch] $Favorite,
        
        # Specifies the 'folder' into which to store the PowerPass Credential. If no folder is specified a default location will be used.
        [string] $Folder = 'Default',

        # Specifies that the automatically generated Id should be the lowest available in the Credential locker. If not specified a new Id higher than all existing Ids will be used.
        [switch] $LowestId,
        
        # Specifies a friendly name by which the PowerPass credential can be refered. If not supplied, the username from the credential parameter will be used.
        [string] $Name,
        
        # Specifies notes to be stored alongside the PowerPass credential. When saved to disk, this will be stored in plain text.        
        [string] $Note = '',
        
        # When present, the Save switch will run the Save-PPCredential cmdlet. This will only work if supplied along with the Add switch. 
        [switch] $Save,
        
        # Specifies notes, in the form of a secure string, to be stored alongside the PowerPass credential. When saved to disk, this will be stored as an encrypted string. 
        [Parameter(ParameterSetName='SecureString')]
        [securestring] $SecureNote,
        
        # # Specifies notes, in the form of a regular string, to be stored alongside the PowerPass credential. This will be converted to a secure string when added to a PowerPass credential. When saved to disk, this will be stored as an encrypted string. 
        [Parameter(ParameterSetName='String')]
        [string] $SecureNoteAsString = 'This is a secure string'
    )

    if ($Credential -eq $null) {
        Write-Verbose -Message 'A preexisting PSCredential object was not supplied. Prompting user to create one.'
        $Credential = Get-Credential
    }

    if ($Name -eq $null -or $Name -eq '') {
        Write-Verbose -Message 'No name was supplied. The PSCredential UserName will be used.'
        $Name = $Credential.UserName
    }

    if ($SecureNoteAsString -ne $null -or $SecureNoteAsString -eq '') {
        Write-Verbose -Message 'Secure note supplied as a string, converting to securestring.'
        $SecureNote = $SecureNoteAsString | ConvertTo-SecureString -AsPlainText -Force
    }

    if ($LowestId) {
        $Id = New-LowestAvailPPCredId
    } else {
        $Id = New-HighestPPCredId
    }

    Write-Verbose -Message 'Creating PPCredential object.'
    $PPCred = [PPCredential]::new($Name, $Id, $Credential, $Folder, $Note, $SecureNote, $Favorite)

    if ($Add -and $Save) {
        Write-Verbose -Message 'Adding PPCredential object to the CredLocker and saving the CredLocker to disk.'
        Add-PPCredential -Credential $PPCred -Save
    } elseif ($Add) {
        Write-Verbose -Message 'Adding PPCredential object to the CredLocker.'
        Add-PPCredential -Credential $PPCred
    }

    $PPCred
}

function Add-PPCredential {
<#
    .Synopsis
    Adds one or more PowerPass credentials to the PowerPass CredLocker.
    .DESCRIPTION
    The Add-PPCredential cmdlet adds one or more PowerPass credentials to the PowerPass CredLocker. Optionally, this cmdlet can also save the CredLocker to disk once all additions have completed.

    You can supply a PowerPass credential object as a parameter of the cmdlet, pipe the object to cmdlet, or call the Add-PPCredential cmdlet without an existing PowerPass credential to generate a new one.
    .EXAMPLE
    Add-PPCredential

    This command will prompt you for a username and password, create a new PowerPass credential and add it to the CredLocker.
    .EXAMPLE
    $cred = New-PPCredential
    Add-PPCredential -Credential $cred

    This example stores a PowerPass credential in the variable, $cred, then supplying it to the Add-PPCredential cmdlet to be added to the CredLocker.
    .EXAMPLE
    New-PPCredential | Add-PPCredential -Save
    .LINK
    https://github.com/Windos/powershell-depot/tree/master/General/PowerPass
    .LINK
    New-PPCredential
    .LINK
    Save-PPCredential
#>
    [CmdletBinding()]
    Param (
        # Specifies one or more PowerPass credential.
        [Parameter(Position=0)]
        [PPCredential] $Credential,

        # When present, the Save switch will run the Save-PPCredential cmdlet.
        [switch]$Save
    )

    if ($Credential -eq $null) {
        Write-Verbose -Message 'A preexisting PowerPass credential object was not supplied. Prompting user to create one.'
        $Credential = New-PPCredential
    }

    Write-Verbose -Message "Processing $($Credential.Name)"
    $Global:CredLocker += ($Credential)

    if ($Save) {
        Write-Verbose -Message 'Saving CredLocker to disk.'
        Save-PPCredential
    }
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
    Export-Clixml -InputObject $Global:CredLocker -Path $SavePath
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

    $Global:CredLocker
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
        [Parameter(ParameterSetName='Default',
                   Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   Position=0)]
        [Parameter(ParameterSetName='Regex',
                   Mandatory=$True,
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
        [switch]$Regex,

        [Parameter(ParameterSetName='Id')]
        [uint32]$Id
    )

    begin {}
    process {
        if ($PSCmdlet.ParameterSetName -eq 'Id') {
            Get-CredById -Id $Id
        } else {
            foreach ($searchCase in $UserName) {
                foreach ($cred in $Global:CredLocker) {
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
                } # foreach ($cred in $Global:CredLocker)
            } # foreach ($searchCase in $UserName)
        } # else (not an Id search)
    }
    end {} 
}