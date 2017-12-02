function Add-KKParticipant {
    <#
    .SYNOPSIS
    Short description

    .DESCRIPTION
    Long description

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>

    [CmdletBinding()]

    param (
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $Email,

        [switch] $Snitch
    )

    if ($Name -notin $Script:Participants.Name) {
        $Obj = [PSCustomObject] @{
            Name = $Name
            Email = $Email
            Snitch = $Snitch
            Paired = $false
            SortKey = [System.Random]::new().Next(1, 1000)
        }
        $null = $Script:Participants.Add($Obj)
    } else {
        Write-Warning "$Name is already a participant!"
    }
}
