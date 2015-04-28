$testcred =@()

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
    Param ()

    $cred = $null
    $cred = Get-Credential

    $global:testcred += ($cred)
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
    Export-Clixml -InputObject $testcred -Path $SavePath
}

function Load-PPCredential {
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

    $LoadPath = Join-Path (Split-Path $profile) 'PPCredential.clixml'
    $global:testcred = Import-Clixml -Path $LoadPath
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

    $testcred
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

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   Position=0)]
        [Alias('User')]
        [ValidateNotNullorEmpty()]
        [string[]]$UserName

        # Case Sensitivety
        
        # exact/wildcards?

        # match/regex
    )

    begin {}
    process {
        foreach ($searchCase in $UserName) {
            foreach ($cred in $testCred) {
                if ($cred.UserName.ToLower() -match $searchCase.ToLower()) {
                    $cred
                }
            }
        }
    }
    end {} 
}