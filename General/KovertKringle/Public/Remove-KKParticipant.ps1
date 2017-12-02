function Remove-KKParticipant {
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
        [string] $Name
    )

    $Obj = $Script:Participants | Where-Object {$_.Name -eq $Name}
    $Script:Participants.Remove($Obj)
}
