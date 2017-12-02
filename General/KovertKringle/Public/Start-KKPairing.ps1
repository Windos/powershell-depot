function Start-KKPairing {
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

    foreach ($Person in ($Script:Participants | Sort-Object -Property SortKey)) {
        $Potential = $Script:Participants | Where-Object {$_ -ne $Person -and $_.Paired -eq $false}

        if ($Potential) {
            $Giftee = $Potential | Get-Random

            $Pairing = [PSCustomObject] @{
                Buyer = $Person
                Receiver = $Giftee
            }

            $null = $Script:Pairings.Add($Pairing)

            $Giftee.Paired = $true
        } else {
            Write-Error 'No possible pairings, you may have already run this function.'
        }
    }
}
