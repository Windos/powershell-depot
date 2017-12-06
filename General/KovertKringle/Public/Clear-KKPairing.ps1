function Clear-KKPairing {
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

    $Script:Pairings.Clear()

    foreach ($Person in $Script:Participants) {
        $Person.Paired = $false
    }
}
