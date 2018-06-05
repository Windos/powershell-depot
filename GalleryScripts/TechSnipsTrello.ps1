# Get your Trello Developer API Key here: https://trello.com/app-key

Import-Module -Name 'TrellOps'          # https://github.com/MethosNL/TrellOps
Import-Module -Name 'CredentialManager' # https://github.com/davotronic5000/PowerShell_Credential_Manager

$Token = @{
    Token     = (Get-StoredCredential -Target TrelloToken).GetNetworkCredential().Password
    AccessKey = (Get-StoredCredential -Target TrelloKey).GetNetworkCredential().Password
}

# Make sure PowerShell is using TLS 1.2 as TLS 1.0 won't work
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Get Board
$Board = Get-TrelloBoard -Token $Token -Name 'Contributor Content Snip Roadmap'

# Get List
$List = Get-TrelloList -Token $Token -Id $Board.Id -Name 'Subscriber Requests'

# Get Cards
$Cards = Get-TrelloCard -Token $Token -Id $Board.id -List $List

# Sort cards on number of votes
$NewBoard = Get-TrelloBoard -Token $Token -Name 'Trello Automation Playground'
$NewList = New-TrelloList -Token $Token -Id $NewBoard.id -Name $List.Name

$DescTemplate = 'This topic has received {0} vote from subscribers'

$SortableCards = foreach ($Card in $Cards) {
    try {
        $SortKey = [int]$Card.Name.Split(' ')[0]
    } catch {
        $SortKey = [int]::MaxValue
    }

    if ($SortKey -ne 0 -and $SortKey -ne [int]::MaxValue) {
        $Card.desc = $DescTemplate -f $SortKey

        if ($SortKey -gt 1) {
            $Card.desc = $Card.desc.Replace('vote', 'votes')
        }
    }

    [PSCustomObject] @{
        SortKey = $SortKey
        Card = $Card
    }
}

$SortableCards | where {$_.SortKey -eq 0} | foreach {
    New-TrelloCard -Token $Token -Id $NewList.id -Name $_.Card.name -Description $_.Card.desc
}

$SortableCards | where {$_.SortKey -ne 0 -and $_.SortKey -ne [int]::MaxValue} | Sort -Property SortKey -Descending | foreach {
    New-TrelloCard -Token $Token -Id $NewList.id -Name $_.Card.name -Description $_.Card.desc
}

$SortableCards | where {$_.SortKey -eq [int]::MaxValue} | foreach {
    New-TrelloCard -Token $Token -Id $NewList.id -Name $_.Card.name -Description $_.Card.desc
}

# Labels

$TechSnipsLabels = Get-TrelloLabel -Token $Token -Id $Board.id -All

foreach ($Label in $TechSnipsLabels) {
    if ($Label.color -ne '' -and $Label.color -ne $null) {
        New-TrelloLabel -Token $Token -Id $NewBoard.id -Name $Label.name -Color $Label.color
    }
}

# Find unprocessed cards

# Get requested categories

# Increment vote count for requested categories
